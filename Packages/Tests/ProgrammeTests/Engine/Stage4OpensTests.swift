import XCTest
@testable import Programme

/// Covers programme spec.md, "Stage 4 opens after the first urge outcome or
/// seven recorded days" (mm-t21.6). Every test opens stage 3 first, since
/// the tool that saves an urge outcome only exists once stage 3 is open.
final class Stage4OpensTests: XCTestCase {
    private let stage3Opened = StageOpenedRecord(stage: 3, moment: moment(2026, 10, 1, 4))

    /// Scenario: The first outcome is "It passed".
    func testTheFirstOutcomeIsItPassed() {
        let outcome = UrgeOutcomeFact(dayKey: dayKey(2026, 10, 2), savedAt: moment(2026, 10, 2, 15))
        let s = StageEngine.state(facts: ProgrammeFacts(urgeOutcomes: [outcome]), openings: [stage3Opened], settings: defaultSettings, constants: .default, now: moment(2026, 10, 2, 16), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.problemSolving))
    }

    /// Scenario: The first outcome is "I binged". Any of the three outcomes
    /// opens the stage; `Programme` does not distinguish them.
    func testTheFirstOutcomeIsIBinged() {
        let outcome = UrgeOutcomeFact(dayKey: dayKey(2026, 10, 2), savedAt: moment(2026, 10, 2, 21, 30))
        let s = StageEngine.state(facts: ProgrammeFacts(urgeOutcomes: [outcome]), openings: [stage3Opened], settings: defaultSettings, constants: .default, now: moment(2026, 10, 2, 22), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.problemSolving))
        XCTAssertEqual(s.stageOpenedMoment[.problemSolving], moment(2026, 10, 2, 21, 30))
    }

    /// Scenario: A timer with no outcome.
    func testATimerWithNoOutcomeStage4StaysClosed() {
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [stage3Opened], settings: defaultSettings, constants: .default, now: moment(2026, 10, 2), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.problemSolving))
    }

    /// Scenario: Seven recorded days without an urge outcome.
    func testSevenRecordedDaysWithoutAnUrgeOutcome() {
        // Stage 3 opened Monday 12 October 2026; entries on each day up to
        // Sunday 18 October.
        let stage3 = StageOpenedRecord(stage: 3, moment: moment(2026, 10, 12, 4))
        let entries = (0..<7).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, 12 + i), starred: false, savedAt: moment(2026, 10, 12 + i, 9)) }
        let s = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [stage3], settings: defaultSettings, constants: .default, now: moment(2026, 10, 18, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 18), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.problemSolving))
        XCTAssertEqual(s.stageOpenedMoment[.problemSolving], moment(2026, 10, 18, 9), "the first entry on the seventh day, 18 October")
    }

    /// Scenario: An outcome before the seventh day.
    func testAnOutcomeBeforeTheSeventhDay() {
        let stage3 = StageOpenedRecord(stage: 3, moment: moment(2026, 10, 12, 4))
        let outcome = UrgeOutcomeFact(dayKey: dayKey(2026, 10, 14), savedAt: moment(2026, 10, 14, 12))
        let s = StageEngine.state(facts: ProgrammeFacts(urgeOutcomes: [outcome]), openings: [stage3], settings: defaultSettings, constants: .default, now: moment(2026, 10, 14, 13), restartAt: nil, currentRecordDay: dayKey(2026, 10, 14), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.problemSolving))
        XCTAssertEqual(s.stageOpenedMoment[.problemSolving], moment(2026, 10, 14, 12))
    }
}
