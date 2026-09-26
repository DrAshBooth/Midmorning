import XCTest
@testable import Programme

/// Covers programme spec.md, "Stage 3 opens after seven planned days or two
/// weeks of regular eating" (mm-t21.5). "The stage 3 rule string" is also
/// proved directly in `ReadingAheadTests`. Every test keeps stage 2's own
/// opening within 14 days of `now`, so the fallback path never fires
/// unintentionally in a test that means to prove the primary path alone (or
/// its absence).
final class Stage3OpensTests: XCTestCase {
    /// Scenario: Seven planned days over ten days.
    func testSevenPlannedDaysOverTenDays() {
        let plannedRecorded = (1...7).map { d -> (plan: PlannedDayFact, entry: EntryFact) in
            let key = dayKey(2026, 10, d)
            return (PlannedDayFact(dayKey: key), EntryFact(id: key, dayKey: key, starred: false, savedAt: moment(2026, 10, d, 9)))
        }
        let facts = ProgrammeFacts(entries: plannedRecorded.map(\.entry), plannedDays: plannedRecorded.map(\.plan))
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 0))] // fallback would land on 15 October, after the primary path
        let s = Programme.state(facts: facts, openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 10), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 8, 4))
    }

    /// Scenario: Two weeks with three planned days.
    func testTwoWeeksWithThreePlannedDays() {
        let keys = [dayKey(2026, 10, 6), dayKey(2026, 10, 10), dayKey(2026, 10, 15)]
        let entries = keys.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) }
        let planned = keys.map { PlannedDayFact(dayKey: $0) }
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let s = Programme.state(facts: ProgrammeFacts(entries: entries, plannedDays: planned), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 19, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 19), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 19, 4))
        XCTAssertTrue(s.computedOpenings.contains(StageOpenedRecord(stage: 3, moment: moment(2026, 10, 19, 4))))
    }

    /// Scenario: Seven planned days before the two weeks.
    func testSevenPlannedDaysBeforeTheTwoWeeks() {
        let days = [6, 7, 8, 9, 10, 12, 13].map { dayKey(2026, 10, $0) } // seventh is 13 October
        let entries = days.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) }
        let planned = days.map { PlannedDayFact(dayKey: $0) }
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let s = Programme.state(facts: ProgrammeFacts(entries: entries, plannedDays: planned), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 14, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 14), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 14, 4))
    }

    /// Scenario: No template in two weeks — the fallback needs no planned day.
    func testNoTemplateInTwoWeeks() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let s = Programme.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 19, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 19), calendar: engineTestCalendar)
        XCTAssertEqual(s.stageOpenedMoment[.alternatives], moment(2026, 10, 19, 4))
    }

    /// Scenario: A planned day with every planned meal skipped. `Programme`
    /// never sees planned-meal answers, only the day's own facts, so the day
    /// counts because it is both a planned day and a recorded day.
    func testAPlannedDayWithEveryPlannedMealSkippedCounts() {
        let sixBefore = (1...6).map { dayKey(2026, 10, $0) }
        let entries = sixBefore.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) }
            + [EntryFact(id: "7", dayKey: dayKey(2026, 10, 7), starred: false, savedAt: moment(2026, 10, 7, 22))]
        let planned = (sixBefore + [dayKey(2026, 10, 7)]).map { PlannedDayFact(dayKey: $0) }
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 0))]
        let s = Programme.state(facts: ProgrammeFacts(entries: entries, plannedDays: planned), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 8, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 8), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.alternatives))
    }

    /// Scenario: A planned day with no entry does not count.
    func testAPlannedDayWithNoEntryDoesNotCount() {
        let sixWithEntries = (1...6).map { dayKey(2026, 10, $0) }
        let entries = sixWithEntries.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) }
        let planned = (sixWithEntries + [dayKey(2026, 10, 7)]).map { PlannedDayFact(dayKey: $0) } // day 7 planned, no entry
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 0))]
        let s = Programme.state(facts: ProgrammeFacts(entries: entries, plannedDays: planned), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 8, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 8), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.alternatives), "only six planned-and-recorded days exist, and the fallback has not reached 14 days")
    }

    /// Scenario: A fasting day on the plan. Same reasoning as "every planned
    /// meal skipped": the fasting state never reaches `Programme`.
    func testAFastingDayOnThePlanCounts() {
        let sixBefore = (1...6).map { dayKey(2026, 10, $0) }
        let entries = sixBefore.map { EntryFact(id: $0, dayKey: $0, starred: false, savedAt: moment(2026, 10, 1, 9)) }
            + [EntryFact(id: "7", dayKey: dayKey(2026, 10, 7), starred: false, savedAt: moment(2026, 10, 7, 20))]
        let planned = (sixBefore + [dayKey(2026, 10, 7)]).map { PlannedDayFact(dayKey: $0) }
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 0))]
        let s = Programme.state(facts: ProgrammeFacts(entries: entries, plannedDays: planned), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 8, 5), restartAt: nil, currentRecordDay: dayKey(2026, 10, 8), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.alternatives))
    }

    /// Scenario: A copied plan with no entry.
    func testACopiedPlanWithNoEntryDoesNotCount() {
        let friday = dayKey(2026, 10, 9)
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 8, 0))]
        let s = Programme.state(facts: ProgrammeFacts(plannedDays: [PlannedDayFact(dayKey: friday)]), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 10), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.alternatives))
    }

    /// Scenario: Set plans with no entries.
    func testSetPlansWithNoEntriesStage3StaysClosed() {
        let sixDays = (1...6).map { dayKey(2026, 10, $0) }
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 0))]
        let s = Programme.state(facts: ProgrammeFacts(plannedDays: sixDays.map { PlannedDayFact(dayKey: $0) }), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 7), restartAt: nil, currentRecordDay: dayKey(2026, 10, 7), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.alternatives))
    }
}
