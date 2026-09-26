import Foundation
import XCTest
@testable import Export

/// export spec, "Accessibility of the export" (`mm-t42.11`). This bead
/// proves what the screen and PDF beads already built; it adds nothing new
/// (per CLAUDE.md, the P2 accessibility bead proves, it does not add).
final class ExportAccessibilityTests: XCTestCase {
    /// Scenario: The tag tree of a day. `ExportPDFRenderer` opens one
    /// `.list` tag for a day's contiguous run of `.entryLine`s and one
    /// `.listItem` per entry; that only holds if the day's entry lines are
    /// truly contiguous, with nothing else interleaved.
    func testADaysEntryLinesAreContiguousSoOneListTagCoversAllOfThem() {
        let entries = (0..<3).map { i in
            ExportEntryLine(clockTime: String(format: "%02d:00", i), starred: false, what: "Entry \(i)", whereText: "", context: "")
        }
        let day = ExportDayBlock(dayKey: "2026-09-24", heading: "Thursday 24 September 2026", didntRecord: false, paused: false, entries: entries)
        let document = ExportDocument(rangeText: "24 September 2026", dayRunLine: "A day runs from 04:00 to 03:59.", includeContext: true, days: [day], weighInLines: [])
        let kinds = document.contentLines().map(\.kind)
        let entryIndices = kinds.indices.filter {
            if case .entryLine = kinds[$0] { return true } else { return false }
        }
        XCTAssertEqual(entryIndices.count, 3)
        XCTAssertEqual(entryIndices, Array(entryIndices.first!...entryIndices.last!), "the three entry lines must be contiguous, with no other line between them")
    }

    /// Scenario: One pass per entry.
    func testOnePassAccessibilityTextEndsAtWhereWhenContextIsExcluded() {
        let entry = ExportEntryLine(clockTime: "13:05", starred: false, what: "Toast", whereText: "Home", context: "Row with my sister")
        XCTAssertEqual(entry.accessibilityText(includeContext: false), "13:05 Toast Home")
        XCTAssertEqual(entry.accessibilityText(includeContext: true), "13:05 Toast Home Row with my sister")
    }

    /// Scenario: Greyscale. The asterisk is a plain text character, not an
    /// image or a colour-only signal.
    func testTheStarredMarkIsAPlainTextCharacter() {
        XCTAssertEqual(ExportContent.starredMark, "*")
    }

    /// Scenario: The PDF at the largest text size. `ExportPDFRenderer`
    /// (app target, untested directly by `swift test`) must use fixed point
    /// sizes, never a Dynamic-Type-scaling API — a source-level regression
    /// guard, the same technique `PaginatorTests` uses for "no UIKit".
    func testThePDFRendererUsesFixedPointSizesNotDynamicType() throws {
        let thisFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot = thisFile
            .deletingLastPathComponent() // ExportAccessibilityTests.swift
            .deletingLastPathComponent() // ExportTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Packages
        let rendererURL = repositoryRoot
            .appendingPathComponent("App/Midmorning/Export/ExportPDFRenderer.swift")
        let contents = try String(contentsOf: rendererURL, encoding: .utf8)
        XCTAssertFalse(contents.contains("preferredFont"), "the PDF's text must not scale with Dynamic Type")
        XCTAssertTrue(contents.contains("ofSize: 11"), "the body text must be fixed at 11 pt")
        XCTAssertTrue(contents.contains("ofSize: 14"), "a day heading must be fixed at 14 pt")
        XCTAssertTrue(contents.contains("ofSize: 18"), "the title must be fixed at 18 pt")
    }
}
