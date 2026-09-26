import Foundation
import XCTest
@testable import Export

/// export spec, "The document and the paginator live in a package".
final class PaginatorTests: XCTestCase {
    /// Scenario: Pagination with a stub measurer.
    func testALongDaySplitsAcrossPagesAndRepeatsItsHeadingOnTheContinuation() {
        let entries = (1...40).map { i in
            ExportEntryLine(clockTime: String(format: "%02d:00", i % 24), starred: false, what: "Entry \(i)", whereText: "", context: "")
        }
        let day = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: entries)
        let document = ExportDocument(rangeText: "24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: [])

        let pages = Paginator.paginate(document: document, pageHeight: 400) { _ in 20 }

        XCTAssertGreaterThan(pages.count, 1, "forty entries plus the front matter must not fit on one 400pt page of 20pt lines")
        for page in pages.dropFirst() {
            guard let firstDayLine = page.lines.first(where: { $0.dayIndex == 0 }) else { continue }
            XCTAssertTrue(firstDayLine.isDayHeading, "a page that continues day 0 must start with its heading")
            XCTAssertEqual(firstDayLine.text, "Thursday 24 September 2026")
        }
    }

    func testAShortDocumentFitsOnOnePage() {
        let day = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: [])
        let document = ExportDocument(rangeText: "24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: [])
        let pages = Paginator.paginate(document: document, pageHeight: 1000) { _ in 20 }
        XCTAssertEqual(pages.count, 1)
    }

    /// Scenario: Days flow on one page.
    func testThreeDaysWithTwoEntriesEachFlowOnOnePage() {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Entry", whereText: "", context: "")
        let days = (21...23).map { day in
            ExportDayBlock(dayKey: "2026-09-\(day)", heading: "Day \(day)", didntRecord: false, paused: false, entries: [entry, entry])
        }
        let document = ExportDocument(rangeText: "21 September\u{2009}–\u{2009}23 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: days, weighInLines: [])
        let pages = Paginator.paginate(document: document, pageHeight: 1000) { _ in 20 }
        XCTAssertEqual(pages.count, 1, "three short days must flow onto the same page, one after another")
        XCTAssertEqual(pages[0].lines.filter(\.isDayHeading).count, 3)
    }

    /// mm-t42.25: a day heading never ends a page. Day 0 fills the first
    /// page to 20 points short of its foot, so day 1's heading alone would
    /// fit there, but not with its column headings and its first entry.
    func testADayHeadingNeverEndsAPageAndPrintsOnceWhenItsDayStartsAPage() {
        let pages = Paginator.paginate(document: twoDayDocument(firstDayEntries: 12), pageHeight: 400) { _ in 20 }

        XCTAssertEqual(pages.count, 2)
        for page in pages {
            XCTAssertFalse(page.lines.last?.keepsWithNext ?? false, "no page ends with a heading, a state line or the column headings")
        }
        let day1Headings = pages.flatMap(\.lines).filter { $0.kind == .dayHeading(dayIndex: 1) }
        XCTAssertEqual(day1Headings.count, 1, "day 1 starts page 2, so its heading prints once, not also as a bare line at the foot of page 1")
        XCTAssertEqual(pages[1].lines.first?.kind, .dayHeading(dayIndex: 1))
        XCTAssertEqual(pages[1].lines.first?.isContinuation, false)
    }

    /// mm-t42.25: a state line stays with its heading and the first entry.
    func testAStateLineAndTheColumnHeadingsStayWithTheirHeadingAndTheFirstEntry() {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Entry", whereText: "", context: "")
        let day0 = ExportDayBlock(dayKey: "2026-09-23", heading: "Wednesday 23 September 2026", didntRecord: false, paused: false, entries: Array(repeating: entry, count: 11))
        let day1 = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: true, entries: [entry, entry])
        let document = ExportDocument(rangeText: "23 September\u{2009}–\u{2009}24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day0, day1], weighInLines: [])

        // Front matter 100 + day 0 (heading, column headings, 11 entries) 260 = 360: day 1's heading and
        // "Paused" (40) fit exactly, but its column headings and first entry do not.
        let pages = Paginator.paginate(document: document, pageHeight: 400) { _ in 20 }

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[1].lines.prefix(4).map(\.kind), [.dayHeading(dayIndex: 1), .stateLine(dayIndex: 1), .columnHeadings(dayIndex: 1), .entryLine(dayIndex: 1)])
        XCTAssertFalse(pages[0].lines.contains { $0.dayIndex == 1 })
    }

