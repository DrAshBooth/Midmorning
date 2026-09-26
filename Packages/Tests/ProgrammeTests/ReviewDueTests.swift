import XCTest
@testable import Programme

/// weekly-review spec, "When a weekly review is due" (mm-t32.3). "No
/// network" has no pure-function shape of its own (the review's save is
/// already a plain local `RecordStore` write with no network call anywhere
/// in the path); `RecordTests.ReviewStoreTests.testNoNetworkReviewSavesLocally`
/// proves the round trip. "After the finish" is deferred to `mm-t36.15`.
final class ReviewDueTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let startDay = dayKey(2026, 9, 28) // Monday

    /// Scenario: The first review.
    func testTheFirstReview() {
        XCTAssertEqual(ReviewDue.dueMoment(week: 1, startDay: startDay, dayStart: 4, calendar: calendar), moment(2026, 10, 5, 4))
        let range = ReviewDue.weekRange(week: 1, startDay: startDay, calendar: calendar)
        XCTAssertEqual(range.first, dayKey(2026, 9, 28))
        XCTAssertEqual(range.last, dayKey(2026, 10, 4))
    }

    /// Scenario: Today while a review is due.
    func testTodayWhileAReviewIsDue() {
        let week = ReviewDue.todayLineWeek(startDay: startDay, currentRecordDay: dayKey(2026, 10, 5), calendar: calendar, isFinished: { _ in false })
        XCTAssertEqual(week, 1)
    }

    /// Scenario: A review left unfinished.
    func testAReviewLeftUnfinished() {
        // Week 2's review becomes due on 12 October; week 1's stays
        // unfinished, but Today shows only week 2's line.
        let week = ReviewDue.todayLineWeek(startDay: startDay, currentRecordDay: dayKey(2026, 10, 12), calendar: calendar, isFinished: { _ in false })
        XCTAssertEqual(week, 2, "the latest due week shows, with no text about week 1")
    }

    /// No due review shows before week 1's own due moment.
    func testNoReviewControlBeforeTheFirstReview() {
        let week = ReviewDue.todayLineWeek(startDay: startDay, currentRecordDay: dayKey(2026, 10, 4), calendar: calendar, isFinished: { _ in false })
        XCTAssertNil(week)
    }

    /// A finished review's line disappears, even before the next one is due.
    func testAFinishedReviewShowsNoLine() {
        let week = ReviewDue.todayLineWeek(startDay: startDay, currentRecordDay: dayKey(2026, 10, 5), calendar: calendar, isFinished: { $0 == 1 })
        XCTAssertNil(week)
    }

    func testWeekDayKeysAreTheSevenDaysInOrder() {
        let keys = ReviewDue.weekDayKeys(week: 3, startDay: startDay, calendar: calendar)
        XCTAssertEqual(keys, [dayKey(2026, 10, 12), dayKey(2026, 10, 13), dayKey(2026, 10, 14), dayKey(2026, 10, 15), dayKey(2026, 10, 16), dayKey(2026, 10, 17), dayKey(2026, 10, 18)])
    }
}
