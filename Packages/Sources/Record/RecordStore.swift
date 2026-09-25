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

    public init(id: UUID, time: Date, utcOffsetSeconds: Int, what: String, feltLikeABinge: Bool, createdAt: Date, dayKey: String) {
        self.id = id
        self.time = time
        self.utcOffsetSeconds = utcOffsetSeconds
        self.what = what
        self.feltLikeABinge = feltLikeABinge
        self.createdAt = createdAt
        self.dayKey = dayKey
    }

    init(entryId: UUID, winner: ItemVersion) {
        self.init(
            id: entryId,
            time: winner.time,
            utcOffsetSeconds: winner.utcOffsetSeconds,
            what: winner.what,
            feltLikeABinge: winner.feltLikeABinge,
            createdAt: winner.createdAt,
            dayKey: winner.dayKey
        )
    }
}

public extension RecordRow {
    /// The entry's time as "HH:mm" at the entry's own UTC offset.
    var clockTime: String {
        RecordRow.clockTime(for: time, utcOffsetSeconds: utcOffsetSeconds)
    }

    /// The VoiceOver label for the row: time, then What when not empty,
    /// then "felt like a binge" when the star is on.
    var accessibilityLabel: String {
        var parts = [clockTime]
        if !what.isEmpty { parts.append(what) }
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

/// The only way to create and read entries. Opens two store configurations
/// in one directory: `Record.store` syncs; `Local.store` never does
/// (data-and-privacy spec, "Two store configurations in one directory").
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

    /// Saves one entry as a new `Item` and its first `ItemVersion`, and
    /// returns the row. Trims white space and line breaks from the ends of
    /// `what`. Truncates `time` to the minute. Throws on failure with no
    /// entry data in the error.
    @discardableResult
    public func add(time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int, dayStartHour: Int = RecordDay.startHour) throws -> RecordRow {
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
            createdAt: createdAt
        )
        context.insert(item)
        context.insert(version)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
        return RecordRow(entryId: entryId, winner: version)
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
        var descriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.dayKey == dayKey })
        descriptor.includePendingChanges = false
        let versions = try context.fetch(descriptor)
        let winners = EntryWinner.winners(in: versions)
        return winners
            .filter { !$0.value.deleted }
            .map { RecordRow(entryId: $0.key, winner: $0.value) }
            .sorted { lhs, rhs in
                if lhs.time != rhs.time { return lhs.time < rhs.time }
                return lhs.createdAt < rhs.createdAt
            }
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }

    private func saveOrRollback() throws {
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
        try saveOrRollback()
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
        try saveOrRollback()
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
