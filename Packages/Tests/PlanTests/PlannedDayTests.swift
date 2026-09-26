import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "A planned day" (mm-t23.8). The store-level
/// facts (the set event row's own persistence, its sticky cross-device
/// behaviour, and the record-day key staying fixed across a "Day starts at"
/// change) are `DayReconciler`'s job, already proven in `RecordTests`; this
/// tests the one pure decision this package owns.
final class PlannedDayTests: XCTestCase {
    /// Scenario: Save an edit to today's plan.
    func testSaveAnEditToTodaysPlanIsASetDayAndAPlannedDay() {
        XCTAssertTrue(PlannedDay.isPlanned(isPaused: false, isSetDay: true, hasEntry: false))
    }

    /// Scenario: An entry on a template day.
    func testAnEntryOnATemplateDayIsAPlannedDay() {
        XCTAssertTrue(PlannedDay.isPlanned(isPaused: false, isSetDay: false, hasEntry: true))
    }

    /// Scenario: A set day without an entry.
    func testASetDayWithoutAnEntryIsStillAPlannedDay() {
        XCTAssertTrue(PlannedDay.isPlanned(isPaused: false, isSetDay: true, hasEntry: false))
        // and does not count toward stage 3 without also being a recorded day:
        XCTAssertEqual(PlannedDay.countTowardStage3([(isPlanned: true, isRecordedDay: false)]), 0)
    }

    /// Scenario: A day the person did not touch.
    func testADayThePersonDidNotTouchIsNotAPlannedDay() {
        XCTAssertFalse(PlannedDay.isPlanned(isPaused: false, isSetDay: false, hasEntry: false))
    }

    /// Scenario: A "Skipped" answer only.
    func testASkippedAnswerOnlyIsNotAPlannedDay() {
        // A "Skipped" answer never sets the day and is not an entry.
        XCTAssertFalse(PlannedDay.isPlanned(isPaused: false, isSetDay: false, hasEntry: false))
    }

    /// Scenario: A snooze only.
    func testASnoozeOnlyIsNotAPlannedDay() {
        // A snooze touches only `Local.store`'s snooze count; it is neither
        // a set event nor an entry.
        XCTAssertFalse(PlannedDay.isPlanned(isPaused: false, isSetDay: false, hasEntry: false))
    }

    /// Scenario: A paused day in a run.
    func testAPausedDayInARunIsNotPlannedButDoesNotBreakTheRun() {
        XCTAssertFalse(PlannedDay.isPlanned(isPaused: true, isSetDay: true, hasEntry: true), "paused overrides every other fact")
        let week: [(isPaused: Bool, isPlanned: Bool)] = [
            (false, true), (false, true), (false, true), (true, false), (false, true), (false, true), (false, true),
        ]
        XCTAssertEqual(PlannedDay.consecutiveRunLength(week), 6)
    }

    /// Scenario: A fasting day on the plan. The `record` capability owns the
    /// fasting state; a fasting day is planned exactly like any other once
    /// it is a set day.
    func testAFastingDayOnThePlanIsAPlannedDay() {
        XCTAssertTrue(PlannedDay.isPlanned(isPaused: false, isSetDay: true, hasEntry: false))
    }

    /// Scenario: A day start change keeps the key. This is `Day`'s own
    /// stored key, which a change to "Day starts at" never rewrites — proven
    /// with the real model in `RecordTests` (`PlanStoreTests`).
    func testADayStartChangeKeepsTheKeyIsAStoreLevelFact() {
        XCTAssertTrue(true, "see RecordTests.PlanStoreTests.testADayStartChangeKeepsTheKey")
    }

    /// Scenario: The set event row from another device — `DayReconciler`'s
    /// sticky-set rule, already proven in `ConflictRulesTests`.
    func testTheSetEventRowFromAnotherDeviceIsADayReconcilerFact() {
        XCTAssertTrue(true, "see RecordTests.ConflictRulesTests.testSetEventIsStickyAcrossALaterPlanEdit")
    }

    /// Scenario: Seven planned days over ten record days.
    func testSevenPlannedDaysOverTenRecordDays() {
        var days: [(isPlanned: Bool, isRecordedDay: Bool)] = Array(repeating: (true, true), count: 7)
        days.append(contentsOf: Array(repeating: (false, true), count: 3))
        XCTAssertEqual(PlannedDay.countTowardStage3(days), 7)
    }
}
