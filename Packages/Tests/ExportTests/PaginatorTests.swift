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
