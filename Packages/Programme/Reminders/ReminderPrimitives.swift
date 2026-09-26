import Foundation
import Constants

/// "HH:mm" clock-time text and arithmetic, independent of the device locale
/// (reminders spec, "Discreet text by default": the body is the time
/// through the en_GB formatter, 24-hour clock). `Plan.PlanTime` is the same
/// shape for the `Plan` target; `Programme` never imports `Plan` (design.md,
/// "One umbrella package, five targets"), so this is its own copy, the same
/// duplication `Plan.QuietHours` already accepts ahead of this capability.
public enum ReminderClock {
    public static func string(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    public static func parse(_ time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return (hour, minute)
    }

    public static func minutesOfDay(_ time: String) -> Int {
        guard let (hour, minute) = parse(time) else { return 0 }
        return hour * 60 + minute
    }

    public static func string(from date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return string(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    /// `time` ("HH:mm") on the calendar day that contains `day`, or `nil`
    /// when `time` does not parse.
    public static func date(atTime time: String, on day: Date, calendar: Calendar) -> Date? {
        guard let (hour, minute) = parse(time) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}

/// The eight reminder types (reminders spec, "Reminder types and their
/// switches"). `reminders` (2.4) owns the planned meal, morning plan,
/// midday and close-the-day types; the weigh-in day, weekly review,
/// worksheet review and check-in types are each asked for by their own
/// owning capability (`weigh-in`, `weekly-review`, `problem-solving`,
/// `staying-on-track`) and travel through the same scheduler as an
/// `extraCandidate` (design.md: "The same scheduler MUST schedule every
/// reminder that another capability asks for").
public enum ReminderKind: String, Sendable, CaseIterable, Equatable, Codable {
    case plannedMeal, morningPlan, midday, closeTheDay, weighInDay, weeklyReview, worksheetReview, checkIn

    /// Highest priority first (reminders spec, "Two reminders never share a
    /// minute").
    public static let sameMinutePriorityOrder: [ReminderKind] = [
        .plannedMeal, .weeklyReview, .closeTheDay, .weighInDay, .checkIn, .worksheetReview, .morningPlan, .midday,
    ]

    /// The cap's drop order, first-dropped first (reminders spec, "The cap
    /// of two other reminders a day"). `.plannedMeal` and `.weeklyReview`
    /// are absent by construction: the cap never drops either.
    public static let dropOrder: [ReminderKind] = [
        .midday, .morningPlan, .worksheetReview, .checkIn, .weighInDay, .closeTheDay,
    ]

    /// The title with explicit wording on (reminders spec, "Discreet text by
    /// default"). `.plannedMeal` needs `slotLabel`; every other kind ignores
    /// it.
    public func explicitTitle(slotLabel: String? = nil) -> String {
        switch self {
        case .plannedMeal: return slotLabel ?? ""
        case .morningPlan: return "Set today's plan"
        case .midday: return "Anything to record from this morning?"
        case .closeTheDay: return "Close the day"
        case .weighInDay: return "Weigh-in day"
        case .weeklyReview: return "Weekly review"
        case .worksheetReview: return "Worksheet review"
        case .checkIn: return "Check-in"
        }
    }

    /// The notification category this kind registers under. Only a planned
    /// meal reminder carries actions (reminders spec, "Actions on a planned
    /// meal reminder"); every other kind opens its own screen on a plain
    /// tap.
    public var notificationCategory: String {
        self == .plannedMeal ? "plannedMeal" : "openOnly"
    }
}

/// One reminder before the pipeline runs (design.md, "Pure seams the
/// packages expose"). `time` is the clock time of day, "HH:mm", inside its
/// own record day.
public struct ReminderCandidate: Sendable, Equatable {
    public var kind: ReminderKind
    public var dayKey: String
    public var slotIndex: Int?
    public var time: String

    public init(kind: ReminderKind, dayKey: String, slotIndex: Int? = nil, time: String) {
        self.kind = kind
        self.dayKey = dayKey
        self.slotIndex = slotIndex
        self.time = time
    }
}

public enum InterruptionLevel: String, Sendable, Equatable {
    case active, timeSensitive
}

/// One local notification request the app maps to a `UNNotificationRequest`
/// (design.md: "`Scheduler.requests` returns `ReminderRequest` values").
public struct ReminderRequest: Sendable, Equatable {
    /// Every reminder shares this thread, so Notification Centre groups them
    /// as one (reminders spec, "Delivered reminders are grouped and
    /// removed").
    public static let threadIdentifier = "uk.midmorning.reminders"

    public let id: String
    public let kind: ReminderKind
    public let dayKey: String
    public let slotIndex: Int?
    public let time: Date
    /// Empty unless explicit wording is on (reminders spec, "Discreet text
    /// by default").
    public let title: String
    public let body: String
    public let userInfo: [String: String]
    public let interruptionLevel: InterruptionLevel
    public let category: String
    public let threadIdentifier: String

    public init(
        id: String, kind: ReminderKind, dayKey: String, slotIndex: Int?, time: Date,
        title: String, body: String, userInfo: [String: String],
        interruptionLevel: InterruptionLevel = .active, category: String,
        threadIdentifier: String = ReminderRequest.threadIdentifier
    ) {
        self.id = id
        self.kind = kind
        self.dayKey = dayKey
        self.slotIndex = slotIndex
        self.time = time
        self.title = title
        self.body = body
        self.userInfo = userInfo
        self.interruptionLevel = interruptionLevel
        self.category = category
        self.threadIdentifier = threadIdentifier
    }
}

/// Whether a clock time falls inside quiet hours (reminders spec, "Quiet
/// hours"). The canonical definition this capability owns; `Plan.QuietHours`
/// stays regular-eating-plan's own interim copy ahead of this change.
public enum ReminderQuietHours {
    public static let reminderNotSentMessage = "This time is in quiet hours. The reminder will not be sent."

    /// False when `start` equals `end` (reminders spec: "When the start
    /// equals the end, quiet hours are off").
    public static func isOn(start: String, end: String) -> Bool {
        start != end
    }

    /// True for `time` inside the half-open range from `start`, included, to
    /// `end`, excluded, wrapping past midnight when `end` is earlier than
    /// `start`. Always false when quiet hours are off.
    public static func contains(time: String, start: String, end: String) -> Bool {
        guard isOn(start: start, end: end) else { return false }
        let t = ReminderClock.minutesOfDay(time)
        let s = ReminderClock.minutesOfDay(start)
        let e = ReminderClock.minutesOfDay(end)
        if s <= e { return t >= s && t < e }
        return t >= s || t < e
    }
}

/// A planned meal reminder's three actions, always in this order, whatever
/// the explicit wording setting (reminders spec, "Actions on a planned meal
/// reminder"; app-lock spec, "A new entry before authentication"). The
/// declarative options mirror what `NotificationCategoryRegistering` (the
/// App target) sets on each `UNNotificationAction`; a device check proves
/// the real iOS behaviour they name.
public enum PlannedMealReminderAction: Sendable, Equatable, CaseIterable {
    case snooze, add, skipped

    /// Snooze, then Add, then Skipped — the one fixed order.
    public static let orderedActions: [PlannedMealReminderAction] = [.snooze, .add, .skipped]

    /// The `UNNotificationAction` identifier the App target registers and
    /// reads back from a notification response.
    public var identifier: String {
        switch self {
        case .snooze: return "uk.midmorning.reminder.snooze"
        case .add: return "uk.midmorning.reminder.add"
        case .skipped: return "uk.midmorning.reminder.skipped"
        }
    }

    /// True for "Skipped": it writes the record, so iOS asks for the device
    /// unlock first. The app makes no authentication request of its own.
    public var requiresDeviceUnlock: Bool { self == .skipped }

    /// True for "Add": it opens the app, so iOS unlocks the device before
    /// the app opens (a foreground action needs the device unlocked).
    public var opensAppInForeground: Bool { self == .add }
}

/// The discreet-by-default title and body (reminders spec, "Discreet text by
/// default"). The body is always the time; the title is empty unless
/// explicit wording is on.
public enum DiscreetText {
    public static func body(time: String) -> String { time }

    public static func title(kind: ReminderKind, explicitWordingOn: Bool, slotLabel: String? = nil) -> String {
        explicitWordingOn ? kind.explicitTitle(slotLabel: slotLabel) : ""
    }
}
