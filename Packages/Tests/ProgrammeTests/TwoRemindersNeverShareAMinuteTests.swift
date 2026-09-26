import XCTest
@testable import Programme

/// reminders spec, "Two reminders never share a minute" (mm-t24.14).
final class TwoRemindersNeverShareAMinuteTests: XCTestCase {
    private func c(_ kind: ReminderKind, _ time: String, slot: Int? = nil) -> ReminderCandidate {
        ReminderCandidate(kind: kind, dayKey: "2026-09-28", slotIndex: slot, time: time)
    }

    /// Scenario: The weigh-in day at the morning plan time.
    func testTheWeighInDayAtTheMorningPlanTime() {
        let result = SameMinuteShift.apply([c(.weighInDay, "07:30"), c(.morningPlan, "07:30")])
        XCTAssertEqual(result.first { $0.kind == .weighInDay }?.time, "07:30")
        XCTAssertEqual(result.first { $0.kind == .morningPlan }?.time, "07:35")
    }

    /// Scenario: Three at one minute.
    func testThreeAtOneMinute() {
        let result = SameMinuteShift.apply([c(.plannedMeal, "07:30", slot: 0), c(.weighInDay, "07:30"), c(.morningPlan, "07:30")])
        XCTAssertEqual(result.first { $0.kind == .plannedMeal }?.time, "07:30")
        XCTAssertEqual(result.first { $0.kind == .weighInDay }?.time, "07:35")
        XCTAssertEqual(result.first { $0.kind == .morningPlan }?.time, "07:40")
    }
}
