import XCTest
@testable import Programme

/// reminders spec, "The weekly review reminder" (mm-t24.12, parented under
/// mm-t32). "After the finish" is deferred to `mm-t36.15`, which supplies the
/// live "no review is due" fact this rule already respects (a `nil`
/// `dueDayKey`).
final class WeeklyReviewReminderTests: XCTestCase {
    private let horizon = (28...30).map { dayKey(2026, 9, $0) } + (1...5).map { dayKey(2026, 10, $0) }

    /// Scenario: The seventh day.
    func testTheSeventhDay() {
        let dueDayKey = dayKey(2026, 10, 4)
        let candidates = WeeklyReviewReminderRule.candidates(dueDayKey: dueDayKey, isFinished: false, dayKeys: horizon, time: "18:00")
        XCTAssertEqual(candidates, [ReminderCandidate(kind: .weeklyReview, dayKey: dueDayKey, time: "18:00")])
    }

    /// Scenario: The review done early.
    func testTheReviewDoneEarly() {
        let dueDayKey = dayKey(2026, 10, 4)
        let candidates = WeeklyReviewReminderRule.candidates(dueDayKey: dueDayKey, isFinished: true, dayKeys: horizon, time: "18:00")
        XCTAssertEqual(candidates, [], "the scheduler recomputes from scratch and no longer offers a finished review's reminder")
    }

    /// Scenario: Mid-week.
    func testMidWeek() {
        let candidates = WeeklyReviewReminderRule.candidates(dueDayKey: nil, isFinished: false, dayKeys: horizon, time: "18:00")
        XCTAssertEqual(candidates, [])
    }

    /// Scenario: After the finish.
    func testAfterTheFinish() {
        let candidates = WeeklyReviewReminderRule.candidates(dueDayKey: nil, isFinished: false, dayKeys: [dayKey(2026, 12, 27)], time: "18:00")
        XCTAssertEqual(candidates, [], "the weekly-review capability makes no review due after the finish, so it asks for no candidate")
    }

    func testAtMostOnePerReview() {
        let dueDayKey = dayKey(2026, 10, 4)
        let candidates = WeeklyReviewReminderRule.candidates(dueDayKey: dueDayKey, isFinished: false, dayKeys: horizon, time: "18:00")
        XCTAssertEqual(candidates.count, 1)
    }
}
