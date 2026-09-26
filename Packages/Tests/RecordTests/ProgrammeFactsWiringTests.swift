import Foundation
import XCTest
@testable import Record
import Programme
import RecordTestSupport

/// mm-t21.23, "wiring: scenarios that need 2.1, end to end": proves
/// `RecordStore`'s own fact-gathering calls that `ProgrammeModel` (App
/// target) composes into `Programme`'s value facts, over the real store.
@MainActor
final class ProgrammeFactsWiringTests: XCTestCase {
    /// `recordedEntryFacts` reads only winning, non-deleted entries.
    func testRecordedEntryFactsSkipsADeletedEntry() throws {
        let store = try makeTemporaryStore()
        let kept = try store.add(time: Date(timeIntervalSince1970: 1_759_000_000), what: "Toast", feltLikeABinge: true, createdAt: Date(timeIntervalSince1970: 1_759_000_000), utcOffsetSeconds: 0)
        let deleted = try store.add(time: Date(timeIntervalSince1970: 1_759_100_000), what: "Cereal", feltLikeABinge: false, createdAt: Date(timeIntervalSince1970: 1_759_100_000), utcOffsetSeconds: 0)
        try store.delete(entryId: deleted.id, deletedAt: Date(timeIntervalSince1970: 1_759_100_100))

        let facts = try store.recordedEntryFacts()
        XCTAssertEqual(facts.count, 1)
        XCTAssertEqual(facts.first?.dayKey, kept.dayKey)
        XCTAssertTrue(facts.first?.starred ?? false)
    }

    /// `plannedDayKeys` includes an entry day and a set day, and excludes a
    /// paused day even with an entry (regular-eating-plan spec, "A planned
    /// day"; `Plan.PlannedDay.isPlanned`).
    func testPlannedDayKeysExcludesAPausedDayWithAnEntry() throws {
        let store = try makeTemporaryStore()
        let entryDay = try store.add(time: Date(timeIntervalSince1970: 1_759_000_000), what: "Lunch", feltLikeABinge: false, createdAt: Date(timeIntervalSince1970: 1_759_000_000), utcOffsetSeconds: 0).dayKey
        try store.setDayPlan(dateKey: "2026-10-20", slotsJSON: "[]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: Date(timeIntervalSince1970: 1_759_200_000), setBy: "device-a", changedAt: Date(timeIntervalSince1970: 1_759_200_000))

        let pausedWithEntry = try store.add(time: Date(timeIntervalSince1970: 1_759_300_000), what: "Snack", feltLikeABinge: false, createdAt: Date(timeIntervalSince1970: 1_759_300_000), utcOffsetSeconds: 0).dayKey
        try store.setDayState(.paused, on: true, dateKey: pausedWithEntry, changedAt: Date(timeIntervalSince1970: 1_759_300_100))

        let planned = try store.plannedDayKeys()
        XCTAssertTrue(planned.contains(entryDay))
        XCTAssertTrue(planned.contains("2026-10-20"))
        XCTAssertFalse(planned.contains(pausedWithEntry), "a paused day is never planned, even with an entry")
    }

    /// `urgeOutcomeFacts` reads only a `Session` with a non-empty outcome.
    func testUrgeOutcomeFactsSkipsAnOpenSession() throws {
        // No public `RecordStore` write for `Session` yet (`urge-toolkit`,
        // 3.1, owns it); an empty store has no urge outcome facts.
        let store = try makeTemporaryStore()
        XCTAssertEqual(try store.urgeOutcomeFacts(), [])
    }

    /// r14-03 (mm-t21.37), over the real store, as `ProgrammeModel.load`
    /// wires it: the engine computes stage 2's opening with its record-day
    /// key, the store writes the key into the `StageOpened` row, and a later
    /// load with the day start 05:00 reads the same record day.
    func testAStageOpeningKeepsItsDayAfterTheDayStartChanges() throws {
        let store = try makeTemporaryStore()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func utc(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
        }
        let entries = (5...9).map { day in
            EntryFact(id: "\(day)", dayKey: String(format: "2026-10-%02d", day), starred: false, savedAt: day == 9 ? utc(9, 4, 30) : utc(day, 9))
        }
        let first = StageEngine.state(
            facts: ProgrammeFacts(entries: entries), openings: [], settings: ProgrammeSettings(startDay: "2026-10-05", dayStart: 4),
            constants: .default, now: utc(9, 5), restartAt: nil, currentRecordDay: "2026-10-09", calendar: calendar
        )
        for computed in first.computedOpenings {
            try store.recordStageOpened(computed.stage, at: computed.moment, dayKey: try XCTUnwrap(computed.dayKey))
        }

        let openings = try store.stageOpenedRows().map { StageOpenedRecord(stage: $0.stage, moment: $0.moment, dayKey: $0.dayKey) }
        XCTAssertEqual(openings, [StageOpenedRecord(stage: 2, moment: utc(9, 4, 30), dayKey: "2026-10-09")])
        let later = StageEngine.state(
            facts: ProgrammeFacts(), openings: openings, settings: ProgrammeSettings(startDay: "2026-10-05", dayStart: 5),
            constants: .default, now: utc(12, 9), restartAt: nil, currentRecordDay: "2026-10-12", calendar: calendar
        )
        XCTAssertEqual(later.stageOpenedDayKey[.regularEating], "2026-10-09", "the stored key, not 8 October, which 05:00 gives")
        XCTAssertTrue(later.computedOpenings.isEmpty)
    }

    /// `hasAnyTemplate` is false until a template is saved.
    func testHasAnyTemplateBeforeAndAfterASave() throws {
        let store = try makeTemporaryStore()
        XCTAssertFalse(try store.hasAnyTemplate())
        try store.setTemplateSlotsJSON("[]", kind: .weekday, changedAt: Date())
        XCTAssertTrue(try store.hasAnyTemplate())
    }
}
