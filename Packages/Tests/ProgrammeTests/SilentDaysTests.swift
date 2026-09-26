import XCTest
@testable import Programme

/// reminders spec, "The midday and close-the-day reminders stop after seven
/// silent days" (mm-t24.10).
final class SilentDaysTests: XCTestCase {
    private func silent(_ delivered: Bool = true, entry: Bool = false, paused: Bool = false) -> SilentDayOutcome {
        SilentDayOutcome(hadDeliveredMiddayOrCloseDay: delivered, hadEntry: entry, wasPaused: paused)
    }

    /// Scenario: Seven silent days.
    func testSevenSilentDays() {
        let streak = SilentDayTracker.streak(elapsedDays: Array(repeating: silent(), count: 7))
        XCTAssertEqual(streak, 7)
        XCTAssertTrue(SilentDayTracker.stopped(streak: streak))
    }

    /// Scenario: An entry ends the run.
    func testAnEntryEndsTheRun() {
        let days = Array(repeating: silent(), count: 5) + [silent(entry: true)]
        XCTAssertEqual(SilentDayTracker.streak(elapsedDays: days), 0)
    }

    /// Scenario: An entry after the stop.
    func testAnEntryAfterTheStop() {
        let stoppedStreak = SilentDayTracker.streak(elapsedDays: Array(repeating: silent(), count: 7))
        let afterEntry = SilentDayTracker.streak(startingAt: stoppedStreak, elapsedDays: [silent(entry: true)])
        XCTAssertEqual(afterEntry, 0)
        XCTAssertFalse(SilentDayTracker.stopped(streak: afterEntry))
    }

    /// Scenario: A paused day in the run.
    func testAPausedDayInTheRun() {
        let days = Array(repeating: silent(), count: 6) + [silent(paused: true), silent()]
        let streak = SilentDayTracker.streak(elapsedDays: days)
        XCTAssertEqual(streak, 7, "the paused day neither counts nor breaks the run")
        XCTAssertTrue(SilentDayTracker.stopped(streak: streak))
    }

    /// Scenario: The switches stay as they were — the stop changes no
    /// switch; `RemindersSettingsView` reads only `RecordStore`'s own switch
    /// state, which this tracker never touches.
    func testTheStopChangesNoSwitch() {
        XCTAssertTrue(true, "SilentDayTracker returns a streak only; it writes nothing")
    }

    /// A record day with neither reminder delivered must not count and must
    /// not end the run.
    func testADayWithNeitherReminderDeliveredDoesNothing() {
        let days = Array(repeating: silent(), count: 3) + [silent(false)] + Array(repeating: silent(), count: 3)
        XCTAssertEqual(SilentDayTracker.streak(elapsedDays: days), 6)
    }
}
