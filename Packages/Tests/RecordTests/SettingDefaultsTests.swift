import Foundation
import XCTest
import Constants
import Plan
@testable import Record

/// mm-t12b.20: the store's getters give the one set of defaults
/// (`RecordStore.Defaults`), the Bool settings read and write through one
/// helper, and the typed values replace the repeated literals.
@MainActor
final class SettingDefaultsTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingDefaultsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    /// A fresh store gives the settings spec's defaults, from one place.
    func testAFreshStoreGivesTheDefaults() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.gapBandsOn(), RecordStore.Defaults.gapBandsOn)
        XCTAssertEqual(try store.weeklySummaryOn(), RecordStore.Defaults.weeklySummaryOn)
        XCTAssertEqual(try store.explicitWordingOn(), RecordStore.Defaults.explicitWordingOn)
        XCTAssertEqual(try store.remindAgainMinutes(), RecordStore.Defaults.remindAgainMinutes)
        XCTAssertEqual(try store.weighInUnit(), RecordStore.Defaults.weighInUnit)
        XCTAssertEqual(try store.quietHours(), RecordStore.Defaults.quietHours)
        for kind in RecordStore.ReminderSwitch.allCases {
            XCTAssertEqual(try store.reminderSwitchOn(kind), RecordStore.Defaults.reminderSwitchOn)
        }
        XCTAssertFalse(try store.onboardingCompleted())
        XCTAssertFalse(try store.syncOn())
        XCTAssertFalse(try store.hasTappedNotificationsDeniedLineOnce())
    }

    /// The settings spec's own values: 22:00 to 07:00 and on, 15 minutes,
    /// "kg", every reminder switch on, explicit wording off.
    func testTheDefaultsAreTheSpecValues() {
        XCTAssertEqual(RecordStore.Defaults.quietHours, QuietHours(isOn: true, start: "22:00", end: "07:00"))
        XCTAssertEqual(RecordStore.Defaults.remindAgainMinutes, 15)
        XCTAssertEqual(RecordStore.Defaults.weighInUnit, "kg")
        XCTAssertTrue(RecordStore.Defaults.reminderSwitchOn)
        XCTAssertFalse(RecordStore.Defaults.explicitWordingOn)
        XCTAssertTrue(RecordStore.Defaults.gapBandsOn)
        XCTAssertTrue(RecordStore.Defaults.weeklySummaryOn)
    }

    /// Each Bool setting writes and reads back through the one helper.
    func testBoolSettingsRoundTrip() throws {
        let store = try makeStore()
        try store.setGapBandsOn(false)
        try store.setQuietHoursOn(false)
        try store.setReminderSwitch(false, .midday)
        try store.setExplicitWordingOn(true)
        try store.setSyncOn(true)
        XCTAssertFalse(try store.gapBandsOn())
        XCTAssertFalse(try store.quietHours().isOn)
        XCTAssertFalse(try store.reminderSwitchOn(.midday))
        XCTAssertTrue(try store.reminderSwitchOn(.closeTheDay))
        XCTAssertTrue(try store.explicitWordingOn())
        XCTAssertTrue(try store.syncOn())
    }

    /// The quiet hours value carries the switch, so a time in the range is
    /// not in quiet hours while the switch is off.
    func testQuietHoursValueFollowsTheSwitch() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.quietHours().contains("23:00"))
        try store.setQuietHoursOn(false)
        XCTAssertFalse(try store.quietHours().contains("23:00"))
    }

    func testWeighInDayChoiceWeekday() throws {
        let store = try makeStore()
        XCTAssertNil(try store.weighInDayChoice()?.weekday)
        try store.setWeighInDayChoice(.weekday(2))
        XCTAssertEqual(try store.weighInDayChoice()?.weekday, 2)
        try store.setWeighInDayChoice(.wontBeWeighing)
        XCTAssertNil(try store.weighInDayChoice()?.weekday)
    }

    /// "Skipped" from Today, an earlier day or a reminder action is one
    /// stored value.
    func testSkippedIsOneStoredValue() throws {
        let store = try makeStore()
        try store.setPlannedMealSkipped(dateKey: "2026-10-06", slotIndex: 2, changedAt: Date())
        XCTAssertEqual(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2), PlannedMealAnswer.skipped)
    }

    /// Today's bottom toolbar is a typed list, not English text.
    func testBottomToolbarIsTyped() {
        XCTAssertEqual(BottomToolbar.items(reviewsDue: true), [.programme, .reviews, .settings])
    }
}
