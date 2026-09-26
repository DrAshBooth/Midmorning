import Foundation
import XCTest
@testable import Record

/// The store-level scenarios of programme spec, "Start week 1 again"
/// (mm-t21.17) and safeguarding spec, "Re-screening at a restart"
/// (mm-t36.1): the ones that need the real store. `Record`'s
/// `StartDayChoice` and `RecordStore.setStartDayKey` already exist
/// (onboarding); this bead's own addition is `restartAt`/`setRestartAt`.
@MainActor
final class RestartStoreTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Scenario: Restart today.
    func testRestartToday() throws {
        let store = try makeStore()
        try store.setStartDayKey("2027-01-01", changedAt: at(2027, 1, 1, 9))
        let now = at(2027, 1, 15, 10)
        let choice = StartDayChoice.dayKey(for: .today, now: now, calendar: london, schedule: .standard)
        try store.setStartDayKey(choice, changedAt: now)
        try store.setRestartAt(now, changedAt: now)
        XCTAssertEqual(try store.startDayKey(), "2027-01-15")
        XCTAssertEqual(try store.restartAt(), now)
    }

    /// Scenario: Restart tomorrow.
    func testRestartTomorrow() throws {
        let store = try makeStore()
        let now = at(2027, 1, 15, 10)
        let choice = StartDayChoice.dayKey(for: .tomorrow, now: now, calendar: london, schedule: .standard)
        try store.setStartDayKey(choice, changedAt: now)
        XCTAssertEqual(try store.startDayKey(), "2027-01-16")
    }

    /// Scenario: Cancel. The app never calls `setStartDayKey` or
    /// `setRestartAt` on "Cancel"; the start day is unchanged by
    /// construction.
    func testCancel() throws {
        let store = try makeStore()
        try store.setStartDayKey("2027-01-01", changedAt: at(2027, 1, 1, 9))
        // "Cancel": no further write.
        XCTAssertEqual(try store.startDayKey(), "2027-01-01")
        XCTAssertNil(try store.restartAt())
    }

    /// Scenario: A restart in week 1. Restarting keeps every entry — the
    /// restart writes only the start day and the restart moment, never an
    /// `ItemVersion`.
    func testARestartInWeek1KeepsEveryEntry() throws {
        let store = try makeStore()
        try store.setStartDayKey("2027-01-01", changedAt: at(2027, 1, 1, 9))
        _ = try store.add(time: at(2027, 1, 2, 9), what: "Toast", feltLikeABinge: false, createdAt: at(2027, 1, 2, 9), utcOffsetSeconds: 0)
        let now = at(2027, 1, 3, 10)
        try store.setStartDayKey(StartDayChoice.dayKey(for: .today, now: now, calendar: london, schedule: .standard), changedAt: now)
        XCTAssertEqual(try store.entries(dayKey: "2027-01-02").count, 1, "the entry from before the restart stays")
    }

    /// Scenario: The restart's height wins on another device (safeguarding
    /// spec, "Re-screening at a restart"). `Profile`'s own winner rule
    /// (later `changedAt`, whole row) already covers this; the re-screen
    /// just calls `setProfile` again with a later moment, the same as any
    /// other device's write.
    func testTheRestartsHeightWinsOnAnotherDevice() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: at(2026, 1, 5, 9), changedAt: at(2026, 1, 5, 9))
        try store.setProfile(heightCm: 172, onboardingBMI: 21.97, cautionFlag: false, askedAt: at(2026, 6, 1, 9), changedAt: at(2026, 6, 1, 9))
        XCTAssertEqual(try store.profile()?.heightCm, 172, "every device reads 172, the later changedAt")
    }
}
