import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "The app keeps the entry's UTC offset and creation moment"
/// and "Edit an entry" (change `rulings-specs-a`). Ash ruled on 26
/// September 2026 (r13-16, mm-t12b.22) that an entry keeps the UTC offset
/// in effect at its own time, by the device's current zone rules, not the
/// offset at the save moment. On edit, the entry keeps the offset of its
/// edit zone at the edited time. The rules are in `RecordStore.add` and
/// `RecordStore.update`, and the new-entry screen and the edit screen pass
/// no offset. So each test makes the same store call as the screen, with
/// London as the device zone. In 2026 the London clocks go forward at 01:00
/// GMT on 29 March and go back at 02:00 BST on 25 October.
@MainActor
final class EntryOffsetTests: XCTestCase {
    private let londonZone = TimeZone(identifier: "Europe/London")!
    private let tokyoZone = TimeZone(identifier: "Asia/Tokyo")!

    private func utc(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// The call of `NewEntryView.save`, in `deviceZone`.
    private func saveNew(_ time: Date, savedAt now: Date, in store: RecordStore, deviceZone: TimeZone? = nil) throws -> RecordRow {
        try store.add(
            time: min(time, now), what: "Toast", feltLikeABinge: false, createdAt: now,
            deviceZone: deviceZone ?? londonZone
        )
    }

    /// The call of `EditEntryView.save`, in `deviceZone`.
    private func saveEdit(_ entry: RecordRow, time: Date, what: String, at now: Date, in store: RecordStore, deviceZone: TimeZone? = nil) throws -> RecordRow {
        try store.update(
            entryId: entry.id, time: time, what: what, feltLikeABinge: entry.feltLikeABinge,
            whereText: entry.whereText, context: entry.context, editedAt: now,
            deviceZone: deviceZone ?? londonZone
        )
    }

    // MARK: Add

    /// Scenario: Earlier time across a clock change. On Sunday 25 October
    /// at 10:00 GMT the person saves an entry for Saturday 04:30 BST. With
    /// the offset at the save moment (GMT) the entry showed 03:30 and took
    /// Friday's key.
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

    /// A given offset wins over the device zone, for a test or an import.
    func testAGivenOffsetWins() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: utc(10, 24, 3, 30), what: "Toast", feltLikeABinge: false, createdAt: utc(10, 25, 10), utcOffsetSeconds: 0, deviceZone: londonZone)
        XCTAssertEqual(entry.utcOffsetSeconds, 0)
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

