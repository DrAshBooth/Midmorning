import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "The plan builder opens at stage 2" (mm-t23.1).
/// `programme-engine` (2.1) is not built yet, so every scenario here runs
/// over a fixture `stage2Open` fact, the same pattern `GapBand` and
/// `TodayCardSlot` already use; `mm-t21.23` wires the live stage.
final class PlanBuilderAccessTests: XCTestCase {
    /// Scenario: Four recorded days (a stage fact; not yet open).
    func testFourRecordedDaysShowsNoPlanBuilderControl() {
        XCTAssertFalse(PlanBuilderAccess.isOffered(stage2Open: false))
    }

    /// Scenario: Five recorded days with gaps (a stage fact; open).
    func testFiveRecordedDaysWithGapsOpensThePlanBuilder() {
        XCTAssertTrue(PlanBuilderAccess.isOffered(stage2Open: true))
    }

    /// Scenario: A day without entries (a stage fact; still not open).
    func testADayWithoutEntriesDoesNotCountTowardStage2() {
        XCTAssertFalse(PlanBuilderAccess.isOffered(stage2Open: false))
    }
}
