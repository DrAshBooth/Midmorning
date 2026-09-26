import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "The app keeps the entry's UTC offset and creation moment".
/// Ash ruled on 26 September 2026 (r13-16, mm-t12b.22) that an entry keeps
/// the UTC offset in effect at its own time, by the device zone rules, not
/// the offset at the save moment, on add and on edit. Each test makes the
/// calls that `NewEntryView` and `EditEntryView` make on save, with London
/// as the device zone. In 2026 the London clocks go forward at 01:00 GMT on
/// 29 March and go back at 02:00 BST on 25 October.
@MainActor
final class EntryOffsetTests: XCTestCase {
    private let londonZone = TimeZone(identifier: "Europe/London")!

    private var london: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = londonZone
        return calendar
    }

    private func utc(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// What `NewEntryView.save` does: the offset at the entry's own time.
    private func saveNew(_ time: Date, savedAt now: Date, in store: RecordStore) throws -> RecordRow {
        try store.add(
            time: min(time, now), what: "Toast", feltLikeABinge: false, createdAt: now,
            utcOffsetSeconds: EntryOffset.seconds(at: min(time, now), in: londonZone), dayStartHour: 4
        )
    }

    /// What `EditEntryView` does: its zone from the entry, and on save the
    /// offset at the edited time in that zone.
    private func saveEdit(_ entry: RecordRow, time: Date, what: String, at now: Date, in store: RecordStore, deviceZone: TimeZone) throws -> RecordRow {
        let zone = EntryOffset.editZone(entryTime: entry.time, entryOffsetSeconds: entry.utcOffsetSeconds, deviceZone: deviceZone)
        return try store.update(
            entryId: entry.id, time: time, what: what, feltLikeABinge: entry.feltLikeABinge,
            whereText: entry.whereText, context: entry.context, editedAt: now,
            utcOffsetSeconds: EntryOffset.seconds(at: time, in: zone)
        )
    }

    // MARK: Add

    /// The 25 October 2026 case from the ruling. On Sunday at 10:00 GMT the
    /// person saves an entry for Saturday 04:30 BST. With the offset at the
    /// save moment (GMT) the entry showed 03:30 and took Friday's key.
    func testABackdatedEntryAcrossTheAutumnChangeKeepsItsOwnOffset() throws {
        let store = try makeTemporaryStore()
        let entryTime = utc(10, 24, 3, 30) // Saturday 04:30 BST
        let savedAt = utc(10, 25, 10) // Sunday 10:00 GMT
        XCTAssertEqual(londonZone.secondsFromGMT(for: savedAt), 0, "the save moment is in GMT")

        let entry = try saveNew(entryTime, savedAt: savedAt, in: store)

        XCTAssertEqual(entry.utcOffsetSeconds, 3600, "the offset in effect at the entry's own time, BST")
        XCTAssertEqual(entry.clockTime, "04:30")
        XCTAssertEqual(entry.dayKey, "2026-10-24", "Saturday's key, not Friday's")
        XCTAssertEqual(try store.entries(dayKey: "2026-10-24").map(\.id), [entry.id])
        XCTAssertTrue(try store.entries(dayKey: "2026-10-23").isEmpty)
    }

    /// The spring change. On Sunday at 09:00 BST the person saves an entry
    /// for Saturday 23:00 GMT. It shows 23:00, not 00:00.
    func testABackdatedEntryAcrossTheSpringChangeKeepsItsOwnOffset() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(3, 28, 23), savedAt: utc(3, 29, 8), in: store)
        XCTAssertEqual(entry.utcOffsetSeconds, 0)
        XCTAssertEqual(entry.clockTime, "23:00")
        XCTAssertEqual(entry.dayKey, "2026-03-28")
    }

    /// An entry with no clock change between its time and the save keeps
    /// the same offset as before the ruling.
    func testAnEntryOnAnOrdinaryDayKeepsTheDeviceOffset() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(9, 25, 12, 5), savedAt: utc(9, 25, 12, 8), in: store)
        XCTAssertEqual(entry.utcOffsetSeconds, 3600)
        XCTAssertEqual(entry.clockTime, "13:05")
        XCTAssertEqual(entry.dayKey, "2026-09-25")
    }

    // MARK: Edit

    /// The edit screen of an entry saved in the device zone uses the device
    /// zone. On the 25-hour record day of Saturday 24 October, the time
    /// control offers the whole day, to 04:00 GMT on Sunday.
    func testTheEditZoneOfADeviceZoneEntryIsTheDeviceZone() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(10, 24, 22), savedAt: utc(10, 24, 22), in: store) // Saturday 23:00 BST
        let zone = EntryOffset.editZone(entryTime: entry.time, entryOffsetSeconds: entry.utcOffsetSeconds, deviceZone: londonZone)
        XCTAssertEqual(zone, londonZone)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let bounds = try XCTUnwrap(RecordDay.interval(forKey: entry.dayKey, calendar: calendar, schedule: .constant(4)))
        XCTAssertEqual(bounds.start, utc(10, 24, 3), "04:00 BST on Saturday")
        XCTAssertEqual(bounds.end, utc(10, 25, 4), "04:00 GMT on Sunday")
        XCTAssertEqual(bounds.duration, 25 * 3600)
    }

    /// An edit that moves the entry across the change, inside its own
    /// record day, keeps the offset in effect at the edited time.
    func testAnEditAcrossTheAutumnChangeTakesTheOffsetAtTheEditedTime() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(10, 24, 22), savedAt: utc(10, 24, 22), in: store) // Saturday 23:00 BST
        let edited = try saveEdit(entry, time: utc(10, 25, 3, 30), what: entry.what, at: utc(10, 25, 9), in: store, deviceZone: londonZone)
        XCTAssertEqual(edited.utcOffsetSeconds, 0, "03:30 on Sunday is GMT")
        XCTAssertEqual(edited.clockTime, "03:30")
        XCTAssertEqual(edited.dayKey, "2026-10-24", "the edit keeps the entry's record day")
    }

    /// Scenario: Change the What, on an ordinary day. The offset and the
    /// time do not change.
    func testAnEditOfTheWhatChangesNothingElse() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(9, 25, 12, 5), savedAt: utc(9, 25, 12, 8), in: store)
        let edited = try saveEdit(entry, time: entry.time, what: "Toast, tea and a biscuit", at: utc(9, 25, 17), in: store, deviceZone: londonZone)
        XCTAssertEqual(edited.utcOffsetSeconds, entry.utcOffsetSeconds)
        XCTAssertEqual(edited.clockTime, "13:05")
    }

    /// An entry saved in another zone: the edit screen uses a fixed zone at
    /// the entry's own offset, so an edit of the What in London does not
    /// move a Tokyo entry's clock time.
    func testAnEntryFromAnotherZoneKeepsItsOffsetOnEdit() throws {
        let store = try makeTemporaryStore()
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let time = utc(9, 24, 23) // 08:00 on 25 September in Tokyo
        let entry = try store.add(
            time: time, what: "Rice", feltLikeABinge: false, createdAt: time,
            utcOffsetSeconds: EntryOffset.seconds(at: time, in: tokyo), dayStartHour: 4
        )
        let zone = EntryOffset.editZone(entryTime: entry.time, entryOffsetSeconds: entry.utcOffsetSeconds, deviceZone: londonZone)
        XCTAssertEqual(zone.secondsFromGMT(for: time), 9 * 3600)

        let edited = try saveEdit(entry, time: entry.time, what: "Rice and egg", at: utc(9, 30, 12), in: store, deviceZone: londonZone)
        XCTAssertEqual(edited.utcOffsetSeconds, 9 * 3600)
        XCTAssertEqual(edited.clockTime, "08:00")
        XCTAssertEqual(edited.dayKey, entry.dayKey)
    }

    /// With no offset given, an edit keeps the current version's offset.
    func testAnUpdateWithNoOffsetKeepsTheOffset() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(10, 24, 3, 30), savedAt: utc(10, 25, 10), in: store)
        let edited = try store.update(entryId: entry.id, time: entry.time, what: "Porridge", feltLikeABinge: false, whereText: "", context: "", editedAt: utc(10, 25, 11))
        XCTAssertEqual(edited.utcOffsetSeconds, 3600)
    }
}
