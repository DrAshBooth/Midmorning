import Foundation

/// The weekly review reminder's own candidate (reminders spec, "The weekly
/// review reminder"; design.md, "The same scheduler MUST schedule every
/// reminder that another capability asks for"). `weekly-review` builds this
/// and feeds it into `Scheduler.requests(extraCandidates:)`, the same way
/// `WeighInReminderRule` does for the weigh-in day reminder.
public enum WeeklyReviewReminderRule {
    /// One `.weeklyReview` candidate for `dueDayKey`, at `time`, when
    /// `dueDayKey` falls in the scheduler's own horizon (`dayKeys`) and the
    /// review is not already finished. `nil` `dueDayKey` (no review due, or
    /// the programme has finished) schedules none ("The scheduler MUST
    /// schedule at most one weekly review reminder per review.").
    public static func candidates(dueDayKey: String?, isFinished: Bool, dayKeys: [String], time: String) -> [ReminderCandidate] {
        guard let dueDayKey, !isFinished, dayKeys.contains(dueDayKey) else { return [] }
        return [ReminderCandidate(kind: .weeklyReview, dayKey: dueDayKey, time: time)]
    }

    /// One `.weeklyReview` candidate for each record day in `dayKeys` on
    /// which a weekly review becomes due (`ReviewDue.dueDayKey`, the start
    /// day plus seven days for each week), unless that review is already
    /// finished. The scheduler asks for the reminder ahead of time, so it
    /// fires on the due day also when the app does not run on that day
    /// (reminders spec, "The weekly review reminder": "The scheduler MUST
    /// schedule the weekly review reminder at that time on the day the
    /// weekly review becomes due."; "Scheduling is local, lazy and
    /// bounded").
    public static func candidates(
        startDay: String, dayKeys: [String], time: String, calendar: Calendar, isFinished: (_ week: Int) -> Bool
    ) -> [ReminderCandidate] {
        dayKeys.compactMap { dayKey in
            let days = DayKeyMath.daysBetween(startDay, dayKey, calendar: calendar)
            guard days > 0, days % 7 == 0 else { return nil }
            let week = days / 7
            guard ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar) == dayKey, !isFinished(week) else { return nil }
            return ReminderCandidate(kind: .weeklyReview, dayKey: dayKey, time: time)
        }
    }
}
