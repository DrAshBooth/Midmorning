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
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 11, 9, 5), restartAt: nil, currentRecordDay: dayKey(2026, 11, 9), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.takingStock))
        XCTAssertEqual(s.stageOpenedMoment[.takingStock], moment(2026, 11, 9, 4))
    }

    /// Scenario: Week 10 of regular eating begins.
    func testWeek10OfRegularEatingBegins() {
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 12, 7, 5), restartAt: nil, currentRecordDay: dayKey(2026, 12, 7), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.stayingOnTrack))
        XCTAssertEqual(s.stageOpenedMoment[.stayingOnTrack], moment(2026, 12, 7, 4))
    }

    /// Scenario: A slow starter.
    func testASlowStarter() {
        let settings = ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 4)
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [], settings: settings, constants: .default, now: moment(2026, 11, 23, 5), restartAt: nil, currentRecordDay: dayKey(2026, 11, 23), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.regularEating))
        XCTAssertFalse(s.isOpen(.takingStock))
        XCTAssertFalse(s.isOpen(.stayingOnTrack))
    }

    /// Scenario: Taking stock recommends "Food rules".
    func testTakingStockRecommendsFoodRules() {
        let facts = ProgrammeFacts(takingStockCompletedAt: moment(2026, 11, 20, 10))
        let s = StageEngine.state(facts: facts, openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 11, 20, 11), restartAt: nil, currentRecordDay: dayKey(2026, 11, 20), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.modules))
        XCTAssertEqual(Stage.modules.tools.map(\.label.english), ["Food rules", "Body image"], "both modules open together")
    }

    /// Scenario: Week 10 of regular eating without taking stock.
    func testWeek10OfRegularEatingWithoutTakingStock() {
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2Opened], settings: defaultSettings, constants: .default, now: moment(2026, 12, 7, 5), restartAt: nil, currentRecordDay: dayKey(2026, 12, 7), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.stayingOnTrack))
        XCTAssertFalse(s.isOpen(.modules))
    }

    /// A restart in week 1, before stage 2 opens (code review of 26
    /// September 2026, mm-t21.27): "While stage 2 is closed, stages 5 and 7
    /// MUST stay closed." Six weeks after the new start day, with one
    /// recorded day, the engine opens neither and computes no opening.
    func testARestartBeforeStage2KeepsStages5And7Closed() {
        let restartAt = moment(2026, 10, 1, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2026, 10, 1), dayStart: 4)
        let facts = ProgrammeFacts(entries: [EntryFact(id: "e1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 10))])
        let s = StageEngine.state(facts: facts, openings: [], settings: settings, constants: .default, now: moment(2026, 11, 6, 9), restartAt: restartAt, currentRecordDay: dayKey(2026, 11, 6), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.regularEating))
        XCTAssertFalse(s.isOpen(.takingStock), "stage 5 stays closed while stage 2 is closed")
        XCTAssertFalse(s.isOpen(.stayingOnTrack))
        XCTAssertTrue(s.computedOpenings.allSatisfy { $0.stage != Stage.takingStock.rawValue && $0.stage != Stage.stayingOnTrack.rawValue }, "no opening for stage 5 or 7 is computed")
        XCTAssertNil(s.weekOfRegularEating)
    }

    /// After that restart, stage 2 opens later. The weeks of regular eating
    /// then count from the later of the new start day and stage 2's day,
    /// here stage 2's day, so taking stock comes after five full weeks of
    /// regular eating (r14-02, mm-t21.36). Before r14-02 the engine counted
    /// from the new start day and opened stage 5 on 5 November, after four
    /// weeks of regular eating.
    func testAfterARestartBeforeStage2TheWeekOfRegularEatingCountsFromStage2sDay() {
        let restartAt = moment(2026, 10, 1, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2026, 10, 1), dayStart: 4)
        let stage2 = StageOpenedRecord(stage: 2, moment: moment(2026, 10, 8, 9))

        let on5November = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2], settings: settings, constants: .default, now: moment(2026, 11, 5, 9), restartAt: restartAt, currentRecordDay: dayKey(2026, 11, 5), calendar: engineTestCalendar)
        XCTAssertEqual(on5November.weekOfRegularEating, 5, "5 November is in week 5 from 8 October")
        XCTAssertFalse(on5November.isOpen(.takingStock))
        XCTAssertTrue(on5November.computedOpenings.allSatisfy { $0.stage != Stage.takingStock.rawValue })

        let on12November = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2], settings: settings, constants: .default, now: moment(2026, 11, 12, 5), restartAt: restartAt, currentRecordDay: dayKey(2026, 11, 12), calendar: engineTestCalendar)
        XCTAssertEqual(on12November.weekOfRegularEating, 6, "12 November is in week 6 from 8 October")
        XCTAssertTrue(on12November.isOpen(.takingStock))
        XCTAssertEqual(on12November.stageOpenedMoment[.takingStock], moment(2026, 11, 12, 4))
    }

    /// r14-02 (mm-t21.36): when stage 2 opens more than five weeks after
    /// the new start day, stage 5 does not open at the same moment as
    /// stage 2. It opens five full weeks after stage 2's day.
    func testAfterARestartALateStage2DoesNotOpenStage5AtTheSameMoment() {
        let restartAt = moment(2026, 10, 1, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2026, 10, 1), dayStart: 4)
        let stage2 = StageOpenedRecord(stage: 2, moment: moment(2026, 11, 20, 9))

        let atStage2 = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2], settings: settings, constants: .default, now: moment(2026, 11, 20, 10), restartAt: restartAt, currentRecordDay: dayKey(2026, 11, 20), calendar: engineTestCalendar)
        XCTAssertTrue(atStage2.isOpen(.regularEating))
        XCTAssertFalse(atStage2.isOpen(.takingStock), "stage 5 waits for five full weeks of regular eating")
        XCTAssertEqual(atStage2.weekOfRegularEating, 1)

        let fiveWeeksLater = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2], settings: settings, constants: .default, now: moment(2026, 12, 25, 5), restartAt: restartAt, currentRecordDay: dayKey(2026, 12, 25), calendar: engineTestCalendar)
        XCTAssertEqual(fiveWeeksLater.stageOpenedMoment[.takingStock], moment(2026, 12, 25, 4))
    }

    /// r14-02 (mm-t21.36): the basis is the later of the two days. Stage 2
    /// opened before the restart, so the new start day is the later day.
    func testTheBasisIsTheLaterOfTheNewStartDayAndStage2sDay() {
        XCTAssertEqual(StageEngine.regularEatingBasis(stage2Day: dayKey(2026, 10, 5), restartAt: nil, startDay: dayKey(2027, 1, 4)), dayKey(2026, 10, 5), "no restart: stage 2's day")
        XCTAssertEqual(StageEngine.regularEatingBasis(stage2Day: dayKey(2026, 10, 5), restartAt: moment(2027, 1, 4, 9), startDay: dayKey(2027, 1, 4)), dayKey(2027, 1, 4), "stage 2 before the restart: the new start day")
        XCTAssertEqual(StageEngine.regularEatingBasis(stage2Day: dayKey(2026, 10, 8), restartAt: moment(2026, 10, 1, 9), startDay: dayKey(2026, 10, 1)), dayKey(2026, 10, 8), "stage 2 after the restart: stage 2's day")
        XCTAssertNil(StageEngine.regularEatingBasis(stage2Day: nil, restartAt: moment(2026, 10, 1, 9), startDay: dayKey(2026, 10, 1)), "stage 2 closed: no basis")
    }

    /// r14-02 (mm-t21.36): stage 7 is also a week-based stage. After a
    /// restart before stage 7 opens, stage 7 counts its weeks of regular
    /// eating from the same basis as stage 5.
    func testAfterARestartStage7CountsFromTheSameBasis() {
        let openings = [
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9)),
            StageOpenedRecord(stage: 5, moment: moment(2026, 11, 9, 4)),
        ]
        let restartAt = moment(2026, 11, 23, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2026, 11, 23), dayStart: 4)

        let on7December = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: settings, constants: .default, now: moment(2026, 12, 7, 5), restartAt: restartAt, currentRecordDay: dayKey(2026, 12, 7), calendar: engineTestCalendar)
        XCTAssertFalse(on7December.isOpen(.stayingOnTrack), "week 10 from stage 2's day is not week 10 from the new start day")

        let week10FromTheNewStartDay = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: settings, constants: .default, now: moment(2027, 1, 25, 5), restartAt: restartAt, currentRecordDay: dayKey(2027, 1, 25), calendar: engineTestCalendar)
        XCTAssertEqual(week10FromTheNewStartDay.stageOpenedMoment[.stayingOnTrack], moment(2027, 1, 25, 4))
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

        let atRestart = StageEngine.state(facts: ProgrammeFacts(), openings: everyStageOpenBeforeRestart, settings: settings, constants: .default, now: restartAt, restartAt: restartAt, currentRecordDay: dayKey(2027, 1, 4), calendar: engineTestCalendar)
        XCTAssertFalse(atRestart.isOpen(.takingStock), "the earlier stage 5 opening is ignored")
        XCTAssertTrue(atRestart.isOpen(.modules))
        XCTAssertTrue(atRestart.isOpen(.stayingOnTrack))

        let atWeek6FromTheNewStartDay = StageEngine.state(facts: ProgrammeFacts(), openings: everyStageOpenBeforeRestart, settings: settings, constants: .default, now: moment(2027, 2, 8, 5), restartAt: restartAt, currentRecordDay: dayKey(2027, 2, 8), calendar: engineTestCalendar)
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.takingStock))
        XCTAssertEqual(atWeek6FromTheNewStartDay.stageOpenedMoment[.takingStock], moment(2027, 2, 8, 4))
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.modules), "stages 6 and 7 stay open throughout")
        XCTAssertTrue(atWeek6FromTheNewStartDay.isOpen(.stayingOnTrack))
    }
}
