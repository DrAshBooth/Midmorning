import XCTest
import Constants
@testable import Programme

/// Safeguarding spec, "The GP suggestion page" (mm-t14.21). No scenario is
/// built here directly (the acceptance criteria names "none"); every
/// scenario needs a trigger from `mm-t22`, `mm-t24` or `mm-t32`, tested over
/// fixture facts. These tests prove the content itself, which those wiring
/// beads then run end to end.
final class GPSuggestionPageTests: XCTestCase {
    func testFallingWeightLine() {
        XCTAssertEqual(GPSuggestionPage.line(for: .fallingWeight), "Your weight has come down since you started.")
    }

    func testQuickChangeLine() {
        XCTAssertEqual(GPSuggestionPage.line(for: .quickChange), "Your weight has changed quickly over the last four weeks.")
    }

    /// Ruling r13-09: the line holds no count, because the page MUST NOT
    /// show a number.
    func testDeteriorationLineHoldsNoNumber() {
        let line = GPSuggestionPage.line(for: .deterioration)
        XCTAssertEqual(line, "Your starred entries have gone up each week lately.")
        XCTAssertFalse(line.contains { $0.isNumber })
    }

    func testGettingWorseLine() {
        XCTAssertEqual(GPSuggestionPage.line(for: .gettingWorse), "You said things are getting worse.")
    }

    func testSupportingLines() {
        XCTAssertEqual(GPSuggestionPage.supportingLine(for: .fallingWeight), "Your plan stays on. It's worth a word with your GP.")
        XCTAssertEqual(GPSuggestionPage.supportingLine(for: .deterioration), "That's worth talking through with your GP. Your plan stays on.")
    }

    func testDiagnosisLine() {
        XCTAssertEqual(GPSuggestionPage.diagnosisLine, "This is not a diagnosis, and nothing here is closed to you.")
    }
}
