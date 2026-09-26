import Foundation
import XCTest
@testable import Record

/// record spec, "Create an entry" and "The new-entry screen's controls":
/// the time control's segments and wheel, end to end from the wheel's clock
/// time to the saved key. Each test makes the calls `NewEntryView` and
/// `RecordTimeControl` make: the segments from `store.dayStartSchedule()`,
/// `NewEntryTime.wheelTime` on each turn of the wheel, then `store.add`
/// (mm-t12b.5). The last tests cover the adjustable VoiceOver element
/// (record spec, "Accessibility of the additions"; mm-t12b.13).
@MainActor
final class NewEntryTimeWiringTests: XCTestCase {
    private let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NewEntryTimeWiringTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    private struct Segment {
        let interval: DateInterval
        let key: String
        let startHour: Int
    }

    /// The previous and the current record day at `now`, as `NewEntryView`
    /// builds them.
    private func segments(store: RecordStore, now: Date) throws -> (previous: Segment, current: Segment) {
        let schedule = try store.dayStartSchedule()
        let current = RecordDay.interval(containing: now, calendar: london, schedule: schedule)
        let previous = RecordDay.previous(current, calendar: london, schedule: schedule)
        func segment(_ interval: DateInterval) -> Segment {
            let key = RecordDay.key(containing: interval.start, calendar: london, schedule: schedule)
            return Segment(interval: interval, key: key, startHour: schedule.hour(effectiveOn: key))
        }
        return (segment(previous), segment(current))
    }

    /// One turn of the wheel to `hour`:`minute` from `near` (the wheel
    /// opens at the current moment).
    private func wheel(_ hour: Int, _ minute: Int, in segment: Segment, now: Date, near: Date? = nil) -> Date {
        NewEntryTime.wheelTime(hour: hour, minute: minute, segment: segment.interval, dayStartHour: segment.startHour, notAfter: now, near: near ?? now, calendar: london)
    }

    private func save(_ time: Date, in store: RecordStore, now: Date) throws -> RecordRow {
        try store.add(time: min(time, now), what: "", feltLikeABinge: false, createdAt: now, utcOffsetSeconds: 3600)
    }

    /// Scenario: Save last night's entry the next morning.
    func testSaveLastNightsEntryTheNextMorning() throws {
        let store = try makeStore()
        let now = at(25, 7, 30)
        let (previous, current) = try segments(store: store, now: now)
        XCTAssertEqual([previous.key, current.key], ["2026-09-24", "2026-09-25"])

        let time = wheel(23, 30, in: previous, now: now)
        XCTAssertEqual(time, at(24, 23, 30))
        let row = try save(time, in: store, now: now)
        XCTAssertEqual(row.time, at(24, 23, 30))
        XCTAssertEqual(row.dayKey, "2026-09-24")
    }

    /// Scenario: Save an evening entry after midnight.
    func testSaveAnEveningEntryAfterMidnight() throws {
        let store = try makeStore()
        let now = at(25, 1)
        let (_, current) = try segments(store: store, now: now)
        XCTAssertEqual(current.key, "2026-09-24")
        let row = try save(wheel(23, 0, in: current, now: now), in: store, now: now)
        XCTAssertEqual(row.time, at(24, 23))
        XCTAssertEqual(row.dayKey, "2026-09-24")
    }

    /// Scenario: Last night's time after midnight.
    func testLastNightsTimeAfterMidnight() throws {
        let store = try makeStore()
        let now = at(25, 2)
        let (previous, current) = try segments(store: store, now: now)
        XCTAssertEqual([previous.key, current.key], ["2026-09-23", "2026-09-24"])
        let row = try save(wheel(23, 30, in: current, now: now), in: store, now: now)
        XCTAssertEqual(row.time, at(24, 23, 30))
        XCTAssertEqual(row.dayKey, "2026-09-24")
    }

    /// Scenario: A time before the day start.
    func testATimeBeforeTheDayStart() throws {
        let store = try makeStore()
        let now = at(25, 2)
        let (_, current) = try segments(store: store, now: now)
        let row = try save(wheel(1, 30, in: current, now: now), in: store, now: now)
        XCTAssertEqual(row.time, at(25, 1, 30))
        XCTAssertEqual(row.dayKey, "2026-09-24", "Today shows it under Thursday 24 September")
    }

    /// Scenario: Time range. A time after now goes back to now; the
    /// previous segment offers its whole record day, up to one minute
    /// before the current one starts.
    func testTimeRange() throws {
        let store = try makeStore()
        let now = at(25, 7, 30)
        let (previous, current) = try segments(store: store, now: now)
        XCTAssertEqual(wheel(9, 0, in: current, now: now), now, "no time after the current moment")
        XCTAssertEqual(wheel(2, 0, in: current, now: now), now, "02:00 in Friday's record day is Saturday night")
        XCTAssertEqual(wheel(3, 59, in: previous, now: now), at(25, 3, 59), "the last minute of Thursday's record day")
        XCTAssertEqual(wheel(4, 0, in: previous, now: now), at(24, 4), "04:00 is Thursday's own start")
        XCTAssertEqual(NewEntryTime.range(of: previous.interval, notAfter: now), at(24, 4)...at(25, 3, 59))
    }

