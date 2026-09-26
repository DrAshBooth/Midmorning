import Foundation
import SwiftData
import Constants
import Plan

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
    var accessibilityLabel: CatalogueText {
        var parts: [CatalogueText] = [.verbatim(clockTime)]
        if !what.isEmpty { parts.append(.verbatim(what)) }
        if !whereText.isEmpty { parts.append(.verbatim(whereText)) }
        if !context.isEmpty { parts.append(.verbatim(context)) }
        if feltLikeABinge { parts.append(.key("entry.feltLikeABinge")) }
        return .list(parts)
    }

    static func clockTime(for time: Date, utcOffsetSeconds: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

/// The record-day states this change keeps, each a `DayState` row
/// model-foundation's model shape already covers (record spec, "'Didn't
/// record'", "'Pause for today'", "'Fasting today'"; reminders spec, "Close
/// the day": the one-word feeling row). `.feelingWord` holds free text, not
/// "on"/"off", so `dayStates(dateKey:)`'s on/off read never matches it; a
/// dedicated pair, `feelingWord(dateKey:)`/`setFeelingWord(_:dateKey:changedAt:)`,
/// reads and writes it.
public enum DayStateKind: String, CaseIterable, Sendable {
    case didntRecord, paused, fasting, feelingWord
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
        // Every file `Record.store` and `Local.store` create (each one's
        // main file, `-wal` and `-shm`) carries `NSFileProtectionComplete`
        // (data-and-privacy spec, "File protection": "Store files"). The App
        // target opens through `openInPreparedDirectory`, which protects the
        // directory itself; this protects the files `ModelContainer` just
        // created inside it.
        FileProtection.applyToDatabaseFiles(in: directory)
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
    /// failure with no entry data in the error. The entry keeps the UTC
    /// offset of `deviceZone` at `time`, not at `createdAt`
    /// (`EntryOffset.forNewEntry`); the new-entry screen passes no offset.
    /// `utcOffsetSeconds` sets one fixed offset instead, for a test or an
    /// import. The record day key comes from `time`, that offset and the
    /// "Day starts at" rows in force (record spec, "The record day");
    /// `dayStartHour` sets one fixed hour instead, for a test.
    @discardableResult
    public func add(
        time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int? = nil,
        whereText: String = "", context: String = "", dayStartHour: Int? = nil, deviceZone: TimeZone = .current
    ) throws -> RecordRow {
        let minute = Self.truncatedToMinute(time)
        let utcOffsetSeconds = utcOffsetSeconds ?? EntryOffset.forNewEntry(at: minute, deviceZone: deviceZone)
        let entryId = UUID()
        let item = Item(id: entryId)
        let schedule = try dayStartHour.map(DayStartSchedule.constant) ?? dayStartSchedule()
        let version = ItemVersion(
            entryId: entryId,
            changedAt: createdAt,
            dayKey: RecordDay.key(for: minute, utcOffsetSeconds: utcOffsetSeconds, schedule: schedule),
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
    /// spec, "Edit an entry"). Keeps the entry's record day and creation
    /// moment as they were; only a fresh `changedAt` and the given fields
    /// move. The version keeps the UTC offset of the entry's edit zone at
    /// `time` (`EntryOffset.forEdit`, `EntryOffset.editZone`): for an entry
    /// from `deviceZone`, that zone's offset at the edited time; for an
    /// entry from another zone, the entry's own offset. So the edited time
    /// and the kept offset still give the kept record day key. The edit
    /// screen passes no offset.
    /// Throws `Failure.saveFailed` when `entryId` has no current version.
    @discardableResult
    public func update(
        entryId: UUID, time: Date, what: String, feltLikeABinge: Bool, whereText: String,
        context: String, editedAt: Date, deviceZone: TimeZone = .current
    ) throws -> RecordRow {
        guard let current = try winningVersion(entryId: entryId) else { throw Failure.saveFailed }
        let minute = Self.truncatedToMinute(time)
        let version = ItemVersion(
            entryId: entryId,
            changedAt: editedAt,
            dayKey: current.dayKey,
            time: minute,
            utcOffsetSeconds: EntryOffset.forEdit(
                entryTime: current.time, entryOffsetSeconds: current.utcOffsetSeconds, editedTime: minute, deviceZone: deviceZone
            ),
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
    public func entries(recordDayContaining moment: Date, calendar: Calendar, dayStartHour: Int? = nil) throws -> [RecordRow] {
        let schedule = try dayStartHour.map(DayStartSchedule.constant) ?? dayStartSchedule()
        return try entries(dayKey: RecordDay.key(containing: moment, calendar: calendar, schedule: schedule))
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

    /// The earliest record day key with a non-deleted entry, or `nil` when
    /// none exists (export spec, "Choose a date range": "When the earliest
    /// record day with an entry is later, 'From' MUST default to that
    /// day.").
    public func earliestEntryDayKey() throws -> String? {
        try liveEntryDayKeys(before: nil).min()
    }

    /// Every date key before `dateKey` that has a non-deleted entry or an
    /// active day state, for "Earlier record days".
    public func dateKeysWithContent(before dateKey: String) throws -> Set<String> {
        let entryDayKeys = try liveEntryDayKeys(before: dateKey)

        var stateDescriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.dateKey < dateKey })
        stateDescriptor.includePendingChanges = false
        let stateWinners = DayStateReconciler.winners(in: try context.fetch(stateDescriptor))
        let activeStateDayKeys = Set(stateWinners.values.filter { $0.value == "on" }.map(\.dateKey))

        return entryDayKeys.union(activeStateDayKeys)
    }

    /// The record day keys (before `dateKey`, when given) of every entry
    /// whose winning version is not deleted. A delete appends a deleted
    /// version and keeps the earlier ones (data-and-privacy spec, "Entries
    /// are append-only versions"), so a plain `!deleted` filter on versions
    /// still matches a deleted entry's earlier version. Every version of an
    /// entry holds the same key, because an entry never changes record day.
    private func liveEntryDayKeys(before dateKey: String?) throws -> Set<String> {
        var descriptor: FetchDescriptor<ItemVersion>
        if let dateKey {
            descriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.dayKey < dateKey })
        } else {
            descriptor = FetchDescriptor<ItemVersion>()
        }
        descriptor.includePendingChanges = false
        return Set(EntryWinner.winners(in: try context.fetch(descriptor)).values.filter { !$0.deleted }.map(\.dayKey))
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

    nonisolated static func truncatedToMinute(_ date: Date) -> Date {
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

    /// Turns `kind` on or off for `dateKey`. Writes into the winning
    /// `DayState` row of (`dateKey`, `kind`), or inserts the first row for
    /// that key (`writeDayState`).
    public func setDayState(_ kind: DayStateKind, on: Bool, dateKey: String, changedAt: Date) throws {
        try writeDayState(kind: kind.rawValue, value: on ? "on" : "off", dateKey: dateKey, changedAt: changedAt)
    }

    /// Writes into the winning `DayState` row of (`dateKey`, `kind`) after a
    /// reconciled fetch, or inserts the first row when no row exists for
    /// that key (data-and-privacy spec, "Rows reference each other by key":
    /// "An edit of a row other than an entry MUST write into the winning
    /// row"). A losing row stays as it is. A write that is earlier than the
    /// winner loses (`Self.wins`) and changes nothing.
    private func writeDayState(kind: String, value: String, dateKey: String, changedAt: Date) throws {
        let descriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.dateKey == dateKey && $0.kind == kind })
        if let winner = DayStateReconciler.winners(in: try context.fetch(descriptor))["\(dateKey)|\(kind)"] {
            guard Self.wins(changedAt, over: winner.changedAt) else { return }
            winner.value = value
            winner.changedAt = changedAt
        } else {
            context.insert(DayState(dateKey: dateKey, kind: kind, value: value, changedAt: changedAt))
        }
        try persist()
    }

    /// The winning "one word for how today felt" (reminders spec, "Close the
    /// day"), or `nil` when the person has not saved one. An empty saved
    /// text reads back as `""`, not `nil` — the store never hard-deletes a
    /// row, so the row's own presence, not its text, decides.
    public func feelingWord(dateKey: String) throws -> String? {
        let kindRaw = DayStateKind.feelingWord.rawValue
        var descriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.dateKey == dateKey && $0.kind == kindRaw })
        descriptor.includePendingChanges = false
        let winners = DayStateReconciler.winners(in: try context.fetch(descriptor))
        return winners["\(dateKey)|\(kindRaw)"]?.value
    }

    /// Keeps `word` as the feeling word of `dateKey`, in the winning
    /// feeling-word row (`writeDayState`).
    public func setFeelingWord(_ word: String, dateKey: String, changedAt: Date) throws {
        try writeDayState(kind: DayStateKind.feelingWord.rawValue, value: word, dateKey: dateKey, changedAt: changedAt)
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
    /// chip's text. The touch writes into the winning row of the place: of
    /// the winners per id, the one with the latest `changedAt`. A touch that
    /// is earlier than that row changes nothing (`Self.wins`), so the
    /// recency moment never goes back.
    public func touchCustomPlace(_ text: String, at moment: Date) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !WhereChip.fixed.map(\.rawValue).contains(trimmed) else { return }
        let descriptor = FetchDescriptor<ListItem>(predicate: #Predicate { $0.kind == "customPlace" && $0.text == trimmed })
        let winners = Reconciler.latestWins(try context.fetch(descriptor), key: \.id, changedAt: \.changedAt).values
        if let existing = winners.max(by: { $0.changedAt < $1.changedAt }) {
            guard Self.wins(moment, over: existing.changedAt) else { return }
            existing.changedAt = moment
            existing.deleted = false
        } else {
            context.insert(ListItem(kind: "customPlace", text: trimmed, changedAt: moment))
        }
        try persist()
    }

    // MARK: Persistence

    /// Whether a write at `changedAt` wins over the winning row's own
    /// `changedAt` under the later-`changedAt` rule (data-and-privacy spec,
    /// "Conflict rules for the plan, weigh-ins and lists": "the store MUST
    /// keep the version with the later `changedAt` whole"). A write that
    /// loses changes nothing, which is what a read shows after a losing
    /// row: for example a queued "Skipped" at 13:40 that the app applies
    /// after an in-app answer at 13:50. An equal moment wins, so a second
    /// write in the same instant is not lost.
    static func wins(_ changedAt: Date, over winnerChangedAt: Date) -> Bool {
        changedAt >= winnerChangedAt
    }

    private func persist() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
        NotificationCenter.default.post(name: Self.didSaveNotification, object: self)
    }

    // MARK: - Settings: synced key/value rows (data-and-privacy spec, "Slot
    // labels and the day start are Settings rows")

    /// The winning value for a synced `Settings` key, or `nil` when no row
    /// has ever been written for it. Fetches only the rows of `key`.
    public func settingValue(key: String) throws -> String? {
        try settingsWinner(key: key)?.value
    }

    /// Writes `value` into the winning `Settings` row for `key` after a
    /// reconciled fetch, or inserts the first row when no row exists for
    /// the key (data-and-privacy spec, "Rows reference each other by key":
    /// "An edit of a row other than an entry MUST write into the winning
    /// row"). A losing row stays as it is, and a write that is earlier than
    /// the winner changes nothing (`Self.wins`). The day start rows do not
    /// come here: they are append-only (`setDayStartHour`).
    public func setSettingValue(_ value: String, key: String, changedAt: Date = .now) throws {
        if let winner = try settingsWinner(key: key) {
            guard Self.wins(changedAt, over: winner.changedAt) else { return }
            winner.value = value
            winner.changedAt = changedAt
        } else {
            context.insert(Settings(key: key, value: value, changedAt: changedAt))
        }
        try persist()
    }

    private func settingsWinner(key: String) throws -> Settings? {
        let descriptor = FetchDescriptor<Settings>(predicate: #Predicate { $0.key == key })
        return SettingsReconciler.winners(in: try context.fetch(descriptor))[key]
    }

    // MARK: - LocalSetting: device-only key/value rows

    /// The value of a device-only key, or `nil` when no row exists.
    public func localSettingValue(key: String) throws -> String? {
        var descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.value
    }

    /// Upserts a device-only value: one row per key, updated in place.
    /// `Local.store` never syncs, so there is no Reconciler and no conflict
    /// to pick a winner from.
    public func setLocalSettingValue(_ value: String, key: String) throws {
        var descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.value = value
        } else {
            context.insert(LocalSetting(key: key, value: value))
        }
        try persist()
    }

    // MARK: - Diagnostics: the eight counts (data-and-privacy spec, "The
    // Diagnostics counts come from the device"; settings spec, "The About
    // group")

    private static let launchFailureCountKey = "diagnostics.launchFailureCount"
    private static let lastSuccessfulSyncDayKey = "diagnostics.lastSuccessfulSyncDay"
    private static let reconcileWinnersKey = "diagnostics.reconcile.winners"
    private static let reconcileLosersKey = "diagnostics.reconcile.losers"
    private static let crashCountKey = "diagnostics.crashCount"

    private func localIntSettingValue(key: String) throws -> Int {
        try (localSettingValue(key: key)).flatMap(Int.init) ?? 0
    }

    /// Every count the Diagnostics page shows. `contentVersion` is the
    /// content capability's own value; `sourceCounts` is the device's
    /// pending-reminders count and the action queue's length, which the App
    /// target reads from the notification centre and the queue file.
    public func diagnosticsCounts(contentVersion: Int, sourceCounts: DiagnosticsSourceCounts = ZeroDiagnosticsSourceCounts()) throws -> DiagnosticsCounts {
        DiagnosticsCounts(
            launchFailures: try localIntSettingValue(key: Self.launchFailureCountKey),
            lastSuccessfulSyncDay: try (localSettingValue(key: Self.lastSuccessfulSyncDayKey)).map(CatalogueText.verbatim) ?? DiagnosticsCounts.noSyncYet,
            schemaVersion: "\(RecordSchemaV1.versionIdentifier)",
            contentVersion: contentVersion,
            pendingReminders: sourceCounts.pendingReminders,
            queueLength: sourceCounts.queueLength,
            lastReconcileOutcome: DiagnosticsCounts.ReconcileOutcome(
                winners: try localIntSettingValue(key: Self.reconcileWinnersKey),
                losers: try localIntSettingValue(key: Self.reconcileLosersKey)
            ),
            crashCount: try localIntSettingValue(key: Self.crashCountKey)
        )
    }

    /// Adds one to the launch failure count (data-and-privacy spec, "Launch
    /// safety": "Launch failures counted"). Returns the new count.
    @discardableResult
    public func incrementLaunchFailureCount() throws -> Int {
        let next = try localIntSettingValue(key: Self.launchFailureCountKey) + 1
        try setLocalSettingValue(String(next), key: Self.launchFailureCountKey)
        return next
    }

    /// Adds one to the MetricKit crash count (data-and-privacy spec, "No
    /// record content in the system log or crash reports": "MetricKit
    /// diagnostic"). Keeps no part of the diagnostic itself. Returns the new
    /// count.
    @discardableResult
    public func incrementCrashCount() throws -> Int {
        let next = try localIntSettingValue(key: Self.crashCountKey) + 1
        try setLocalSettingValue(String(next), key: Self.crashCountKey)
        return next
    }

    /// Records a reconcile pass's winner and loser counts, for the
    /// Diagnostics page's "last reconcile outcome". Nothing in the first cut
    /// runs a reconcile pass yet, so both counts stay zero until a later
    /// change calls this.
    public func recordReconcileOutcome(winners: Int, losers: Int) throws {
        try setLocalSettingValue(String(winners), key: Self.reconcileWinnersKey)
        try setLocalSettingValue(String(losers), key: Self.reconcileLosersKey)
    }

    // MARK: - The Record group: "Day starts at" and "Gap bands" (settings
    // spec, "The Record group"; decision 65)

    /// Every append-only `DayStartSetting` row, one winner per effective day,
    /// as one schedule. A screen reads it once per load and passes it to
    /// every `RecordDay` call, so the current record day, its neighbours and
    /// each day's start all use the day start in force, with no two-step
    /// lookup (record spec, "The record day").
    public func dayStartSchedule() throws -> DayStartSchedule {
        let prefix = DayStartSetting.key(effectiveFromDayKey: "")
        let rows = try context.fetch(FetchDescriptor<Settings>(predicate: #Predicate { $0.key.starts(with: prefix) }))
        let changes = SettingsReconciler.winners(in: rows).values.compactMap { row -> DayStartSchedule.Change? in
            guard row.key.hasPrefix(prefix), let hour = Int(row.value) else { return nil }
            return DayStartSchedule.Change(effectiveFromDayKey: String(row.key.dropFirst(prefix.count)), hour: hour)
        }
        return DayStartSchedule(changes: changes)
    }

    /// The day-start hour in effect for the record day keyed `dayKey`: the
    /// latest append-only `DayStartSetting` row whose effective day is
    /// `dayKey` or earlier, or `RecordDay.startHour` when no row applies yet.
    public func dayStartHour(effectiveOn dayKey: String) throws -> Int {
        try dayStartSchedule().hour(effectiveOn: dayKey)
    }

    /// Writes a new "Day starts at" hour, effective from the record day
    /// right after `now` — never from `now`'s own record day, so no saved
    /// entry's record day changes. Always a new row: the day start rows are
    /// append-only (data-and-privacy spec, "Slot labels and the day start
    /// are Settings rows"), so this does not write into an earlier row.
    public func setDayStartHour(_ hour: Int, now: Date, calendar: Calendar, changedAt: Date = .now) throws {
        let choices = RecordDay.startHourChoices
        let nextDayKey = RecordDay.nextDayKey(after: now, calendar: calendar, schedule: try dayStartSchedule())
        let value = String(min(max(hour, choices.lowerBound), choices.upperBound))
        context.insert(Settings(key: DayStartSetting.key(effectiveFromDayKey: nextDayKey), value: value, changedAt: changedAt))
        try persist()
    }

    /// The hour the "Day starts at" row shows: the hour in force from the
    /// record day after `now`, so the row shows a change at once, although
    /// the change applies only from the next day start.
    public func dayStartHourFromNextRecordDay(after now: Date, calendar: Calendar) throws -> Int {
        let schedule = try dayStartSchedule()
        return schedule.hour(effectiveOn: RecordDay.nextDayKey(after: now, calendar: calendar, schedule: schedule))
    }

    // MARK: - Profile: the one-time BMI (onboarding spec, "What onboarding
    // keeps and what it never keeps"; safeguarding spec, "Re-screening at a
    // restart")

    /// The winning `Profile` row: height, the onboarding BMI, the caution
    /// flag and `askedAt`, or `nil` before onboarding writes it. Sync can
    /// bring a second row with the same fixed id; `ProfileReconciler` picks
    /// the winner.
    public func profile() throws -> Profile? {
        let fixedId = Profile.fixedId
        let descriptor = FetchDescriptor<Profile>(predicate: #Predicate { $0.id == fixedId })
        return ProfileReconciler.winner(in: try context.fetch(descriptor))
    }

    /// Writes into the winning `Profile` row, or inserts the first one.
    /// Onboarding calls this once, at "Start"; a later re-screen calls it
    /// again with a later `changedAt`, the field `data-and-privacy` keeps on
    /// sync. A write that is earlier than the winning row changes nothing
    /// (`Self.wins`), so an older screening never replaces a newer one.
    public func setProfile(heightCm: Double, onboardingBMI: Double, cautionFlag: Bool, askedAt: Date, changedAt: Date = .now) throws {
        if let existing = try profile() {
            guard Self.wins(changedAt, over: existing.changedAt) else { return }
            existing.heightCm = heightCm
            existing.onboardingBMI = onboardingBMI
            existing.cautionFlag = cautionFlag
            existing.askedAt = askedAt
            existing.changedAt = changedAt
        } else {
            context.insert(Profile(heightCm: heightCm, onboardingBMI: onboardingBMI, cautionFlag: cautionFlag, askedAt: askedAt, changedAt: changedAt))
        }
        try persist()
    }

    // MARK: - Onboarding: the start day, the weigh-in day and Local.store's
    // device state (onboarding spec, "Screen 3: the start day", "Screen 3:
    // weigh-in day and quiet hours", "Screen 4: your record", "Finish")

    private static let startDaySettingKey = "onboarding.startDay"

    /// The chosen start day, as a record-day key, or `nil` before "Start".
    public func startDayKey() throws -> String? {
        try settingValue(key: Self.startDaySettingKey)
    }

    /// Keeps the chosen start day as a calendar date, in one `Settings` row.
    /// When two devices hold a start day, `SettingsReconciler` keeps the
    /// later `changedAt`, so a restart's write replaces the earlier one.
    public func setStartDayKey(_ dayKey: String, changedAt: Date = .now) throws {
        try setSettingValue(dayKey, key: Self.startDaySettingKey, changedAt: changedAt)
    }

    /// "Weigh-in day" or "I won't be weighing" (onboarding spec, "Screen 3:
    /// weigh-in day and quiet hours"). The weekday matches `Calendar`'s own
    /// `weekday` component: 1 is Sunday, 7 is Saturday.
    public enum WeighInDayChoice: Sendable, Equatable {
        case weekday(Int)
        case wontBeWeighing

        /// The chosen weekday, or `nil` for "I won't be weighing".
        public var weekday: Int? {
            if case .weekday(let weekday) = self { return weekday }
            return nil
        }
    }

    private static let weighInDaySettingKey = "onboarding.weighInDay"

    public func weighInDayChoice() throws -> WeighInDayChoice? {
        guard let value = try settingValue(key: Self.weighInDaySettingKey) else { return nil }
        if value == "none" { return .wontBeWeighing }
        return Int(value).map(WeighInDayChoice.weekday)
    }

    public func setWeighInDayChoice(_ choice: WeighInDayChoice, changedAt: Date = .now) throws {
        let value: String
        switch choice {
        case .weekday(let weekday): value = String(weekday)
        case .wontBeWeighing: value = "none"
        }
        try setSettingValue(value, key: Self.weighInDaySettingKey, changedAt: changedAt)
    }

    // Local.store: device-only onboarding state (data-and-privacy spec,
    // "Two store configurations in one directory").

    private static let installMomentKey = "onboarding.installMoment"

    /// The moment onboarding's first screen wrote at first launch, or `nil`
    /// before that (onboarding spec, "Four screens, once, in order": "writes
    /// the install moment to Local.store").
    public func installMoment() throws -> Date? {
        try localSettingValue(key: Self.installMomentKey).flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    public func setInstallMoment(_ moment: Date) throws {
        try setLocalSettingValue(ISO8601DateFormatter().string(from: moment), key: Self.installMomentKey)
    }

    private static let onboardingCompletedKey = "onboarding.completed"

    /// The completion flag: `false` until "Start" sets it (onboarding spec, "Finish").
    public func onboardingCompleted() throws -> Bool {
        try localBoolSetting(key: Self.onboardingCompletedKey, default: false)
    }

    public func setOnboardingCompleted(_ completed: Bool) throws {
        try setLocalBoolSetting(completed, key: Self.onboardingCompletedKey)
    }

    private static let syncOnKey = "onboarding.syncOn"

    /// The sync choice as device state (onboarding spec, "Screen 4: your
    /// record"). `false` — off — in the first cut, always, because "Your
    /// record" shows one control, "This device only".
    public func syncOn() throws -> Bool {
        try localBoolSetting(key: Self.syncOnKey, default: false)
    }

    public func setSyncOn(_ on: Bool) throws {
        try setLocalBoolSetting(on, key: Self.syncOnKey)
    }

    // MARK: - Plan: templates, days and planned-meal answers (regular-eating-
    // plan spec, "Weekday and weekend templates", "A planned day", "The
    // plan's data stays on the device"). An edit writes into the winning row
    // of its natural key after a reconciled fetch, and inserts a row only
    // when no row exists for the key (data-and-privacy spec, "Rows reference
    // each other by key"). The Reconciler picks the winner on read.

    public enum TemplateKind: String, Sendable, CaseIterable, Equatable {
        case weekday, weekend
    }

    /// The winning `slotsJSON` for `kind`'s template, or "[]" when none
    /// exists yet. Fetches only the rows of `kind`.
    public func templateSlotsJSON(_ kind: TemplateKind) throws -> String {
        try templateWinner(kind)?.slotsJSON ?? "[]"
    }

    /// Writes `json` into the winning `Template` row for `kind`, or inserts
    /// the first row for `kind`. A write that is earlier than the winner
    /// changes nothing (`Self.wins`).
    public func setTemplateSlotsJSON(_ json: String, kind: TemplateKind, changedAt: Date) throws {
        if let winner = try templateWinner(kind) {
            guard Self.wins(changedAt, over: winner.changedAt) else { return }
            winner.slotsJSON = json
            winner.changedAt = changedAt
        } else {
            context.insert(Template(kind: kind.rawValue, slotsJSON: json, changedAt: changedAt))
        }
        try persist()
    }

    private func templateWinner(_ kind: TemplateKind) throws -> Template? {
        let kindValue = kind.rawValue
        let descriptor = FetchDescriptor<Template>(predicate: #Predicate { $0.kind == kindValue })
        return TemplateReconciler.winners(in: try context.fetch(descriptor))[kindValue]
    }

    /// One record day's plan, as the store keeps it (regular-eating-plan
    /// spec, "A planned day").
    public struct DayPlan: Sendable, Equatable {
        public let dateKey: String
        public let slotsJSON: String
        public let windowBeforeMinutes: Int
        public let windowAfterMinutes: Int
        public let setAt: Date?
        public let setBy: String
    }

    /// The winning `Day` row for `dateKey`, or `nil` when no row exists yet
    /// (the day's plan then comes from its template).
    public func dayPlan(dateKey: String) throws -> DayPlan? {
        var descriptor = FetchDescriptor<Day>(predicate: #Predicate { $0.dateKey == dateKey })
        descriptor.includePendingChanges = false
        guard let winner = DayReconciler.winners(in: try context.fetch(descriptor))[dateKey] else { return nil }
        return DayPlan(
            dateKey: winner.dateKey, slotsJSON: winner.slotsJSON,
            windowBeforeMinutes: winner.windowBeforeMinutes, windowAfterMinutes: winner.windowAfterMinutes,
            setAt: winner.setAt, setBy: winner.setBy
        )
    }

    /// True once any `Day` row for `dateKey` carries a set event, on this
    /// device or synced from another (regular-eating-plan spec, "A planned
    /// day": "A set event on any device means the day is set").
    public func isSetDay(dateKey: String) throws -> Bool {
        try dayPlan(dateKey: dateKey)?.setAt != nil
    }

    /// Writes the person's edit to `dateKey`'s plan from "Today's plan" or
    /// "Tomorrow's plan", and sets the day (regular-eating-plan spec, "A
    /// planned day": "The person taps 'Save' on an edit ... for that day").
    /// Writes into the plan winner of `dateKey` (the row with the later
    /// `changedAt`, often the materialised row), or inserts the first row
    /// for the key. An existing row keeps its window constants from its
    /// materialisation, and keeps its set event when it has one: "set" is
    /// sticky, and the store never removes or moves a set event.
    /// `windowBeforeMinutes` and `windowAfterMinutes` apply only to a new
    /// row. A plan that is earlier than the winner does not change the
    /// winner's plan (`Self.wins`), but its set event still applies: a set
    /// event on any device means the day is set. `DayReconciler` still keeps
    /// the earliest set event of any row for the key.
    public func setDayPlan(
        dateKey: String, slotsJSON: String, windowBeforeMinutes: Int, windowAfterMinutes: Int,
        setAt: Date, setBy: String, changedAt: Date
    ) throws {
        let rows = try context.fetch(FetchDescriptor<Day>(predicate: #Predicate { $0.dateKey == dateKey }))
        if let winner = DayReconciler.payloadWinners(in: rows)[dateKey] {
            if Self.wins(changedAt, over: winner.changedAt) {
                winner.slotsJSON = slotsJSON
                winner.changedAt = changedAt
            }
            if winner.setAt == nil {
                // The set event a reader already sees (the earliest of any
                // row for the key) stays; only an unset day takes this one.
                let seen = DayReconciler.winners(in: rows)[dateKey]
                if let seen, let seenSetAt = seen.setAt {
                    winner.setAt = seenSetAt
                    winner.setBy = seen.setBy
                } else {
                    winner.setAt = setAt
                    winner.setBy = setBy
                }
            }
        } else {
            context.insert(Day(
                dateKey: dateKey, slotsJSON: slotsJSON, windowBeforeMinutes: windowBeforeMinutes,
                windowAfterMinutes: windowAfterMinutes, changedAt: changedAt, setAt: setAt, setBy: setBy
            ))
        }
        try persist()
    }

    /// Copies the template onto `dateKey` as a `Day` row, only when no row
    /// for that key exists yet (regular-eating-plan spec, "Weekday and
    /// weekend templates": "Materialisation MUST NOT create a Day row for a
    /// key that already exists"; data-and-privacy spec: "Materialisation
    /// MUST NOT write `changedAt`"). `.distantPast` is the sentinel: a real
    /// edit's own `changedAt` always outranks it, and it is never read as a
    /// genuine moment. Returns whether it wrote a row.
    @discardableResult
    public func materialiseDayFromTemplate(dateKey: String, slotsJSON: String, windowBeforeMinutes: Int, windowAfterMinutes: Int) throws -> Bool {
        guard try dayPlan(dateKey: dateKey) == nil else { return false }
        context.insert(Day(dateKey: dateKey, slotsJSON: slotsJSON, windowBeforeMinutes: windowBeforeMinutes, windowAfterMinutes: windowAfterMinutes, changedAt: .distantPast))
        try persist()
        return true
    }

    /// The key of every record day that has a `Day` row, from this device
    /// or from another (mm-t23.21).
    public func dayRowKeys() throws -> Set<String> {
        var descriptor = FetchDescriptor<Day>()
        descriptor.includePendingChanges = false
        return Set(try context.fetch(descriptor).map(\.dateKey))
    }

    /// The winning value of `dateKey`'s `slotIndex` planned-meal answer
    /// ("Skipped", or a later answer kind), or `nil` when unanswered.
    public func plannedMealAnswer(dateKey: String, slotIndex: Int) throws -> String? {
        try plannedMealAnswers(dateKey: dateKey)[slotIndex]
    }

    /// Every planned-meal answer of `dateKey`, by slot index.
    public func plannedMealAnswers(dateKey: String) throws -> [Int: String] {
        var descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "plannedMeal" && $0.dateKey == dateKey })
        descriptor.includePendingChanges = false
        let winners = AnswerReconciler.winners(in: try context.fetch(descriptor))
        return Dictionary(uniqueKeysWithValues: winners.values.map { ($0.slotIndex, $0.value) })
    }

    /// Writes `value` into the winning planned-meal `Answer` row of
    /// (`dateKey`, `slotIndex`), or inserts the first row for that key.
    public func setPlannedMealAnswer(_ value: String, dateKey: String, slotIndex: Int, changedAt: Date) throws {
        let descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "plannedMeal" && $0.dateKey == dateKey && $0.slotIndex == slotIndex })
        let row = Answer(kind: "plannedMeal", dateKey: dateKey, slotIndex: slotIndex, value: value, changedAt: changedAt)
        try writeAnswer(row, winner: AnswerReconciler.winners(in: try context.fetch(descriptor))[AnswerReconciler.naturalKey(row)])
    }

    /// Writes the value and the moment of `row` into `winner`, the winning
    /// `Answer` row of the same natural key, or inserts `row` when no row
    /// exists for the key. A write that is earlier than the winner changes
    /// nothing (`Self.wins`).
    private func writeAnswer(_ row: Answer, winner: Answer?) throws {
        if let winner {
            guard Self.wins(row.changedAt, over: winner.changedAt) else { return }
            winner.value = row.value
            winner.changedAt = row.changedAt
        } else {
            context.insert(row)
        }
        try persist()
    }

    /// The "Skipped" answer, from Today, an earlier day or a reminder action.
    public func setPlannedMealSkipped(dateKey: String, slotIndex: Int, changedAt: Date) throws {
        try setPlannedMealAnswer(PlannedMealAnswer.skipped, dateKey: dateKey, slotIndex: slotIndex, changedAt: changedAt)
    }

    /// The stored override of a slot's label, or `nil` when the slot shows
    /// its default label (regular-eating-plan spec, "Rename a slot in the
    /// plan builder").
    public func slotLabel(index: Int) throws -> String? {
        try settingValue(key: Settings.slotLabelKey(index))
    }

    /// Writes the slot's label into its `Settings` row. `nil` writes an
    /// empty value, which reverts the slot to its default label — the store
    /// never deletes a row, even to clear one (data-and-privacy spec, "The
    /// Reconciler never deletes a row").
    public func setSlotLabel(_ label: String?, index: Int, changedAt: Date) throws {
        try setSettingValue(label ?? "", key: Settings.slotLabelKey(index), changedAt: changedAt)
    }

    // MARK: - Weigh-in: the kept row and the Weigh-in group's unit (weigh-in
    // spec, "The store keeps the weigh-in on the device and away from
    // HealthKit"; settings spec, "The Weigh-in group"). The row is a
    // `Measure` row, one per record day key. A change writes into the
    // winning row of the key; `MeasureReconciler` picks the winner on read.

    /// One saved weigh-in as the app reads it: its record day key, its kept
    /// kilogram value, the unit the person used, and its `savedAt` and
    /// `changedAt` moments.
    public struct WeighInRow: Sendable, Equatable {
        public let dateKey: String
        public let weightKg: Double
        public let unit: String
        public let savedAt: Date
        public let changedAt: Date
    }

    /// The winning weigh-in for `dateKey`, or `nil` when none exists.
    public func weighIn(dateKey: String) throws -> WeighInRow? {
        var descriptor = FetchDescriptor<Measure>(predicate: #Predicate { $0.dateKey == dateKey })
        descriptor.includePendingChanges = false
        return MeasureReconciler.winners(in: try context.fetch(descriptor))[dateKey].map(weighInRow)
    }

    /// Every kept weigh-in, one per record day key, oldest first (weigh-in
    /// spec, "The chart": "The chart MUST show every weigh-in in the
    /// programme."; "The store keeps every weigh-in" while no weigh-in day
    /// exists).
    public func weighIns() throws -> [WeighInRow] {
        let winners = MeasureReconciler.winners(in: try context.fetch(FetchDescriptor<Measure>()))
        return winners.values
            .map(weighInRow)
            .sorted { $0.dateKey < $1.dateKey }
    }

    /// Saves `weightKg` for `dateKey` (weigh-in spec, "The app accepts a
    /// weight on the weigh-in day only": "For 10 minutes after 'Save', the
    /// person MUST be able to change the number."). A later call for the
    /// same `dateKey` writes into the winning row of that key: it keeps the
    /// row's `savedAt` and writes a new `changedAt` ("A change within the 10
    /// minutes MUST write into the same row with a later `changedAt`"). The
    /// caller (the weigh-in screen) only offers a second call inside the
    /// 10-minute window. `weightKg` MUST already be rounded to two decimal
    /// places (`WeighInWeight.storedKg`); this call does not round it again.
    /// A save that is earlier than the winner changes nothing
    /// (`Self.wins`). Returns the weigh-in the store then holds.
    @discardableResult
    public func saveWeighIn(dateKey: String, weightKg: Double, unit: String, at moment: Date) throws -> WeighInRow {
        let descriptor = FetchDescriptor<Measure>(predicate: #Predicate { $0.dateKey == dateKey })
        let row: Measure
        if let winner = MeasureReconciler.winners(in: try context.fetch(descriptor))[dateKey] {
            row = winner
            guard Self.wins(moment, over: winner.changedAt) else { return weighInRow(row) }
            winner.weightKg = weightKg
            winner.unit = unit
            winner.changedAt = moment
        } else {
            row = Measure(dateKey: dateKey, weightKg: weightKg, unit: unit, savedAt: moment, changedAt: moment)
            context.insert(row)
        }
        try persist()
        return weighInRow(row)
    }

    private func weighInRow(_ model: Measure) -> WeighInRow {
        WeighInRow(dateKey: model.dateKey, weightKg: model.weightKg, unit: model.unit, savedAt: model.savedAt, changedAt: model.changedAt)
    }

    private static let weighInUnitKey = "weighIn.unit"

    /// "Unit": "kg" or "st lb", default "kg" (settings spec, "The Weigh-in
    /// group"). Read from the weigh-in screen and from the settings screen,
    /// so both agree at once.
    public func weighInUnit() throws -> String {
        try settingValue(key: Self.weighInUnitKey) ?? Defaults.weighInUnit
    }

    public func setWeighInUnit(_ unit: String, changedAt: Date = .now) throws {
        try setSettingValue(unit, key: Self.weighInUnitKey, changedAt: changedAt)
    }

    // MARK: - Reviews: weekly reviews and check-ins (weekly-review spec,
    // "Finish and reopen a review", "The week's counts are frozen in the
    // Review row"; data-and-privacy spec, "Day states, sessions and
    // reviews"). A `Review` row's natural key is (`kind`, `dueDateKey`); a
    // write goes into the row that `ReviewReconciler.writeTarget` names,
    // and `ReviewReconciler` picks the earliest-frozen winner on read.
    // `weekly-review` (3.2) owns `answersJSON`'s shape — a JSON payload of
    // the review's own answers and its frozen counts, opaque to this store
    // the same way `Day.slotsJSON` is opaque to it.

    public enum ReviewKind: String, Sendable, CaseIterable {
        case weeklyReview, checkIn
    }

    /// One `Review` row as the app reads it.
    public struct ReviewRow: Sendable, Equatable {
        public let id: UUID
        public let kind: String
        public let dueDateKey: String
        public let frozenAt: Date?
        public let answersJSON: String
        public let selfHarmAnswered: Bool
        public let pinnedNote: String
        public let changedAt: Date
    }

    private func reviewRow(_ model: Review) -> ReviewRow {
        ReviewRow(
            id: model.id, kind: model.kind, dueDateKey: model.dueDateKey, frozenAt: model.frozenAt,
            answersJSON: model.answersJSON, selfHarmAnswered: model.selfHarmAnswered,
            pinnedNote: model.pinnedNote, changedAt: model.changedAt
        )
    }

    private func reviewModels(kind: ReviewKind, dueDateKey: String? = nil) throws -> [Review] {
        let kindValue = kind.rawValue
        var descriptor: FetchDescriptor<Review>
        if let dueDateKey {
            descriptor = FetchDescriptor<Review>(predicate: #Predicate { $0.kind == kindValue && $0.dueDateKey == dueDateKey })
        } else {
            descriptor = FetchDescriptor<Review>(predicate: #Predicate { $0.kind == kindValue })
        }
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor)
    }

    /// The winning row for (`kind`, `dueDateKey`): the frozen row with the
    /// earliest freeze moment, or `nil` when none is frozen yet ("Freeze
    /// waits for sync": an unfrozen row is never a winner).
    /// A row dated later than `now` is ignored and kept
    /// (`ReviewReconciler.winners(in:now:currentDayKey:)`); `calendar`
    /// gives the device zone, and `nil` means the device's own zone.
    public func review(kind: ReviewKind, dueDateKey: String, now: Date, calendar: Calendar? = nil) throws -> ReviewRow? {
        let rows = try reviewModels(kind: kind, dueDateKey: dueDateKey)
        let winners = ReviewReconciler.winners(in: rows, now: now, currentDayKey: try reviewReadDayKey(now: now, calendar: calendar))
        guard let winner = winners["\(kind.rawValue)|\(dueDateKey)"] else { return nil }
        return reviewRow(winner)
    }

    /// Every `dueDateKey`'s winning row for `kind` — one per key, frozen
    /// rows only (the "Reviews" list, the deterioration rule's last four
    /// frozen counts, and "Today's pinned note" all read from this). A row
    /// dated later than `now` is ignored and kept.
    public func reviewRowWinners(kind: ReviewKind, now: Date, calendar: Calendar? = nil) throws -> [ReviewRow] {
        let rows = try reviewModels(kind: kind)
        return ReviewReconciler.winners(in: rows, now: now, currentDayKey: try reviewReadDayKey(now: now, calendar: calendar)).values.map(reviewRow)
    }

    /// The key of the record day that holds `now`, under the "Day starts
    /// at" rows in force, for the future-dated test of a review read. Each
    /// record day uses its own start hour, so one lookup gives the key
    /// (never a key at 04:00 first and then its hour).
    private func reviewReadDayKey(now: Date, calendar: Calendar?) throws -> String {
        let calendar = calendar ?? {
            var device = Calendar(identifier: .gregorian)
            device.timeZone = .current
            return device
        }()
        return RecordDay.key(containing: now, calendar: calendar, schedule: try dayStartSchedule())
    }

    /// The row that a review write of (`kind`, `dueDateKey`) at `now` goes
    /// into, or `nil` when that write inserts a new row
    /// (`ReviewReconciler.writeTarget`). Before the freeze, this is the
    /// unfrozen row with the answers that the person saved so far. A read
    /// (`review`) never shows that row, so the freeze reads it here and
    /// keeps those answers in the frozen row (`ReviewFreeze.frozenValues`).
    public func reviewWriteTarget(kind: ReviewKind, dueDateKey: String, now: Date, calendar: Calendar? = nil) throws -> ReviewRow? {
        let rows = try reviewWriteRows(kind: kind, dueDateKey: dueDateKey)
        let currentDayKey = try reviewReadDayKey(now: now, calendar: calendar)
        return ReviewReconciler.writeTarget(in: rows, now: now, currentDayKey: currentDayKey).map(reviewRow)
    }

    private func reviewWriteRows(kind: ReviewKind, dueDateKey: String) throws -> [Review] {
        let kindValue = kind.rawValue
        return try context.fetch(FetchDescriptor<Review>(predicate: #Predicate { $0.kind == kindValue && $0.dueDateKey == dueDateKey }))
    }

    /// Writes the review of (`kind`, `dueDateKey`) after a reconciled fetch
    /// (weekly-review spec, "The week's counts are frozen in the Review
    /// row": "When one key has more than one row, the app MUST read the row
    /// with the earliest freeze moment. Every edit to the review MUST write
    /// into that row."). The target is `ReviewReconciler.writeTarget` at
    /// `changedAt`: the frozen winner that a read at that moment shows, else
    /// the latest unfrozen row, else a new row. A future-dated row is never
    /// the target, so the write never changes it. A frozen target keeps its
    /// own freeze moment: pass `frozenAt` to freeze an unfrozen or a new
    /// row, or the frozen row's own `frozenAt` back to save an answer. The
    /// caller passes the complete, already-merged `answersJSON`; this store
    /// never reads or writes its shape. `calendar` gives the device zone
    /// for the future-dated test, and `nil` means the device's own zone.
    ///
    /// An edit of the target changes its content only when `changedAt` is
    /// not earlier than the target's own `changedAt`, the same
    /// later-changedAt rule as every other row (`wins`). So an edit after
    /// the device clock goes back, or after a device with a clock ahead
    /// edits the row, does not replace newer answers. A write that freezes
    /// an unfrozen target always applies, because the freeze must happen;
    /// the caller merges that row's own answers into it
    /// (`reviewWriteTarget`), and its `changedAt` never goes back. A
    /// `selfHarmAnswered` of `true` always stays `true` (weekly-review spec,
    /// "The self-harm item at the review": "When step 1 has an answer, the
    /// store MUST keep `selfHarmAnswered: true` for the review.").
    @discardableResult
    public func upsertReview(
        kind: ReviewKind, dueDateKey: String, frozenAt: Date?, answersJSON: String,
        selfHarmAnswered: Bool, pinnedNote: String, changedAt: Date, calendar: Calendar? = nil
    ) throws -> ReviewRow {
        let rows = try reviewWriteRows(kind: kind, dueDateKey: dueDateKey)
        let currentDayKey = try reviewReadDayKey(now: changedAt, calendar: calendar)
        let model: Review
        if let target = ReviewReconciler.writeTarget(in: rows, now: changedAt, currentDayKey: currentDayKey) {
            model = target
            if selfHarmAnswered { model.selfHarmAnswered = true }
            if model.frozenAt == nil, let frozenAt {
                model.frozenAt = frozenAt
                model.answersJSON = answersJSON
                model.pinnedNote = pinnedNote
                model.changedAt = max(model.changedAt, changedAt)
            } else if Self.wins(changedAt, over: model.changedAt) {
                model.answersJSON = answersJSON
                model.pinnedNote = pinnedNote
                model.changedAt = changedAt
            }
        } else {
            model = Review(
                kind: kind.rawValue, dueDateKey: dueDateKey, frozenAt: frozenAt,
                answersJSON: answersJSON, selfHarmAnswered: selfHarmAnswered, pinnedNote: pinnedNote, changedAt: changedAt
            )
            context.insert(model)
        }
        try persist()
        return reviewRow(model)
    }

    // MARK: - Programme: stage-opened rows, card answers and the restart
    // moment (programme spec, "A pure stage engine with stored openings as
    // input", "The card's answer is kept in the record", "Start week 1
    // again"). A stage opening is an event: each one is a new row, and the
    // caller applies the engine's own ignore rules on read. A card answer
    // and the restart moment write into the winning row of their key.

    /// One `StageOpened` row as the store keeps it: an `Answer` row of kind
    /// "stageOpened", keyed by the stage number in `cardId` (data-and-privacy
    /// spec, "Model names, singletons and the account binding").
    public struct StageOpenedRow: Sendable, Equatable {
        public let stage: Int
        public let moment: Date
    }

    /// Every `StageOpened` row the store holds, for every stage, unfiltered.
    /// The caller passes this straight to `Programme.state`'s `openings`
    /// parameter, which applies the ignore-future and ignore-pre-restart
    /// rules itself.
    public func stageOpenedRows() throws -> [StageOpenedRow] {
        var descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "stageOpened" })
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor).compactMap { row in
            Int(row.cardId).map { StageOpenedRow(stage: $0, moment: row.changedAt) }
        }
    }

    /// Writes a new `StageOpened` row for `stage` at `moment` (programme
    /// spec: "When the engine computes an opening the store lacks, the app
    /// MUST write that moment to the store."). Never overwrites or deletes
    /// an existing row — a stage can end up with more than one, and the
    /// engine reads the earliest.
    public func recordStageOpened(_ stage: Int, at moment: Date) throws {
        context.insert(Answer(kind: StageOpenedReconciler.kind, cardId: String(stage), value: "", changedAt: moment))
        try persist()
    }

    /// The winning value of a card's answer ("Open", "Close", "Read", "Yes",
    /// "Set it up"), or `nil` when unanswered (programme spec, "The card's
    /// answer is kept in the record").
    public func cardAnswer(id: String) throws -> String? {
        var descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "card" && $0.cardId == id })
        descriptor.includePendingChanges = false
        return AnswerReconciler.winners(in: try context.fetch(descriptor))["card|\(id)"]?.value
    }

    /// Every card id that has an answer on any device, for the engine's
    /// pending-card picker: "A card whose Answer row exists on any device
    /// MUST NOT show again."
    public func answeredCardIds() throws -> Set<String> {
        var descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "card" })
        descriptor.includePendingChanges = false
        return Set(AnswerReconciler.winners(in: try context.fetch(descriptor)).values.map(\.cardId))
    }

    /// Writes `value` into the winning card-answer `Answer` row of `id`, or
    /// inserts the first row for `id` (data-and-privacy spec, "Card answers
    /// live in the record": "one card answer row ... for each answered
    /// card").
    public func setCardAnswer(_ value: String, id: String, changedAt: Date) throws {
        let descriptor = FetchDescriptor<Answer>(predicate: #Predicate { $0.kind == "card" && $0.cardId == id })
        let row = Answer(kind: "card", cardId: id, value: value, changedAt: changedAt)
        try writeAnswer(row, winner: AnswerReconciler.winners(in: try context.fetch(descriptor))[AnswerReconciler.naturalKey(row)])
    }

    private static let restartAtSettingKey = "programme.restartAt"

    /// The moment of the last restart, or `nil` before any restart (programme
    /// spec, "Start week 1 again": "The restart MUST write the restart
    /// moment to its Settings key. The engine reads it as restartAt.").
    public func restartAt() throws -> Date? {
        try settingValue(key: Self.restartAtSettingKey).flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    public func setRestartAt(_ moment: Date, changedAt: Date = .now) throws {
        try setSettingValue(ISO8601DateFormatter().string(from: moment), key: Self.restartAtSettingKey, changedAt: changedAt)
    }

    // MARK: - Content: which content version the person saw (content spec,
    // "The store keeps which content version the person saw").

    /// Writes a new `Seen` row: the card opened, at the content version in
    /// force, in the card's language, at `seenAt`. Never overwrites or
    /// merges with an earlier view of the same card — "the same card after
    /// an update" keeps both.
    public func recordCardSeen(cardId: String, contentVersion: Int, language: String, seenAt: Date) throws {
        context.insert(Seen(cardId: cardId, seenAt: seenAt, contentVersion: contentVersion, language: language))
        try persist()
    }

    /// Every `Seen` row for `cardId`, most recent first — never shown to the
    /// person; a test or a diagnostic reads this.
    public func cardViews(cardId: String) throws -> [Seen] {
        var descriptor = FetchDescriptor<Seen>(predicate: #Predicate { $0.cardId == cardId })
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor).sorted { $0.seenAt > $1.seenAt }
    }

    // MARK: - Programme: value facts for the engine (programme spec, "A pure
    // stage engine with stored openings as input"). The App target maps each
    // one to `Programme`'s own fact type; `Programme` never imports `Record`.

    /// One winning, non-deleted entry, as the engine needs it: its record
    /// day, whether it is starred, and the moment the store actually saved
    /// it (`createdAt`, not `time` — a backdated entry's own `time` can
    /// differ from the moment it was saved).
    public struct RecordedEntryFact: Sendable, Equatable {
        public let dayKey: String
        public let starred: Bool
        public let savedAt: Date
    }

    /// Every winning, non-deleted entry in the whole store.
    public func recordedEntryFacts() throws -> [RecordedEntryFact] {
        var descriptor = FetchDescriptor<ItemVersion>()
        descriptor.includePendingChanges = false
        let winners = EntryWinner.winners(in: try context.fetch(descriptor))
        return winners.values.filter { !$0.deleted }.map { RecordedEntryFact(dayKey: $0.dayKey, starred: $0.feltLikeABinge, savedAt: $0.createdAt) }
    }

    /// Every record day that counts as "planned" (regular-eating-plan spec,
    /// "A planned day": explicitly set, or holding an entry, and never a
    /// paused day), for the stage 3 count. `PlannedDay.isPlanned` in `Plan`
    /// is the rule; this gathers the store-wide facts it needs, since no
    /// single `Day`/`ItemVersion` row already carries "is this day paused".
    public func plannedDayKeys() throws -> Set<String> {
        let entryDayKeys = try liveEntryDayKeys(before: nil)

        var dayDescriptor = FetchDescriptor<Day>()
        dayDescriptor.includePendingChanges = false
        let setDayKeys = Set(DayReconciler.winners(in: try context.fetch(dayDescriptor)).values.filter { $0.setAt != nil }.map(\.dateKey))

        var pausedDescriptor = FetchDescriptor<DayState>(predicate: #Predicate { $0.kind == "paused" })
        pausedDescriptor.includePendingChanges = false
        let pausedDayKeys = Set(DayStateReconciler.winners(in: try context.fetch(pausedDescriptor)).values.filter { $0.value == "on" }.map(\.dateKey))

        return entryDayKeys.union(setDayKeys).subtracting(pausedDayKeys)
    }

    /// One urge outcome, as the engine needs it (`urge-toolkit` owns the
    /// outcome's own vocabulary; the engine only needs that one exists).
    public struct UrgeOutcomeRow: Sendable, Equatable {
        public let dayKey: String
        public let outcomeAt: Date
    }

    public func urgeOutcomeFacts() throws -> [UrgeOutcomeRow] {
        var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.outcome != "" })
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor).compactMap { session in
            session.outcomeAt.map { UrgeOutcomeRow(dayKey: session.outcomeDayKey, outcomeAt: $0) }
        }
    }

    /// One urge outcome with its own outcome value, for `weekly-review`'s
    /// "Urges: %1$lld. Passed: %2$lld." (`urge-toolkit` owns the outcome
    /// vocabulary; this store only reports the value it kept).
    public struct UrgeOutcomeDetailRow: Sendable, Equatable {
        public let dayKey: String
        public let outcome: String
    }

    public func urgeOutcomeDetails() throws -> [UrgeOutcomeDetailRow] {
        var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.outcome != "" })
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor).map { UrgeOutcomeDetailRow(dayKey: $0.outcomeDayKey, outcome: $0.outcome) }
    }

    /// Whether the store holds any `Template` row (programme spec, "A card
    /// when the plan is not set": "The plan card shows while the store
    /// holds no Template row.").
    public func hasAnyTemplate() throws -> Bool {
        try !context.fetch(FetchDescriptor<Template>()).isEmpty
    }

    // MARK: - Reminders: device-only counters and the action queue applier
    // (reminders spec, "Snooze a reminder", "The morning plan reminder while
    // the plan needs setting", "The midday and close-the-day reminders stop
    // after seven silent days"; widgets-and-intents spec, "The action
    // queue"). Every value here is `Local.store`, device-only, per
    // design.md's "Two store configurations in one directory" field list.

    /// The snooze count for `dateKey`'s `slotIndex` (reminders spec: "The app
    /// MUST apply it to `Local.store`, keyed by the record day key and the
    /// slot index.").
    public func snoozeCount(dateKey: String, slotIndex: Int) throws -> Int {
        try localSettingValue(key: Self.snoozeKey(dateKey: dateKey, slotIndex: slotIndex)).flatMap(Int.init) ?? 0
    }

    public func setSnoozeCount(_ count: Int, dateKey: String, slotIndex: Int) throws {
        try setLocalSettingValue(String(count), key: Self.snoozeKey(dateKey: dateKey, slotIndex: slotIndex))
    }

    private static func snoozeKey(dateKey: String, slotIndex: Int) -> String { "reminder.snooze.\(dateKey).\(slotIndex)" }

    /// The count of consecutive unanswered morning plan reminders
    /// (`MorningPlanUnansweredTracker`'s own count).
    public func morningPlanUnansweredCount() throws -> Int {
        try localSettingValue(key: "reminder.morningPlan.unansweredCount").flatMap(Int.init) ?? 0
    }

    public func setMorningPlanUnansweredCount(_ count: Int) throws {
        try setLocalSettingValue(String(count), key: "reminder.morningPlan.unansweredCount")
    }

    /// The current midday/close-the-day silent-day streak
    /// (`SilentDayTracker`'s own count).
    public func silentDayStreak() throws -> Int {
        try localSettingValue(key: "reminder.silentDays.streak").flatMap(Int.init) ?? 0
    }

    public func setSilentDayStreak(_ streak: Int) throws {
        try setLocalSettingValue(String(streak), key: "reminder.silentDays.streak")
    }

    /// The device flag "the person tapped the denied Today line once" (
    /// reminders spec, "Reminder types and their switches": "The app MUST
    /// keep that tap as a device flag in `Local.store`.").
    public func hasTappedNotificationsDeniedLineOnce() throws -> Bool {
        try localBoolSetting(key: "reminder.deniedLineTapped", default: false)
    }

    public func setHasTappedNotificationsDeniedLineOnce(_ tapped: Bool) throws {
        try setLocalBoolSetting(tapped, key: "reminder.deniedLineTapped")
    }

    /// Applies every queued action to the store, in order, then answers with
    /// the ones whose date key is at least `currentRecordDayKey` — the app
    /// drops the rest (widgets-and-intents spec: "The app MUST drop an
    /// action whose date key is earlier than the current record day.").
    /// Each "Skipped" Answer row carries the action's own moment as its
    /// `changedAt` ("the store holds the skip for lunch with the moment
    /// 13:40"). A snooze writes its count and its tap moment to
    /// `Local.store`, so the scheduler can schedule the snooze again.
    /// Call this, then clear the queue file, on activation and whenever
    /// protected data becomes available.
    @discardableResult
    public func applyQueuedActions(_ actions: [QueuedAction], currentRecordDayKey: String) throws -> [QueuedAction] {
        let kept = actions.filter { $0.dayKey >= currentRecordDayKey }
        for action in kept {
            switch action.kind {
            case .skipped:
                try setPlannedMealSkipped(dateKey: action.dayKey, slotIndex: action.slotIndex, changedAt: action.moment)
            case .snooze:
                try setSnoozeCount(action.snoozeCount, dateKey: action.dayKey, slotIndex: action.slotIndex)
                try setSnoozeTapMoment(action.moment, dateKey: action.dayKey, slotIndex: action.slotIndex)
            }
        }
        return kept
    }
}

