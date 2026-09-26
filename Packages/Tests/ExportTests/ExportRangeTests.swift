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
        XCTAssertEqual(ExportContent.includeWeighInsLabel.english, "Include weigh-ins")
        XCTAssertEqual(ExportContent.includeContextLabel.english, "Include context")
    }

    /// Requirement: "Choose a date range": the screen's title "Export", the
    /// "From" and "To" controls and "Make PDF", from the app's catalogue.
    func testTheScreenLabels() {
        XCTAssertEqual(ExportContent.screenTitle.english, "Export")
        XCTAssertEqual(ExportContent.fromLabel.english, "From")
        XCTAssertEqual(ExportContent.toLabel.english, "To")
        XCTAssertEqual(ExportContent.makePDFLabel.english, "Make PDF")
    }

    /// Scenario: The line above "Make PDF".
    func testTheDisclosureLine() {
        XCTAssertEqual(
            ExportContent.shareDisclosureLine.english,
            "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies."
        )
    }

    /// export spec, "Offline and out of logs", Scenario: Build error. The
    /// message itself carries no entry field or weight value; the app
    /// target's catch site (untestable by `swift test`) always shows this
    /// fixed string, never the underlying error's own description.
    func testTheBuildErrorMessage() {
        XCTAssertEqual(ExportContent.buildErrorMessage.english, "The PDF could not be made. Try again.")
    }
}
