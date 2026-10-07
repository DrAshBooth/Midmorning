import Foundation
import XCTest

/// mm-t32.28 (weekly-review spec, "Accessibility of the review"): each row
/// of an inline answer picker is one answer, and VoiceOver reads that
/// answer. An accessibility label on an inline picker goes to every row,
/// so the review read the question on each self-harm row. A picker label
/// that shows also repeats the question of the section header. There is no
/// App-target test runner, so this structural test reads the App sources of
/// the review and of the screening questions (onboarding screen 2 and the
/// restart re-screen). `AutomatedChecks.reviewSelfHarmRows` finds the rows
/// by their answers on the simulator; the device check in mm-t32.28 proves
/// what VoiceOver reads.
final class SelfHarmRowLabelTests: XCTestCase {
    private let appDirectory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ProgrammeTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // repo root
        .appendingPathComponent("App/Midmorning", isDirectory: true)

    private let files = ["WeeklyReview/ReviewScreenView.swift", "Onboarding/ScreeningQuestionSections.swift"]

    private func lines(_ file: String) throws -> [String] {
        try String(contentsOf: appDirectory.appendingPathComponent(file), encoding: .utf8)
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Each inline picker hides its label and has no accessibility label of
    /// its own, so each row reads its own answer.
    func testEachInlinePickerHidesItsLabelAndHasNoAccessibilityLabel() throws {
        for file in files {
            let lines = try lines(file)
            let inline = lines.indices.filter { lines[$0] == ".pickerStyle(.inline)" }
            XCTAssertFalse(inline.isEmpty, "\(file) has inline pickers")
            for index in inline {
                let next = lines.indices.contains(index + 1) ? lines[index + 1] : ""
                XCTAssertEqual(next, ".labelsHidden()", "\(file):\(index + 2) hides the picker label")
            }
            XCTAssertFalse(
                lines.contains { $0.hasPrefix(".accessibilityLabel(ScreeningQuestionCatalog") },
                "\(file) puts no question on the answer rows"
            )
        }
    }

    /// At the review, step 2 shares the section of step 1, so its question
    /// shows once, as a header row above its two answers.
    func testTheReviewShowsTheStepTwoQuestionAsAHeaderRow() throws {
        let lines = try lines(files[0])
        let question = try XCTUnwrap(lines.firstIndex(of: "Text(ScreeningQuestionCatalog.selfHarmSecondQuestion)"))
        XCTAssertEqual(lines[question + 1], ".accessibilityAddTraits(.isHeader)")
        XCTAssertTrue(lines[question + 2].hasPrefix("Picker(ScreeningQuestionCatalog.selfHarmSecondQuestion"))
    }
}
