import Foundation
import XCTest
@testable import Record

@MainActor
final class RecordStoreTests: XCTestCase {
    /// From the walking skeleton: saves entries around the 04:00 boundary,
    /// reopens the store, and asserts what Today reads — now backed by
    /// append-only `ItemVersion` rows read through `EntryWinner`.
    func testEntriesSurviveReopenAndComeBackInRecordDayOrder() throws {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let londonOffset = 3600
        func at(_ day: Int, _ hour: Int, _ minute: Int, month: Int = 9) -> Date {
            london.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecordStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        // First container: save entries out of time order, with fixed creation moments.
        var store: RecordStore? = try RecordStore(directory: directory)
        try store!.add(time: at(24, 13, 5), what: "Toast and tea", feltLikeABinge: true, createdAt: at(24, 13, 8), utcOffsetSeconds: londonOffset)
        try store!.add(time: at(24, 8, 10), what: "Porridge", feltLikeABinge: false, createdAt: at(24, 9, 0), utcOffsetSeconds: londonOffset)
        try store!.add(time: at(25, 0, 30), what: "Crisps", feltLikeABinge: false, createdAt: at(25, 0, 31), utcOffsetSeconds: londonOffset)
        try store!.add(time: at(24, 3, 59), what: "Soup", feltLikeABinge: false, createdAt: at(24, 4, 0), utcOffsetSeconds: londonOffset)
        try store!.add(time: at(24, 4, 0), what: "Tea", feltLikeABinge: false, createdAt: at(24, 4, 1), utcOffsetSeconds: londonOffset)
        try store!.add(time: at(24, 13, 5), what: "", feltLikeABinge: false, createdAt: at(24, 13, 7), utcOffsetSeconds: londonOffset)
        let trimmed = try store!.add(time: at(24, 20, 0).addingTimeInterval(42), what: "  Toast and tea \n", feltLikeABinge: false, createdAt: at(24, 20, 1), utcOffsetSeconds: londonOffset)
        XCTAssertEqual(trimmed.what, "Toast and tea")
        XCTAssertEqual(trimmed.time, at(24, 20, 0), "time is stored to the minute")
        store = nil

        // Second container on the same directory: the entries survived.
        let reopened = try RecordStore(directory: directory)
        let expected: [(String, String, Bool, Date)] = [
            ("04:00", "Tea", false, at(24, 4, 1)),
            ("08:10", "Porridge", false, at(24, 9, 0)),
            ("13:05", "", false, at(24, 13, 7)),
            ("13:05", "Toast and tea", true, at(24, 13, 8)),
            ("20:00", "Toast and tea", false, at(24, 20, 1)),
            ("00:30", "Crisps", false, at(25, 0, 31)),
        ]
        for moment in [at(24, 13, 30), at(25, 1, 0)] {
            let day = try reopened.entries(recordDayContaining: moment, calendar: london)
            XCTAssertEqual(day.map(\.clockTime), expected.map(\.0), "query at \(moment)")
            XCTAssertEqual(day.map(\.what), expected.map(\.1))
            XCTAssertEqual(day.map(\.feltLikeABinge), expected.map(\.2))
            XCTAssertEqual(day.map(\.createdAt), expected.map(\.3))
            XCTAssertFalse(day.contains { $0.what == "Soup" }, "03:59 is the previous record day")
        }

        // Labels.
        let day = try reopened.entries(recordDayContaining: at(24, 13, 30), calendar: london)
        XCTAssertEqual(day[3].accessibilityLabel.english, "13:05, Toast and tea, felt like a binge")
        XCTAssertEqual(day[2].accessibilityLabel.english, "13:05")

        // Record days are fixed at save from the entry's own offset. A viewer in
        // New York on the same key sees the same day, and the London entry still
        // reads 20:00.
        XCTAssertEqual(day.map(\.dayKey), Array(repeating: "2026-09-24", count: 6))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let seenFromNewYork = try reopened.entries(recordDayContaining: at(24, 22, 0), calendar: newYork)
        XCTAssertEqual(seenFromNewYork.map(\.clockTime), expected.map(\.0), "the same record day from New York, keyed at save")
        XCTAssertEqual(RecordDay.key(for: at(25, 0, 30), utcOffsetSeconds: londonOffset, schedule: .standard), "2026-09-24")
        XCTAssertEqual(RecordDay.key(for: at(25, 0, 30), utcOffsetSeconds: londonOffset, startHour: 0), "2026-09-25", "a day start of 00:00 puts 00:30 on the 25th")

        // Clock change: the record day of Saturday 24 October 2026 is 25 hours long.
        let clockChange = RecordDay.interval(containing: at(25, 1, 0, month: 10), calendar: london, schedule: .standard)
        XCTAssertEqual(clockChange.start, at(24, 4, 0, month: 10))
        XCTAssertEqual(clockChange.duration, 25 * 3600)

        // Night.
        let thursday = RecordDay.interval(containing: at(24, 13, 30), calendar: london, schedule: .standard)
        XCTAssertTrue(RecordDay.isNight(at(25, 1, 0), inRecordDay: thursday, calendar: london))
        XCTAssertFalse(RecordDay.isNight(at(24, 13, 30), inRecordDay: thursday, calendar: london))
    }

    /// mm-t12.4, "Two files": Record.store and Local.store, each with their
    /// own -wal and -shm, and nothing else in the directory.
    func testTwoStoreConfigurationsInOneDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecordStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        // Keep the container open: the -wal and -shm sidecar files exist
        // only while a connection is live.
        let store = try RecordStore(directory: directory)
        try store.add(time: Date(), what: "Toast", feltLikeABinge: false, createdAt: Date(), utcOffsetSeconds: 0)

        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        let stems = Set(names.map { ($0 as NSString).deletingPathExtension })
        XCTAssertEqual(stems, ["Record", "Local"], "nothing else lives in the store directory")
        XCTAssertTrue(names.contains("Record.store"))
        XCTAssertTrue(names.contains("Local.store"))
        withExtendedLifetime(store) {}
    }
}
