import XCTest
@testable import Programme

/// weekly-review spec, "Finish and reopen a review" ("after a restart the
/// list can show two runs") and "The week's counts are frozen in the Review
/// row", scenario "Keyed by the due day" (mm-t32.22). The App target's
/// `WeeklyReviewModel.reviewsListRows` and the pinned note's route call
/// `ReviewRuns.runWeeks`; `RecordTests.ReviewSaveStoreTests` runs it over
/// the real store.
final class ReviewRunsTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let firstRun = dayKey(2026, 9, 28) // Monday
    private let secondRun = dayKey(2027, 1, 4) // Monday, after the restart

    /// Rows that hold their run start day keep their week, in both runs.
    func testRowsWithTheirRunStartDay() {
        let rows = [
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 5), runStartDay: firstRun),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 12), runStartDay: firstRun),
            ReviewRuns.Row(dueDayKey: dayKey(2027, 1, 11), runStartDay: secondRun),
        ]
        let runs = ReviewRuns.runWeeks(rows: rows, currentStartDay: secondRun, calendar: calendar)
        XCTAssertEqual(runs[dayKey(2026, 10, 5)], ReviewRunWeek(week: 1, runStartDay: firstRun))
        XCTAssertEqual(runs[dayKey(2026, 10, 12)], ReviewRunWeek(week: 2, runStartDay: firstRun))
        XCTAssertEqual(runs[dayKey(2027, 1, 11)], ReviewRunWeek(week: 1, runStartDay: secondRun))
    }

    /// Scenario: Keyed by the due day. Older rows hold no run start day;
    /// the first run's rows still get their own weeks after the restart.
    func testOlderRowsAfterARestart() {
        let rows = [
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 5), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 12), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 19), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2027, 1, 11), runStartDay: nil),
        ]
        let runs = ReviewRuns.runWeeks(rows: rows, currentStartDay: secondRun, calendar: calendar)
        XCTAssertEqual(runs[dayKey(2026, 10, 5)], ReviewRunWeek(week: 1, runStartDay: firstRun))
        XCTAssertEqual(runs[dayKey(2026, 10, 19)], ReviewRunWeek(week: 3, runStartDay: firstRun))
        XCTAssertEqual(runs[dayKey(2027, 1, 11)], ReviewRunWeek(week: 1, runStartDay: secondRun), "the second run uses its own due-day keys")
    }

    /// A restart on a weekday that keeps the first run's weekday: a first
    /// run review due on the new start day is still in the first run.
    func testARestartOnTheSameWeekday() {
        let restartDay = dayKey(2026, 10, 19)
        let rows = [
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 5), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 12), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 19), runStartDay: nil),
            ReviewRuns.Row(dueDayKey: dayKey(2026, 10, 26), runStartDay: nil),
        ]
        let runs = ReviewRuns.runWeeks(rows: rows, currentStartDay: restartDay, calendar: calendar)
        XCTAssertEqual(runs[dayKey(2026, 10, 19)], ReviewRunWeek(week: 3, runStartDay: firstRun))
        XCTAssertEqual(runs[dayKey(2026, 10, 26)], ReviewRunWeek(week: 1, runStartDay: restartDay))
    }

    /// With no restart, every row is in the current run.
    func testNoRestart() {
        let rows = [ReviewRuns.Row(dueDayKey: dayKey(2026, 11, 2), runStartDay: nil)]
        let runs = ReviewRuns.runWeeks(rows: rows, currentStartDay: firstRun, calendar: calendar)
        XCTAssertEqual(runs[dayKey(2026, 11, 2)], ReviewRunWeek(week: 5, runStartDay: firstRun))
        XCTAssertEqual(ReviewDue.dueDayKey(week: 5, startDay: firstRun, calendar: calendar), dayKey(2026, 11, 2))
    }

    /// `week(dueDayKey:runStartDay:)` accepts only a due day of that run.
    func testWeekOfADueDay() {
        XCTAssertEqual(ReviewRuns.week(dueDayKey: dayKey(2026, 10, 5), runStartDay: firstRun, calendar: calendar), 1)
        XCTAssertNil(ReviewRuns.week(dueDayKey: dayKey(2026, 10, 6), runStartDay: firstRun, calendar: calendar))
        XCTAssertNil(ReviewRuns.week(dueDayKey: firstRun, runStartDay: firstRun, calendar: calendar))
    }
}

/// weekly-review spec, "The summary built from the record", scenario "I
/// won't be weighing" (mm-t32.23). `WeeklyReviewModel.weekFacts` calls
/// `ReviewWeekFacts.weighInDoneDayKey`; `RecordTests.ReviewSaveStoreTests`
/// runs it over the real store.
final class ReviewWeighInPartTests: XCTestCase {
    private let week = (0..<7).map { dayKey(2026, 10, 5 + $0) }

    /// Scenario: I won't be weighing. A kept weigh-in gives no part.
    func testIWontBeWeighingLeavesThePartOut() {
        let key = ReviewWeekFacts.weighInDoneDayKey(weighInDayKeys: [dayKey(2026, 10, 5)], weekDayKeys: week, weighInDayChosen: false)
        XCTAssertNil(key)
        let facts = ReviewWeekFacts(weekDayKeys: week, weighInDoneDayKey: key)
        XCTAssertFalse(ReviewSummary.parts(facts, calendar: engineTestCalendar).contains { $0.contains("Weigh-in") })
    }

    /// With a weigh-in day chosen, the week's weigh-in gives the part.
    func testAChosenDayShowsThePart() {
        let key = ReviewWeekFacts.weighInDoneDayKey(weighInDayKeys: [dayKey(2026, 9, 28), dayKey(2026, 10, 5)], weekDayKeys: week, weighInDayChosen: true)
        XCTAssertEqual(key, dayKey(2026, 10, 5))
        let facts = ReviewWeekFacts(weekDayKeys: week, weighInDoneDayKey: key)
        XCTAssertTrue(ReviewSummary.parts(facts, calendar: engineTestCalendar).contains("Weigh-in: done on Monday."))
    }
}
