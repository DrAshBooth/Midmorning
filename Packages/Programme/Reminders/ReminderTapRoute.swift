import Foundation

/// The screen a response to a reminder opens (reminders spec: "Actions on a
/// planned meal reminder", "The morning plan reminder while the plan needs
/// setting", "Close the day", "The midday reminder", "Scheduling is local,
/// lazy and bounded", "The weigh-in day reminder", "The weekly review
/// reminder"). The App target's notification delegate calls this, and
/// Today opens the route.
public enum ReminderTapRoute: Sendable, Equatable {
    /// Today as it is: a tap on a planned meal reminder or on the far
    /// reminder, and a tap on a kind that has no screen of its own yet.
    case today
    /// "Add" on a planned meal reminder: the new-entry screen through the
    /// pending-route rule, with no cover (app-lock spec, "A new entry before
    /// authentication").
    case addAction
    /// A tap on the midday reminder: the new-entry screen. This is not one
    /// of the entry points of the pending-route rule, so it opens only when
    /// no cover shows.
    case newEntry
    /// A tap on the morning plan reminder: "Today's plan".
    case todaysPlan
    /// A tap on the close-the-day reminder: the close-the-day screen for the
    /// record day that the reminder names.
    case closeTheDay(dayKey: String?)
    /// A tap on the weigh-in day reminder: the weigh-in screen.
    case weighIn
    /// A tap on the weekly review reminder: the weekly review.
    case weeklyReview

    /// The route for one notification response, or `nil` for "Skipped" and
    /// the snooze action, which open no screen. `requestIdentifier` tells
    /// the far reminder apart: it carries the close-the-day kind, but a tap
    /// on it opens Today.
    public static func forResponse(actionIdentifier: String, requestIdentifier: String, kind: String?, dayKey: String?) -> ReminderTapRoute? {
        switch actionIdentifier {
        case PlannedMealReminderAction.snooze.identifier, PlannedMealReminderAction.skipped.identifier:
            return nil
        case PlannedMealReminderAction.add.identifier:
            return .addAction
        default:
            return forPlainTap(requestIdentifier: requestIdentifier, kind: kind, dayKey: dayKey)
        }
    }

    /// The route for a tap on the body of a reminder.
    public static func forPlainTap(requestIdentifier: String, kind: String?, dayKey: String?) -> ReminderTapRoute {
        if requestIdentifier.hasPrefix(farReminderIdentifierPrefix) { return .today }
        switch kind.flatMap(ReminderKind.init(rawValue:)) {
        case .morningPlan: return .todaysPlan
        case .midday: return .newEntry
        case .closeTheDay: return .closeTheDay(dayKey: dayKey)
        case .weighInDay: return .weighIn
        case .weeklyReview: return .weeklyReview
        case .plannedMeal, .worksheetReview, .checkIn, nil: return .today
        }
    }

    /// The start of the far reminder's request identifier (`Scheduler
    /// .requests`, "far.<day key>").
    public static let farReminderIdentifierPrefix = "far."
}
