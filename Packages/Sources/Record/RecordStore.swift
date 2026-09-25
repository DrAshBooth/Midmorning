import Foundation
import SwiftData

/// One entry as Today reads it: the winning `ItemVersion` of one `Item`,
/// reduced to the fields a screen needs. Not a stored type; `RecordStore`
/// computes it with `EntryWinner` on every read (data-and-privacy spec,
/// "Entries are append-only versions").
public struct RecordRow: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let time: Date
    public let utcOffsetSeconds: Int
    public let what: String
    public let feltLikeABinge: Bool
    public let createdAt: Date
    public let dayKey: String
    /// A fixed chip's name or a custom place's text. Empty when the entry
    /// has no Where (record spec, "Where chips").
    public let whereText: String
    /// Free text under the What (record spec, "The Context field").
    public let context: String

    public init(
        id: UUID, time: Date, utcOffsetSeconds: Int, what: String, feltLikeABinge: Bool,
        createdAt: Date, dayKey: String, whereText: String = "", context: String = ""
    ) {
        self.id = id
        self.time = time
        self.utcOffsetSeconds = utcOffsetSeconds
        self.what = what
        self.feltLikeABinge = feltLikeABinge
        self.createdAt = createdAt
        self.dayKey = dayKey
        self.whereText = whereText
        self.context = context
    }

    init(entryId: UUID, winner: ItemVersion) {
        self.init(
            id: entryId,
            time: winner.time,
            utcOffsetSeconds: winner.utcOffsetSeconds,
            what: winner.what,
            feltLikeABinge: winner.feltLikeABinge,
            createdAt: winner.createdAt,
            dayKey: winner.dayKey,
            whereText: winner.whereText,
            context: winner.context
        )
    }
}

public extension RecordRow {
    /// The entry's time as "HH:mm" at the entry's own UTC offset.
    var clockTime: String {
        RecordRow.clockTime(for: time, utcOffsetSeconds: utcOffsetSeconds)
    }

    /// The VoiceOver label for the row (record spec, "Accessibility of the
    /// additions"): the time, then the What, the Where and the Context when
    /// each is not empty, then "felt like a binge" when the star is on. A
    /// comma and a space separate the parts that are present.
    var accessibilityLabel: String {
        var parts = [clockTime]
        if !what.isEmpty { parts.append(what) }
        if !whereText.isEmpty { parts.append(whereText) }
        if !context.isEmpty { parts.append(context) }
        if feltLikeABinge { parts.append("felt like a binge") }
        return parts.joined(separator: ", ")
    }

