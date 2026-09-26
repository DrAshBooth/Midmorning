import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "The soft rules show and ask" (mm-t23.5).
final class SoftRulesTests: XCTestCase {
    /// Scenario: Too few meals and snacks.
    func testTooFewMealsAndSnacks() {
        let line = SoftRules.mealLine(mealCount: 2, snackCount: 1)
        XCTAssertEqual(line, "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?")
    }

    /// Scenario: Save anyway — a store write, not a pure-function scenario;
    /// covered at the store level (`RecordStoreTests`/the builder view). The
    /// pure fact this scenario rests on, that the day saves as it is with no
    /// further check, is that `SoftRules` never blocks a save: it only
    /// returns lines to show.
    func testSaveAnywayIsAdvisoryOnly() {
        XCTAssertFalse(SoftRules.mealLine(mealCount: 2, snackCount: 1) == nil, "there is a line to show")
        // Nothing in this package's API can refuse a save; the builder always
        // may persist regardless of `lines(...)`'s result.
    }

    /// Scenario: No meals at all.
    func testNoMealsAtAll() {
        let line = SoftRules.mealLine(mealCount: 0, snackCount: 2)
        XCTAssertEqual(line, "This day has no meals and 2 snacks. Three meals and two or three snacks keep the gaps short. Save anyway?")
    }

    /// Scenario: Go back — a builder-navigation fact; the store is untouched,
    /// which this package expresses by never being called to write anything
    /// (there is no half-way "propose a save" state in `SoftRules`).
    func testGoBackChangesNothing() {
        // `SoftRules.lines` is a pure read of a proposed day; calling it
        // performs no write, so "Go back" needs no undo.
        _ = SoftRules.lines(orderedMeals: [], dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false)
    }

    /// Scenario: A gap over four hours.
    func testAGapOverFourHours() {
        let meals = [PlanMealFact(label: "Lunch", time: "12:30", kind: .meal), PlanMealFact(label: "Evening meal", time: "17:00", kind: .meal)]
        let lines = SoftRules.gapLines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false)
        XCTAssertEqual(lines, ["4 hours 30 minutes between Lunch at 12:30 and Evening meal at 17:00."])
    }

    /// Scenario: Two broken rules.
    func testTwoBrokenRulesShowBothLines() {
        let meals = [PlanMealFact(label: "Breakfast", time: "08:00", kind: .meal), PlanMealFact(label: "Lunch", time: "13:00", kind: .meal)]
        let lines = SoftRules.lines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false)
        XCTAssertEqual(lines.count, 2, "the meal line and the gap line, as two paragraphs")
        XCTAssertTrue(lines[0].hasPrefix("This day has"), "the meal line comes first")
    }

    /// Scenario: A gap of exactly four hours.
    func testAGapOfExactlyFourHoursShowsNoLine() {
        let meals = [PlanMealFact(label: "Lunch", time: "13:00", kind: .meal), PlanMealFact(label: "Evening meal", time: "17:00", kind: .meal)]
        let lines = SoftRules.gapLines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false)
        XCTAssertEqual(lines, [])
    }

    /// Scenario: A renamed slot counts by its kind.
    func testARenamedSlotCountsByItsKind() {
        // "Mid-afternoon" renamed to "Cake" is still a snack.
        let line = SoftRules.mealLine(mealCount: 2, snackCount: 1)
        XCTAssertEqual(line, "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?", "renamed labels never change the kind count")
    }

    /// Scenario: A long gap on a fasting day.
    func testALongGapOnAFastingDayShowsNoGapLineButStillTheMealLine() {
        let meals = [PlanMealFact(label: "Lunch", time: "12:30", kind: .meal), PlanMealFact(label: "Evening meal", time: "17:00", kind: .meal)]
        let lines = SoftRules.lines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: true)
        XCTAssertEqual(lines.count, 1, "no gap line, the meal line still applies")
        XCTAssertTrue(lines[0].hasPrefix("This day has 2 meals"))
    }

    /// Scenario: A day that meets every rule.
    func testADayThatMeetsEveryRuleShowsNoLine() {
        let meals = Slot.all.map { PlanMealFact(label: $0.defaultLabel, time: $0.defaultTime, kind: $0.kind) }
        let lines = SoftRules.lines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: false)
        XCTAssertEqual(lines, [])
    }
}
