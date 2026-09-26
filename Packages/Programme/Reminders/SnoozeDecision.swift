import Foundation
import Constants

/// The seven values a planned meal reminder's `userInfo` carries (reminders
/// spec, "Actions on a planned meal reminder"; widgets-and-intents spec,
/// "Notification actions are entry points"). Every field is a plain value:
/// the handler reads this without opening the store.
public struct ReminderUserInfo: Sendable, Equatable {
    public var dayKey: String
    public var slotIndex: Int
    /// "HH:mm".
    public var plannedTime: String
    /// "HH:mm", or `nil` when the day has no later planned meal.
    public var nextPlannedTime: String?
    public var snoozeCount: Int
    public var quietHoursStart: String
    public var quietHoursEnd: String
    public var snoozeMinutes: Int

    public init(
        dayKey: String, slotIndex: Int, plannedTime: String, nextPlannedTime: String?,
        snoozeCount: Int, quietHoursStart: String, quietHoursEnd: String, snoozeMinutes: Int
    ) {
        self.dayKey = dayKey
        self.slotIndex = slotIndex
        self.plannedTime = plannedTime
        self.nextPlannedTime = nextPlannedTime
        self.snoozeCount = snoozeCount
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.snoozeMinutes = snoozeMinutes
    }

    /// The seven-key form a `UNNotificationRequest`'s `userInfo` carries:
    /// the record day key, the slot index, the planned time, the next
    /// planned time, the snooze count, quiet hours (one key, "HH:mm-HH:mm")
    /// and the snooze minutes (reminders spec, "Actions on a planned meal
    /// reminder"). Holds a slot index, never a slot label.
    public var dictionary: [String: String] {
        [
            "dayKey": dayKey,
            "slotIndex": String(slotIndex),
            "plannedTime": plannedTime,
            "nextPlannedTime": nextPlannedTime ?? "",
            "snoozeCount": String(snoozeCount),
            "quietHours": "\(quietHoursStart)-\(quietHoursEnd)",
            "snoozeMinutes": String(snoozeMinutes),
        ]
    }

    public init?(dictionary: [String: String]) {
        guard
            let dayKey = dictionary["dayKey"],
            let slotIndexText = dictionary["slotIndex"], let slotIndex = Int(slotIndexText),
            let plannedTime = dictionary["plannedTime"],
            let snoozeCountText = dictionary["snoozeCount"], let snoozeCount = Int(snoozeCountText),
            let quietHours = dictionary["quietHours"],
            let snoozeMinutesText = dictionary["snoozeMinutes"], let snoozeMinutes = Int(snoozeMinutesText)
        else { return nil }
        let quietHoursParts = quietHours.split(separator: "-", maxSplits: 1).map(String.init)
        guard quietHoursParts.count == 2 else { return nil }
        self.dayKey = dayKey
        self.slotIndex = slotIndex
        self.plannedTime = plannedTime
        let next = dictionary["nextPlannedTime"] ?? ""
        self.nextPlannedTime = next.isEmpty ? nil : next
        self.snoozeCount = snoozeCount
        self.quietHoursStart = quietHoursParts[0]
        self.quietHoursEnd = quietHoursParts[1]
        self.snoozeMinutes = snoozeMinutes
    }
}

/// The one pure rule the notification handler and the scheduler both call
/// (reminders spec, "Snooze a reminder": "One pure function
/// `SnoozeDecision.decide(userInfo:now:)` MUST hold every snooze rule.").
public enum SnoozeDecision {
    public enum Outcome: Sendable, Equatable {
        case scheduleAt(Date)
        case drop
    }

    public static func decide(
        userInfo: ReminderUserInfo, now: Date,
        calendar: Calendar = Calendar(identifier: .gregorian),
        constants: ProgrammeConstants = .default
    ) -> Outcome {
        guard userInfo.snoozeCount < constants.maxSnoozes else { return .drop }
        guard let candidate = calendar.date(byAdding: .minute, value: userInfo.snoozeMinutes, to: now) else { return .drop }
        let candidateClock = ClockTime.string(from: candidate, calendar: calendar)
        if QuietHours.contains(time: candidateClock, start: userInfo.quietHoursStart, end: userInfo.quietHoursEnd) {
            return .drop
        }
        // Order both times from the planned time, so a next planned meal
        // after midnight still comes after an evening snooze.
        if let next = userInfo.nextPlannedTime {
            let plannedMinute = ClockTime.minutesOfDay(userInfo.plannedTime)
            let untilNext = ClockTime.minutesSinceDayStart(next, dayStartMinute: plannedMinute)
            let untilSnooze = ClockTime.minutesSinceDayStart(candidateClock, dayStartMinute: plannedMinute)
            if untilSnooze >= untilNext { return .drop }
        }
        return .scheduleAt(candidate)
    }

    /// The one identifier a snoozed reminder carries, from the handler and
    /// from the scheduler alike, so the scheduler replaces the handler's
    /// request and never adds a second one.
    public static func requestIdentifier(dayKey: String, slotIndex: Int, snoozeCount: Int) -> String {
        "snooze.\(dayKey).\(slotIndex).\(snoozeCount)"
    }
}