    static func clockTime(for time: Date, utcOffsetSeconds: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

/// The three record-day states this change keeps, each a `DayState` row
/// model-foundation's model shape already covers (record spec, "'Didn't
/// record'", "'Pause for today'", "'Fasting today'"). The feeling-word kind
/// belongs to a later change.
public enum DayStateKind: String, CaseIterable, Sendable {
    case didntRecord, paused, fasting
}

/// Whether a record day shows its rows or a count line (record spec,
/// "Collapse a day to a count"). Kept in `Local.store`, never synced.
public enum CollapseChoiceValue: String, Sendable {
    case expanded, collapsed
}

/// The only way to create and read entries. Opens two store configurations
/// in one directory: `Record.store` for synced rows, `Local.store` for
/// device-only rows (data-and-privacy spec, "Two store configurations in one
/// directory").
@MainActor
public final class RecordStore {
    /// Thrown by the store. Carries no entry data.
    public enum Failure: Error {
        case saveFailed
    }

    public let container: ModelContainer
    private let context: ModelContext

    /// Opens the store from the two files in `directory`: `Record.store` and
    /// `Local.store`. Sync is off: both configurations carry
    /// `cloudKitDatabase: .none` (sync turns on in 4.1b, on CKSyncEngine, not
    /// SwiftData's own mirroring).
    public init(directory: URL) throws {
        let recordConfiguration = ModelConfiguration(
            "Record",
            schema: Schema(RecordSchema.models),
            url: directory.appendingPathComponent("Record.store"),
            cloudKitDatabase: .none
        )
        let localConfiguration = ModelConfiguration(
            "Local",
            schema: Schema(RecordSchema.localModels),
            url: directory.appendingPathComponent("Local.store"),
            cloudKitDatabase: .none
        )
        container = try ModelContainer(
            for: Schema(RecordSchema.models + RecordSchema.localModels),
            migrationPlan: RecordMigrationPlan.self,
            configurations: recordConfiguration, localConfiguration
        )
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    /// Opens the store on a single legacy file URL, for tests that predate
    /// the two-configuration split. Prefer `init(directory:)`.
    public convenience init(url: URL) throws {
        try self.init(directory: url.deletingLastPathComponent())
    }

    // MARK: Entries

    /// Saves one entry as a new `Item` and its first `ItemVersion`, and
    /// returns the row. Trims white space and line breaks from the ends of
    /// `what` and `context`. Truncates `time` to the minute. Throws on
    /// failure with no entry data in the error.
    @discardableResult
    public func add(
        time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int,
        whereText: String = "", context: String = "", dayStartHour: Int = RecordDay.startHour
    ) throws -> RecordRow {
        let minute = Self.truncatedToMinute(time)
        let entryId = UUID()
        let item = Item(id: entryId)
        let version = ItemVersion(
            entryId: entryId,
            changedAt: createdAt,
            dayKey: RecordDay.key(for: minute, utcOffsetSeconds: utcOffsetSeconds, startHour: dayStartHour),
            time: minute,
            utcOffsetSeconds: utcOffsetSeconds,
            what: what.trimmingCharacters(in: .whitespacesAndNewlines),
            feltLikeABinge: feltLikeABinge,
            createdAt: createdAt,
            whereText: whereText,
            context: context.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        self.context.insert(item)
        self.context.insert(version)
        try persist()
        return RecordRow(entryId: entryId, winner: version)
    }

    /// Writes a new version of `entryId` with the changed fields (record
    /// spec, "Edit an entry"). Keeps the entry's record day, UTC offset and
    /// creation moment as they were; only a fresh `changedAt` and the given
    /// fields move. Throws `Failure.saveFailed` when `entryId` has no
    /// current version.
    @discardableResult
    public func update(
        entryId: UUID, time: Date, what: String, feltLikeABinge: Bool, whereText: String,
        context: String, editedAt: Date
    ) throws -> RecordRow {
        guard let current = try winningVersion(entryId: entryId) else { throw Failure.saveFailed }
        let version = ItemVersion(
            entryId: entryId,
            changedAt: editedAt,
            dayKey: current.dayKey,
            time: Self.truncatedToMinute(time),
            utcOffsetSeconds: current.utcOffsetSeconds,
            what: what.trimmingCharacters(in: .whitespacesAndNewlines),
            feltLikeABinge: feltLikeABinge,
            createdAt: current.createdAt,
            whereText: whereText,
            context: context.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        self.context.insert(version)
        try persist()
        return RecordRow(entryId: entryId, winner: version)
    }

    /// Writes a version of `entryId` with the deleted flag on (record spec,
    /// "Delete an entry"; data-and-privacy spec, "Entries are append-only
    /// versions"). Keeps every other field from the current winner: the
    /// store prunes a deleted version's content only after the 90-day
    /// retention rule, not at delete. Throws `Failure.saveFailed` when
    /// `entryId` has no current version.
    public func delete(entryId: UUID, deletedAt: Date) throws {
        guard let current = try winningVersion(entryId: entryId) else { throw Failure.saveFailed }
        let version = ItemVersion(
            entryId: entryId,
            changedAt: deletedAt,
            deleted: true,
            dayKey: current.dayKey,
            time: current.time,
            utcOffsetSeconds: current.utcOffsetSeconds,
            what: current.what,
            feltLikeABinge: current.feltLikeABinge,
            createdAt: current.createdAt,
            whereText: current.whereText,
            context: current.context
        )
        context.insert(version)
        try persist()
    }

    /// The winning row per entry id of the record day that contains `moment`
    /// in the calendar's zone, ordered by time, then by creation moment. An
    /// entry's day was fixed at save, so this matches by key, never by
    /// recomputing the entry's day.
    public func entries(recordDayContaining moment: Date, calendar: Calendar, dayStartHour: Int = RecordDay.startHour) throws -> [RecordRow] {
        try entries(dayKey: RecordDay.key(containing: moment, calendar: calendar, startHour: dayStartHour))
    }

    /// The winning, non-deleted row per entry id whose winning version keys
    /// to `dayKey`, ordered by time, then by creation moment.
    public func entries(dayKey: String) throws -> [RecordRow] {
        let versions = try allVersions(dayKey: dayKey)
        let winners = EntryWinner.winners(in: versions)
        return winners
            .filter { !$0.value.deleted }
            .map { RecordRow(entryId: $0.key, winner: $0.value) }
            .sorted { lhs, rhs in
                if lhs.time != rhs.time { return lhs.time < rhs.time }
                return lhs.createdAt < rhs.createdAt
            }
    }

    /// The number of winning, non-deleted entries keyed to `dayKey`, for the
    /// collapsed count line (record spec, "Collapse a day to a count").
    public func entryCount(dayKey: String) throws -> Int {
        try entries(dayKey: dayKey).count
    }

    /// Every date key before `dateKey` that has a non-deleted entry or an
    /// active day state, for "Earlier record days". A coarse presence check:
    /// any surviving `ItemVersion` for the day counts, without picking a
    /// per-entry winner first — cheap, and `entries(dayKey:)` is still the
    /// source of truth for what a day shows once opened.
    public func dateKeysWithContent(before dateKey: String) throws -> Set<String> {
        var versionDescriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.dayKey < dateKey && !$0.deleted })
        versionDescriptor.includePendingChanges = false
        let entryDayKeys = Set(try context.fetch(versionDescriptor).map(\.dayKey))

        var stateDescriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.dateKey < dateKey })
        stateDescriptor.includePendingChanges = false
        let stateWinners = DayStateReconciler.winners(in: try context.fetch(stateDescriptor))
        let activeStateDayKeys = Set(stateWinners.values.filter { $0.value == "on" }.map(\.dateKey))

        return entryDayKeys.union(activeStateDayKeys)
    }

    private func winningVersion(entryId: UUID) throws -> ItemVersion? {
        var descriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.entryId == entryId })
        descriptor.includePendingChanges = false
        return EntryWinner.pick(try context.fetch(descriptor))
    }

    private func allVersions(dayKey: String) throws -> [ItemVersion] {
        var descriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.dayKey == dayKey })
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor)
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }

    // MARK: Day states

    /// The active states of `dateKey`: a kind is active when its winning
    /// `DayState` row's `value` is "on" (record spec, "'Didn't record'",
    /// "'Pause for today'", "'Fasting today'").
    public func dayStates(dateKey: String) throws -> Set<DayStateKind> {
        var descriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.dateKey == dateKey })
        descriptor.includePendingChanges = false
        let winners = DayStateReconciler.winners(in: try context.fetch(descriptor))
        var active: Set<DayStateKind> = []
        for kind in DayStateKind.allCases where winners["\(dateKey)|\(kind.rawValue)"]?.value == "on" {
            active.insert(kind)
        }
        return active
    }

    /// Writes a new `DayState` row turning `kind` on or off for `dateKey`.
    /// Every write is a new row; the Reconciler's later-`changedAt` rule
    /// picks the winner on every read, on this device and across devices.
    public func setDayState(_ kind: DayStateKind, on: Bool, dateKey: String, changedAt: Date) throws {
        context.insert(DayState(dateKey: dateKey, kind: kind.rawValue, value: on ? "on" : "off", changedAt: changedAt))
        try persist()
    }

    // MARK: Collapse choice

    /// The kept collapse-or-expand choice for `dateKey`, or `nil` when the
    /// person has not chosen (record spec, "Collapse a day to a count"; kept
    /// in `Local.store`, never synced).
    public func collapseChoice(dateKey: String) throws -> CollapseChoiceValue? {
        let key = Self.collapseKey(dateKey)
        var descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        descriptor.includePendingChanges = false
        guard let row = try context.fetch(descriptor).first else { return nil }
        return CollapseChoiceValue(rawValue: row.value)
    }

    /// Keeps `value` as the collapse-or-expand choice for `dateKey`,
    /// replacing any earlier choice for that day.
    public func setCollapseChoice(_ value: CollapseChoiceValue, dateKey: String) throws {
        let key = Self.collapseKey(dateKey)
        let descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        if let existing = try context.fetch(descriptor).first {
            existing.value = value.rawValue
        } else {
            context.insert(LocalSetting(key: key, value: value.rawValue))
        }
        try persist()
    }

    private static func collapseKey(_ dateKey: String) -> String { "collapse.\(dateKey)" }

    // MARK: Where's custom places

    /// The custom Where places, most recently used first, capped at
    /// `CustomPlaces.maxChips` (record spec, "Where chips"). A custom place
    /// is a `ListItem` of kind "customPlace" (design.md, "Model names,
    /// singletons and the account binding").
    public func customPlaces() throws -> [String] {
        var descriptor = FetchDescriptor<ListItem>(predicate: #Predicate { $0.kind == "customPlace" && !$0.deleted })
        descriptor.includePendingChanges = false
        return CustomPlaces.ordered(try context.fetch(descriptor))
    }

    /// Keeps `text` as a custom place, touching its `changedAt` (its recency
    /// moment) when it already exists. Does nothing for an empty or a fixed
    /// chip's text.
    public func touchCustomPlace(_ text: String, at moment: Date) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !WhereChip.fixed.map(\.rawValue).contains(trimmed) else { return }
        let descriptor = FetchDescriptor<ListItem>(predicate: #Predicate { $0.kind == "customPlace" && $0.text == trimmed })
        if let existing = try context.fetch(descriptor).first {
            existing.changedAt = moment
            existing.deleted = false
        } else {
            context.insert(ListItem(kind: "customPlace", text: trimmed, changedAt: moment))
        }
        try persist()
    }

    // MARK: Persistence

    private func persist() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
    }
}

/// The store directory inside the app's own `Application Support` directory
/// — never inside the App Group container (data-and-privacy spec, "The
/// store lives in the app's own container"). The App target's own
/// `StoreLocation.url()` builds this same path against the real sandbox;
/// this is the pure, non-isolated form a test can check with a fixed URL.
public enum StoreLayout {
    public static func storeDirectory(applicationSupportDirectory: URL) -> URL {
        applicationSupportDirectory.appendingPathComponent("Record", isDirectory: true)
    }
}

/// What the App Group container holds: only the widget snapshot and the
/// action queue, never the store (data-and-privacy spec, "The store lives in
/// the app's own container": "App Group content"). `widgets-and-intents`
/// (2.5) names the real files; this records the shape now so the store never
/// grows into the App Group by accident.
public enum AppGroupContent {
    public static let fileStems: Set<String> = ["snapshot", "queue"]
}
