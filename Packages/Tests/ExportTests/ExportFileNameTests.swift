import XCTest
@testable import Export

/// export spec, "What the PDF never contains": "File name", "Metadata".
final class ExportFileNameTests: XCTestCase {
    /// Scenario: File name.
    func testFileName() {
        XCTAssertEqual(ExportFileName.name(fromDayKey: "2026-08-28", toDayKey: "2026-09-24"), "Record 2026-08-28 to 2026-09-24.pdf")
    }

    func testFileNameHasNoProductNameOrPersonName() {
        let name = ExportFileName.name(fromDayKey: "2026-08-28", toDayKey: "2026-09-24")
        XCTAssertFalse(name.contains("Midmorning"))
    }

    /// Scenario: Metadata.
    func testPDFTitle() {
        let document = ExportDocument(
            rangeText: "28 August\u{2009}–\u{2009}24 September 2026",
            dayRunLine: "A day runs from 04:00 to 03:59.",
            includeContext: true,
            days: [],
            weighInLines: []
        )
        XCTAssertEqual(document.pdfTitle, "Record 28 August\u{2009}–\u{2009}24 September 2026")
    }
}
