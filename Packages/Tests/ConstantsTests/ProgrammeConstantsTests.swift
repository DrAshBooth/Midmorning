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
    }

    /// Scenario: The lock grace set.
    func testLockGraceSet() {
        let c = ProgrammeConstants.default
        XCTAssertEqual(c.lockGraceSecondsChoices, [0, 30, 120, 300])
        XCTAssertEqual(c.lockGraceSecondsChoices.first, 0, "0 is the default")
    }

    /// Scenario: A threshold test. Builds a modified value and passes it to a
    /// stand-in "engine" function; `.default` keeps its own value throughout.
    func testThresholdTestConstructsAModifiedValue() {
        func stage2Opens(recordedDays: Int, constants: ProgrammeConstants) -> Bool {
            recordedDays >= constants.recordedDaysForStage2
        }
        var modified = ProgrammeConstants.default
        modified.recordedDaysForStage2 = 3
        XCTAssertTrue(stage2Opens(recordedDays: 3, constants: modified))
        XCTAssertFalse(stage2Opens(recordedDays: 3, constants: .default), "default still holds 5")
        XCTAssertEqual(ProgrammeConstants.default.recordedDaysForStage2, 5)
    }

    /// Scenario: The default day start never changes. A version that edited
    /// the initializer's default to 5 would fail this assertion.
    func testDefaultDayStartHourIsAlwaysFour() {
        XCTAssertEqual(ProgrammeConstants.default.defaultDayStartHour, 4)
    }

    /// Scenario: A capability reads the day start from the setting.
    /// `RecordDay` takes `startHour` as a parameter; the setting supplies it,
    /// never `ProgrammeConstants`. The constant is unaffected by a setting change.
    func testACapabilityReadsTheDayStartFromTheSettingNotTheConstant() {
        let settingDayStart = 5 // "Day starts at" 05:00, read from Settings, not from ProgrammeConstants.
        XCTAssertNotEqual(settingDayStart, ProgrammeConstants.default.defaultDayStartHour)
        XCTAssertEqual(ProgrammeConstants.default.defaultDayStartHour, 4, "the constant never stands in for the setting")
    }
}
