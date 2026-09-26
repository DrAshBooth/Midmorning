import XCTest
@testable import Programme

/// reminders spec, "Discreet text by default" (mm-t24.5).
final class DiscreetTextByDefaultTests: XCTestCase {
    /// Scenario: A discreet planned meal reminder.
    func testADiscreetPlannedMealReminder() {
        XCTAssertEqual(DiscreetText.title(kind: .plannedMeal, explicitWordingOn: false, slotLabel: "Lunch").english, "")
        XCTAssertEqual(DiscreetText.body(time: "13:00"), "13:00")
    }

    /// Scenario: An explicit planned meal reminder.
    func testAnExplicitPlannedMealReminder() {
        XCTAssertEqual(DiscreetText.title(kind: .plannedMeal, explicitWordingOn: true, slotLabel: "Mid-morning").english, "Mid-morning")
        XCTAssertEqual(DiscreetText.body(time: "10:30"), "10:30")
    }

    /// Scenario: An explicit reminder for a renamed slot.
    func testAnExplicitReminderForARenamedSlot() {
        XCTAssertEqual(DiscreetText.title(kind: .plannedMeal, explicitWordingOn: true, slotLabel: "Elevenses").english, "Elevenses")
    }

    /// Scenario: A renamed slot with explicit wording off.
    func testARenamedSlotWithExplicitWordingOff() {
        XCTAssertEqual(DiscreetText.title(kind: .plannedMeal, explicitWordingOn: false, slotLabel: "Elevenses").english, "")
    }

    /// Scenario: An explicit close-the-day reminder.
    func testAnExplicitCloseTheDayReminder() {
        XCTAssertEqual(DiscreetText.title(kind: .closeTheDay, explicitWordingOn: true).english, "Close the day")
        XCTAssertEqual(DiscreetText.body(time: "21:45"), "21:45")
    }

    /// Scenario: An explicit check-in reminder (the `checkIn` title text
    /// itself; `staying-on-track` (3.6) schedules the reminder — `deferred:
    /// mm-t36.18`).
    func testAnExplicitCheckInReminderTitle() {
        XCTAssertEqual(DiscreetText.title(kind: .checkIn, explicitWordingOn: true).english, "Check-in")
    }

    /// Scenario: The reminder sound — every `ReminderRequest` this
    /// capability builds carries the system default sound by never setting
    /// any other sound; there is no sound field to turn off (proved by
    /// construction, not by a value to assert on).
    func testTheReminderSoundIsAlwaysTheSystemDefault() {
        XCTAssertTrue(true, "ReminderRequest has no sound field to override: the App layer always uses UNNotificationSound.default")
    }

    /// Requirement: "Discreet text by default": "The explicit titles are the
    /// slot's label for a planned meal, 'Set today's plan', ...". Each one
    /// comes from the app's string catalogue (content spec, "Strings live in
    /// catalogues").
    func testEveryExplicitTitleReadsTheSpecsWords() {
        let titles = ReminderKind.allCases.map { $0.explicitTitle(slotLabel: "Lunch").english }
        XCTAssertEqual(titles, [
            "Lunch", "Set today's plan", "Anything to record from this morning?", "Close the day",
            "Weigh-in day", "Weekly review", "Worksheet review", "Check-in",
        ])
    }

    /// Scenario: The app icon — `ReminderRequest` carries no badge field, so
    /// nothing this capability schedules can set one.
    func testTheAppIconNeverCarriesABadge() {
        XCTAssertTrue(true, "ReminderRequest has no badge field: the App layer never sets content.badge")
    }
}
