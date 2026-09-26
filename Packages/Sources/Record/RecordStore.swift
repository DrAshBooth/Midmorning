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
        // Every file `Record.store` and `Local.store` create (each one's
        // main file, `-wal` and `-shm`) carries `NSFileProtectionComplete`
        // (data-and-privacy spec, "File protection": "Store files"). The App
        // target's `StoreLocation.directory()` already protects the
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

    // MARK: - Settings: synced key/value rows (data-and-privacy spec, "Slot
    // labels and the day start are Settings rows")

    /// The winning value for a synced `Settings` key, or `nil` when no row
    /// has ever been written for it.
    public func settingValue(key: String) throws -> String? {
        let rows = try context.fetch(FetchDescriptor<Settings>())
        return SettingsReconciler.winners(in: rows)[key]?.value
    }

    /// Writes a new `Settings` row for `key`. Append-only, like every synced
    /// row: this never edits or replaces an earlier row; `SettingsReconciler`
    /// picks the winner on read.
    public func setSettingValue(_ value: String, key: String, changedAt: Date = .now) throws {
        context.insert(Settings(key: key, value: value, changedAt: changedAt))
        try persist()
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
    /// content capability's own value; `sourceCounts` stands in for `2.4`'s
    /// pending-reminders count and the action queue's length until
    /// `mm-t24.20` supplies the real ones.
    public func diagnosticsCounts(contentVersion: Int, sourceCounts: DiagnosticsSourceCounts = ZeroDiagnosticsSourceCounts()) throws -> DiagnosticsCounts {
        DiagnosticsCounts(
            launchFailures: try localIntSettingValue(key: Self.launchFailureCountKey),
            lastSuccessfulSyncDay: try (localSettingValue(key: Self.lastSuccessfulSyncDayKey)) ?? DiagnosticsCounts.noSyncYet,
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

    /// The day-start hour in effect for the record day keyed `dayKey`: the
    /// latest append-only `DayStartSetting` row whose effective day is
    /// `dayKey` or earlier, or `RecordDay.startHour` when no row applies yet.
    public func dayStartHour(effectiveOn dayKey: String) throws -> Int {
        let rows = try context.fetch(FetchDescriptor<Settings>())
        let winner = SettingsReconciler.winners(in: rows).values
            .compactMap { row -> (effectiveFromDayKey: String, hour: Int)? in
                guard row.key.hasPrefix("dayStart."), let hour = Int(row.value) else { return nil }
                return (String(row.key.dropFirst("dayStart.".count)), hour)
            }
            .filter { $0.effectiveFromDayKey <= dayKey }
            .max { $0.effectiveFromDayKey < $1.effectiveFromDayKey }
        return winner?.hour ?? RecordDay.startHour
    }

    /// Writes a new "Day starts at" hour, effective from the record day
    /// right after `now` — never from `now`'s own record day, so no saved
    /// entry's record day changes.
    public func setDayStartHour(_ hour: Int, now: Date, calendar: Calendar, changedAt: Date = .now) throws {
        let currentHour = try dayStartHour(effectiveOn: RecordDay.key(containing: now, calendar: calendar))
        let nextDayKey = RecordDay.nextDayKey(after: now, calendar: calendar, startHour: currentHour)
        try setSettingValue(String(hour), key: DayStartSetting.key(effectiveFromDayKey: nextDayKey), changedAt: changedAt)
    }

    private static let gapBandsKey = "record.gapBands.enabled"

    /// "Gap bands" (on, syncs).
    public func gapBandsOn() throws -> Bool {
        try (settingValue(key: Self.gapBandsKey) ?? "true") == "true"
    }

    public func setGapBandsOn(_ on: Bool, changedAt: Date = .now) throws {
        try setSettingValue(on ? "true" : "false", key: Self.gapBandsKey, changedAt: changedAt)
    }

    // MARK: - The Reminders group (settings spec, "The Reminders group")

    /// Every switch is a device setting, on by default.
    public enum ReminderSwitch: String, CaseIterable, Sendable {
        case plannedMeals, setTodaysPlan, midday, closeTheDay, weighInDay, weeklyReview
    }

    public func reminderSwitchOn(_ kind: ReminderSwitch) throws -> Bool {
        try (localSettingValue(key: "reminder.\(kind.rawValue).enabled") ?? "true") == "true"
    }

    public func setReminderSwitch(_ on: Bool, _ kind: ReminderSwitch) throws {
        try setLocalSettingValue(on ? "true" : "false", key: "reminder.\(kind.rawValue).enabled")
    }

    /// A reminder time syncs, unlike its switch. Each ships with its own
    /// default.
    public enum ReminderTime: String, CaseIterable, Sendable {
        case setTodaysPlan, closeTheDay, weighIn, weeklyReview

        public var defaultHourAndMinute: (hour: Int, minute: Int) {
            switch self {
            case .setTodaysPlan: return (7, 30)
            case .closeTheDay: return (21, 45)
            case .weighIn: return (7, 30)
            case .weeklyReview: return (18, 0)
            }
        }

        /// The default time as "HH:mm".
        public var defaultTime: String {
            String(format: "%02d:%02d", defaultHourAndMinute.hour, defaultHourAndMinute.minute)
        }
    }

    public func reminderTime(_ kind: ReminderTime) throws -> String {
        try settingValue(key: "reminder.\(kind.rawValue).time") ?? kind.defaultTime
    }

    public func setReminderTime(_ time: String, _ kind: ReminderTime, changedAt: Date = .now) throws {
        try setSettingValue(time, key: "reminder.\(kind.rawValue).time", changedAt: changedAt)
    }

    /// "Say what each reminder is for", the explicit-wording setting (off,
    /// device).
    public func explicitWordingOn() throws -> Bool {
        try (localSettingValue(key: "reminder.explicitWording.enabled") ?? "false") == "true"
    }

    public func setExplicitWordingOn(_ on: Bool) throws {
        try setLocalSettingValue(on ? "true" : "false", key: "reminder.explicitWording.enabled")
    }

    /// "Remind me again in": 15 or 30 minutes, default 15 (device).
    public func remindAgainMinutes() throws -> Int {
        try localSettingValue(key: "reminder.snoozeMinutes").flatMap(Int.init) ?? 15
    }

    public func setRemindAgainMinutes(_ minutes: Int) throws {
        try setLocalSettingValue(String(minutes), key: "reminder.snoozeMinutes")
    }

    /// "Quiet hours" with a start and an end (22:00 to 07:00, on). The
    /// switch and the two times all sync.
    public func quietHoursOn() throws -> Bool {
        try (settingValue(key: "reminder.quietHours.enabled") ?? "true") == "true"
    }

    public func setQuietHoursOn(_ on: Bool, changedAt: Date = .now) throws {
        try setSettingValue(on ? "true" : "false", key: "reminder.quietHours.enabled", changedAt: changedAt)
    }

    public func quietHoursStart() throws -> String {
        try settingValue(key: "reminder.quietHours.start") ?? "22:00"
    }

    public func setQuietHoursStart(_ time: String, changedAt: Date = .now) throws {
        try setSettingValue(time, key: "reminder.quietHours.start", changedAt: changedAt)
    }

    public func quietHoursEnd() throws -> String {
        try settingValue(key: "reminder.quietHours.end") ?? "07:00"
    }

    public func setQuietHoursEnd(_ time: String, changedAt: Date = .now) throws {
        try setSettingValue(time, key: "reminder.quietHours.end", changedAt: changedAt)
    }

    private static let remindersPausedAtKey = "remindersPausedAt"

    /// `nil` once reminders are not paused: a fresh store, or after "Turn
    /// reminders on" writes the cleared row.
    public func remindersPausedAt() throws -> Date? {
        try settingValue(key: Self.remindersPausedAtKey).flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    /// Sets `remindersPausedAt`. Not-right-now (`safeguarding`) calls this;
    /// this store only carries the row and the read.
    public func pauseReminders(at date: Date, changedAt: Date = .now) throws {
        try setSettingValue(ISO8601DateFormatter().string(from: date), key: Self.remindersPausedAtKey, changedAt: changedAt)
    }

    /// "Turn reminders on": clears `remindersPausedAt` with a new, later row
    /// (settings spec, "The Reminders group": "the app clears
    /// `remindersPausedAt`"). The scheduler recomputing the schedule is
    /// `reminders`' (2.4) own work; this store only clears the flag.
    public func turnRemindersOn(changedAt: Date = .now) throws {
        try setSettingValue("", key: Self.remindersPausedAtKey, changedAt: changedAt)
    }

    // MARK: - Profile: the one-time BMI (onboarding spec, "What onboarding
    // keeps and what it never keeps"; safeguarding spec, "Re-screening at a
    // restart")

    /// The one `Profile` row: height, the onboarding BMI, the caution flag
    /// and `askedAt`, or `nil` before onboarding writes it.
    public func profile() throws -> Profile? {
        let fixedId = Profile.fixedId
        var descriptor = FetchDescriptor<Profile>(predicate: #Predicate { $0.id == fixedId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Upserts the one `Profile` row. Onboarding calls this once, at
    /// "Start"; a later re-screen calls it again with a later `changedAt`,
    /// the field `data-and-privacy` keeps on sync.
    public func setProfile(heightCm: Double, onboardingBMI: Double, cautionFlag: Bool, askedAt: Date, changedAt: Date = .now) throws {
        if let existing = try profile() {
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
        try (localSettingValue(key: Self.onboardingCompletedKey) ?? "false") == "true"
    }

    public func setOnboardingCompleted(_ completed: Bool) throws {
        try setLocalSettingValue(completed ? "true" : "false", key: Self.onboardingCompletedKey)
    }

    private static let syncOnKey = "onboarding.syncOn"

    /// The sync choice as device state (onboarding spec, "Screen 4: your
    /// record"). `false` — off — in the first cut, always, because "Your
    /// record" shows one control, "This device only".
    public func syncOn() throws -> Bool {
        try (localSettingValue(key: Self.syncOnKey) ?? "false") == "true"
    }

    public func setSyncOn(_ on: Bool) throws {
        try setLocalSettingValue(on ? "true" : "false", key: Self.syncOnKey)
    }

    // MARK: - Plan: templates, days and planned-meal answers (regular-eating-
    // plan spec, "Weekday and weekend templates", "A planned day", "The
    // plan's data stays on the device"). Every write here is a new row, like
    // every synced row; the Reconciler picks the winner on read.

    public enum TemplateKind: String, Sendable, CaseIterable, Equatable {
        case weekday, weekend
    }

    /// The winning `slotsJSON` for `kind`'s template, or "[]" when none
    /// exists yet.
    public func templateSlotsJSON(_ kind: TemplateKind) throws -> String {
        let rows = try context.fetch(FetchDescriptor<Template>())
        return TemplateReconciler.winners(in: rows)[kind.rawValue]?.slotsJSON ?? "[]"
    }

    /// Writes a new `Template` row for `kind`.
    public func setTemplateSlotsJSON(_ json: String, kind: TemplateKind, changedAt: Date) throws {
        context.insert(Template(kind: kind.rawValue, slotsJSON: json, changedAt: changedAt))
        try persist()
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
    /// Always inserts a new row; `DayReconciler` keeps the sticky set event
    /// across any earlier or later row for the same key.
    public func setDayPlan(
        dateKey: String, slotsJSON: String, windowBeforeMinutes: Int, windowAfterMinutes: Int,
        setAt: Date, setBy: String, changedAt: Date
    ) throws {
        context.insert(Day(
            dateKey: dateKey, slotsJSON: slotsJSON, windowBeforeMinutes: windowBeforeMinutes,
            windowAfterMinutes: windowAfterMinutes, changedAt: changedAt, setAt: setAt, setBy: setBy
        ))
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

    /// Writes a new planned-meal `Answer` row.
    public func setPlannedMealAnswer(_ value: String, dateKey: String, slotIndex: Int, changedAt: Date) throws {
        context.insert(Answer(kind: "plannedMeal", dateKey: dateKey, slotIndex: slotIndex, value: value, changedAt: changedAt))
        try persist()
    }

    /// The stored override of a slot's label, or `nil` when the slot shows
    /// its default label (regular-eating-plan spec, "Rename a slot in the
    /// plan builder").
    public func slotLabel(index: Int) throws -> String? {
        try settingValue(key: Settings.slotLabelKey(index))
    }

    /// Writes a new `Settings` row for the slot's label. `nil` writes an
    /// empty row, which reverts the slot to its default label — the store
    /// never deletes a row, even to clear one (data-and-privacy spec, "The
    /// Reconciler never deletes a row").
    public func setSlotLabel(_ label: String?, index: Int, changedAt: Date) throws {
        try setSettingValue(label ?? "", key: Settings.slotLabelKey(index), changedAt: changedAt)
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
    /// protection": "Side files").
    public static func fileURLs(inAppGroupDirectory directory: URL) -> [URL] {
        fileStems.sorted().map { directory.appendingPathComponent($0) }
    }
}
