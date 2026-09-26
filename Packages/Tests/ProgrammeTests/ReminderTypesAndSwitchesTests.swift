import XCTest
@testable import Programme

/// reminders spec, "Reminder types and their switches" (mm-t24.1). The
/// switch storage and the Reminders group UI are `RecordStore` and
/// `RemindersSettingsView` (already built by `settings`, mm-t13); this file
/// covers the pure permission-state text and the switch-off scheduling rule.
final class ReminderTypesAndSwitchesTests: XCTestCase {
    /// Scenario: Turn off planned meal reminders.
    func testTurnOffPlannedMealReminders() {
        let lunch = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 2, time: "13:00")
        let closeTheDay = ReminderCandidate(kind: .closeTheDay, dayKey: "2026-09-24", time: "21:45")
        let result = Scheduler.pipeline([lunch, closeTheDay], switches: [.plannedMeal: false], remindersPausedAt: nil, quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.map(\.kind), [.closeTheDay])
    }

    /// Scenario: Permission not determined.
    func testPermissionNotDetermined() {
        XCTAssertEqual(ReminderPermissionText.todayLine(permission: .notDetermined, hasTappedDeniedLineOnce: false), ReminderPermissionText.todayLineBeforePermission)
        XCTAssertEqual(ReminderPermissionText.groupNotDeterminedLine.english, "Reminders need notification permission.")
        XCTAssertEqual(ReminderPermissionText.groupAllowControl.english, "Allow notifications")
    }

    /// Scenario: The line before permission.
    func testTheLineBeforePermission() {
        XCTAssertEqual(ReminderPermissionText.todayLine(permission: .notDetermined, hasTappedDeniedLineOnce: false)?.english, "Allow notifications to get reminders.")
    }

    /// Scenario: Permission granted from the line.
    func testPermissionGrantedFromTheLine() {
        XCTAssertNil(ReminderPermissionText.todayLine(permission: .granted, hasTappedDeniedLineOnce: false))
    }

    /// Scenario: Permission denied.
    func testPermissionDenied() {
        XCTAssertEqual(ReminderPermissionText.groupDeniedLine.english, "Notifications are off in iOS Settings. The plan still shows on Today, and the Home Screen widget can show your next planned time.")
    }

    /// Scenario: The line on Today.
    func testTheLineOnToday() {
        XCTAssertEqual(ReminderPermissionText.todayLine(permission: .denied, hasTappedDeniedLineOnce: false)?.english, "Notifications are off in iOS Settings.")
    }

    /// Scenario: The line after one tap.
    func testTheLineAfterOneTap() {
        XCTAssertNil(ReminderPermissionText.todayLine(permission: .denied, hasTappedDeniedLineOnce: true))
    }

    /// Scenario: Turn a type back on.
    func testTurnATypeBackOn() {
        let lunch = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 2, time: "13:00")
        let result = Scheduler.pipeline([lunch], switches: [.plannedMeal: true], remindersPausedAt: nil, quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.map(\.kind), [.plannedMeal])
    }

    /// Scenario: Two devices — the switch is a `Local.store` device row that
    /// never syncs; `RecordStore.setReminderSwitch` already keys it into
    /// `LocalSetting` (device-only). The fixed caption text:
    func testTwoDevices() {
        XCTAssertEqual(ReminderPermissionText.eachDeviceSendsItsOwn.english, "Each device sends its own reminders.")
    }
}
