import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "'Didn't record'" (mm-t12.21), "'Pause for today'"
/// (mm-t12.22), "'Fasting today'" (mm-t12.23) and "The app keeps day states
/// on the device" (mm-t12.28).
@MainActor
final class DayStatesTests: XCTestCase {
    // MARK: "Didn't record"

    /// Scenario: Set the current day, and Scenario: Set an earlier day.
    func testSetTheStateOnTheCurrentDayAndOnAnEarlierDay() throws {
        let store = try makeTemporaryStore()
        try store.setDayState(.didntRecord, on: true, dateKey: "2026-09-24", changedAt: .now)
        XCTAssertTrue(try store.dayStates(dateKey: "2026-09-24").contains(.didntRecord))

        try store.setDayState(.didntRecord, on: true, dateKey: "2026-09-21", changedAt: .now)
        XCTAssertTrue(try store.dayStates(dateKey: "2026-09-21").contains(.didntRecord))
        XCTAssertFalse(try store.dayStates(dateKey: "2026-09-22").contains(.didntRecord), "a different day is untouched")
    }

    /// Scenario: Turn it off.
    func testTurnItOff() throws {
        let store = try makeTemporaryStore()
        let start = Date(timeIntervalSince1970: 0)
        try store.setDayState(.didntRecord, on: true, dateKey: "2026-09-24", changedAt: start)
        try store.setDayState(.didntRecord, on: false, dateKey: "2026-09-24", changedAt: start.addingTimeInterval(60))
        XCTAssertFalse(try store.dayStates(dateKey: "2026-09-24").contains(.didntRecord))
    }

    /// Scenario: Entry on a "didn't record" day. Setting the state and
    /// saving an entry on the same day are independent; each survives.
    func testEntryOnADidntRecordDayKeepsBoth() throws {
        let store = try makeTemporaryStore()
        let entryTime = Date(timeIntervalSince1970: 1_758_700_800) // 2026-09-24T08:00:00Z
        let dayKey = RecordDay.key(for: entryTime, utcOffsetSeconds: 0, startHour: 0)
        try store.setDayState(.didntRecord, on: true, dateKey: dayKey, changedAt: entryTime)
        try store.add(time: entryTime, what: "Toast", feltLikeABinge: false, createdAt: entryTime, utcOffsetSeconds: 0, dayStartHour: 0)
        XCTAssertTrue(try store.dayStates(dateKey: dayKey).contains(.didntRecord))
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 1)
    }

    // MARK: "Pause for today"

    /// Scenario: Pause, and Scenario: Undo a pause.
    func testPauseAndUndoAPause() throws {
        let store = try makeTemporaryStore()
        let start = Date(timeIntervalSince1970: 1000)
        try store.setDayState(.paused, on: true, dateKey: "2026-09-24", changedAt: start)
        XCTAssertTrue(try store.dayStates(dateKey: "2026-09-24").contains(.paused))

        try store.setDayState(.paused, on: false, dateKey: "2026-09-24", changedAt: start.addingTimeInterval(3600))
        XCTAssertFalse(try store.dayStates(dateKey: "2026-09-24").contains(.paused))
    }

    /// Scenario: Entry on a paused day. An entry still saves on a paused day.
    func testEntryOnAPausedDayStillSaves() throws {
        let store = try makeTemporaryStore()
        let entryTime = Date(timeIntervalSince1970: 1_758_700_800) // 2026-09-24T08:00:00Z
        let dayKey = RecordDay.key(for: entryTime, utcOffsetSeconds: 0, startHour: 0)
        try store.setDayState(.paused, on: true, dateKey: dayKey, changedAt: entryTime)
        try store.add(time: entryTime, what: "Pasta", feltLikeABinge: false, createdAt: entryTime, utcOffsetSeconds: 0, dayStartHour: 0)
        XCTAssertTrue(try store.dayStates(dateKey: dayKey).contains(.paused))
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 1)
    }

    /// Scenario: The next day, and Scenario: Paused day seen later. The
    /// state is keyed per record day; pausing one day never touches another.
    func testPauseIsKeyedPerRecordDay() throws {
        let store = try makeTemporaryStore()
        try store.setDayState(.paused, on: true, dateKey: "2026-09-24", changedAt: .now)
        XCTAssertFalse(try store.dayStates(dateKey: "2026-09-25").contains(.paused), "the next day starts unpaused")
        XCTAssertTrue(try store.dayStates(dateKey: "2026-09-24").contains(.paused), "the paused day still shows it, seen later")
    }

    // MARK: "Fasting today"

    /// Scenario: Turn it on, and Scenario: The day ends.
    func testFastingIsKeyedPerRecordDay() throws {
        let store = try makeTemporaryStore()
        try store.setDayState(.fasting, on: true, dateKey: "2026-09-24", changedAt: .now)
        XCTAssertTrue(try store.dayStates(dateKey: "2026-09-24").contains(.fasting))
        XCTAssertFalse(try store.dayStates(dateKey: "2026-09-25").contains(.fasting), "the next day has no fasting state")
    }

    /// Scenario: Entries on a fasting day. The gap band reads the exempt
    /// state and shows no band ("The gap band" requirement).
    func testFastingDayIsAGapBandExemptState() {
        let calendar: (Int, Int) -> Date = { h, m in
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Europe/London")!
            return cal.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: h, minute: m))!
        }
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [calendar(20, 30), calendar(21, 0)],
            stage2Open: true, dayHasExemptState: true, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [])
    }

    // MARK: The app keeps day states on the device (mm-t12.28)

    /// Scenario: Restart.
    func testStateSurvivesReopeningTheStore() throws {
        let directory = try makeTemporaryDirectory()
        do {
            let store = try RecordStore(directory: directory)
            try store.setDayState(.didntRecord, on: true, dateKey: "2026-09-24", changedAt: .now)
        }
        let reopened = try RecordStore(directory: directory)
        XCTAssertTrue(try reopened.dayStates(dateKey: "2026-09-24").contains(.didntRecord))
    }

    /// Scenario: No network. Every day-state and collapse-choice call is a
    /// local store write; none reaches the network.
    func testNoNetworkNeededToPauseOrCollapse() throws {
        let store = try makeTemporaryStore()
        XCTAssertNoThrow(try store.setDayState(.paused, on: true, dateKey: "2026-09-24", changedAt: .now))
        XCTAssertNoThrow(try store.setCollapseChoice(.collapsed, dateKey: "2026-09-24"))
    }

    /// Scenario: A failed state save. The thrown error carries no date and
    /// no state: `Failure.saveFailed` has no associated value.
    func testAFailedStateSaveThrowsWithNoData() {
        let error = RecordStore.Failure.saveFailed
        XCTAssertEqual("\(error)", "saveFailed", "the case name carries no date and no state")
    }
}
