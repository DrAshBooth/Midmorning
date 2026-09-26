import XCTest
@testable import Programme

/// regular-eating-plan spec, "The plan builder opens at stage 2" (mm-t23.1).
/// Today offers the plan builder when the live state has stage 2 open
/// (`TodayView.stage2Open`, `DaySection.load`), so these scenarios run on
/// the engine that gives that state.
final class PlanBuilderOpensAtStage2Tests: XCTestCase {
    private func stage2Open(entryDays: [Int]) -> Bool {
        let entries = entryDays.enumerated().map { i, day in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, day), starred: false, savedAt: moment(2026, 9, day, 9))
        }
        let state = StageEngine.state(
            facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 5, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 5), calendar: engineTestCalendar
        )
        return state.isOpen(.regularEating)
    }

    /// Scenario: Four recorded days.
    func testFourRecordedDaysShowsNoPlanBuilderControl() {
        XCTAssertFalse(stage2Open(entryDays: [28, 29, 30, 30]))
        XCTAssertFalse(stage2Open(entryDays: [28, 29, 30]))
        XCTAssertFalse(stage2Open(entryDays: [28, 29]))
    }

    /// Scenario: Five recorded days with gaps. Monday 28 September, Tuesday,
    /// Thursday, Saturday and Sunday 4 October, and no other day.
    func testFiveRecordedDaysWithGapsOpensThePlanBuilder() {
        let entries = [(9, 28), (9, 29), (10, 1), (10, 3), (10, 4)].enumerated().map { i, pair in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, pair.0, pair.1), starred: false, savedAt: moment(2026, pair.0, pair.1, 9))
        }
        let state = StageEngine.state(
            facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 5, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 5), calendar: engineTestCalendar
        )
        XCTAssertTrue(state.isOpen(.regularEating))
    }

    /// Scenario: A day without entries. Wednesday 30 September has a planned
    /// day but no entry, so four recorded days still keep stage 2 closed.
    func testADayWithoutEntriesDoesNotCountTowardStage2() {
        let entries = [28, 29, 1, 2].enumerated().map { i, day in
            let month = day > 27 ? 9 : 10
            return EntryFact(id: "\(i)", dayKey: dayKey(2026, month, day), starred: false, savedAt: moment(2026, month, day, 9))
        }
        let facts = ProgrammeFacts(entries: entries, plannedDays: [PlannedDayFact(dayKey: dayKey(2026, 9, 30))])
        let state = StageEngine.state(
            facts: facts, openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 10, 5, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 5), calendar: engineTestCalendar
        )
        XCTAssertFalse(state.isOpen(.regularEating))
    }
}