/// The store directory inside the app's own `Application Support` directory
/// — never inside the App Group container (data-and-privacy spec, "The
/// store lives in the app's own container"). The App target's own
/// `StoreLocation.applicationSupportDirectory()` gives the real root;
/// this is the pure, non-isolated form a test can check with a fixed URL.
public enum StoreLayout {
    public static func storeDirectory(applicationSupportDirectory: URL) -> URL {
        applicationSupportDirectory.appendingPathComponent("Record", isDirectory: true)
    }

    /// The launch marker file's path: beside the store directory, never
    /// inside it (data-and-privacy spec, "Launch safety": "The marker MUST
    /// live outside the store directory").
    public static func launchMarkerURL(applicationSupportDirectory: URL) -> URL {
        applicationSupportDirectory.appendingPathComponent("LaunchMarker", isDirectory: false)
    }
}

/// What the App Group container holds: only the widget snapshot and the
/// action queue, never the store (data-and-privacy spec, "The store lives in
/// the app's own container": "App Group content"). `widgets-and-intents`
/// (2.5) names the real files; this records the shape now so the store never
/// grows into the App Group by accident.
public enum AppGroupContent {
    public static let fileStems: Set<String> = ["snapshot", "queue"]

    /// The two side files' real paths inside `directory` (the App Group
    /// container). Delete-all and "Delete from this device" delete both by
    /// this same path, whether or not either file exists yet (data-and-
    /// privacy spec, "Delete-all", "Delete from this device", "File
    /// protection": "Side files"). `StoreFiles.swift` holds each name.
    public static func fileURLs(inAppGroupDirectory directory: URL) -> [URL] {
        [actionQueueURL(inAppGroupDirectory: directory), snapshotURL(inAppGroupDirectory: directory)]
    }
}
