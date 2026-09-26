import XCTest
@testable import Programme

/// Covers programme spec.md, "Resume after an absence" (mm-t21.21). "Away
/// past week 6 of regular eating" is `deferred: mm-t32b.3`.
final class ResumeAfterAnAbsenceTests: XCTestCase {
    /// Scenario: Three weeks away. The engine is a pure function of its
    /// inputs, so returning after any absence with the same facts and a
    /// later `now`/`currentRecordDay` gives the week the calendar says, the
    /// same stage state, and the same recorded-days count — no absence
    /// tracking exists to reset.
    func testThreeWeeksAway() {
        let startDay = dayKey(2026, 9, 28) // week 1 begins Monday 28 September 2026
        let entries = (0..<4).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, 1 + i), starred: false, savedAt: moment(2026, 10, 1 + i, 9)) }
        let facts = ProgrammeFacts(entries: entries)
        let settings = ProgrammeSettings(startDay: startDay, dayStart: 4)

        // Week 2, four recorded days.
        let inWeek2 = StageEngine.state(facts: facts, openings: [], settings: settings, constants: .default, now: moment(2026, 10, 5, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 5), calendar: engineTestCalendar)
        XCTAssertEqual(inWeek2.week, 2)
        XCTAssertFalse(inWeek2.isOpen(.regularEating))
        XCTAssertEqual(inWeek2.recordedDaysCount, 4)

        // Week 5, no new entries — the same facts, a later "now".
        let inWeek5 = StageEngine.state(facts: facts, openings: [], settings: settings, constants: .default, now: moment(2026, 10, 26, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 26), calendar: engineTestCalendar)
        XCTAssertEqual(inWeek5.week, 5)
        XCTAssertFalse(inWeek5.isOpen(.regularEating), "stage 2 is still closed")
        XCTAssertEqual(inWeek5.recordedDaysCount, 4, "the four recorded days still count")
    }
}
