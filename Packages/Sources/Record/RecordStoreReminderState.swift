import Foundation

// MARK: - One change signal for every write (reminders spec, "Scheduling is
// local, lazy and bounded": "It MUST compute it again when a plan or a
// setting changes. It MUST compute it again when an entry matches a planned
// meal or the person answers a reminder.")

extension RecordStore {
    /// Posted after each successful save, with the store as the object. The
    /// reminder scheduler in the App target listens for it, so every write
    /// (an entry, a day state, a plan, a template, a setting, a reminder
    /// pause) makes the schedule compute again, with no call in each
    /// screen.
    public nonisolated static let didSaveNotification = Notification.Name("uk.midmorning.recordStoreDidSave")
}

// MARK: - Device-only reminder state in `Local.store` (reminders spec, "Snooze
// a reminder", "The morning plan reminder while the plan needs setting",
// "The midday and close-the-day reminders stop after seven silent days")

extension RecordStore {
    private static func snoozeTapKey(dateKey: String, slotIndex: Int) -> String { "reminder.snoozeAt.\(dateKey).\(slotIndex)" }
    private static let foldedThroughKey = "reminder.stops.foldedThrough"
    private static let pendingDeliveredKey = "reminder.stops.pendingDelivered"
    private static let templatesSeenKey = "reminder.stops.templatesSeen"

    /// The moment of the last snooze tap for `dateKey`'s `slotIndex`, from
    /// the action queue. With the snooze count, this lets the scheduler
    /// schedule the snooze again after it replaces the pending requests.
    public func snoozeTapMoment(dateKey: String, slotIndex: Int) throws -> Date? {
        try localSettingValue(key: Self.snoozeTapKey(dateKey: dateKey, slotIndex: slotIndex)).flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    public func setSnoozeTapMoment(_ moment: Date, dateKey: String, slotIndex: Int) throws {
        try setLocalSettingValue(ISO8601DateFormatter().string(from: moment), key: Self.snoozeTapKey(dateKey: dateKey, slotIndex: slotIndex))
    }

    /// The last elapsed record day the two stop counts already hold, or
    /// `nil` before the first fold.
    public func reminderStopsFoldedThrough() throws -> String? {
        try localSettingValue(key: Self.foldedThroughKey).flatMap { $0.isEmpty ? nil : $0 }
    }

    public func setReminderStopsFoldedThrough(_ dayKey: String) throws {
        try setLocalSettingValue(dayKey, key: Self.foldedThroughKey)
    }

    /// The reminder kinds (their raw names) that Notification Centre held
    /// for a record day that had not ended when the app read them. The app
    /// folds them into the stop counts after that day ends.
    public func pendingDeliveredReminderKinds() throws -> [String: Set<String>] {
        guard let text = try localSettingValue(key: Self.pendingDeliveredKey), let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return decoded.mapValues(Set.init)
    }

    public func setPendingDeliveredReminderKinds(_ kinds: [String: Set<String>]) throws {
        let sorted = kinds.mapValues { $0.sorted() }
        let data = try JSONEncoder().encode(sorted)
        try setLocalSettingValue(String(decoding: data, as: UTF8.self), key: Self.pendingDeliveredKey)
    }

    /// The weekday and weekend templates as the scheduler last saw them.
    /// A different value now means the person saved a template, which
    /// starts the morning plan reminder again.
    public func templatesSeenByReminders() throws -> String? {
        try localSettingValue(key: Self.templatesSeenKey)
    }

    public func setTemplatesSeenByReminders(_ value: String) throws {
        try setLocalSettingValue(value, key: Self.templatesSeenKey)
    }
}