    /// mm-t42.25: a day with no entries and no state is its heading only,
    /// so the heading may end a page: the whole day is on that page.
    func testAnEmptyDayMayEndAPage() {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Entry", whereText: "", context: "")
        let day0 = ExportDayBlock(dayKey: "2026-09-22", heading: "Tuesday 22 September 2026", didntRecord: false, paused: false, entries: Array(repeating: entry, count: 12))
        let empty = ExportDayBlock(dayKey: "2026-09-23", heading: "Wednesday 23 September 2026", didntRecord: false, paused: false, entries: [])
        let day2 = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: [entry])
        let document = ExportDocument(rangeText: "22 September\u{2009}–\u{2009}24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day0, empty, day2], weighInLines: [])

        let pages = Paginator.paginate(document: document, pageHeight: 400) { _ in 20 }

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[0].lines.last?.kind, .dayHeading(dayIndex: 1))
        XCTAssertEqual(pages[1].lines.first?.kind, .dayHeading(dayIndex: 2), "the next day starts page 2; the empty day's heading does not repeat")
    }

    /// mm-t42.26: the heading that a continuation page repeats is marked, so
    /// the renderer can draw it without a second H2 tag. Every day keeps
    /// exactly one unmarked heading.
    func testTheRepeatedHeadingIsMarkedAsAContinuation() {
        let entries = (1...40).map { i in
            ExportEntryLine(clockTime: String(format: "%02d:00", i % 24), starred: false, what: "Entry \(i)", whereText: "", context: "")
        }
        let day = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: entries)
        let document = ExportDocument(rangeText: "24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: [])

        let pages = Paginator.paginate(document: document, pageHeight: 400) { _ in 20 }

        let headings = pages.flatMap(\.lines).filter(\.isDayHeading)
        XCTAssertEqual(headings.filter { !$0.isContinuation }.count, 1, "one H2 for the day")
        XCTAssertEqual(headings.filter(\.isContinuation).count, pages.count - 1, "each later page repeats the heading once")
        for page in pages.dropFirst() {
            XCTAssertEqual(page.lines.first?.isContinuation, true)
        }
        XCTAssertEqual(pages.flatMap(\.lines).filter { $0.kind == .entryLine(dayIndex: 0) }.count, 40, "no entry is lost or doubled")
    }

    private func twoDayDocument(firstDayEntries: Int) -> ExportDocument {
        let entry = ExportEntryLine(clockTime: "08:00", starred: false, what: "Entry", whereText: "", context: "")
        let day0 = ExportDayBlock(dayKey: "2026-09-23", heading: "Wednesday 23 September 2026", didntRecord: false, paused: false, entries: Array(repeating: entry, count: firstDayEntries))
        let day1 = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: [entry, entry])
        return ExportDocument(rangeText: "23 September\u{2009}–\u{2009}24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day0, day1], weighInLines: [])
    }

    /// Scenario: No UIKit in the package. A source-level check (macOS has no
    /// UIKit at all, so this is also enforced simply by `swift test`
    /// compiling this target on macOS in the first place).
    func testThePackageSourceImportsNoUIKit() throws {
        let thisFile = URL(fileURLWithPath: #filePath)
        let packagesRoot = thisFile
            .deletingLastPathComponent() // ExportTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Packages
        let sourcesDirectory = packagesRoot.appendingPathComponent("Sources/Export")
        let files = try FileManager.default.contentsOfDirectory(at: sourcesDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        XCTAssertFalse(files.isEmpty, "expected to find the Export target's own source files at \(sourcesDirectory.path)")
        for file in files {
            let contents = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(contents.contains("import UIKit"), "\(file.lastPathComponent) must not import UIKit")
        }
    }
}
