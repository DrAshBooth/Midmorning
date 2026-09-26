import XCTest
import Constants
@testable import Programme

/// Covers programme spec.md, "A pure stage engine with stored openings as
/// input" (mm-t21.19).
final class PureStageEngineTests: XCTestCase {
    /// Scenario: Stored moment without the entries.
    func testStoredMomentWithoutTheEntries() {
        let facts = ProgrammeFacts(entries: [
            EntryFact(id: "1", dayKey: dayKey(2026, 9, 29), starred: false, savedAt: moment(2026, 9, 29, 9)),
            EntryFact(id: "2", dayKey: dayKey(2026, 9, 30), starred: false, savedAt: moment(2026, 9, 30, 9)),
        ])
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 9))]
        let state = StageEngine.state(
            facts: facts, openings: openings, settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 2), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar
        )
        XCTAssertTrue(state.isOpen(.regularEating))
        XCTAssertTrue(state.computedOpenings.isEmpty, "the stored row already covers it")
    }

    /// Scenario: A computed opening.
    func testAComputedOpening() {
        let entries = (0..<5).map { i in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 9))
        }
        let state = StageEngine.state(
            facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 3, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar
        )
        XCTAssertTrue(state.isOpen(.regularEating))
        XCTAssertEqual(state.computedOpenings, [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 3, 9))])
    }

    /// Scenario: The scan is bounded.
    func testTheScanIsBounded() {
        let stage3Opening = moment(2026, 10, 12, 4)
        // Entries and an urge outcome dated before the stored stage 3
        // opening — six distinct days, one short of the stage 4 fallback,
        // and all irrelevant to the bound.
        let earlyEntries = (0..<6).map { i in
            EntryFact(id: "early\(i)", dayKey: dayKey(2026, 10, 1 + i), starred: false, savedAt: moment(2026, 10, 1 + i, 9))
        }
        let earlyOutcome = UrgeOutcomeFact(dayKey: dayKey(2026, 10, 1), savedAt: moment(2026, 10, 1, 10))
        let facts = ProgrammeFacts(entries: earlyEntries, urgeOutcomes: [earlyOutcome])
        let openings = [StageOpenedRecord(stage: 3, moment: stage3Opening)]
        let state = StageEngine.state(
            facts: facts, openings: openings, settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 13), restartAt: nil, currentRecordDay: dayKey(2026, 10, 13), calendar: engineTestCalendar
        )
        XCTAssertFalse(state.isOpen(.problemSolving), "facts dated before the stored stage 3 opening do not open stage 4")
    }

    /// Scenario: A computed moment is the day start that ended the gate.
    func testAComputedMomentIsTheDayStartThatEndedTheGate() {
        let stage2Day = dayKey(2026, 9, 29)
        let plannedRecorded = (0..<7).map { i in
            (plan: PlannedDayFact(dayKey: dayKey(2026, 9, 29 + i)), entry: EntryFact(id: "p\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 9)))
        }
        let facts = ProgrammeFacts(entries: plannedRecorded.map(\.entry), plannedDays: plannedRecorded.map(\.plan))
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 9, 29, 9))]
        let state = StageEngine.state(
            facts: facts, openings: openings, settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 6, 9, 15), restartAt: nil, currentRecordDay: stage2Day, calendar: engineTestCalendar
        )
        // The seventh planned+recorded day is 2026-10-05; the day start that
        // ends it is 04:00 on 2026-10-06, not 09:15.
        XCTAssertEqual(state.stageOpenedMoment[.alternatives], moment(2026, 10, 6, 4))
    }

    /// Scenario: A computed moment is the save moment.
    func testAComputedMomentIsTheSaveMoment() {
        let entries = (0..<5).map { i in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, 2 + i), starred: false, savedAt: moment(2026, 10, 2 + i, 13, 2))
        }
        let state = StageEngine.state(
            facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 7), restartAt: nil, currentRecordDay: dayKey(2026, 10, 7), calendar: engineTestCalendar
        )
        XCTAssertEqual(state.stageOpenedMoment[.regularEating], moment(2026, 10, 6, 13, 2))
    }

    /// Scenario: The same inputs twice.
    func testTheSameInputsTwice() {
        let entries = (0..<5).map { i in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 9))
        }
        let facts = ProgrammeFacts(entries: entries)
        func run() -> ProgrammeState {
            StageEngine.state(facts: facts, openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 3), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        }
        XCTAssertEqual(run(), run())
    }

    /// Scenario: A future-dated opening.
    func testAFutureDatedOpening() {
        let openings = [StageOpenedRecord(stage: 5, moment: moment(2026, 11, 9, 4))]
        let state = StageEngine.state(
            facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default,
            now: moment(2026, 11, 3, 10), restartAt: nil, currentRecordDay: dayKey(2026, 11, 3), calendar: engineTestCalendar
        )
        XCTAssertFalse(state.isOpen(.takingStock))
    }

    /// Scenario: A stage 5 opening before the restart.
    func testAStage5OpeningBeforeTheRestart() {
        let openings = [StageOpenedRecord(stage: 5, moment: moment(2026, 11, 9, 4))]
        let restartAt = moment(2027, 1, 4, 9)
        let settings = ProgrammeSettings(startDay: dayKey(2027, 1, 4), dayStart: 4)
        let state = StageEngine.state(
            facts: ProgrammeFacts(), openings: openings, settings: settings, constants: .default,
            now: moment(2027, 1, 4, 9), restartAt: restartAt, currentRecordDay: dayKey(2027, 1, 4), calendar: engineTestCalendar
        )
        XCTAssertFalse(state.isOpen(.takingStock), "the pre-restart opening is ignored")
    }
}

