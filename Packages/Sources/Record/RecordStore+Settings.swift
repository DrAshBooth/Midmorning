import Foundation
import Constants

// MARK: - Setting defaults and typed reads over the key/value rows (settings
// spec, "The Record group", "The Reminders group", "The Weigh-in group")

extension RecordStore {
    /// The value each setting has until the person changes it. A getter
    /// gives this value when no row exists. A caller that falls back after
    /// a read error uses this value too, never its own copy.
    public enum Defaults {
        public static let gapBandsOn = true
        public static let weeklySummaryOn = true
        public static let reminderSwitchOn = true
        public static let explicitWordingOn = false
        public static let remindAgainMinutes = ProgrammeConstants.default.snoozeMinutes
        public static let quietHours = QuietHours(isOn: true, start: "22:00", end: "07:00")
        public static let weighInUnit = "kg"
    }

    /// A synced Bool setting, stored as "true" or "false".
    func boolSetting(key: String, default defaultValue: Bool) throws -> Bool {
        try settingValue(key: key).map { $0 == "true" } ?? defaultValue
    }

    func setBoolSetting(_ on: Bool, key: String, changedAt: Date) throws {
        try setSettingValue(on ? "true" : "false", key: key, changedAt: changedAt)
    }

    /// A device-only Bool setting, stored as "true" or "false".
    func localBoolSetting(key: String, default defaultValue: Bool) throws -> Bool {
        try localSettingValue(key: key).map { $0 == "true" } ?? defaultValue
    }

    func setLocalBoolSetting(_ on: Bool, key: String) throws {
        try setLocalSettingValue(on ? "true" : "false", key: key)
    }
}

// MARK: - The Record group's switches and the Reminders group (settings spec)

extension RecordStore {
    private static let gapBandsKey = "record.gapBands.enabled"

    /// "Gap bands" (on, syncs).
    public func gapBandsOn() throws -> Bool {
        try boolSetting(key: Self.gapBandsKey, default: Defaults.gapBandsOn)
    }

    public func setGapBandsOn(_ on: Bool, changedAt: Date = .now) throws {
        try setBoolSetting(on, key: Self.gapBandsKey, changedAt: changedAt)
    }

    private static let weeklySummaryKey = "record.weeklySummary.enabled"

    /// "Weekly summary" (on, syncs; settings spec, "The Record group").
    /// Weekly-review reads this to decide whether a review shows its summary
    /// part (weekly-review spec, "The weekly summary is opt-out": the
    /// reflection questions, the self-harm item and "I'm getting worse" stay
    /// regardless).
    public func weeklySummaryOn() throws -> Bool {
        try boolSetting(key: Self.weeklySummaryKey, default: Defaults.weeklySummaryOn)
    }

    public func setWeeklySummaryOn(_ on: Bool, changedAt: Date = .now) throws {
        try setBoolSetting(on, key: Self.weeklySummaryKey, changedAt: changedAt)
    }

    // MARK: - The Reminders group (settings spec, "The Reminders group")

    /// Every switch is a device setting, on by default.
    public enum ReminderSwitch: String, CaseIterable, Sendable {
        case plannedMeals, setTodaysPlan, midday, closeTheDay, weighInDay, weeklyReview
    }

    public func reminderSwitchOn(_ kind: ReminderSwitch) throws -> Bool {
        try localBoolSetting(key: "reminder.\(kind.rawValue).enabled", default: Defaults.reminderSwitchOn)
    }

    public func setReminderSwitch(_ on: Bool, _ kind: ReminderSwitch) throws {
        try setLocalBoolSetting(on, key: "reminder.\(kind.rawValue).enabled")
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
            ClockTime.string(hour: defaultHourAndMinute.hour, minute: defaultHourAndMinute.minute)
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
        try localBoolSetting(key: "reminder.explicitWording.enabled", default: Defaults.explicitWordingOn)
    }

    public func setExplicitWordingOn(_ on: Bool) throws {
        try setLocalBoolSetting(on, key: "reminder.explicitWording.enabled")
    }

    /// "Remind me again in": 15 or 30 minutes, default 15 (device).
    public func remindAgainMinutes() throws -> Int {
        try localSettingValue(key: "reminder.snoozeMinutes").flatMap(Int.init) ?? Defaults.remindAgainMinutes
    }

    public func setRemindAgainMinutes(_ minutes: Int) throws {
        try setLocalSettingValue(String(minutes), key: "reminder.snoozeMinutes")
    }

    /// "Quiet hours" with a start and an end (22:00 to 07:00, on). The
    /// switch and the two times all sync.
    public func quietHoursOn() throws -> Bool {
        try boolSetting(key: "reminder.quietHours.enabled", default: Defaults.quietHours.isOn)
    }

    public func setQuietHoursOn(_ on: Bool, changedAt: Date = .now) throws {
        try setBoolSetting(on, key: "reminder.quietHours.enabled", changedAt: changedAt)
    }

    public func quietHoursStart() throws -> String {
        try settingValue(key: "reminder.quietHours.start") ?? Defaults.quietHours.start
    }

    public func setQuietHoursStart(_ time: String, changedAt: Date = .now) throws {
        try setSettingValue(time, key: "reminder.quietHours.start", changedAt: changedAt)
    }

    public func quietHoursEnd() throws -> String {
        try settingValue(key: "reminder.quietHours.end") ?? Defaults.quietHours.end
    }

    public func setQuietHoursEnd(_ time: String, changedAt: Date = .now) throws {
        try setSettingValue(time, key: "reminder.quietHours.end", changedAt: changedAt)
    }

    /// The switch and the two times in one value, for every screen and rule
    /// that asks whether a time is in quiet hours.
    public func quietHours() throws -> QuietHours {
        QuietHours(isOn: try quietHoursOn(), start: try quietHoursStart(), end: try quietHoursEnd())
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
