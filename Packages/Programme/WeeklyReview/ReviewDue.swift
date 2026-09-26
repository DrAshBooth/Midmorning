import Foundation

/// When a weekly review becomes due, and which week's line Today shows
/// (weekly-review spec, "When a weekly review is due"). Week counting is
/// `programme`'s own rule (`StageEngine.week`); this file only adds the
/// due-moment and due-line rules on top of it. First cut: the "After the
/// finish" scenario waits for `staying-on-track` (mm-t36.15 builds it).
public enum ReviewDue {
    /// The record-day key on which the review of `week` becomes due: the
    /// start day plus `7 * week` days — the first day of week `week + 1`
    /// ("week n starts on the start day plus 7 × (n − 1) days").
    public static func dueDayKey(week: Int, startDay: String, calendar: Calendar) -> String {
        DayKeyMath.adding(7 * week, to: startDay, calendar: calendar)
    }

    /// The moment the review of `week` becomes due: `dueDayKey`'s own day
    /// start.
    public static func dueMoment(week: Int, startDay: String, dayStart: Int, calendar: Calendar) -> Date {
        DayKeyMath.dayStartMoment(for: dueDayKey(week: week, startDay: startDay, calendar: calendar), dayStart: dayStart, calendar: calendar)
    }

    /// The first and last record-day keys of `week` (its "covers ... to
    /// ..." range).
    public static func weekRange(week: Int, startDay: String, calendar: Calendar) -> (first: String, last: String) {
        let first = DayKeyMath.adding(7 * (week - 1), to: startDay, calendar: calendar)
        let last = DayKeyMath.adding(7 * (week - 1) + 6, to: startDay, calendar: calendar)
        return (first, last)
    }

    /// The seven record-day keys of `week`, in order.
    public static func weekDayKeys(week: Int, startDay: String, calendar: Calendar) -> [String] {
        let first = DayKeyMath.adding(7 * (week - 1), to: startDay, calendar: calendar)
        return (0..<7).map { DayKeyMath.adding($0, to: first, calendar: calendar) }
    }

    /// The latest week whose review has become due by `currentRecordDay`, or
    /// `nil` before week 1's review is due ("The review of week n MUST stay
    /// due until the review of week n + 1 becomes due.").
    public static func latestDueWeek(startDay: String, currentRecordDay: String, calendar: Calendar) -> Int? {
        guard let week = StageEngine.week(startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar), week > 1 else { return nil }
        return week - 1
    }

    /// The week whose "Weekly review" line Today shows: the latest due
    /// week, unless the person already finished it ("While a review is due
    /// and not finished, Today MUST show the line").
    public static func todayLineWeek(startDay: String, currentRecordDay: String, calendar: Calendar, isFinished: (Int) -> Bool) -> Int? {
        guard let week = latestDueWeek(startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar) else { return nil }
        return isFinished(week) ? nil : week
    }
}
