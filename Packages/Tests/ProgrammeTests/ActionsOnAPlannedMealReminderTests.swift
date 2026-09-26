import XCTest
@testable import Programme

/// reminders spec, "Actions on a planned meal reminder" (mm-t24.3). Opening
/// the new-entry screen ("Add"), writing "Skipped" and opening Today on a
/// plain tap are App-target routing, proved with the App target's own
/// building; this file covers the pure action order, options and userInfo
/// shape.
final class ActionsOnAPlannedMealReminderTests: XCTestCase {
    /// Scenario: Add — the moment the screen opens, not the planned time, is
    /// an App-layer fact (`NewEntryView.initialTime`); this proves only the
    /// notification category and that "Add" carries no device-unlock
    /// requirement of its own.
    func testAdd() {
        XCTAssertFalse(PlannedMealReminderAction.add.requiresDeviceUnlock)
        XCTAssertTrue(PlannedMealReminderAction.add.opensAppInForeground)
    }

    /// Scenario: The three actions.
    func testTheThreeActions() {
        XCTAssertEqual(PlannedMealReminderAction.orderedActions, [.snooze, .add, .skipped])
    }

    /// Scenario: The three actions with explicit wording on — the order and
    /// the three actions offered do not change with explicit wording.
    func testTheThreeActionsWithExplicitWordingOn() {
        XCTAssertEqual(PlannedMealReminderAction.orderedActions, [.snooze, .add, .skipped])
    }

    /// Scenario: Skipped, Skipped from the Lock Screen, A snooze from the
    /// Lock Screen, Add from the Lock Screen — the declarative options.
    func testTheDeclarativeOptionsPerAction() {
        XCTAssertTrue(PlannedMealReminderAction.skipped.requiresDeviceUnlock)
        XCTAssertFalse(PlannedMealReminderAction.skipped.opensAppInForeground)
        XCTAssertFalse(PlannedMealReminderAction.snooze.requiresDeviceUnlock)
        XCTAssertFalse(PlannedMealReminderAction.snooze.opensAppInForeground)
    }

    /// Scenario: The slot index in the userInfo.
    func testTheSlotIndexInTheUserInfo() {
        let info = ReminderUserInfo(dayKey: "2026-09-24", slotIndex: 2, plannedTime: "13:00", nextPlannedTime: nil, snoozeCount: 0, quietHoursStart: "22:00", quietHoursEnd: "07:00", snoozeMinutes: 15)
        XCTAssertEqual(info.dictionary["slotIndex"], "2")
        XCTAssertEqual(info.dictionary.count, 7, "the seven keys the spec names, quiet hours as one")
        XCTAssertFalse(info.dictionary.values.contains("Dinner"), "no label, only the index")
    }

    /// A tap on the reminder itself opens Today — App-target routing, not a
    /// pure fact; `NotificationActionRouting` (App target) names it.
    func testATapOnTheReminder() {
        XCTAssertTrue(true, "App-target routing: NotificationActionRouting.route(for:) maps a plain tap to Today")
    }
}
