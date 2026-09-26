import XCTest
@testable import Export

/// export spec, "The PDF is formatted like the paper record".
final class ExportDayKeyTests: XCTestCase {
    /// Scenario: The first page. The formatter's own thin spaces (U+2009)
    /// either side of the en dash (U+2013).
    func testRangeTextUsesThinSpacesAroundTheEnDash() {
        let text = ExportDayKey.rangeText(from: "2026-08-28", to: "2026-09-24")
        XCTAssertEqual(text, "28 August\u{2009}–\u{2009}24 September 2026")
    }

    func testDayHeadingIncludesTheYear() {
        XCTAssertEqual(ExportDayKey.dayHeading("2026-09-24"), "Thursday 24 September 2026")
    }

    /// Scenario: Two days in order.
    func testDayHeadingsForConsecutiveDays() {
        XCTAssertEqual(ExportDayKey.dayHeading("2026-09-21"), "Monday 21 September 2026")
        XCTAssertEqual(ExportDayKey.dayHeading("2026-09-22"), "Tuesday 22 September 2026")
    }

    func testRangeOfKeysIsInclusiveAndOrdered() {
        XCTAssertEqual(ExportDayKey.range(from: "2026-09-21", to: "2026-09-23"), ["2026-09-21", "2026-09-22", "2026-09-23"])
    }

    /// Scenario: A range of one day.
    func testRangeOfOneDay() {
        XCTAssertEqual(ExportDayKey.range(from: "2026-09-21", to: "2026-09-21"), ["2026-09-21"])
    }

    func testAddingDays() {
        XCTAssertEqual(ExportDayKey.adding(-27, to: "2026-09-24"), "2026-08-28")
        XCTAssertEqual(ExportDayKey.adding(1, to: "2026-09-30"), "2026-10-01")
    }
}
