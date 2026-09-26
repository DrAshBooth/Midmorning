import Foundation
import XCTest
@testable import Export
@testable import Record
@testable import Programme

/// export spec, "The optional weigh-in page"; weigh-in spec, "The weigh-in
/// page in an export"; settings spec, "The Weigh-in group" (`mm-t42.5`,
/// `mm-t22.13`, `mm-t42.12`).
final class ExportWeighInPageBuilderTests: XCTestCase {
    private func row(_ dayKey: String, _ kg: Double) -> RecordStore.WeighInRow {
        RecordStore.WeighInRow(dateKey: dayKey, weightKg: kg, unit: "kg", savedAt: .now, changedAt: .now)
    }

    /// Scenario: Weigh-ins included (weigh-in spec).
    func testWeighInsIncludedListsFiveRowsInKg() {
        let rows = [
            row("2026-09-28", 68.0), row("2026-10-05", 67.5), row("2026-10-12", 67.0),
            row("2026-10-19", 66.8), row("2026-10-26", 66.4)
        ]
        let lines = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-28", toDayKey: "2026-10-26", unit: .kg)
        XCTAssertEqual(lines.count, 5)
        XCTAssertEqual(lines[0].dateText, "Monday 28 September 2026")
        XCTAssertEqual(lines[0].valueText, "68.0 kg")
    }

    /// Scenario: Weigh-ins in stone and pounds (export spec).
    func testWeighInsInStoneAndPounds() {
        let rows = [row("2026-09-07", 66.40)]
        let lines = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-07", toDayKey: "2026-09-07", unit: .stLb)
        XCTAssertEqual(lines[0].dateText, "Monday 7 September 2026")
        XCTAssertEqual(lines[0].valueText, "10 st 6 lb")
    }

    /// Scenario: Weigh-ins after an opt-out — decision 103: the export
    /// still lists every kept weigh-in even though no weigh-in day exists;
    /// the builder never reads the weigh-in day at all, so an opt-out
    /// cannot affect it.
    func testWeighInsAfterAnOptOutStillListsEveryKeptRow() {
        let rows = (0..<5).map { i in row(ExportDayKey.adding(i * 7, to: "2026-09-28"), 68.0 - Double(i) * 0.2) }
        let lines = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-28", toDayKey: "2026-10-26", unit: .kg)
        XCTAssertEqual(lines.count, 5)
    }

    /// Scenario: No weigh-in in the range.
    func testRowsOutsideTheRangeAreExcluded() {
        let rows = [row("2026-08-01", 70.0)]
        let lines = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-01", toDayKey: "2026-09-30", unit: .kg)
        XCTAssertTrue(lines.isEmpty)
    }

    /// settings spec, "The Weigh-in group": "Change the unit" — the export
    /// half. Changing the unit changes only display; the kept kilogram
    /// value is untouched.
    func testChangingTheUnitChangesDisplayOnly() {
        let rows = [row("2026-09-07", 66.40)]
        let kg = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-07", toDayKey: "2026-09-07", unit: .kg)
        let stLb = ExportWeighInPageBuilder.lines(from: rows, fromDayKey: "2026-09-07", toDayKey: "2026-09-07", unit: .stLb)
        XCTAssertEqual(kg[0].valueText, "66.4 kg")
        XCTAssertEqual(stLb[0].valueText, "10 st 6 lb")
    }
}
