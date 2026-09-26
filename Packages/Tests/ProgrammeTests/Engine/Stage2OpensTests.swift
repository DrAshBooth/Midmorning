import XCTest
@testable import Programme

/// Covers programme spec.md, "Stage 2 opens after five recorded days"
/// (mm-t21.4).
final class Stage2OpensTests: XCTestCase {
    private func state(_ entries: [EntryFact], now: Date) -> ProgrammeState {
        Programme.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default, now: now, restartAt: nil, currentRecordDay: dayKey(2026, 10, 20), calendar: engineTestCalendar)
    }

    /// Scenario: Five recorded days over two weeks.
    func testFiveRecordedDaysOverTwoWeeks() {
        // Monday, Wednesday, Friday, the next Tuesday, the next Thursday.
        let days = [dayKey(2026, 9, 28), dayKey(2026, 9, 30), dayKey(2026, 10, 2), dayKey(2026, 10, 6), dayKey(2026, 10, 8)]
        let savedAts = [moment(2026, 9, 28, 9), moment(2026, 9, 30, 9), moment(2026, 10, 2, 9), moment(2026, 10, 6, 9), moment(2026, 10, 8, 9)]
        let entries = zip(days, savedAts).enumerated().map { i, pair in EntryFact(id: "\(i)", dayKey: pair.0, starred: false, savedAt: pair.1) }
        let s = state(entries, now: moment(2026, 10, 8, 10))
        XCTAssertTrue(s.isOpen(.regularEating), "stage 2 opens when the entry on the second Thursday is saved")
        XCTAssertEqual(s.stageOpenedMoment[.regularEating], moment(2026, 10, 8, 9))
    }

    /// Scenario: Three recorded days in a week.
    func testThreeRecordedDaysInAWeek() {
        let days = (0..<3).map { dayKey(2026, 9, 28 + $0 * 2) } // three of seven calendar days
        let entries = days.enumerated().map { i, d in EntryFact(id: "\(i)", dayKey: d, starred: false, savedAt: moment(2026, 9, 28 + i * 2, 9)) }
        let s = state(entries, now: moment(2026, 10, 5))
        XCTAssertFalse(s.isOpen(.regularEating))
    }

    /// Scenario: An entry saved for the previous record day. The store
    /// assigns the record day; `Programme` only sees the resulting fact, and
    /// Thursday still counts toward the gate.
    func testAnEntrySavedForThePreviousRecordDay() {
        let thursday = dayKey(2026, 10, 1)
        let fridaySave = moment(2026, 10, 2, 7, 30) // backdated to Thursday's record day
        let others = (0..<4).map { i in EntryFact(id: "o\(i)", dayKey: dayKey(2026, 9, 27 + i), starred: false, savedAt: moment(2026, 9, 27 + i, 9)) }
        let backdated = EntryFact(id: "backdated", dayKey: thursday, starred: false, savedAt: fridaySave)
        let s = state(others + [backdated], now: moment(2026, 10, 2, 8))
        XCTAssertTrue(s.isOpen(.regularEating))
        XCTAssertEqual(s.recordedDaysCount, 5)
    }

    /// Scenario: Many entries on one day.
    func testManyEntriesOnOneDay() {
        let oneDay = dayKey(2026, 10, 1)
        let entries = (0..<10).map { i in EntryFact(id: "\(i)", dayKey: oneDay, starred: false, savedAt: moment(2026, 10, 1, 8 + i)) }
        let s = state(entries, now: moment(2026, 10, 2))
        XCTAssertEqual(s.recordedDaysCount, 1)
    }

    /// Scenario: A "didn't record" day with an entry. `Programme` reads only
    /// the entry fact — the "didn't record" state is `Record`'s own row and
    /// never reaches the engine — so the day counts by construction.
    func testADidntRecordDayWithAnEntryCounts() {
        let entries = [EntryFact(id: "1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 9))]
        let s = state(entries, now: moment(2026, 10, 2))
        XCTAssertEqual(s.recordedDaysCount, 1)
    }

    /// Scenario: A fasting day with an entry. Same reasoning as above.
    func testAFastingDayWithAnEntryCounts() {
        let entries = [EntryFact(id: "1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 20))]
        let s = state(entries, now: moment(2026, 10, 2))
        XCTAssertEqual(s.recordedDaysCount, 1)
    }

    /// Scenario: The day start changes. `Programme` never recomputes an
    /// entry's own `dayKey`; a later "Day starts at" change only affects
    /// `settings.dayStart`, an input the gate's own count does not use.
    func testTheDayStartChangeKeepsTheEntrysRecordDay() {
        let entries = [EntryFact(id: "1", dayKey: dayKey(2026, 10, 2), starred: false, savedAt: moment(2026, 10, 2, 4, 30))]
        let laterDayStart = ProgrammeSettings(startDay: defaultSettings.startDay, dayStart: 5)
        let s = Programme.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: laterDayStart, constants: .default, now: moment(2026, 10, 3), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        XCTAssertEqual(s.recordedDaysCount, 1, "Friday still counts")
    }
}
