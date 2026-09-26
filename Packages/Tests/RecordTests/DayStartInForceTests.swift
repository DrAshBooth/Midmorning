import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "The record day": "The key comes from the entry's time, its
/// UTC offset and the day start in force", and a record day "ends one
/// minute before the next day start". settings spec, "The Record group": a
/// change to "Day starts at" applies from the next day start.
///
/// These tests run the same calls the App target makes: `TodayView.reload`,
/// `EarlierDayDetailView`, `ReminderCoordinator` and the new-entry screen
/// read `store.dayStartSchedule()` once and pass it to every `RecordDay`
/// call (mm-t13.10, mm-t13.12).
@MainActor
final class DayStartInForceTests: XCTestCase {
    private let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 9) -> Date {
        london.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// A store where "Day starts at" is 04:00 up to Thursday 24 September
    /// and `hour` from Friday 25 September: the person changed it on
    /// Thursday afternoon.
    private func storeWithDayStart(_ hour: Int) throws -> RecordStore {
        let store = try makeTemporaryStore()
        try store.setDayStartHour(hour, now: at(24, 13), calendar: london, changedAt: at(24, 13))
        return store
    }

    // MARK: The schedule

    func testScheduleHourIsTheLatestChangeAtOrBeforeTheKey() {
        let schedule = DayStartSchedule(changes: [
            .init(effectiveFromDayKey: "2026-10-10", hour: 5),
            .init(effectiveFromDayKey: "2026-09-25", hour: 6),
        ])
        XCTAssertEqual(schedule.hour(effectiveOn: "2026-09-24"), 4, "no change yet: the default")
        XCTAssertEqual(schedule.hour(effectiveOn: "2026-09-25"), 6)
        XCTAssertEqual(schedule.hour(effectiveOn: "2026-10-09"), 6)
        XCTAssertEqual(schedule.hour(effectiveOn: "2026-10-10"), 5)
        XCTAssertEqual(DayStartSchedule.standard.hour(effectiveOn: "2026-09-24"), RecordDay.startHour)
    }

    func testStoreScheduleHoldsEveryDayStartRow() throws {
        let store = try storeWithDayStart(6)
        let schedule = try store.dayStartSchedule()
        XCTAssertEqual(schedule.changes, [.init(effectiveFromDayKey: "2026-09-25", hour: 6)])
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-24"), 4)
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-25"), 6)
    }

    // MARK: A new entry takes the day start in force (mm-t13.10)

    /// With 06:00 in force from Friday, an entry at 05:00 on Friday belongs
    /// to Thursday's record day. Before the fix `add` used 04:00 and gave it
    /// Friday's key, while the programme read Thursday.
    func testNewEntryBeforeALaterDayStartKeysToThePreviousRecordDay() throws {
        let store = try storeWithDayStart(6)
        let row = try store.add(time: at(25, 5), what: "Tea", feltLikeABinge: false, createdAt: at(25, 5), utcOffsetSeconds: 3600)
        XCTAssertEqual(row.dayKey, "2026-09-24")
        XCTAssertEqual(try store.entries(recordDayContaining: at(25, 5, 30), calendar: london).map(\.id), [row.id])
    }

    func testNewEntryAfterAnEarlierDayStartKeysToItsOwnDay() throws {
        let store = try storeWithDayStart(2)
        let row = try store.add(time: at(25, 3), what: "Tea", feltLikeABinge: false, createdAt: at(25, 3), utcOffsetSeconds: 3600)
        XCTAssertEqual(row.dayKey, "2026-09-25", "Friday started at 02:00")
    }

    // MARK: Today, Earlier days and the reminder horizon (mm-t13.10)

    func testTodaysCurrentAndPreviousRecordDayFollowTheSetting() throws {
        let store = try storeWithDayStart(6)
        let schedule = try store.dayStartSchedule()
        let now = at(25, 5, 30)
        let current = RecordDay.interval(containing: now, calendar: london, schedule: schedule)
        XCTAssertEqual(RecordDay.key(containing: now, calendar: london, schedule: schedule), "2026-09-24")
        XCTAssertEqual(current.start, at(24, 4))
        XCTAssertEqual(current.end, at(25, 6))
        XCTAssertEqual(current.duration, 26 * 3600, "the day before a later day start is 26 hours")
        XCTAssertTrue(RecordDay.isNight(now, inRecordDay: current, calendar: london), "05:30 before a 06:00 day start is night")

        let previous = RecordDay.previous(current, calendar: london, schedule: schedule)
        XCTAssertEqual(RecordDay.key(containing: previous.start, calendar: london, schedule: schedule), "2026-09-23")

        let next = RecordDay.next(current, calendar: london, schedule: schedule)
        XCTAssertEqual(next.start, at(25, 6))
        XCTAssertEqual(next.end, at(26, 6))
    }

    func testEarlierDayIntervalComesFromItsOwnKey() throws {
        let store = try storeWithDayStart(6)
        let schedule = try store.dayStartSchedule()
        let friday = try XCTUnwrap(RecordDay.interval(forKey: "2026-09-25", calendar: london, schedule: schedule))
        XCTAssertEqual(friday.start, at(25, 6))
        XCTAssertEqual(friday.end, at(26, 6))
        let thursday = try XCTUnwrap(RecordDay.interval(forKey: "2026-09-24", calendar: london, schedule: schedule))
        XCTAssertEqual(thursday.start, at(24, 4))
        XCTAssertEqual(thursday.end, at(25, 6))
        XCTAssertEqual(RecordDay.next(thursday, calendar: london, schedule: schedule), friday)
        XCTAssertEqual(RecordDay.previous(friday, calendar: london, schedule: schedule), thursday)
        XCTAssertNil(RecordDay.interval(forKey: "not a key", calendar: london, schedule: schedule))
    }

    /// The reminder horizon steps day by day with `next`; each day's start
    /// is the day start in force for that day.
    func testReminderHorizonDaysStartAtTheirOwnDayStart() throws {
        let store = try storeWithDayStart(6)
        let schedule = try store.dayStartSchedule()
        var day = RecordDay.interval(containing: at(24, 20), calendar: london, schedule: schedule)
        var starts: [Date] = []
        for _ in 0..<3 {
            starts.append(day.start)
            day = RecordDay.next(day, calendar: london, schedule: schedule)
        }
        XCTAssertEqual(starts, [at(24, 4), at(25, 6), at(26, 6)])
    }

    // MARK: The day an earlier day start takes effect (mm-t13.12)

    /// 04:00 up to Thursday and 02:00 from Friday. At 03:00 on Friday the
    /// current record day is Friday, which started at 02:00. The two-step
    /// lookup computed the key at 04:00 first and reported Thursday.
    func testEarlierDayStartOnItsFirstDay() throws {
        let store = try storeWithDayStart(2)
        let schedule = try store.dayStartSchedule()
        let now = at(25, 3)
        XCTAssertEqual(RecordDay.key(containing: now, calendar: london, schedule: schedule), "2026-09-25")
        let current = RecordDay.interval(containing: now, calendar: london, schedule: schedule)
        XCTAssertEqual(current.start, at(25, 2))
        XCTAssertFalse(RecordDay.isNight(now, inRecordDay: current, calendar: london), "03:00 after a 02:00 day start is not night")

        let thursday = RecordDay.previous(current, calendar: london, schedule: schedule)
        XCTAssertEqual(thursday.start, at(24, 4))
        XCTAssertEqual(thursday.end, at(25, 2))
        XCTAssertEqual(thursday.duration, 22 * 3600, "the day before an earlier day start is 22 hours")
    }

    /// A second change on that day takes effect from Saturday, not from
    /// Friday, which is already under way.
    func testSetDayStartOnTheDayAnEarlierStartTakesEffect() throws {
        let store = try storeWithDayStart(2)
        try store.setDayStartHour(5, now: at(25, 3), calendar: london, changedAt: at(25, 3))
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-25"), 2, "Friday keeps the hour it started with")
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-26"), 5)
    }

    // MARK: The start day choice

    func testStartDayChoiceUsesTheDayStartInForce() throws {
        let store = try storeWithDayStart(6)
        let schedule = try store.dayStartSchedule()
        let now = at(25, 5)
        XCTAssertEqual(StartDayChoice.dayKey(for: .today, now: now, calendar: london, schedule: schedule), "2026-09-24")
        XCTAssertEqual(StartDayChoice.dayKey(for: .tomorrow, now: now, calendar: london, schedule: schedule), "2026-09-25")
    }
}
