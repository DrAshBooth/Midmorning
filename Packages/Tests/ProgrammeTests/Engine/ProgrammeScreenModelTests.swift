import XCTest
import Constants
@testable import Programme

/// Covers programme spec.md, "The Programme screen shows where the person
/// is" and "The stage screen" (mm-t21.16). "Get support on the stage screen"
/// and "VoiceOver on the stage screen" are screen-level checks the App
/// target's own view proves.
final class ProgrammeScreenModelTests: XCTestCase {
    private let fullBuild: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    private let firstCutBuild: Set<Int> = [1, 2]

    private func state(openStages: [Int], startDay: String = dayKey(2026, 9, 28), now: Date, currentRecordDay: String, restartAt: Date? = nil) -> ProgrammeState {
        let openings = openStages.map { StageOpenedRecord(stage: $0, moment: moment(2026, 9, 28)) }
        return StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: ProgrammeSettings(startDay: startDay, dayStart: 4), constants: .default, now: now, restartAt: restartAt, currentRecordDay: currentRecordDay, calendar: engineTestCalendar)
    }

    /// A `ProgrammeState` built directly, for a scenario that names an exact
    /// open/closed combination without describing the facts that produced
    /// it: letting the real engine run its own gates over a long-elapsed
    /// `now` risks a later stage's own fallback firing too, which the
    /// screen-model tests are not about.
    private func directState(open: [Stage], week: Int? = 1, recordedDaysCount: Int = 0) -> ProgrammeState {
        var stageMoment: [Stage: Date] = [:]
        var stageDayKey: [Stage: String] = [:]
        for stage in open {
            stageMoment[stage] = moment(2026, 1, 1)
            stageDayKey[stage] = dayKey(2026, 1, 1)
        }
        return ProgrammeState(openStages: Set(open), stageOpenedMoment: stageMoment, stageOpenedDayKey: stageDayKey, computedOpenings: [], week: week, weekOfRegularEating: nil, recordedDaysCount: recordedDaysCount)
    }

    // MARK: The Programme screen

    /// Scenario: Day 1.
    func testDay1() {
        let s = state(openStages: [1], now: moment(2026, 9, 28), currentRecordDay: dayKey(2026, 9, 28))
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: fullBuild)
        XCTAssertEqual(screen.weekLine, "Week 1")
        XCTAssertTrue(screen.rows.first { $0.stage == .gettingStarted }!.isNow)
        for row in screen.rows.dropFirst() {
            XCTAssertNotNil(row.ruleString, "\(row.stage) shows its rule string")
        }
    }

    /// Scenario: A slow starter in week 3.
    func testASlowStarterInWeek3() {
        let entries = [dayKey(2026, 10, 10), dayKey(2026, 10, 11), dayKey(2026, 10, 12)]
        let facts = ProgrammeFacts(entries: entries.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 10, 9)) })
        let s = StageEngine.state(facts: facts, openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 13), restartAt: nil, currentRecordDay: dayKey(2026, 10, 13), calendar: engineTestCalendar)
        XCTAssertEqual(s.week, 3)
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: fullBuild)
        XCTAssertEqual(screen.weekLine, "Week 3")
        XCTAssertTrue(screen.rows.first { $0.stage == .gettingStarted }!.isNow)
        XCTAssertEqual(screen.rows.first { $0.stage == .regularEating }!.ruleString, "Opens after 5 recorded days. You have 3.")
    }

    /// Scenario: A slow starter in week 8.
    func testASlowStarterInWeek8() {
        let entries = (1...4).map { dayKey(2026, 10, $0) }
        let facts = ProgrammeFacts(entries: entries.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) })
        // Week 8 begins 49 days after the start day, 28 September 2026: 16 November 2026.
        let s = StageEngine.state(facts: facts, openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 11, 16), restartAt: nil, currentRecordDay: dayKey(2026, 11, 16), calendar: engineTestCalendar)
        XCTAssertEqual(s.week, 8)
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: fullBuild)
        XCTAssertEqual(screen.weekLine, "Week 8")
        XCTAssertEqual(screen.rows.first { $0.stage == .regularEating }!.ruleString, "Opens after 5 recorded days. You have 4.")
        XCTAssertEqual(screen.rows.first { $0.stage == .takingStock }!.ruleString, "Opens 6 weeks after your plan starts")
    }

    /// Scenario: Stage 5 open with stage 3 closed.
    func testStage5OpenWithStage3Closed() {
        let s = directState(open: [.gettingStarted, .regularEating, .takingStock])
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: fullBuild)
        XCTAssertTrue(screen.rows.first { $0.stage == .regularEating }!.isNow)
        XCTAssertEqual(screen.rows.filter(\.isNow).count, 1)
    }

    /// Scenario: The stage 6 row.
    func testTheStage6Row() {
        XCTAssertEqual(Stage.modules.toolNames, ["Food rules", "Body image"])
        XCTAssertFalse(Stage.orderedByStage.contains { $0.toolNames.contains { $0.localizedCaseInsensitiveContains("dieting") } })
    }

    /// Scenario: Every stage open.
    func testEveryStageOpen() {
        let s = directState(open: Stage.orderedByStage)
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: fullBuild)
        XCTAssertTrue(screen.rows.last!.isNow)
        XCTAssertEqual(screen.rows.filter(\.isNow).count, 1)
        XCTAssertTrue(screen.rows.allSatisfy { $0.ruleString == nil })
    }

    /// Scenario: The marker after a restart.
    func testTheMarkerAfterARestart() {
        let restartAt = moment(2027, 1, 4, 9)
        let s = state(openStages: [1, 2, 3, 4, 6, 7], startDay: dayKey(2027, 1, 4), now: moment(2027, 1, 18), currentRecordDay: dayKey(2027, 1, 18), restartAt: restartAt)
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: restartAt, stagesWithToolInBuild: fullBuild)
        XCTAssertTrue(screen.rows.first { $0.stage == .takingStock }!.isNow)
        XCTAssertEqual(screen.rows.first { $0.stage == .takingStock }!.ruleString, "Opens 6 weeks after your plan starts")
        XCTAssertEqual(screen.rows.filter(\.isNow).count, 1)
    }

    /// Scenario: Stages without their tools in the build.
    func testStagesWithoutTheirToolsInTheBuild() {
        let s = directState(open: [.gettingStarted, .regularEating, .alternatives, .problemSolving])
        let screen = ProgrammeScreenBuilder.build(state: s, constants: .default, restartAt: nil, stagesWithToolInBuild: firstCutBuild)
        XCTAssertTrue(screen.rows.first { $0.stage == .regularEating }!.isNow)
        for row in screen.rows where row.stage.rawValue >= 3 {
            XCTAssertTrue(row.comesInALaterVersion)
            XCTAssertFalse(row.isNow)
            XCTAssertFalse(row.isTappable)
        }
    }

    // MARK: The stage screen

    /// Scenario: The stage 1 screen.
    func testTheStage1Screen() {
        let s = state(openStages: [1], now: moment(2026, 9, 30), currentRecordDay: dayKey(2026, 9, 30))
        let screen = StageScreenBuilder.build(stage: .gettingStarted, state: s, constants: .default, settings: ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 4), currentRecordDay: dayKey(2026, 9, 30), calendar: engineTestCalendar)
        XCTAssertEqual(screen.title, "Getting started")
        XCTAssertEqual(screen.line, "Opened in week 1")
        XCTAssertEqual(screen.toolNames, ["Weigh-in"])
    }

    /// Scenario: A closed stage's screen.
    func testAClosedStagesScreen() {
        let entries = [dayKey(2026, 10, 1), dayKey(2026, 10, 2)]
        let facts = ProgrammeFacts(entries: entries.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) })
        let s = StageEngine.state(facts: facts, openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 3), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        let screen = StageScreenBuilder.build(stage: .regularEating, state: s, constants: .default, settings: defaultSettings, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        XCTAssertEqual(screen.title, "Regular eating")
        XCTAssertEqual(screen.line, "Opens after 5 recorded days. You have 2.")
        XCTAssertTrue(screen.toolNames.isEmpty)
    }

    /// Scenario: An open stage's screen.
    func testAnOpenStagesScreen() {
        let settings = ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 4)
        let openings = [StageOpenedRecord(stage: 1, moment: moment(2026, 9, 28)), StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: settings, constants: .default, now: moment(2026, 10, 20), restartAt: nil, currentRecordDay: dayKey(2026, 10, 20), calendar: engineTestCalendar)
        let screen = StageScreenBuilder.build(stage: .regularEating, state: s, constants: .default, settings: settings, currentRecordDay: dayKey(2026, 10, 20), calendar: engineTestCalendar)
        XCTAssertEqual(screen.line, "Opened in week 2")
        XCTAssertEqual(screen.toolNames, ["Plan"])
    }

    /// Scenario: A tool row: `Stage.toolNames` names the row a tap opens;
    /// the app target's own view wires "Plan" to the plan builder.
    func testATooRow() {
        XCTAssertEqual(Stage.regularEating.toolNames, ["Plan"])
    }

    /// Scenario: The stage 1 screen before week 1.
    func testTheStage1ScreenBeforeWeek1() {
        let tomorrow = dayKey(2026, 9, 29)
        let settings = ProgrammeSettings(startDay: tomorrow, dayStart: 4)
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [], settings: settings, constants: .default, now: moment(2026, 9, 28), restartAt: nil, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar)
        let screen = StageScreenBuilder.build(stage: .gettingStarted, state: s, constants: .default, settings: settings, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar)
        XCTAssertNil(screen.line)
        XCTAssertEqual(screen.toolNames, ["Weigh-in"])
    }

    /// Scenario: A stage that opened before a restart.
    func testAStageThatOpenedBeforeARestart() {
        let settings = ProgrammeSettings(startDay: dayKey(2027, 1, 4), dayStart: 4)
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: settings, constants: .default, now: moment(2027, 1, 6), restartAt: moment(2027, 1, 4, 9), currentRecordDay: dayKey(2027, 1, 6), calendar: engineTestCalendar)
        let screen = StageScreenBuilder.build(stage: .regularEating, state: s, constants: .default, settings: settings, currentRecordDay: dayKey(2027, 1, 6), calendar: engineTestCalendar)
        XCTAssertNil(screen.line)
        XCTAssertEqual(screen.toolNames, ["Plan"])
    }
}
