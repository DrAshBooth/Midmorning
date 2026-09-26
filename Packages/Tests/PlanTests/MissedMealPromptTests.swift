import Foundation
import XCTest
@testable import Plan
import Constants

/// regular-eating-plan spec, "A missed planned meal gets one prompt"
/// (mm-t23.11). First cut: "Skipped" and "Add it" are wired; "That was it"
/// and "That was it, then a later window moves over the entry" are
/// `deferred: mm-t33.14` (3.3 problem-solving).
final class MissedMealPromptTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func lunch(windowEnd: Date, matched: Bool = false, skipped: Bool = false, laterEntry: Bool = false, laterAnswered: Bool = false, quietHours: Bool = false, candidate: Date? = nil) -> MissedPlannedMeal {
        MissedPlannedMeal(slotIndex: 2, windowEnd: windowEnd, hasMatchedEntry: matched, hasSkippedAnswer: skipped, hasLaterEntry: laterEntry, laterSlotAnswered: laterAnswered, windowEndsInQuietHours: quietHours, candidateEntryTime: candidate)
    }

    /// Scenario: The window ends with no entry.
    func testTheWindowEndsWithNoEntry() {
        let meal = lunch(windowEnd: at(14, 30))
        let state = MissedMealPrompt.active(meals: [meal], now: at(14, 30), recordDayHasEnded: false)
        XCTAssertEqual(state?.form, .skippedOrNotRecorded)
        XCTAssertEqual(MissedMealPrompt.line(for: state!.form, timeText: { _ in "" }), "Skipped, or not recorded yet?")
    }

    /// Scenario: Add it — the new-entry screen opens with the planned meal's
    /// own time (13:00); a UI wiring fact, not a new pure rule. The pure
    /// input it depends on — that the prompt is active for Lunch — is
    /// exactly `testTheWindowEndsWithNoEntry` above.
    func testAddItUsesThePlannedMealsOwnTime() {
        let plannedTime = "13:00"
        XCTAssertEqual(PlannedMeal(slotIndex: 2, time: plannedTime).time, plannedTime)
    }

    /// Scenario: An unmatched entry after the window.
    func testAnUnmatchedEntryAfterTheWindowShowsTheWasThatForm() {
        let candidateTime = at(14, 45)
        let found = MissedMealPrompt.candidateEntry(after: at(13, 0), before: at(16, 0), unmatchedEntries: [PlanEntryFact(id: UUID(), time: candidateTime)])
        XCTAssertEqual(found?.time, candidateTime)
        let meal = lunch(windowEnd: at(14, 30), candidate: candidateTime)
        let state = MissedMealPrompt.active(meals: [meal], now: at(15, 0), recordDayHasEnded: false)
        XCTAssertEqual(state?.form, .skippedOrWasThat(candidateTime: candidateTime))
    }

    /// Scenario: Two missed planned meals.
    func testTwoMissedPlannedMealsShowThePromptOnTheLatestOnly() {
        let lunchMeal = lunch(windowEnd: at(14, 30))
        let midAfternoon = MissedPlannedMeal(slotIndex: 3, windowEnd: at(17, 30), hasMatchedEntry: false, hasSkippedAnswer: false, hasLaterEntry: false, laterSlotAnswered: false, windowEndsInQuietHours: false)
        let state = MissedMealPrompt.active(meals: [lunchMeal, midAfternoon], now: at(18, 0), recordDayHasEnded: false)
        XCTAssertEqual(state?.slotIndex, 3, "the prompt sits on Mid-afternoon only")
    }

    /// Scenario: The prompt moves to a later missed planned meal.
    func testThePromptMovesToALaterMissedPlannedMeal() {
        let lunchMeal = lunch(windowEnd: at(14, 30))
        let midAfternoon = MissedPlannedMeal(slotIndex: 3, windowEnd: at(17, 30), hasMatchedEntry: false, hasSkippedAnswer: false, hasLaterEntry: false, laterSlotAnswered: false, windowEndsInQuietHours: false)
        let atSeventeen = MissedMealPrompt.active(meals: [lunchMeal, midAfternoon], now: at(17, 0), recordDayHasEnded: false)
        XCTAssertEqual(atSeventeen?.slotIndex, 2, "still on Lunch; Mid-afternoon's window has not ended")
        let atSeventeenThirty = MissedMealPrompt.active(meals: [lunchMeal, midAfternoon], now: at(17, 30), recordDayHasEnded: false)
        XCTAssertEqual(atSeventeenThirty?.slotIndex, 3, "moved to Mid-afternoon")
    }

    /// Scenario: An answered prompt, then an earlier missed planned meal.
    func testAnAnsweredPromptThenAnEarlierMissedPlannedMealShowsNoPrompt() {
        let lunchMeal = lunch(windowEnd: at(14, 30), laterAnswered: true)
        let midAfternoon = MissedPlannedMeal(slotIndex: 3, windowEnd: at(17, 30), hasMatchedEntry: false, hasSkippedAnswer: true, hasLaterEntry: false, laterSlotAnswered: false, windowEndsInQuietHours: false)
        let state = MissedMealPrompt.active(meals: [lunchMeal, midAfternoon], now: at(18, 0), recordDayHasEnded: false)
        XCTAssertNil(state, "no second prompt on the earlier missed planned meal after the person answers")
    }

    /// Scenario: A later entry.
    func testALaterEntrySuppressesTheEarlierPrompt() {
        let meal = lunch(windowEnd: at(14, 30), laterEntry: true)
        let state = MissedMealPrompt.active(meals: [meal], now: at(20, 0), recordDayHasEnded: false)
        XCTAssertNil(state)
    }

    /// Scenario: The window ends inside quiet hours.
    func testTheWindowEndsInsideQuietHoursShowsNoPrompt() {
        XCTAssertTrue(QuietHours.contains(time: "22:30", start: "22:00", end: "07:00"))
        let meal = lunch(windowEnd: at(22, 30), quietHours: true)
        let state = MissedMealPrompt.active(meals: [meal], now: at(22, 30), recordDayHasEnded: false)
        XCTAssertNil(state)
    }

    /// Scenario: Skipped from the reminder.
    func testSkippedFromTheReminderShowsNoPrompt() {
        let meal = lunch(windowEnd: at(13, 5), skipped: true)
        let state = MissedMealPrompt.active(meals: [meal], now: at(13, 40), recordDayHasEnded: false)
        XCTAssertNil(state)
    }

    /// Scenario: Unanswered at the end of the day.
    func testUnansweredAtTheEndOfTheDayHidesThePrompt() {
        let meal = lunch(windowEnd: at(14, 30))
        let state = MissedMealPrompt.active(meals: [meal], now: at(4, 0, day: 25), recordDayHasEnded: true)
        XCTAssertNil(state)
    }
}
