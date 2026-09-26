import XCTest
@testable import Export

/// export spec, "Choose a date range".
final class ExportRangeTests: XCTestCase {
    /// Scenario: Default range.
    func testDefaultRangeIsTwentySevenDaysBack() {
        let range = ExportRange.defaultRange(currentDayKey: "2026-09-24", earliestEntryDayKey: "2026-08-01")
        XCTAssertEqual(range.from, "2026-08-28")
        XCTAssertEqual(range.to, "2026-09-24")
    }

    /// Scenario: Short record.
    func testDefaultRangeStartsAtTheEarliestEntryWhenLater() {
        let range = ExportRange.defaultRange(currentDayKey: "2026-09-24", earliestEntryDayKey: "2026-09-20")
        XCTAssertEqual(range.from, "2026-09-20")
        XCTAssertEqual(range.to, "2026-09-24")
    }

    func testDefaultRangeWithNoEntriesAtAllUsesTwentySevenDaysBack() {
        let range = ExportRange.defaultRange(currentDayKey: "2026-09-24", earliestEntryDayKey: nil)
        XCTAssertEqual(range.from, "2026-08-28")
    }

    /// Scenario: To before From.
    func testFromIsNotAllowedAfterTo() {
        XCTAssertFalse(ExportRange.isFromAllowed(candidateFromDayKey: "2026-09-22", toDayKey: "2026-09-21"))
        XCTAssertTrue(ExportRange.isFromAllowed(candidateFromDayKey: "2026-09-21", toDayKey: "2026-09-21"))
    }

    func testToIsNotAllowedAfterTheCurrentRecordDay() {
        XCTAssertFalse(ExportRange.isToAllowed(candidateToDayKey: "2026-09-25", currentDayKey: "2026-09-24"))
        XCTAssertTrue(ExportRange.isToAllowed(candidateToDayKey: "2026-09-24", currentDayKey: "2026-09-24"))
    }

    /// Scenario: The switches when the screen opens.
    func testTheSwitchDefaults() {
        XCTAssertFalse(ExportContent.includeWeighInsDefault)
        XCTAssertTrue(ExportContent.includeContextDefault)
    }

    /// Scenario: The line above "Make PDF".
    func testTheDisclosureLine() {
        XCTAssertEqual(
            ExportContent.shareDisclosureLine,
            "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies."
        )
    }
}
