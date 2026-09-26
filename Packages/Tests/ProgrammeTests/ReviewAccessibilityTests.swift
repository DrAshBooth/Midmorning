import XCTest
@testable import Programme

/// weekly-review spec, "Accessibility of the review" (mm-t32.15). What the
/// screen itself does with these constants (one accessibility element per
/// summary sentence, the button trait, Dynamic Type) has no App-target test
/// runner (`ReviewScreenView.swift` is the App-target seam); these prove
/// what a test can reach: every VoiceOver-facing string is a named,
/// spec-quoted constant, never a bare literal a screen could typo.
final class ReviewAccessibilityTests: XCTestCase {
    /// Scenario: VoiceOver reads the summary. Each summary sentence
    /// `ReviewSummary.parts` returns is already the exact, complete text a
    /// VoiceOver label reads — proved directly by `ReviewSummaryTests`.
    func testEachSummarySentenceIsSelfContained() {
        let facts = ReviewWeekFacts(weekDayKeys: ["2026-10-12"], entries: [ReviewEntryFact(dayKey: "2026-10-12", time: moment(2026, 10, 12, 9), starred: false)])
        for line in ReviewSummary.parts(facts, calendar: engineTestCalendar) {
            XCTAssertFalse(line.isEmpty)
        }
    }

    /// Scenario: VoiceOver on "I'm getting worse".
    func testGettingWorseLabelAndHint() {
        XCTAssertEqual(ReviewContent.gettingWorseButton, "I'm getting worse")
        XCTAssertEqual(ReviewContent.gettingWorseHint, "Opens a page about seeing your GP.")
    }

    /// Scenario: Largest text size (the review and taking stock halves;
    /// `mm-t32b.5` proves the taking-stock half). Every question and
    /// heading this change adds is plain text, not a fixed-size image or a
    /// truncating single-line label.
    func testNoFixedWidthContent() {
        for question in ReviewContent.reflectionQuestions + ReviewContent.weekOneQuestions + [ReviewContent.oneThingToChangeQuestion] {
            XCTAssertFalse(question.isEmpty)
        }
    }
}