/// Covers programme spec.md, "The app keeps the stage state" (mm-t21.20):
/// the scenarios the pure engine itself proves. The store-level scenarios
/// ("The opening stays in the store", "Restart of the app", "Delete-all")
/// live in `RecordTests.ProgrammeStoreTests`.
final class AppKeepsTheStageStateTests: XCTestCase {
    /// Scenario: Entries deleted after stage 2 opened. A stored opening
    /// stays open however few entries the facts now hold.
    func testEntriesDeletedAfterStage2OpenedStageStaysOpen() {
        let facts = ProgrammeFacts(entries: [EntryFact(id: "1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 9))])
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 9))]
        let state = StageEngine.state(facts: facts, openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 2), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar)
        XCTAssertTrue(state.isOpen(.regularEating))
    }

    /// Scenario: The first urge outcome deleted. A stored stage 4 opening
    /// stays open with no urge outcome in the facts at all.
    func testTheFirstUrgeOutcomeDeletedStage4StaysOpen() {
        let openings = [StageOpenedRecord(stage: 3, moment: moment(2026, 10, 1, 4)), StageOpenedRecord(stage: 4, moment: moment(2026, 10, 5, 9))]
        let state = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 6), restartAt: nil, currentRecordDay: dayKey(2026, 10, 6), calendar: engineTestCalendar)
        XCTAssertTrue(state.isOpen(.problemSolving))
    }

    /// Scenario: Restart of the app. Running the engine again with the same
    /// stored inputs reports the same open stage, the same as the app
    /// closing and reopening.
    func testRestartOfTheAppStage3StaysOpen() {
        let openings = [StageOpenedRecord(stage: 3, moment: moment(2026, 10, 1, 4))]
        func run() -> Bool {
            StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 2), restartAt: nil, currentRecordDay: dayKey(2026, 10, 2), calendar: engineTestCalendar).isOpen(.alternatives)
        }
        XCTAssertTrue(run())
        XCTAssertTrue(run())
    }

    /// Scenario: Two devices open one stage.
    func testTwoDevicesOpenOneStage() {
        let openings = [
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 6, 13, 2)),
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 6, 18, 40)),
        ]
        let state = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 7), restartAt: nil, currentRecordDay: dayKey(2026, 10, 7), calendar: engineTestCalendar)
        XCTAssertEqual(state.stageOpenedMoment[.regularEating], moment(2026, 10, 6, 13, 2))
    }

    /// Scenario: The clock moves back past an opening.
    func testTheClockMovesBackPastAnOpening() {
        let openings = [StageOpenedRecord(stage: 5, moment: moment(2026, 11, 9, 4))]
        let movedBack = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 11, 3), restartAt: nil, currentRecordDay: dayKey(2026, 11, 3), calendar: engineTestCalendar)
        XCTAssertFalse(movedBack.isOpen(.takingStock), "the engine ignores it until the clock passes its moment")

        let clockPassesItAgain = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 11, 10), restartAt: nil, currentRecordDay: dayKey(2026, 11, 10), calendar: engineTestCalendar)
        XCTAssertTrue(clockPassesItAgain.isOpen(.takingStock), "the store kept the row, so stage 5 opens again at its own moment")
        XCTAssertEqual(clockPassesItAgain.stageOpenedMoment[.takingStock], moment(2026, 11, 9, 4))
    }
}
