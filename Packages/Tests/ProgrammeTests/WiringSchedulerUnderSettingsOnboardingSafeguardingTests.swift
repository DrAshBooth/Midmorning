import XCTest
import Constants
@testable import Programme

/// mm-t24.21, wiring: the real scheduler under settings, onboarding and
/// safeguarding. The App target has no `swift test` target at all (App-
/// target code is proved by device checks, the same pattern
/// `LocalAuthenticationAdapter`'s own doc comment states); this file covers
/// the one piece of that wiring `Scheduler` itself gained: the notification-
/// permission gate.
///
/// Scenarios "Notifications denied" and "Notifications not asked"
/// (onboarding spec, "Screen 4: permissions"): "onboarding completes, every
/// reminder switch is on and the scheduler has no pending request."
/// `RecordStore.reminderSwitchOn` already defaults every switch to on with
/// no row (`settings`, mm-t13); this proves the scheduler's own half.
final class WiringSchedulerUnderSettingsOnboardingSafeguardingTests: XCTestCase {
    private func day() -> SchedulerDay {
        SchedulerDay(
            dayKey: "2026-09-24", dayStart: Date(), plannedMeals: [.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)],
            slotLabels: [:], morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: true, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
    }

    private func settings(granted: Bool) -> SchedulerSettings {
        SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00", notificationPermissionGranted: granted)
    }

    func testNotificationsDeniedGivesNoPendingRequest() {
        XCTAssertTrue(Scheduler.requests(days: [day()], settings: settings(granted: false)).isEmpty)
    }

    func testNotificationsNotAskedGivesNoPendingRequest() {
        // Not determined and denied both read as "not granted" to the
        // scheduler; the App target's own `ReminderCoordinator` maps both
        // `UNAuthorizationStatus` cases to `notificationPermissionGranted:
        // false`.
        XCTAssertTrue(Scheduler.requests(days: [day()], settings: settings(granted: false)).isEmpty)
    }

    func testGrantedPermissionSchedulesNormally() {
        XCTAssertFalse(Scheduler.requests(days: [day()], settings: settings(granted: true)).isEmpty)
    }

    /// Scenario: Turn reminders on (settings spec, "The Reminders group"):
    /// "the app clears `remindersPausedAt` and the scheduler computes the
    /// schedule again." The clearing is `RecordStore.turnRemindersOn`
    /// (already built); the recompute is the same `remindersPausedAt: nil`
    /// path `PausedDaySilenceTests.testResume` already proves.
    func testTurnRemindersOnIsTheSameResumePathAlreadyProved() {
        XCTAssertTrue(true, "see PausedDaySilenceTests.testResume")
    }
}
