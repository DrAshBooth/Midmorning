import Foundation
import XCTest
@testable import Record

/// record spec, "The gap band": the "Gap bands" switch (mm-t13.11) and the
/// record day stage 2 opened (mm-t12b.18). Each test runs the composition
/// that `DaySection.load` runs in the App target: it reads the switch from
/// the store, passes `GapBand.applies` as `indexesBeforeBand`'s
/// `stage2Open`, and reads the day's entry times from the store.
@MainActor
final class GapBandGateTests: XCTestCase {
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

    /// Adds entries at 08:00 and 13:30 on `day` and returns the day's key.
    private func addGapDay(_ store: RecordStore, day: Int) throws -> String {
        try store.add(time: london(8, 0, day: day), what: "Toast", feltLikeABinge: false, createdAt: london(8, 0, day: day), utcOffsetSeconds: 3600)
        try store.add(time: london(13, 30, day: day), what: "Soup", feltLikeABinge: false, createdAt: london(13, 30, day: day), utcOffsetSeconds: 3600)
        return String(format: "2026-09-%02d", day)
    }

    /// The same call `DaySection.load` makes.
    private func bands(_ store: RecordStore, dayKey: String, stage2OpenedDayKey: String?) throws -> [Int] {
        GapBand.indexesBeforeBand(
            sortedTimes: try store.entries(dayKey: dayKey).map(\.time),
            stage2Open: GapBand.applies(toDayKey: dayKey, stage2OpenedDayKey: stage2OpenedDayKey, switchOn: try store.gapBandsOn()),
            dayHasExemptState: false,
            isCollapsed: false,
            maxAwakeGapHours: 4
        )
    }

    /// Scenario: Gap over four hours, with the switch at its default (on).
    func testTheSwitchIsOnByDefaultAndABandShows() throws {
        let store = try makeStore()
        let dayKey = try addGapDay(store, day: 24)
        XCTAssertTrue(try store.gapBandsOn())
        XCTAssertEqual(try bands(store, dayKey: dayKey, stage2OpenedDayKey: "2026-09-20"), [0])
    }

    /// With "Gap bands" off in Settings, entries at 08:00 and 13:30 show no
    /// band, although stage 2 is open.
    func testTheSwitchOffShowsNoBand() throws {
        let store = try makeStore()
        let dayKey = try addGapDay(store, day: 24)
        try store.setGapBandsOn(false)
        XCTAssertEqual(try bands(store, dayKey: dayKey, stage2OpenedDayKey: "2026-09-20"), [])

        try store.setGapBandsOn(true)
        XCTAssertEqual(try bands(store, dayKey: dayKey, stage2OpenedDayKey: "2026-09-20"), [0], "on again, the band shows again")
    }

    /// A band shows on every day from the record day stage 2 opened: the
    /// previous day and an earlier day as well as the current day.
    func testBandsShowOnEveryDayFromTheStage2Day() throws {
        let store = try makeStore()
        let stage2Day = try addGapDay(store, day: 20)
        let earlier = try addGapDay(store, day: 22)
        let previous = try addGapDay(store, day: 25)
        let current = try addGapDay(store, day: 26)
        for dayKey in [stage2Day, earlier, previous, current] {
            XCTAssertEqual(try bands(store, dayKey: dayKey, stage2OpenedDayKey: "2026-09-20"), [0], dayKey)
        }
    }

    /// Scenario: Before stage 2, and "The app MUST NOT show a band on a day
    /// before that record day".
    func testNoBandBeforeTheStage2DayOrWhileStage2IsClosed() throws {
        let store = try makeStore()
        let before = try addGapDay(store, day: 19)
        XCTAssertEqual(try bands(store, dayKey: before, stage2OpenedDayKey: "2026-09-20"), [])
        XCTAssertEqual(try bands(store, dayKey: before, stage2OpenedDayKey: nil), [])
    }
}
