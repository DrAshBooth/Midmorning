import XCTest
@testable import Programme

/// Covers programme spec.md, "Taking stock, the modules and staying on
/// track open by week of regular eating" (mm-t21.7). "Taking stock
/// recommends 'Food rules'" and "Week 10 of regular eating without taking
/// stock" are built here over a fixture `takingStockCompletedAt` fact, with
/// no live dependency on `weekly-review`/`taking-stock` (3.2b); `mm-t32b.7`
/// runs each end to end.
final class WeekOpeningsTests: XCTestCase {
    private let stage2Opened = StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))

    /// Scenario: Week 6 of regular eating begins.
    func testWeek6OfRegularEatingBegins() {
        let s = Programme.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 11, 9, 5), restartAt: nil, currentRecordDay: dayKey(2026, 11, 9), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.takingStock))
        XCTAssertEqual(s.stageOpenedMoment[.takingStock], moment(2026, 11, 9, 4))
    }

    /// Scenario: Week 10 of regular eating begins.
    func testWeek10OfRegularEatingBegins() {
        let s = Programme.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 12, 7, 5), restartAt: nil, currentRecordDay: dayKey(2026, 12, 7), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.stayingOnTrack))
        XCTAssertEqual(s.stageOpenedMoment[.stayingOnTrack], moment(2026, 12, 7, 4))
    }

    /// Scenario: A slow starter.
    func testASlowStarter() {
        let settings = ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 4)
        let s = Programme.state(facts: ProgrammeFacts(), openings: [], settings: settings, constants: .default, now: moment(2026, 11, 23, 5), restartAt: nil, currentRecordDay: dayKey(2026, 11, 23), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.regularEating))
        XCTAssertFalse(s.isOpen(.takingStock))
        XCTAssertFalse(s.isOpen(.stayingOnTrack))
    }

    /// Scenario: Taking stock recommends "Food rules".
    func testTakingStockRecommendsFoodRules() {
        let facts = ProgrammeFacts(takingStockCompletedAt: moment(2026, 11, 20, 10))
        let s = Programme.state(facts: facts, openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 11, 20, 11), restartAt: nil, currentRecordDay: dayKey(2026, 11, 20), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.modules))
        XCTAssertEqual(Stage.modules.toolNames, ["Food rules", "Body image"], "both modules open together")
    }

    /// Scenario: Week 10 of regular eating without taking stock.
    func testWeek10OfRegularEatingWithoutTakingStock() {
        let s = Programme.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 12, 7, 5), restartAt: nil, currentRecordDay: dayKey(2026, 12, 7), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.stayingOnTrack))
        XCTAssertFalse(s.isOpen(.modules))
    }

    /// Scenario: Taking stock after a restart.
    func testTakingStockAfterARestart() {
        let everyStageOpenBeforeRestart: [StageOpenedRecord] = [
            StageOpenedRecord(stage: 1, moment: moment(2026, 9, 28, 4)),
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 3, 9)),
            StageOpenedRecord(stage: 3, moment: moment(2026, 10, 10, 4)),
            StageOpenedRecord(stage: 4, moment: moment(2026, 10, 17, 9)),
            StageOpenedRecord(stage: 5, moment: moment(2026, 11, 14, 4)), // before the restart
            StageOpenedRecord(stage: 6, moment: moment(2026, 11, 20, 10)),
            StageOpenedRecord(stage: 7, moment: moment(2026, 12, 12, 4)),
        ]
        let restartAt = moment(2027, 1, 4, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2027, 1, 4), dayStart: 4)

        let atRestart = Programme.state(facts: ProgrammeFacts(), openings: everyStageOpenBeforeRestart, settings: settings, constants: .default, now: restartAt, restartAt: restartAt, currentRecordDay: dayKey(2027, 1, 4), calendar: engineTestCalendar)
        XCTAssertFalse(atRestart.isOpen(.takingStock), "the earlier stage 5 opening is ignored")
        XCTAssertTrue(atRestart.isOpen(.modules))
        XCTAssertTrue(atRestart.isOpen(.stayingOnTrack))

        let atWeek6FromTheNewStartDay = Programme.state(facts: ProgrammeFacts(), openings: everyStageOpenBeforeRestart, settings: settings, constants: .default, now: moment(2027, 2, 8, 5), restartAt: restartAt, currentRecordDay: dayKey(2027, 2, 8), calendar: engineTestCalendar)
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.takingStock))
        XCTAssertEqual(atWeek6FromTheNewStartDay.stageOpenedMoment[.takingStock], moment(2027, 2, 8, 4))
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.modules), "stages 6 and 7 stay open throughout")
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.stayingOnTrack))
    }
}
