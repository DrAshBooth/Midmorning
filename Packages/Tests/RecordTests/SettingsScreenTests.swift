import Foundation
import XCTest
@testable import Record

/// settings spec: "The Record group" (decision 65), "The Reminders group",
/// "The Privacy group". Every test is a pure function over a fresh store
/// with fixed dates.
@MainActor
final class SettingsScreenTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int, _ minute: Int, month: Int = 9, year: Int = 2026) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsScreenTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    // MARK: - The Record group: "Day starts at" (decision 65)

    func testDayStartDefaultsToFourWithNoRowWritten() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-24"), 4)
    }

    /// A change to "Day starts at" applies from the next day start, never
    /// from the day the person changed it.
    func testDayStartAppliesFromTheNextDayStartNotTheCurrentOne() throws {
        let store = try makeStore()
        let changeMoment = at(24, 13, 0) // record day 2026-09-24, current hour 4
        try store.setDayStartHour(6, now: changeMoment, calendar: london)

        // The record day already under way keeps the old hour...
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-24"), 4)
        // ...and the next record day picks up the new one.
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-25"), 6)
    }

    /// A change to "Day starts at" MUST NOT change any saved entry's record
    /// day: the entry's `dayKey` was fixed at save, from the hour in force
    /// then, and a later `Settings` row never recomputes it.
    func testDayStartChangeNeverMovesASavedEntrysRecordDay() throws {
        let store = try makeStore()
        let saved = try store.add(time: at(24, 5, 0), what: "Toast", feltLikeABinge: false, createdAt: at(24, 5, 0), utcOffsetSeconds: 3600, dayStartHour: 4)
        XCTAssertEqual(saved.dayKey, "2026-09-24")

        try store.setDayStartHour(6, now: at(24, 13, 0), calendar: london)

        let reread = try store.entries(dayKey: "2026-09-24")
        XCTAssertEqual(reread.first?.dayKey, "2026-09-24", "the saved entry's own day key never moves")
    }

    func testDayStartOnTwoDevicesKeepsBothAppendOnlyRows() throws {
        let store = try makeStore()
        try store.setDayStartHour(5, now: at(1, 12, 0), calendar: london, changedAt: at(1, 12, 0))
        try store.setDayStartHour(6, now: at(10, 12, 0), calendar: london, changedAt: at(10, 12, 0))
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-05"), 5, "the earlier row still applies before the later one's day")
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-11"), 6)
    }

    // MARK: - The Record group: "Gap bands" (on, syncs)

    func testGapBandsDefaultsOn() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.gapBandsOn())
    }

    func testGapBandsCanBeTurnedOff() throws {
        let store = try makeStore()
        try store.setGapBandsOn(false)
        XCTAssertFalse(try store.gapBandsOn())
    }

    // MARK: - The Reminders group: switches and times

    func testEveryReminderSwitchIsOnByDefault() throws {
        let store = try makeStore()
        for kind in RecordStore.ReminderSwitch.allCases {
            XCTAssertTrue(try store.reminderSwitchOn(kind), "\(kind) is on by default")
        }
    }

    func testATurnedOffSwitchStaysOffAndOthersAreUnaffected() throws {
        let store = try makeStore()
        try store.setReminderSwitch(false, .midday)
        XCTAssertFalse(try store.reminderSwitchOn(.midday))
        XCTAssertTrue(try store.reminderSwitchOn(.closeTheDay), "turning one switch off leaves every other switch's own state")
    }

    func testReminderTimeDefaultsMatchTheSpec() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.reminderTime(.setTodaysPlan), "07:30")
        XCTAssertEqual(try store.reminderTime(.closeTheDay), "21:45")
        XCTAssertEqual(try store.reminderTime(.weighIn), "07:30")
        XCTAssertEqual(try store.reminderTime(.weeklyReview), "18:00")
    }

    func testReminderTimeCanBeChangedAndSyncs() throws {
        let store = try makeStore()
        try store.setReminderTime("19:00", .weeklyReview)
        XCTAssertEqual(try store.reminderTime(.weeklyReview), "19:00")
        XCTAssertTrue(RecordSchema.models.contains { $0 == Settings.self }, "reminder times live in the synced schema")
    }

    func testExplicitWordingDefaultsOff() throws {
        let store = try makeStore()
        XCTAssertFalse(try store.explicitWordingOn())
        try store.setExplicitWordingOn(true)
        XCTAssertTrue(try store.explicitWordingOn())
    }

    func testRemindAgainDefaultsToFifteenMinutes() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.remindAgainMinutes(), 15)
        try store.setRemindAgainMinutes(30)
        XCTAssertEqual(try store.remindAgainMinutes(), 30)
    }

    func testQuietHoursDefaultsMatchTheSpec() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.quietHoursOn())
        XCTAssertEqual(try store.quietHoursStart(), "22:00")
        XCTAssertEqual(try store.quietHoursEnd(), "07:00")
    }

    /// Scenario: Reminders paused by the not-right-now page (built here over
    /// fixture facts; mm-t24.21 runs it end to end).
    func testRemindersPausedByTheNotRightNowPageShowsThePausedLine() throws {
        let store = try makeStore()
        XCTAssertNil(try store.remindersPausedAt())
        let pausedAt = at(24, 20, 15)
        try store.pauseReminders(at: pausedAt, changedAt: pausedAt)
        XCTAssertEqual(try store.remindersPausedAt(), pausedAt)
        // Every switch keeps its own state while paused.
        XCTAssertTrue(try store.reminderSwitchOn(.plannedMeals))
    }

    /// Scenario: Turn reminders on.
    func testTurnRemindersOnClearsThePausedFlag() throws {
        let store = try makeStore()
        try store.pauseReminders(at: at(24, 20, 15), changedAt: at(24, 20, 15))
        XCTAssertNotNil(try store.remindersPausedAt())
        try store.turnRemindersOn(changedAt: at(24, 20, 20))
        XCTAssertNil(try store.remindersPausedAt(), "the app clears remindersPausedAt")
    }

    // MARK: - The Weigh-in group (mm-t22.20)

    func testUnitDefaultsToKg() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.weighInUnit(), "kg")
    }

    /// Scenario: Change the unit.
    func testChangeTheUnit() throws {
        let store = try makeStore()
        try store.setWeighInUnit("stLb")
        XCTAssertEqual(try store.weighInUnit(), "stLb", "the weigh-in screen and the export read the same row from then on")
    }

    /// The Weigh-in group's "Weigh-in day" reads and writes the same row the
    /// weigh-in screen's own control uses.
    func testWeighInDayIsTheSameRowAsTheWeighInScreen() throws {
        let store = try makeStore()
        try store.setWeighInDayChoice(.weekday(6))
        XCTAssertEqual(try store.weighInDayChoice(), .weekday(6))
    }

    // MARK: - The Privacy group: "Delete everything" calls a stub seam

    func testStubDeleteAllSeamDoesNothingAndNeverThrows() {
        let seam: DeleteAllSeam = StubDeleteAllSeam()
        XCTAssertNoThrow(try seam.deleteEverything())
    }
}
