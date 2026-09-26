import XCTest
import Constants
@testable import Programme

/// widgets-and-intents spec, "Notification actions are entry points"
/// (mm-t25.8). Opening the new-entry screen for "Add" is
/// `NotificationActionHandling` (App target), proved by the epic's device
/// checks; this file covers the pure action shape "Add" shares with
/// `app-lock`'s own locked-device scenarios.
final class NotificationActionsAreEntryPointsTests: XCTestCase {
    /// Scenario: Add.
    func testAdd() {
        XCTAssertTrue(PlannedMealReminderAction.add.opensAppInForeground)
    }

    /// Scenario: Actions in order.
    func testActionsInOrder() {
        XCTAssertEqual(PlannedMealReminderAction.orderedActions, [.snooze, .add, .skipped])
    }

    /// Scenario: Skipped.
    func testSkipped() {
        XCTAssertFalse(PlannedMealReminderAction.skipped.opensAppInForeground, "the app does not open")
    }

    /// Scenario: Skipped on the locked device.
    func testSkippedOnTheLockedDevice() {
        XCTAssertTrue(PlannedMealReminderAction.skipped.requiresDeviceUnlock)
    }

    /// Scenario: Snooze.
    func testSnooze() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 13, minute: 5))!
        let info = ReminderUserInfo(dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", nextPlannedTime: nil, snoozeCount: 0, quietHoursStart: "22:00", quietHoursEnd: "07:00", snoozeMinutes: 15)
        guard case .scheduleAt(let when) = SnoozeDecision.decide(userInfo: info, now: now, calendar: calendar) else { return XCTFail() }
        XCTAssertEqual(ReminderClock.string(from: when, calendar: calendar), "13:20")
        XCTAssertFalse(PlannedMealReminderAction.snooze.opensAppInForeground)
        XCTAssertFalse(PlannedMealReminderAction.snooze.requiresDeviceUnlock)
    }

    /// Scenario: userInfo content.
    func testUserInfoContent() {
        let info = ReminderUserInfo(dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", nextPlannedTime: "16:00", snoozeCount: 0, quietHoursStart: "22:00", quietHoursEnd: "07:00", snoozeMinutes: 15)
        XCTAssertEqual(info.dictionary.count, 7)
        XCTAssertNil(info.dictionary["slotLabel"])
        XCTAssertEqual(Set(info.dictionary.keys), ["dayKey", "slotIndex", "plannedTime", "nextPlannedTime", "snoozeCount", "quietHours", "snoozeMinutes"])
    }
}
