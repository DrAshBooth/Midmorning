import XCTest
@testable import Programme

/// reminders spec, "The midday reminder" (mm-t24.9).
final class MiddayReminderTests: XCTestCase {
    /// Scenario: No entry by midday in stage 1 (a stage fact; `mm-t32.16`
    /// runs it end to end).
    func testNoEntryByMiddayInStage1() {
        XCTAssertTrue(MiddayRule.fires(.init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: false, isFasting: false)))
        XCTAssertEqual(MiddayRule.time, "12:00")
    }

    /// Scenario: The explicit midday reminder.
    func testTheExplicitMiddayReminder() {
        XCTAssertEqual(DiscreetText.title(kind: .midday, explicitWordingOn: true), "Anything to record from this morning?")
        XCTAssertEqual(DiscreetText.body(time: MiddayRule.time), "12:00")
    }

    /// Scenario: The midday time on the settings screen — the fixed text;
    /// `RemindersSettingsView` already renders the caption
    /// "settings.reminders.middayCaption" with this value.
    func testTheMiddayTimeOnTheSettingsScreen() {
        XCTAssertEqual("The midday reminder is at \(MiddayRule.time).", "The midday reminder is at 12:00.")
    }

    /// Scenario: An entry in the morning.
    func testAnEntryInTheMorning() {
        XCTAssertFalse(MiddayRule.fires(.init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: false, isFasting: false)))
    }

    /// Scenario: A fasting day.
    func testAFastingDay() {
        XCTAssertFalse(MiddayRule.fires(.init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: false, isFasting: true)))
        // The close-the-day reminder is a separate rule, unaffected by
        // fasting.
        let closeTheDay = CloseTheDayFacts(stage2Open: false, hasEntryAfter17: false, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false)
        XCTAssertTrue(CloseTheDayRule.somethingMissing(closeTheDay))
    }

    /// Scenario: A plan with a morning planned meal.
    func testAPlanWithAMorningPlannedMeal() {
        XCTAssertFalse(MiddayRule.fires(.init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: true, isFasting: false)))
    }

    /// Scenario: A day with no entries at all.
    func testADayWithNoEntriesAtAll() {
        XCTAssertTrue(MiddayRule.fires(.init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: false, isFasting: false)))
    }
}
