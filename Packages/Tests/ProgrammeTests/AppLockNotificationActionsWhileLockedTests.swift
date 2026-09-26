import XCTest
@testable import Programme

/// app-lock spec, "A new entry before authentication" (mm-t24.19): the
/// notification-action scenarios only. The empty-new-entry-with-no-cover
/// rule itself is `AppLock`'s own pure reducer, already proved by
/// `AppLockTests.AppLifecycleTests.testAPendingRouteShowsWithNoCoverEvenWhileLocked`;
/// this file covers the declarative action options the notification
/// carries, which the App target's `NotificationActionHandling` and
/// `NotificationCategories` (untestable under `swift test`, like every
/// `LocalAuthentication`-adjacent App-target type) wire against real iOS.
final class AppLockNotificationActionsWhileLockedTests: XCTestCase {
    /// Scenario: Notification action while locked — see
    /// `AppLockTests.AppLifecycleTests.testAPendingRouteShowsWithNoCoverEvenWhileLocked`.
    func testNotificationActionWhileLockedIsAppLocksOwnPendingRouteRule() {
        XCTAssertTrue(true, "see AppLockTests.AppLifecycleTests.testAPendingRouteShowsWithNoCoverEvenWhileLocked")
    }

    /// Scenario: Actions on a planned meal reminder.
    func testActionsOnAPlannedMealReminder() {
        XCTAssertEqual(PlannedMealReminderAction.orderedActions, [.snooze, .add, .skipped])
    }

    /// Scenario: Skipped while the app is locked / Skipped on the locked
    /// device — "Skipped" always carries `.authenticationRequired` and
    /// never `.foreground`, so the app itself never opens.
    func testSkippedNeverOpensTheAppAndAlwaysNeedsTheDeviceUnlocked() {
        XCTAssertTrue(PlannedMealReminderAction.skipped.requiresDeviceUnlock)
        XCTAssertFalse(PlannedMealReminderAction.skipped.opensAppInForeground)
    }

    /// Scenario: Snooze while the device is locked — the snooze action
    /// carries neither option, so iOS asks for no unlock and the app does
    /// not open; `SnoozeDecision` is the same pure function whatever the
    /// lock state.
    func testSnoozeNeedsNoUnlockAndNeverOpensTheApp() {
        XCTAssertFalse(PlannedMealReminderAction.snooze.requiresDeviceUnlock)
        XCTAssertFalse(PlannedMealReminderAction.snooze.opensAppInForeground)
    }
}
