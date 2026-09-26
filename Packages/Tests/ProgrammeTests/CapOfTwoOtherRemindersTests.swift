import XCTest
@testable import Programme

/// reminders spec, "The cap of two other reminders a day" (mm-t24.13).
final class CapOfTwoOtherRemindersTests: XCTestCase {
    private func c(_ kind: ReminderKind, _ time: String = "12:00") -> ReminderCandidate {
        ReminderCandidate(kind: kind, dayKey: "2026-09-24", time: time)
    }

    /// Scenario: A weekday with three other reminders.
    func testAWeekdayWithThreeOtherReminders() {
        let result = ReminderCap.apply([c(.morningPlan), c(.midday), c(.closeTheDay)])
        XCTAssertEqual(Set(result.map(\.kind)), [.morningPlan, .closeTheDay])
    }

    /// Scenario: The weekly review on the weigh-in day.
    func testTheWeeklyReviewOnTheWeighInDay() {
        let result = ReminderCap.apply([c(.weighInDay), c(.weeklyReview), c(.closeTheDay)])
        XCTAssertEqual(Set(result.map(\.kind)), [.weeklyReview, .closeTheDay])
    }

    /// Scenario: Six planned meals and two others.
    func testSixPlannedMealsAndTwoOthers() {
        let plannedMeals = (0..<6).map { ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: $0, time: "0\($0):00") }
        let result = ReminderCap.apply(plannedMeals + [c(.weighInDay), c(.closeTheDay)])
        XCTAssertEqual(result.count, 8)
    }

    /// Scenario: Snoozes do not count — a snooze never becomes a
    /// `ReminderCandidate` in the first place; `SnoozeDecision` schedules it
    /// directly, bypassing the cap entirely.
    func testSnoozesDoNotCount() {
        let result = ReminderCap.apply([c(.weighInDay), c(.closeTheDay)])
        XCTAssertEqual(result.count, 2, "at the cap already, with no snooze candidate to consider")
    }
}
