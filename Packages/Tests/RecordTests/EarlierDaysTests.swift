import Foundation
import XCTest
@testable import Record

/// record spec, "Earlier record days" (mm-t12.24).
@MainActor
final class EarlierDaysTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private func london(_ hour: Int, _ minute: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    /// Scenario: Open an earlier day.
    func testOpenAnEarlierDay() throws {
        let store = try makeStore()
        try store.add(time: london(9, 0, day: 21), what: "Cereal", feltLikeABinge: false, createdAt: london(9, 0, day: 21), utcOffsetSeconds: 3600)
        let rows = try store.entries(dayKey: "2026-09-21")
        XCTAssertEqual(rows.map(\.what), ["Cereal"])
    }

    /// Scenario: The list shows dates only. Monday 21 September has
    /// entries and Tuesday 22 September has none: the list still shows
    /// both, most recent first (mm-t12b.15).
    func testTheListShowsDatesOnly() throws {
        let store = try makeStore()
        for minute in 0..<15 {
            try store.add(time: london(9, minute, day: 21), what: "Entry \(minute)", feltLikeABinge: false, createdAt: london(9, minute, day: 21), utcOffsetSeconds: 3600)
        }
        let content = try store.dateKeysWithContent(before: "2026-09-23")
        XCTAssertEqual(content, ["2026-09-21"], "Tuesday 22 September has no content")
        let list = EarlierDays.list(dateKeysWithContent: content, previousRecordDayKey: "2026-09-23")
        XCTAssertEqual(list, ["2026-09-22", "2026-09-21"], "most recent first, with the empty day too")
    }

    /// The list starts at the earliest day with content, ends at the day
    /// before the previous record day, and steps across a month end.
    func testTheListRunsFromTheEarliestContentDayAcrossAMonthEnd() {
        let list = EarlierDays.list(dateKeysWithContent: ["2026-08-30", "2026-09-03"], previousRecordDayKey: "2026-09-02")
        XCTAssertEqual(list, ["2026-09-01", "2026-08-31", "2026-08-30"])
        XCTAssertEqual(EarlierDays.list(dateKeysWithContent: ["2026-09-02"], previousRecordDayKey: "2026-09-02"), [])
        XCTAssertEqual(EarlierDays.list(dateKeysWithContent: [], previousRecordDayKey: "2026-09-02"), [])
    }

    /// Scenario: Move between days, and Scenario: Return to Today. The
    /// day-navigation arithmetic is `RecordDay.next`/`.previous`, already
    /// covered by "Current record day" tests; this proves the round trip.
    func testMoveBetweenDaysAndReturnToToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let monday = RecordDay.interval(containing: london(12, 0, day: 21), calendar: calendar, schedule: .standard)
        let tuesday = RecordDay.next(monday, calendar: calendar, schedule: .standard)
        XCTAssertEqual(RecordDay.key(containing: tuesday.start, calendar: calendar, schedule: .standard), "2026-09-22")
        XCTAssertEqual(RecordDay.previous(tuesday, calendar: calendar, schedule: .standard).start, monday.start, "back to Monday")
    }

    /// Scenario: No earlier day yet.
    func testNoEarlierDayYet() throws {
        let store = try makeStore()
        try store.add(time: london(20, 0, day: 23), what: "First entry", feltLikeABinge: false, createdAt: london(20, 0, day: 23), utcOffsetSeconds: 3600)
        let content = try store.dateKeysWithContent(before: "2026-09-24")
        XCTAssertFalse(EarlierDays.isAvailable(dateKeysWithContent: content, previousRecordDayKey: "2026-09-23"))
    }

    /// Scenario: An earlier day with a state only.
    func testAnEarlierDayWithAStateOnly() throws {
        let store = try makeStore()
        try store.setDayState(.didntRecord, on: true, dateKey: "2026-09-21", changedAt: london(9, 0, day: 21))
        let content = try store.dateKeysWithContent(before: "2026-09-23")
        XCTAssertTrue(EarlierDays.isAvailable(dateKeysWithContent: content, previousRecordDayKey: "2026-09-22"))
        XCTAssertEqual(EarlierDays.list(dateKeysWithContent: content, previousRecordDayKey: "2026-09-22"), ["2026-09-21"])
    }
}
