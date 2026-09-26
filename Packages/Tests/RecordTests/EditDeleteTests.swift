import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "Edit an entry" (mm-t12.19), "Delete an entry" (mm-t12.20)
/// and "A save that fails" (mm-t12.27).
@MainActor
final class EditDeleteTests: XCTestCase {
    private func london(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: Edit an entry

    /// Scenario: Change the What.
    func testChangeTheWhat() throws {
        let store = try makeTemporaryStore()
        let saveMoment = london(2026, 9, 25, 13, 8)
        let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: saveMoment, utcOffsetSeconds: 3600)
        let edited = try store.update(entryId: entry.id, time: entry.time, what: "Toast, tea and a biscuit", feltLikeABinge: false, whereText: "", context: "", editedAt: london(2026, 9, 25, 18, 0))
        XCTAssertEqual(edited.what, "Toast, tea and a biscuit")
        XCTAssertEqual(edited.time, entry.time, "no other change")
    }

    /// Scenario: Change the time inside the entry's record day.
    func testChangeTheTimeInsideTheEntrysRecordDay() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 25, 8, 30), what: "Porridge", feltLikeABinge: false, createdAt: london(2026, 9, 25, 8, 30), utcOffsetSeconds: 3600, dayStartHour: 4)
        let newTime = london(2026, 9, 25, 6, 45)
        let edited = try store.update(entryId: entry.id, time: newTime, what: "Porridge", feltLikeABinge: false, whereText: "", context: "", editedAt: london(2026, 9, 25, 9, 0))
        XCTAssertEqual(edited.time, newTime)
        XCTAssertEqual(edited.dayKey, entry.dayKey, "the entry keeps Friday's key")
        let rows = try store.entries(dayKey: entry.dayKey)
        XCTAssertEqual(rows.first?.time, newTime)
    }

    /// Scenario: One segment on the edit screen. The edit screen's time
    /// control bounds come from the entry's own record day, computed at the
    /// entry's own UTC offset — one calendar date's worth of bounds, unlike
    /// the new-entry screen's two segments.
    func testEditTimeControlBoundsComeFromTheEntrysOwnRecordDay() throws {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let entryTime = self.london(2026, 9, 23, 21, 0)
        let bounds = RecordDay.interval(containing: entryTime, calendar: london, startHour: 4)
        XCTAssertEqual(bounds.start, self.london(2026, 9, 23, 4, 0))
        XCTAssertEqual(bounds.end, self.london(2026, 9, 24, 4, 0), "one record day's bounds, not two")
    }

    /// Scenario: Creation moment stays.
    func testCreationMomentStays() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(2026, 9, 25, 13, 8), utcOffsetSeconds: 3600)
        XCTAssertEqual(entry.createdAt, london(2026, 9, 25, 13, 8))
        let edited = try store.update(entryId: entry.id, time: entry.time, what: "Toast", feltLikeABinge: false, whereText: "", context: "", editedAt: london(2026, 9, 25, 18, 0))
        XCTAssertEqual(edited.createdAt, london(2026, 9, 25, 13, 8), "the creation moment never moves")
    }

    /// Scenario: Cancel an edit. Discarding every change means never calling
    /// `update`; the entry keeps its saved values.
    func testCancelAnEditCallsNoUpdate() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(2026, 9, 25, 13, 5), utcOffsetSeconds: 3600)
        // No `update` call represents "Cancel".
        let rows = try store.entries(dayKey: entry.dayKey)
        XCTAssertEqual(rows.first?.feltLikeABinge, false)
    }

    // MARK: Delete an entry

    /// Scenario: Delete from the edit screen.
    func testDeleteFromTheEditScreen() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(2026, 9, 25, 13, 5), utcOffsetSeconds: 3600)
        try store.delete(entryId: entry.id, deletedAt: london(2026, 9, 25, 14, 0))
        XCTAssertEqual(try store.entries(dayKey: entry.dayKey), [])
    }

    /// Scenario: Cancel a delete. Not calling `delete` leaves the entry.
    func testCancelADeleteCallsNoDelete() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(2026, 9, 25, 13, 5), utcOffsetSeconds: 3600)
        let rows = try store.entries(dayKey: entry.dayKey)
        XCTAssertEqual(rows.count, 1)
    }

    /// Scenario: Delete the only entry of the previous record day.
    func testDeleteTheOnlyEntryOfThePreviousRecordDay() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: london(2026, 9, 24, 19, 20), what: "Pasta", feltLikeABinge: false, createdAt: london(2026, 9, 24, 19, 20), utcOffsetSeconds: 3600)
        try store.delete(entryId: entry.id, deletedAt: london(2026, 9, 25, 9, 0))
        XCTAssertEqual(try store.entries(dayKey: entry.dayKey), [], "no heading for a day with no entries")
    }

    /// Scenario: Deleted entry after restart.
    func testDeletedEntryStaysHiddenAfterRestart() throws {
        let directory = try makeTemporaryDirectory()
        let dayKey: String
        let entryId: UUID
        do {
            let store = try RecordStore(directory: directory)
            let entry = try store.add(time: london(2026, 9, 25, 13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(2026, 9, 25, 13, 5), utcOffsetSeconds: 3600)
            entryId = entry.id
            dayKey = entry.dayKey
            try store.delete(entryId: entry.id, deletedAt: london(2026, 9, 25, 14, 0))
        }
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.entries(dayKey: dayKey), [])
        _ = entryId
    }

    // MARK: A save that fails

    /// The exact failure text (record spec, "A save that fails").
    func testFailureMessageText() {
        XCTAssertEqual(SaveOutcome.failureMessage, "Could not save. Try again.")
    }
}
