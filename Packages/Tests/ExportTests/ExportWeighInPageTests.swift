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

    /// Scenario: Weigh-ins included, through the paginator (mm-t42.22). One
    /// day of two entries and the page would all fit on one page, but the
    /// weigh-ins still start their own last page, and that page holds the
    /// heading and the rows and nothing else.
    func testTheWeighInsAreTheirOwnLastPageAndNothingElse() {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Toast and tea", whereText: "Home", context: "")
        let day = ExportDayBlock(dayKey: "2026-09-14", heading: "Monday 14 September 2026", didntRecord: false, paused: false, entries: [entry, entry])
        let lines = [
            ExportWeighInLine(dateText: "Monday 7 September 2026", valueText: "66.8 kg"),
            ExportWeighInLine(dateText: "Monday 14 September 2026", valueText: "66.2 kg")
        ]
        let document = ExportDocument(rangeText: "7 September\u{2009}–\u{2009}14 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: lines)

        let pages = Paginator.paginate(document: document, pageHeight: 1000) { _ in 20 }

        XCTAssertEqual(pages.count, 2)
        XCTAssertFalse(pages[0].lines.contains { $0.kind == .weighInHeading || $0.kind == .weighInRow }, "no weight value prints under the record")
        XCTAssertEqual(pages[1].lines.map(\.kind), [.weighInHeading, .weighInRow, .weighInRow])
        XCTAssertEqual(pages[1].lines.first?.text, "Weigh-ins")
        XCTAssertEqual(pages[1].lines.compactMap(\.weighIn), lines)
    }

    /// A weigh-in list longer than a page continues on the next page under
    /// a repeated "Weigh-ins" heading, so the last page still reads
    /// "Weigh-ins" and holds only weigh-in rows.
    func testALongWeighInListRepeatsItsHeadingOnTheLastPage() {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Toast", whereText: "", context: "")
        let day = ExportDayBlock(dayKey: "2026-09-14", heading: "Monday 14 September 2026", didntRecord: false, paused: false, entries: [entry])
        let lines = (1...30).map { ExportWeighInLine(dateText: "Week \($0)", valueText: "66.0 kg") }
        let document = ExportDocument(rangeText: "14 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: lines)

        let pages = Paginator.paginate(document: document, pageHeight: 400) { _ in 20 }

        let weighInPages = pages.filter { $0.lines.contains { $0.kind == .weighInRow } }
        XCTAssertEqual(weighInPages.count, 2)
        for page in weighInPages {
            XCTAssertEqual(page.lines.first?.kind, .weighInHeading)
            XCTAssertTrue(page.lines.dropFirst().allSatisfy { $0.kind == .weighInRow }, "a weigh-in page holds nothing else")
        }
        XCTAssertEqual(weighInPages[0].lines.first?.isContinuation, false)
        XCTAssertEqual(weighInPages[1].lines.first?.isContinuation, true)
        XCTAssertEqual(weighInPages.flatMap(\.lines).filter { $0.kind == .weighInRow }.count, 30)
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
