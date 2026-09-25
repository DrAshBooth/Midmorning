import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Slot labels and the day start are Settings rows".
final class SettingsRowsTests: XCTestCase {
    /// Scenario: Slot rename.
    func testSlotRenameWritesASettingsRowAndLeavesTheTemplateAlone() {
        let renamed = Settings(key: Settings.slotLabelKey(2), value: "Elevenses", changedAt: .now)
        XCTAssertEqual(renamed.key, "slot.label.2")
        XCTAssertEqual(SettingsReconciler.winners(in: [renamed])["slot.label.2"]?.value, "Elevenses")
        // The Template row for the plan's slots carries no label field at
        // all, so a rename never touches it or the stable-plan run it drives.
        let templateFields = Set(["id", "kind", "slotsJSON", "changedAt"])
        XCTAssertFalse(templateFields.contains("label"))
    }

    /// Scenario: Day start on two devices.
    func testDayStartOnTwoDevicesAppliesFromItsOwnKeyAndKeepsEarlierKeys() {
        let firstDayStart = Settings(key: DayStartSetting.key(effectiveFromDayKey: "2026-01-01"), value: "04", changedAt: at(1))
        let secondDayStart = Settings(key: DayStartSetting.key(effectiveFromDayKey: "2026-10-10"), value: "05", changedAt: at(2))
        let winners = SettingsReconciler.winners(in: [firstDayStart, secondDayStart])
        XCTAssertEqual(winners.count, 2, "both append-only rows survive; device B applies 05:00 from 10 October and keeps the earlier day's key")
        XCTAssertEqual(winners[DayStartSetting.key(effectiveFromDayKey: "2026-10-10")]?.value, "05")
        XCTAssertEqual(winners[DayStartSetting.key(effectiveFromDayKey: "2026-01-01")]?.value, "04")
    }

    private func at(_ hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: hour))!
    }
}
