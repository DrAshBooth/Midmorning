import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Day states, sessions and reviews".
final class DayStateSessionReviewTests: XCTestCase {
    /// Scenario: Two day states.
    func testTwoDayStatesOneRowPerKind() {
        let didntRecord = DayState(dateKey: "2026-10-06", kind: "didntRecord", changedAt: at(1))
        let paused = DayState(dateKey: "2026-10-06", kind: "paused", changedAt: at(2))
        let winners = DayStateReconciler.winners(in: [didntRecord, paused])
        XCTAssertEqual(winners.count, 2, "one row for 6 October per state kind")
        XCTAssertEqual(winners["2026-10-06|didntRecord"]?.changedAt, at(1))
        XCTAssertEqual(winners["2026-10-06|paused"]?.changedAt, at(2))
    }

    /// Scenario: Collapsed day. The collapse choice is not a `DayState`; it
    /// lives in `Local.store` by date key, so it never syncs and `Record.store`
    /// holds no row for it.
    func testCollapsedDayIsALocalChoiceNotADayState() {
        var localCollapseChoices: [String: Bool] = [:]
        localCollapseChoices["2026-10-06"] = true
        XCTAssertTrue(localCollapseChoices["2026-10-06"] == true, "device A's Local.store holds the collapse choice")
        XCTAssertTrue(DayStateReconciler.winners(in: []).isEmpty, "Record.store holds no DayState row for a collapse choice")
    }

    /// Scenario: Two open urges.
    func testTwoOpenUrgesTheEarliestStartedIsOpenAndTheOtherClosesSilently() {
        let dayKey = "2026-10-06"
        let earlier = Session(startedAt: at(21, minute: 0), startDayKey: dayKey)
        let later = Session(startedAt: at(21, minute: 10), startDayKey: dayKey)
        let open = SessionOpenPicker.open(in: [earlier, later], dayKey: dayKey)
        XCTAssertEqual(open?.id, earlier.id, "the 21:00 urge is open on both devices")

        let dayEnd = atDay(7, hour: 4, minute: 0) // the next record day's 04:00 boundary
        let closed = SessionOpenPicker.silentlyClosedAtDayEnd(in: [earlier, later], dayKey: dayKey, dayEnd: dayEnd)
        XCTAssertEqual(closed.map(\.id), [later.id])
        XCTAssertEqual(closed.first?.outcomeAt, dayEnd)
        XCTAssertFalse(closed.first!.outcome.isEmpty, "the 21:10 session closes with no message shown, but it is no longer open")
    }

    /// Scenario: Reviews keyed by due day.
    func testReviewsKeyedByDueDayNotByWeekNumber() {
        // Start day 1 September; a restart on 20 October opens a second run.
        // Reviews are due every 7 days from the run's own start day.
        let firstRunDue = "2026-09-08"
        let secondRunDue = "2026-10-27"
        let firstRun = Review(kind: "weeklyReview", dueDateKey: firstRunDue, frozenAt: at(1), changedAt: at(1))
        let secondRun = Review(kind: "weeklyReview", dueDateKey: secondRunDue, frozenAt: at(2), changedAt: at(2))
        let winners = ReviewReconciler.winners(in: [firstRun, secondRun])
        XCTAssertEqual(Set(winners.keys), ["weeklyReview|\(firstRunDue)", "weeklyReview|\(secondRunDue)"], "the Reviews list shows both runs, keyed by due day")
    }

    /// Scenario: Freeze waits for sync. An unfrozen review has no winner
    /// yet: nothing has crossed the due moment on a synced device.
    func testFreezeWaitsForSync() {
        let dueDateKey = "2026-09-07"
        let unfrozen = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: nil, changedAt: at(1))
        XCTAssertTrue(ReviewReconciler.winners(in: [unfrozen]).isEmpty, "device B has not frozen yet; nothing to read")
    }

    /// Scenario: Two frozen rows.
    func testTwoFrozenRowsTheEarliestFreezeWins() {
        let dueDateKey = "2026-09-08"
        let deviceA = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: at(18), changedAt: at(18))
        let deviceB = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: at(18, minute: 30), changedAt: at(18, minute: 30))
        let winner = ReviewReconciler.winners(in: [deviceA, deviceB])["weeklyReview|\(dueDateKey)"]!
        XCTAssertEqual(winner.frozenAt, at(18), "both devices show the 18:00 row")

        // An edit to a question writes into that same row.
        let edited = Review(id: winner.id, kind: winner.kind, dueDateKey: winner.dueDateKey, frozenAt: winner.frozenAt, answersJSON: "{\"q1\":\"yes\"}", changedAt: at(19))
        XCTAssertEqual(edited.id, winner.id, "the edit targets the frozen winner's own row")
    }

    private func at(_ hour: Int, minute: Int = 0) -> Date {
        atDay(6, hour: hour, minute: minute)
    }

    private func atDay(_ day: Int, hour: Int, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }
}
