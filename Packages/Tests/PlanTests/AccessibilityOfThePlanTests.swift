import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Accessibility of the plan" (mm-t23.14). Read
/// before the epic's first screen bead, per CLAUDE.md's "Worktrees and
/// beads": every screen this change adds builds its VoiceOver labels inside
/// its own screen bead; this bead proves them.
final class AccessibilityOfThePlanTests: XCTestCase {
    /// Scenario: Label of a matched planned meal.
    func testLabelOfAMatchedPlannedMeal() {
        let label = PlannedMealAccessibility.label(
            slotLabel: "Lunch", time: "13:00",
            matchedEntryAccessibilityLabel: .list([.verbatim("13:10"), .verbatim("Toast and tea"), .key("entry.feltLikeABinge")]),
            isSkipped: false, prompt: nil, timeText: { _ in "" }
        )
        XCTAssertEqual(label.english, "Lunch, 13:00, 13:10, Toast and tea, felt like a binge")
    }

    /// Scenario: Label of a skipped planned meal.
    func testLabelOfASkippedPlannedMeal() {
        let label = PlannedMealAccessibility.label(slotLabel: "Lunch", time: "13:00", matchedEntryAccessibilityLabel: nil, isSkipped: true, prompt: nil, timeText: { _ in "" })
        XCTAssertEqual(label.english, "Lunch, 13:00, Skipped")
    }

    /// Scenario: Label of a planned meal without an entry.
    func testLabelOfAPlannedMealWithoutAnEntry() {
        let label = PlannedMealAccessibility.label(slotLabel: "Evening meal", time: "19:00", matchedEntryAccessibilityLabel: nil, isSkipped: false, prompt: nil, timeText: { _ in "" })
        XCTAssertEqual(label.english, "Evening meal, 19:00")
    }

    /// Scenario: Label of a planned meal with the prompt.
    func testLabelOfAPlannedMealWithThePrompt() {
        let label = PlannedMealAccessibility.label(
            slotLabel: "Lunch", time: "13:00", matchedEntryAccessibilityLabel: nil, isSkipped: false,
            prompt: .skippedOrNotRecorded, timeText: { _ in "" }
        )
        XCTAssertEqual(label.english, "Lunch, 13:00, Skipped, or not recorded yet?")
        // and the row offers the custom actions "Skipped" and "Add it" — a
        // view-layer fact (`.accessibilityAction`), proven in the app target.
    }

    /// Scenario: Labels in the builder.
    func testLabelsInTheBuilder() {
        XCTAssertEqual(PlanBuilderAccessibility.timeControlLabel(slotLabel: "Lunch").english, "Lunch time")
        XCTAssertEqual(PlanBuilderAccessibility.removeControlLabel(slotLabel: "Lunch").english, "Remove Lunch")
        XCTAssertEqual(PlanBuilderAccessibility.renameControlLabel(slotLabel: "Lunch").english, "Rename Lunch")
    }

    /// Scenario: Label of a renamed planned meal.
    func testLabelOfARenamedPlannedMeal() {
        let label = PlannedMealAccessibility.label(slotLabel: "Elevenses", time: "10:30", matchedEntryAccessibilityLabel: nil, isSkipped: false, prompt: nil, timeText: { _ in "" })
        XCTAssertEqual(label.english, "Elevenses, 10:30")
    }

    /// Scenario: Largest text size — a device check (system text styles and
    /// Dynamic Type at AX5), listed on the epic's device-check bead
    /// (mm-t23.15), not a pure function.
}
