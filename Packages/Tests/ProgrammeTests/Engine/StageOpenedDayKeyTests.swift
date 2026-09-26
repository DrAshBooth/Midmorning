import XCTest
@testable import Programme

/// r14-03 (mm-t21.37): each `StageOpened` row keeps the record-day key of
/// the day on which the stage opened. The engine reads that key as the
/// stage's day. A later change of "Day starts at" then does not move the
/// day. An old row with no key falls back to the record day that contains
/// its moment, with the day start in force.
final class StageOpenedDayKeyTests: XCTestCase {
    /// Stage 2 opened at 04:30 on Friday 9 October 2026 with the day start
    /// 04:00, so its record day is 9 October. The person then sets 05:00.
    private let stage2Moment = moment(2026, 10, 9, 4, 30)
    private let laterSettings = ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 5)

    func testAStoredKeyKeepsTheStagesDayAfterTheDayStartChanges() {
        let openings = [StageOpenedRecord(stage: 2, moment: stage2Moment, dayKey: dayKey(2026, 10, 9))]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: laterSettings, constants: .default, now: moment(2026, 10, 23, 6), restartAt: nil, currentRecordDay: dayKey(2026, 10, 23), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedDayKey[.regularEating], dayKey(2026, 10, 9), "the stored key, not the day that 05:00 gives")
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 23, 5), "the stage 3 fallback counts 14 record days from 9 October")
    }

    func testAnOldRowWithNoKeyFallsBackToTheDayStartInForce() {
        let openings = [StageOpenedRecord(stage: 2, moment: stage2Moment)]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: laterSettings, constants: .default, now: moment(2026, 10, 23, 6), restartAt: nil, currentRecordDay: dayKey(2026, 10, 23), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedDayKey[.regularEating], dayKey(2026, 10, 8), "04:30 is before the 05:00 day start, so the day is 8 October")
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 22, 5))
    }

    func testAnEmptyKeyFallsBackToTheDayStartInForce() {
        let openings = [StageOpenedRecord(stage: 2, moment: stage2Moment, dayKey: "")]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: laterSettings, constants: .default, now: moment(2026, 10, 12), restartAt: nil, currentRecordDay: dayKey(2026, 10, 11), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedDayKey[.regularEating], dayKey(2026, 10, 8))
    }

    /// A computed opening carries its record-day key, so the app writes the
    /// key with the row. The fifth recorded day's first entry is saved at
    /// 02:00 on 4 October, before the 04:00 day start, so stage 2's day is
    /// 3 October.
    func testAComputedOpeningCarriesItsRecordDayKey() {
        var entries = (0..<4).map { i in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 9))
        }
        entries.append(EntryFact(id: "4", dayKey: dayKey(2026, 10, 3), starred: false, savedAt: moment(2026, 10, 4, 2)))
        let s = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 4, 3), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        XCTAssertEqual(s.computedOpenings, [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 4, 2), dayKey: dayKey(2026, 10, 3))])
        XCTAssertEqual(s.stageOpenedDayKey[.regularEating], dayKey(2026, 10, 3))
    }

    /// The engine reads the key of the row it uses: the earliest row that
    /// the ignore rules keep.
    func testTheEarliestRowGivesTheKey() {
        let openings = [
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 9, 18), dayKey: dayKey(2026, 10, 9)),
            StageOpenedRecord(stage: 2, moment: stage2Moment, dayKey: dayKey(2026, 10, 9)),
            StageOpenedRecord(stage: 2, moment: moment(2026, 10, 10, 9), dayKey: dayKey(2026, 10, 10)),
        ]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: laterSettings, constants: .default, now: moment(2026, 10, 12), restartAt: nil, currentRecordDay: dayKey(2026, 10, 11), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedMoment[.regularEating], stage2Moment)
        XCTAssertEqual(s.stageOpenedDayKey[.regularEating], dayKey(2026, 10, 9))
    }

    /// Stage 1's day is the start day ("For stage 1, that record day is the
    /// start day.").
    func testStage1sDayIsTheStartDay() {
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [], settings: laterSettings, constants: .default, now: moment(2026, 9, 29), restartAt: nil, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedDayKey[.gettingStarted], dayKey(2026, 9, 28))
    }
}