    /// Scenario: Edit across a clock change. An edit that moves the entry
    /// across the change, inside its own record day, keeps the offset in
    /// effect at the edited time.
    func testAnEditAcrossTheAutumnChangeTakesTheOffsetAtTheEditedTime() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(10, 24, 22), savedAt: utc(10, 24, 22), in: store) // Saturday 23:00 BST
        let edited = try saveEdit(entry, time: utc(10, 25, 3, 30), what: entry.what, at: utc(10, 25, 9), in: store)
        XCTAssertEqual(edited.utcOffsetSeconds, 0, "03:30 on Sunday is GMT")
        XCTAssertEqual(edited.clockTime, "03:30")
        XCTAssertEqual(edited.dayKey, "2026-10-24", "the edit keeps the entry's record day")
    }

    /// Scenario: Change the What, on an ordinary day. The offset and the
    /// time do not change.
    func testAnEditOfTheWhatChangesNothingElse() throws {
        let store = try makeTemporaryStore()
        let entry = try saveNew(utc(9, 25, 12, 5), savedAt: utc(9, 25, 12, 8), in: store)
        let edited = try saveEdit(entry, time: entry.time, what: "Toast, tea and a biscuit", at: utc(9, 25, 17), in: store)
        XCTAssertEqual(edited.utcOffsetSeconds, entry.utcOffsetSeconds)
        XCTAssertEqual(edited.clockTime, "13:05")
    }

    /// An entry saved in another zone: the edit screen uses a fixed zone at
    /// the entry's own offset, and an edit that keeps the time keeps the
    /// offset. So an edit of the What in London does not move a Tokyo
    /// entry's clock time.
    func testAnEntryFromAnotherZoneKeepsItsOffsetWhenTheTimeStays() throws {
        let store = try makeTemporaryStore()
        let time = utc(9, 24, 23) // 08:00 on 25 September in Tokyo
        let entry = try saveNew(time, savedAt: time, in: store, deviceZone: tokyoZone)
        XCTAssertEqual(entry.utcOffsetSeconds, 9 * 3600)
        let zone = EntryOffset.editZone(entryTime: entry.time, entryOffsetSeconds: entry.utcOffsetSeconds, deviceZone: londonZone)
        XCTAssertEqual(zone.secondsFromGMT(for: time), 9 * 3600)

        let edited = try saveEdit(entry, time: entry.time, what: "Rice and egg", at: utc(9, 30, 12), in: store)
        XCTAssertEqual(edited.utcOffsetSeconds, 9 * 3600)
        XCTAssertEqual(edited.clockTime, "08:00")
        XCTAssertEqual(edited.dayKey, entry.dayKey)
    }

    /// An entry saved in another zone, with a time change: the edit keeps
    /// the offset of the edit zone, a fixed zone at the entry's own offset.
    /// So a Tokyo 08:00 entry that the person sets to 08:30 in London shows
    /// 08:30, and the edited time and its offset still give the entry's
    /// record day key. mm-t12b.25 and mm-t12b.26 ask Ash to confirm this.
    func testAnEntryFromAnotherZoneKeepsItsOffsetWhenTheTimeChanges() throws {
        let store = try makeTemporaryStore()
        let time = utc(9, 24, 23) // 08:00 on 25 September in Tokyo
        let entry = try saveNew(time, savedAt: time, in: store, deviceZone: tokyoZone)

        let edited = try saveEdit(entry, time: utc(9, 24, 23, 30), what: entry.what, at: utc(9, 30, 12), in: store)

        XCTAssertEqual(edited.utcOffsetSeconds, 9 * 3600, "the entry's own offset, not the London offset")
        XCTAssertEqual(edited.clockTime, "08:30", "the time that the time control showed")
        XCTAssertEqual(edited.dayKey, "2026-09-25", "the edit keeps the entry's record day")
        XCTAssertEqual(
            RecordDay.key(for: edited.time, utcOffsetSeconds: edited.utcOffsetSeconds, schedule: .constant(4)),
            edited.dayKey,
            "the edited time and its offset still give the kept key"
        )
    }

    /// Scenario: Edit after travel. The person saves an entry at 05:00 on
    /// Saturday 26 September in London at UTC+1. On Sunday 27 September in
    /// New York at UTC-4, the person opens it and sets 05:30. The time
    /// control opens at 05:00, the entry keeps UTC+1, and it shows at 05:30
    /// under Saturday 26 September.
    func testEditAfterTravelKeepsTheEntrysOffset() throws {
        let store = try makeTemporaryStore()
        let newYorkZone = TimeZone(identifier: "America/New_York")!
        let time = utc(9, 26, 4) // 05:00 BST on Saturday 26 September
        let entry = try saveNew(time, savedAt: time, in: store)
        XCTAssertEqual(entry.utcOffsetSeconds, 3600)
        XCTAssertEqual(entry.dayKey, "2026-09-26")

        let zone = EntryOffset.editZone(entryTime: entry.time, entryOffsetSeconds: entry.utcOffsetSeconds, deviceZone: newYorkZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        XCTAssertEqual(calendar.component(.hour, from: entry.time), 5, "the time control opens at 05:00")
        XCTAssertEqual(calendar.component(.minute, from: entry.time), 0)

        let edited = try saveEdit(entry, time: utc(9, 26, 4, 30), what: entry.what, at: utc(9, 27, 14), in: store, deviceZone: newYorkZone)

        XCTAssertEqual(newYorkZone.secondsFromGMT(for: edited.time), -4 * 3600, "the device zone is UTC-4")
        XCTAssertEqual(edited.utcOffsetSeconds, 3600, "the entry keeps UTC+1")
        XCTAssertEqual(edited.clockTime, "05:30")
        XCTAssertEqual(edited.dayKey, "2026-09-26", "under Saturday 26 September")
        XCTAssertEqual(try store.entries(dayKey: "2026-09-26").map(\.id), [entry.id])
    }

    /// The rule itself: the same minute keeps the entry's offset. A new
    /// minute takes the offset of the edit zone at that minute: the device
    /// zone's offset for an entry from the device zone, and the entry's own
    /// offset for an entry from another zone.
    func testTheEditRuleUsesTheEditZone() {
        let tokyoEntryTime = utc(9, 24, 23)
        XCTAssertEqual(EntryOffset.forEdit(entryTime: tokyoEntryTime, entryOffsetSeconds: 9 * 3600, editedTime: tokyoEntryTime.addingTimeInterval(30), deviceZone: londonZone), 9 * 3600)
        XCTAssertEqual(EntryOffset.forEdit(entryTime: tokyoEntryTime, entryOffsetSeconds: 9 * 3600, editedTime: tokyoEntryTime.addingTimeInterval(60), deviceZone: londonZone), 9 * 3600)

        let londonEntryTime = utc(10, 24, 22) // Saturday 23:00 BST
        XCTAssertEqual(EntryOffset.forEdit(entryTime: londonEntryTime, entryOffsetSeconds: 3600, editedTime: utc(10, 25, 3, 30), deviceZone: londonZone), 0)
    }
}
