import XCTest
@testable import Programme

/// reminders spec, "Close the day" (mm-t24.8). The screen's own scenarios
/// ("Add an entry", "One word", "A day with no entries") are the
/// `CloseTheDayView` App-target screen plus `RecordStore`'s feeling-word row
/// (`RecordTests.FeelingWordStoreTests`); this file covers the pure "is
/// something missing" rule the reminder itself fires on.
final class CloseTheDayTests: XCTestCase {
    /// Scenario: The reminder.
    func testTheReminder() {
        let facts = CloseTheDayFacts(stage2Open: false, hasEntryAfter17: false, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false)
        XCTAssertTrue(CloseTheDayRule.somethingMissing(facts))
    }

    /// Scenario: An evening entry in stage 1 (a stage fact; `mm-t32.16` runs
    /// it end to end).
    func testAnEveningEntryInStage1() {
        let facts = CloseTheDayFacts(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false)
        XCTAssertFalse(CloseTheDayRule.somethingMissing(facts))
    }

    /// Scenario: The last planned meal has an entry.
    func testTheLastPlannedMealHasAnEntry() {
        let facts = CloseTheDayFacts(stage2Open: true, hasEntryAfter17: false, lastPlannedMealTime: "21:00", lastPlannedMealMatched: true, hasEntryAtOrAfterLastPlannedMealTime: true)
        XCTAssertFalse(CloseTheDayRule.somethingMissing(facts))
    }

    /// Scenario: The last planned meal is missed.
    func testTheLastPlannedMealIsMissed() {
        let facts = CloseTheDayFacts(stage2Open: true, hasEntryAfter17: false, lastPlannedMealTime: "21:00", lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false)
        XCTAssertTrue(CloseTheDayRule.somethingMissing(facts))
    }

    /// Scenario: An entry after the last planned meal's time.
    func testAnEntryAfterTheLastPlannedMealsTime() {
        let facts = CloseTheDayFacts(stage2Open: true, hasEntryAfter17: false, lastPlannedMealTime: "19:00", lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: true)
        XCTAssertFalse(CloseTheDayRule.somethingMissing(facts))
    }

    /// From stage 2, on a day with no planned meal, the stage 1 rule
    /// applies.
    func testStage2WithNoPlannedMealUsesTheStage1Rule() {
        let facts = CloseTheDayFacts(stage2Open: true, hasEntryAfter17: false, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false)
        XCTAssertTrue(CloseTheDayRule.somethingMissing(facts))
    }
}
