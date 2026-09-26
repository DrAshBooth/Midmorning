import Foundation
import XCTest
@testable import Plan
import Constants

/// regular-eating-plan spec, "Place slots in the plan builder" (mm-t23.3).
final class PlanBuilderPlacementTests: XCTestCase {
    /// Scenario: Place a slot.
    func testPlaceASlotUsesItsDefaultTime() {
        let slot = Slot.at(index: 0)!
        let placed = PlanCodec.placing(slot.index, at: slot.defaultTime, in: [])
        XCTAssertEqual(placed, [PlannedMeal(slotIndex: 0, time: "08:00")])
    }

    /// Scenario: Place a renamed slot. The rename only changes the label
    /// shown on the button; the default time placed is still the slot's own.
    func testPlaceARenamedSlotStillUsesTheSlotsDefaultTime() {
        let slot = Slot.at(index: 1)!
        let label = SlotLabel.effective(stored: "Elevenses", defaultLabel: slot.defaultLabel)
        XCTAssertEqual(label.english, "Elevenses")
        let placed = PlanCodec.placing(slot.index, at: slot.defaultTime, in: [])
        XCTAssertEqual(placed, [PlannedMeal(slotIndex: 1, time: "10:30")])
    }

    /// Scenario: Place the evening snack.
    func testPlaceTheEveningSnack() {
        let slot = Slot.at(index: 5)!
        let placed = PlanCodec.placing(slot.index, at: slot.defaultTime, in: [])
        XCTAssertEqual(placed, [PlannedMeal(slotIndex: 5, time: "21:00")])
    }

    /// Scenario: Change a time.
    func testChangeATime() {
        let day = [PlannedMeal(slotIndex: 0, time: "08:00")]
        let changed = PlanCodec.placing(0, at: "07:15", in: day)
        XCTAssertEqual(changed, [PlannedMeal(slotIndex: 0, time: "07:15")])
    }

    /// Scenario: Remove a planned meal.
    func testRemoveAPlannedMeal() {
        let day = [PlannedMeal(slotIndex: 2, time: "13:00")]
        XCTAssertEqual(PlanCodec.removing(2, from: day), [], "the Lunch button shows again")
    }

    /// Scenario: Gap shown between planned meals.
    func testGapShownBetweenPlannedMeals() {
        let gap = PlanOrdering.minutesAfterDayStart(time: "16:00", dayStartHour: 4) - PlanOrdering.minutesAfterDayStart(time: "13:00", dayStartHour: 4)
        XCTAssertEqual(DurationText.string(minutes: gap), "3 hours")
    }

    /// Scenario: No gap on a fasting day. The builder shows no gap line for
    /// a fasting day; `SoftRules.gapLines` already honours `isFastingDay`,
    /// and the builder's per-pair gap display uses the same flag.
    func testNoGapOnAFastingDay() {
        let meals = [PlanMealFact(label: "Lunch", time: "13:00", kind: .meal), PlanMealFact(label: "Evening meal", time: "19:00", kind: .meal)]
        let lines = SoftRules.gapLines(orderedMeals: meals, dayStartHour: 4, maxAwakeGapHours: 4, isFastingDay: true)
        XCTAssertEqual(lines, [], "no gap message on a fasting day")
    }

    /// Scenario: A planned meal inside quiet hours.
    func testAPlannedMealInsideQuietHoursShowsAMessageAndKeepsIt() {
        XCTAssertTrue(QuietHours.contains(time: "22:30", start: "22:00", end: "07:00"))
        XCTAssertFalse(QuietHours.contains(time: "12:00", start: "22:00", end: "07:00"))
    }

    /// Scenario: Save below the planned meals — decision 94: layout is a
    /// screen-level fact, not a pure function; `PlanBuilderLayout` records
    /// the fixed positions the view must use.
    func testSaveBelowThePlannedMealsLayout() {
        XCTAssertEqual(PlanBuilderLayout.leadingNavigationItem, "Cancel")
        XCTAssertEqual(PlanBuilderLayout.trailingNavigationItem, "Get support")
        XCTAssertEqual(PlanBuilderLayout.saveControlPosition, .fullWidthBelowPlannedMeals)
    }
}
