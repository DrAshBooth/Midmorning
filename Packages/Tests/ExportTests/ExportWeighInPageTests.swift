import XCTest
@testable import Export

/// export spec, "The optional weigh-in page". Unit conversion is
/// `weigh-in`'s own rule (`Programme.WeighInWeight`); this package only
/// arranges the already-formatted rows the app hands it.
final class ExportWeighInPageTests: XCTestCase {
    /// Scenario: Weigh-ins included.
    func testWeighInsIncludedListsEveryRowAndNothingElse() {
        let lines = [
            ExportWeighInLine(dateText: "Monday 7 September 2026", valueText: "66.8 kg"),
            ExportWeighInLine(dateText: "Monday 14 September 2026", valueText: "66.2 kg")
        ]
        let document = ExportDocument(rangeText: "7 September\u{2009}–\u{2009}14 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [], weighInLines: lines)
        let content = document.contentLines()
        XCTAssertEqual(content.filter { $0.kind == .weighInHeading }.count, 1)
        let rows = content.filter { $0.kind == .weighInRow }
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].weighIn?.dateText, "Monday 7 September 2026")
        XCTAssertEqual(rows[0].weighIn?.valueText, "66.8 kg")
    }

    /// Scenario: Weigh-ins not included / No weigh-in in the range: an empty
    /// list omits the whole page.
    func testNoWeighInLinesOmitsThePage() {
        let document = ExportDocument(rangeText: "24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [], weighInLines: [])
        XCTAssertTrue(document.contentLines().filter { $0.kind == .weighInHeading }.isEmpty)
    }

    func testTheWeighInPageHeading() {
        XCTAssertEqual(ExportContent.weighInsPageHeading, "Weigh-ins")
    }
}
