import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "Earlier record days": "The control MUST appear only when a
/// record day before the previous record day has an entry or a state"; the
/// list "MUST start at the earliest record day with an entry or a state".
/// export spec, "Choose a date range": 'From' defaults to the earliest
/// record day with an entry. A deleted entry is no entry (mm-t12b.16).
@MainActor
final class DeletedEntryDayContentTests: XCTestCase {
    private func at(_ day: Int, _ hour: Int) -> Date {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        return london.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    private func add(_ store: RecordStore, day: Int) throws -> RecordRow {
        try store.add(time: at(day, 13), what: "Toast", feltLikeABinge: false, createdAt: at(day, 13), utcOffsetSeconds: 3600)
    }

    func testDeletedOnlyEntryLeavesNoDayContent() throws {
        let store = try makeTemporaryStore()
        let monday = try add(store, day: 21)
        XCTAssertEqual(try store.dateKeysWithContent(before: "2026-09-24"), ["2026-09-21"])

        try store.delete(entryId: monday.id, deletedAt: at(24, 9))

        XCTAssertEqual(try store.dateKeysWithContent(before: "2026-09-24"), [], "the day with only a deleted entry has no content")
        XCTAssertFalse(EarlierDays.isAvailable(dateKeysWithContent: try store.dateKeysWithContent(before: "2026-09-23"), previousRecordDayKey: "2026-09-23"))
    }

    func testEarliestEntryDaySkipsADeletedEntry() throws {
        let store = try makeTemporaryStore()
        let monday = try add(store, day: 21)
        _ = try add(store, day: 22)
        XCTAssertEqual(try store.earliestEntryDayKey(), "2026-09-21")

        try store.delete(entryId: monday.id, deletedAt: at(24, 9))

        XCTAssertEqual(try store.earliestEntryDayKey(), "2026-09-22")
    }

    func testEarliestEntryDayIsNilWhenEveryEntryIsDeleted() throws {
        let store = try makeTemporaryStore()
        let monday = try add(store, day: 21)
        try store.delete(entryId: monday.id, deletedAt: at(24, 9))
        XCTAssertNil(try store.earliestEntryDayKey())
    }

    func testDayWithADeletedAndALiveEntryStillHasContent() throws {
        let store = try makeTemporaryStore()
        let first = try add(store, day: 21)
        _ = try add(store, day: 21)
        try store.delete(entryId: first.id, deletedAt: at(24, 9))
        XCTAssertEqual(try store.dateKeysWithContent(before: "2026-09-24"), ["2026-09-21"])
        XCTAssertEqual(try store.earliestEntryDayKey(), "2026-09-21")
    }

    func testDeletedOnlyEntryDayIsNotAPlannedDay() throws {
        let store = try makeTemporaryStore()
        let monday = try add(store, day: 21)
        XCTAssertEqual(try store.plannedDayKeys(), ["2026-09-21"])
        try store.delete(entryId: monday.id, deletedAt: at(24, 9))
        XCTAssertEqual(try store.plannedDayKeys(), [])
    }
}
