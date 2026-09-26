import XCTest
@testable import Constants

/// Covers programme spec.md, "The constants live in one value": the values,
/// the lock grace set, a threshold test, the default day start, and a
/// capability reading the day start from the setting rather than the constant.
final class ProgrammeConstantsTests: XCTestCase {
    /// Scenario: The values.
    func testEachDefaultValue() {
        let c = ProgrammeConstants.default
        XCTAssertEqual(c.defaultDayStartHour, 4)
        XCTAssertEqual(c.programmeWeeks, 12)
        XCTAssertEqual(c.minHeightCm, 100)
        XCTAssertEqual(c.maxHeightCm, 250)
        XCTAssertEqual(c.minWeightKg, 30)
        XCTAssertEqual(c.recordedDaysForStage2, 5)
        XCTAssertEqual(c.daysOnPlanForStage3, 7)
        XCTAssertEqual(c.recordDaysForStage3Fallback, 14)
        XCTAssertEqual(c.recordedDaysForStage4Fallback, 7)
        XCTAssertEqual(c.weekOfTakingStock, 6)
        XCTAssertEqual(c.weekOfStayingOnTrack, 10)
        XCTAssertEqual(c.maxAwakeGapHours, 4)
        XCTAssertEqual(c.maxOtherRemindersPerDay, 2)
        XCTAssertEqual(c.snoozeMinutes, 15)
        XCTAssertEqual(c.maxSnoozes, 2)
        XCTAssertEqual(c.rollingAverageWeeks, 4)
        XCTAssertEqual(c.urgeTimerMinutes, 20)
        XCTAssertEqual(c.deteriorationWeeks, 3)
        XCTAssertEqual(c.checkInWeeks, [4, 8, 12])
        XCTAssertEqual(c.patternWindowDays, 28)
        XCTAssertEqual(c.patternMinStarred, 5)
        XCTAssertEqual(c.patternMinGroup, 3)
        XCTAssertEqual(c.plannedMealWindowBeforeMinutes, 60)
        XCTAssertEqual(c.plannedMealWindowAfterMinutes, 90)
        XCTAssertEqual(c.reminderHorizonDays, 6)
        XCTAssertEqual(c.maxPendingReminderRequests, 60)
    }

    /// Scenario: The lock grace set.
    func testLockGraceSet() {
        let c = ProgrammeConstants.default
        XCTAssertEqual(c.lockGraceSecondsChoices, [0, 30, 120, 300])
        XCTAssertEqual(c.lockGraceSecondsChoices.first, 0, "0 is the default")
    }

    /// Scenario: A threshold test, the `Constants` half: a modified value is
    /// a copy, so `.default` keeps 5. `ProgrammeTests.ConstantsThresholdTests`
    /// passes the modified value to the real stage engine.
    func testAModifiedValueLeavesTheDefaultUnchanged() {
        var modified = ProgrammeConstants.default
        modified.recordedDaysForStage2 = 3
        XCTAssertEqual(modified.recordedDaysForStage2, 3)
        XCTAssertEqual(ProgrammeConstants.default.recordedDaysForStage2, 5, "default still holds 5")
    }

    /// Scenario: The default day start never changes. A version that edited
    /// the initializer's default to 5 would fail this assertion.
    func testDefaultDayStartHourIsAlwaysFour() {
        XCTAssertEqual(ProgrammeConstants.default.defaultDayStartHour, 4)
    }

    // Scenario: A capability reads the day start from the setting. The
    // `Constants` target cannot open the store, so
    // `RecordTests.DayStartSettingTests` sets "Day starts at" to 05:00 in
    // the real store and computes the current record day from it.
}
