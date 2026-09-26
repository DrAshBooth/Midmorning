import Foundation

/// The week number of one review and the start day of its run.
public struct ReviewRunWeek: Sendable, Hashable {
    public var week: Int
    public var runStartDay: String

    public init(week: Int, runStartDay: String) {
        self.week = week
        self.runStartDay = runStartDay
    }
}

/// Finds the run and the week of each stored review (weekly-review spec,
/// "Finish and reopen a review": "Each review has its own due day as its
/// key, so after a restart the list can show two runs."; "The week's counts
/// are frozen in the Review row", scenario "Keyed by the due day"). A
/// restart replaces the start day setting, so a review from an earlier run
/// cannot get its week from the start day in force now.
public enum ReviewRuns {
    /// One stored review as this rule reads it: its due-day key and the run
    /// start day its payload holds, or `nil` on an older row.
    public struct Row: Sendable, Equatable {
        public var dueDayKey: String
        public var runStartDay: String?

        public init(dueDayKey: String, runStartDay: String?) {
            self.dueDayKey = dueDayKey
            self.runStartDay = runStartDay
        }
    }

    /// The week whose review is due on `dueDayKey` in the run that started
    /// on `runStartDay`, or `nil` when the key is not a due day of that run.
    public static func week(dueDayKey: String, runStartDay: String, calendar: Calendar) -> Int? {
        let days = DayKeyMath.daysBetween(runStartDay, dueDayKey, calendar: calendar)
        guard days >= 7, days % 7 == 0 else { return nil }
        return days / 7
    }

    /// The run and week of every row in `rows`, by due-day key. Pass every
    /// stored review, finished or not, because the rule for an older row
    /// reads the rows before it.
    ///
    /// - A row that holds its run start day uses it.
    /// - An older row due after the current start day is in the current
    ///   run: a review freezes only after its due day, and a restart picks
    ///   today or tomorrow, so no earlier run has a review due after the
    ///   new start day.
    /// - An older row due on or before the current start day is in an
    ///   earlier run. The app froze every week of that run from week 1, so
    ///   the rows 7, 14, 21 ... days before it give its week number.
    public static func runWeeks(rows: [Row], currentStartDay: String, calendar: Calendar) -> [String: ReviewRunWeek] {
        let keys = Set(rows.map(\.dueDayKey))
        var result: [String: ReviewRunWeek] = [:]
        for row in rows {
            if let start = row.runStartDay, let week = week(dueDayKey: row.dueDayKey, runStartDay: start, calendar: calendar) {
                result[row.dueDayKey] = ReviewRunWeek(week: week, runStartDay: start)
                continue
            }
            if DayKeyMath.isBefore(currentStartDay, row.dueDayKey),
               let week = week(dueDayKey: row.dueDayKey, runStartDay: currentStartDay, calendar: calendar) {
                result[row.dueDayKey] = ReviewRunWeek(week: week, runStartDay: currentStartDay)
                continue
            }
            var week = 1
            while keys.contains(DayKeyMath.adding(-7 * week, to: row.dueDayKey, calendar: calendar)) {
                week += 1
            }
            result[row.dueDayKey] = ReviewRunWeek(week: week, runStartDay: DayKeyMath.adding(-7 * week, to: row.dueDayKey, calendar: calendar))
        }
        return result
    }
}
