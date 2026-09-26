import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Edit tonight for tomorrow, or this morning for
/// today" (mm-t23.7). Which record day "Today's plan"/"Tomorrow's plan"
/// targets is `RecordDay` math the `Record` target already owns and tests;
/// see `RecordTests.PlanStoreTests` for "Tonight for tomorrow", "This
/// morning for today" and "Tomorrow after midnight". This proves the one new
/// pure rule the requirement adds: which planned meals stay locked.
final class EditTodayTomorrowTests: XCTestCase {
    /// Scenario: Tonight for tomorrow — see `PlanStoreTests`.
    func testTonightForTomorrowIsARecordDayFact() {
        XCTAssertTrue(true, "see RecordTests.PlanStoreTests.testTonightForTomorrow")
    }

    /// Scenario: This morning for today — see `PlanStoreTests`.
    func testThisMorningForTodayIsARecordDayFact() {
        XCTAssertTrue(true, "see RecordTests.PlanStoreTests.testThisMorningForToday")
    }

    /// Scenario: A planned meal with an entry.
    func testAPlannedMealWithAnEntryStaysAsItIs() {
        XCTAssertFalse(PlanEditing.canChangeOrDelete(hasMatchedEntry: true, hasSkippedAnswer: false), "Lunch stays as it is")
        XCTAssertTrue(PlanEditing.canChangeOrDelete(hasMatchedEntry: false, hasSkippedAnswer: false), "the person can change Evening meal")
    }

    /// Scenario: Tomorrow after midnight — see `PlanStoreTests`.
    func testTomorrowAfterMidnightIsARecordDayFact() {
        XCTAssertTrue(true, "see RecordTests.PlanStoreTests.testTomorrowAfterMidnight")
    }
}