    /// A change of segment keeps the wheel's clock time and moves it to the
    /// other record day, as `RecordTimeControl.select` does.
    func testSegmentChangeKeepsTheClockTime() throws {
        let store = try makeStore()
        let now = at(25, 7, 30)
        let (previous, _) = try segments(store: store, now: now)
        XCTAssertEqual(wheel(7, 30, in: previous, now: now), at(24, 7, 30))
    }

    /// The day start in force sets the segments and where a clock time
    /// lands (mm-t13.10): with 06:00 from Friday, Thursday's record day
    /// runs 26 hours, to 06:00 on Friday. 05:00 is then on the wheel twice;
    /// a turn from 05:30 on Friday stays on Friday.
    func testWheelFollowsTheDayStartInForce() throws {
        let store = try makeStore()
        try store.setDayStartHour(6, now: at(24, 13), calendar: london, changedAt: at(24, 13))
        let now = at(25, 5, 30)
        let (previous, current) = try segments(store: store, now: now)
        XCTAssertEqual([previous.key, current.key], ["2026-09-23", "2026-09-24"])
        XCTAssertEqual(current.interval.end, at(25, 6))
        let row = try save(wheel(5, 0, in: current, now: now), in: store, now: now)
        XCTAssertEqual(row.time, at(25, 5))
        XCTAssertEqual(row.dayKey, "2026-09-24")
        XCTAssertEqual(wheel(5, 0, in: current, now: now, near: at(24, 8)), at(24, 5), "a turn from Thursday morning stays on Thursday")
        XCTAssertEqual(wheel(23, 0, in: current, now: now), at(24, 23), "a clock time on the wheel once has one place")
    }

    /// Edit an entry: a 21:00 entry can move to 01:00 inside its own
    /// record day, and keeps its key (record spec, "Edit an entry").
    func testEditMovesAnEveningEntryAfterMidnight() throws {
        let store = try makeStore()
        let entry = try store.add(time: at(23, 21), what: "Pasta", feltLikeABinge: false, createdAt: at(23, 21), utcOffsetSeconds: 3600)
        let schedule = try store.dayStartSchedule()
        let ownDay = try XCTUnwrap(RecordDay.interval(forKey: entry.dayKey, calendar: london, schedule: schedule))
        let now = at(25, 2)
        let time = NewEntryTime.wheelTime(hour: 1, minute: 0, segment: ownDay, dayStartHour: schedule.hour(effectiveOn: entry.dayKey), notAfter: now, calendar: london)
        XCTAssertEqual(time, at(24, 1))
        let updated = try store.update(entryId: entry.id, time: time, what: entry.what, feltLikeABinge: false, whereText: "", context: "", editedAt: now)
        XCTAssertEqual(updated.time, at(24, 1))
        XCTAssertEqual(updated.dayKey, "2026-09-23")
    }

    // MARK: The adjustable "Time" element (mm-t12b.13)

    /// A swipe moves a quarter hour, from the next quarter hour on.
    func testVoiceOverStepsByAQuarterHour() {
        let range = at(24, 4)...at(25, 7, 32)
        XCTAssertEqual(NewEntryTime.stepped(at(25, 7, 32), by: -1, within: range, calendar: london), at(25, 7, 30))
        XCTAssertEqual(NewEntryTime.stepped(at(25, 7, 30), by: -1, within: range, calendar: london), at(25, 7, 15))
        XCTAssertEqual(NewEntryTime.stepped(at(25, 7, 0), by: 1, within: range, calendar: london), at(25, 7, 15))
        XCTAssertEqual(NewEntryTime.stepped(at(25, 7, 30), by: 1, within: range, calendar: london), at(25, 7, 32), "never after now")
        XCTAssertEqual(NewEntryTime.stepped(at(24, 4), by: -1, within: range, calendar: london), at(24, 4), "never before the previous record day")
    }

    /// Scenario: Save last night's entry the next morning, with VoiceOver.
    /// The swipes cross from the current record day into the previous one.
    func testVoiceOverReachesLastNightFromTheMorning() throws {
        let store = try makeStore()
        let now = at(25, 7, 30)
        let (previous, current) = try segments(store: store, now: now)
        let range = previous.interval.start...NewEntryTime.range(of: current.interval, notAfter: now).upperBound
        var time = now
        for _ in 0..<32 {
            time = NewEntryTime.stepped(time, by: -1, within: range, calendar: london)
        }
        XCTAssertEqual(time, at(24, 23, 30))
        XCTAssertTrue(previous.interval.contains(time), "the previous segment is now the selected one")
        XCTAssertEqual(try save(time, in: store, now: now).dayKey, "2026-09-24")
    }
}
