import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Slots and planned meals" (mm-t23.2).
final class SlotsAndPlannedMealsTests: XCTestCase {
    /// Scenario: A slot placed twice.
    func testASlotPlacedTwiceKeepsOneRowAtTheNewTime() {
        let day = [PlannedMeal(slotIndex: 2, time: "13:00")]
        let replaced = PlanCodec.placing(2, at: "13:30", in: day)
        XCTAssertEqual(replaced, [PlannedMeal(slotIndex: 2, time: "13:30")], "one Lunch, at 13:30")
    }

    /// Scenario: Slots out of their usual order.
    func testSlotsOutOfTheirUsualOrderSortByRecordDayPlace() {
        let meals = [PlannedMeal(slotIndex: 4, time: "16:30"), PlannedMeal(slotIndex: 3, time: "17:00")]
        let ordered = PlanOrdering.sorted(meals, dayStartHour: 4)
        XCTAssertEqual(ordered.map(\.slotIndex), [4, 3], "Evening meal above Mid-afternoon")
    }

    /// Scenario: A planned meal after midnight.
    func testAPlannedMealAfterMidnightStaysInFridaysRecordDay() {
        let minutes = PlanOrdering.minutesAfterDayStart(time: "00:30", dayStartHour: 4)
        XCTAssertEqual(minutes, 20 * 60 + 30, "20h30 after 04:00 start, still Friday's record day")
    }

    /// Scenario: A later day start.
    func testALaterDayStartKeepsTheSameRecordDay() {
        let minutes = PlanOrdering.minutesAfterDayStart(time: "04:30", dayStartHour: 5)
        XCTAssertEqual(minutes, 23 * 60 + 30, "23h30 after a 05:00 start; still the same record day")
    }

    /// Scenario: A renamed slot keeps its kind and index.
    func testARenamedSlotKeepsItsKindAndIndex() {
        let slot = Slot.at(index: 1)!
        XCTAssertEqual(slot.kind, .snack)
        XCTAssertEqual(slot.index, 1, "Elevenses is still slot index 1, a snack")
    }

    // MARK: Slot table

    func testTheSixSlotsAndTheirDefaults() {
        XCTAssertEqual(Slot.all.map(\.defaultLabel.english), ["Breakfast", "Mid-morning", "Lunch", "Mid-afternoon", "Evening meal", "Evening snack"])
        XCTAssertEqual(Slot.all.map(\.kind), [.meal, .snack, .meal, .snack, .meal, .snack])
        XCTAssertEqual(Slot.all.map(\.defaultTime), ["08:00", "10:30", "13:00", "16:00", "19:00", "21:00"])
    }

    func testPlanCodecRoundTripsTheEstablishedShape() {
        let json = "[{\"slot\":1,\"time\":\"13:30\"}]"
        let decoded = PlanCodec.decode(json)
        XCTAssertEqual(decoded, [PlannedMeal(slotIndex: 1, time: "13:30")])
        XCTAssertEqual(PlanCodec.decode(PlanCodec.encode(decoded)), decoded)
    }

    func testRemovingASlot() {
        let day = [PlannedMeal(slotIndex: 2, time: "13:00"), PlannedMeal(slotIndex: 4, time: "19:00")]
        XCTAssertEqual(PlanCodec.removing(2, from: day), [PlannedMeal(slotIndex: 4, time: "19:00")])
    }
}
