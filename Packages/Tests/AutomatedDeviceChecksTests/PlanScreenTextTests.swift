import Foundation
import XCTest
import Constants
import Plan

/// Ruling r13-19 (mm-t43.30): the text check on mm-t23.15 from mm-t11.39
/// (commit f6b57d3), "plan strings now come from Localizable.xcstrings".
/// Each test names the words that the check asked Ash to look for, proves
/// them from the catalogue, and proves that the screen's App file shows
/// them. The rules under the words have their own tests in PlanTests.
final class PlanScreenTextTests: XCTestCase {
    /// "the builder shows the six default slot labels".
    func testTheBuilderShowsTheSixDefaultSlotLabels() throws {
        XCTAssertEqual(Slot.all.map { ScreenText.english($0.defaultLabel) },
                       ["Breakfast", "Mid-morning", "Lunch", "Mid-afternoon", "Evening meal", "Evening snack"])
        try ScreenText.assertScreen("SlotLabelText.swift", shows: ["SlotLabel.effective(stored: stored, defaultLabel: slot.defaultLabel).string"])
        try ScreenText.assertScreen("PlanBuilderView.swift", shows: ["SlotLabelText.effective(index: slotIndex", "Button(label(slot.index))"])
    }

    /// "'Lunch time', 'Remove Lunch' and VoiceOver 'Rename Lunch'".
    func testTheBuilderShowsTheControlLabelsForASlot() throws {
        XCTAssertEqual(ScreenText.english(PlanBuilderAccessibility.timeControlLabel(slotLabel: "Lunch")), "Lunch time")
        XCTAssertEqual(ScreenText.english(PlanBuilderAccessibility.removeControlLabel(slotLabel: "Lunch")), "Remove Lunch")
        XCTAssertEqual(ScreenText.english(PlanBuilderAccessibility.renameControlLabel(slotLabel: "Lunch")), "Rename Lunch")
        try ScreenText.assertScreen("PlanBuilderView.swift", shows: [
            "PlanBuilderAccessibility.timeControlLabel(slotLabel: slotLabel).string",
            "Text(PlanBuilderAccessibility.removeControlLabel(slotLabel: slotLabel).string)",
            ".accessibilityLabel(PlanBuilderAccessibility.renameControlLabel(slotLabel: slotLabel).string)",
        ])
    }

    /// "a rename to 'Midmorning' shows 'That is the app's name. Choose
    /// another word.'".
    func testARenameToTheAppsNameShowsTheMessage() throws {
        guard case .rejected(let message) = SlotLabel.outcome(forSavedText: "Midmorning") else {
            return XCTFail("the builder refuses the app's name")
        }
        XCTAssertEqual(ScreenText.english(message), "That is the app's name. Choose another word.")
        try ScreenText.assertScreen("PlanBuilderView.swift", shows: ["SlotLabel.outcome(forSavedText: renameText)", "renameMessage = message", "Text(renameMessage.string)"])
    }

    /// "saving 2 meals and 1 snack shows 'This day has 2 meals and 1
    /// snack. ...'", and "a long gap shows '4 hours 30 minutes between
    /// Lunch at 12:30 and Evening meal at 17:00.'".
    func testSavingShowsTheSoftRuleLines() throws {
        let meals = SoftRules.mealLine(mealCount: 2, snackCount: 1).map(ScreenText.english)
        XCTAssertEqual(meals, "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?")
        let gap = SoftRules.gapLines(
            orderedMeals: [PlanMealFact(label: "Lunch", time: "12:30", kind: .meal), PlanMealFact(label: "Evening meal", time: "17:00", kind: .meal)],
            dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false
        ).map(ScreenText.english)
        XCTAssertEqual(gap, ["4 hours 30 minutes between Lunch at 12:30 and Evening meal at 17:00."])
        try ScreenText.assertScreen("PlanBuilderView.swift", shows: ["SoftRules.lines(orderedMeals: facts", "softRuleLines = lines", "softRuleLines.map(\\.string)"])
    }

    /// "Today shows 'Skipped, or not recorded yet?' on a missed planned
    /// meal".
    func testTodayShowsTheMissedPlannedMealPrompt() throws {
        XCTAssertEqual(ScreenText.english(MissedMealPrompt.line(for: .skippedOrNotRecorded, timeText: { _ in "" })), "Skipped, or not recorded yet?")
        try ScreenText.assertScreen("PlannedMealRowView.swift", shows: ["Text(MissedMealPrompt.line(for: prompt, timeText: clockTimeText).string)"])
    }

    /// Ruling r19-03 (mm-t23.25): an earlier day shows no "Skipped". The
    /// prompt hides when the record day ends (`MissedMealPromptTests
    /// .testUnansweredAtTheEndOfTheDayHidesThePrompt`), and the earlier-day
    /// screen gives no "Skipped" or "Add it" action to its rows. Today
    /// still gives both.
    func testAnEarlierDayGivesNoSkippedAction() throws {
        let earlierDay = try ScreenText.source("EarlierDaysListView.swift")
        for absent in ["skipPlannedMeal", "setPlannedMealSkipped", "addPlannedMeal"] {
            XCTAssertFalse(earlierDay.contains(absent), "EarlierDaysListView.swift holds \(absent)")
        }
        try ScreenText.assertScreen("TodayView.swift", shows: ["skipPlannedMeal: { slotIndex in", "store.setPlannedMealSkipped(dateKey: section.id"])
        try ScreenText.assertScreen("PlannedMealRowView.swift", shows: ["if let onSkip, let onAddIt {"])
    }

    /// "'Mid-afternoon at 16:00 still happens.' as the next line".
    func testTodayShowsTheNextPlannedMealLine() throws {
        let line = NextPlannedMeal.line(for: PlanMealFact(label: "Mid-afternoon", time: "16:00", kind: .snack))
        XCTAssertEqual(ScreenText.english(line), "Mid-afternoon at 16:00 still happens.")
        try ScreenText.assertScreen("PlanTodayModel.swift", shows: ["NextPlannedMeal.line(for: PlanMealFact("])
        try ScreenText.assertScreen("PlannedMealRowView.swift", shows: ["if let nextLine = row.nextLine", "Text(nextLine)"])
        // Ruling r19-02 (mm-t23.26): the row's accessibility label ends
        // with the same line (`PlannedMealAccessibility`).
        try ScreenText.assertScreen("PlannedMealRowView.swift", shows: ["nextPlannedMealLine: row.nextLine.map(CatalogueText.verbatim)"])
    }
}
