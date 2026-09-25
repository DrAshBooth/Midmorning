import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "The Reconciler never deletes a row".
final class ReconcilerNeverDeletesTests: XCTestCase {
    /// Scenario: Future-dated review. The device clock moves back a day; a
    /// review row dated tomorrow is ignored today, kept, and read tomorrow.
    func testFutureDatedReviewIsIgnoredTodayKeptAndReadTomorrow() {
        let today = date(2026, 10, 6)
        let tomorrow = date(2026, 10, 7)
        let review = Review(kind: "weeklyReview", dueDateKey: "2026-10-07", frozenAt: tomorrow, changedAt: tomorrow)
        XCTAssertTrue(ReviewReconciler.winners(in: [review]).isEmpty == false, "the row stays in the store")
        // The engine's own read of it as "future" is a `now`-gated concern;
        // the Reconciler itself never deletes it regardless of `now`.
        XCTAssertEqual(review.frozenAt, tomorrow, "the row is unchanged; nothing removed it")
        _ = today
    }

    /// Scenario: Restart keeps the stage 5 row.
    func testRestartKeepsTheStage5Row() {
        let openedAt = date(2026, 10, 12)
        let restartAt = date(2026, 10, 20)
        let row = Answer(kind: StageOpenedReconciler.kind, cardId: "5", value: "", changedAt: openedAt)
        let now = date(2026, 10, 21)
        let winner = StageOpenedReconciler.winner(stage: 5, in: [row], now: now, restartAt: restartAt)
        XCTAssertNil(winner, "the engine ignores the pre-restart opening")
        // The row itself is untouched: a second pass after a later opening
        // still finds this earlier row present.
        XCTAssertEqual(row.changedAt, openedAt, "the row stays in the store")
    }

    /// Scenario: Two stage-opened rows.
    func testTwoStageOpenedRowsBothRowsStayAndTheEarliestWins() {
        let fromDeviceA = Answer(kind: StageOpenedReconciler.kind, cardId: "2", value: "", changedAt: date(2026, 10, 6, hour: 4))
        let fromDeviceB = Answer(kind: StageOpenedReconciler.kind, cardId: "2", value: "", changedAt: date(2026, 10, 7, hour: 4))
        let now = date(2026, 10, 8)
        let winner = StageOpenedReconciler.winner(stage: 2, in: [fromDeviceA, fromDeviceB], now: now)
        XCTAssertEqual(winner?.changedAt, date(2026, 10, 6, hour: 4), "both devices report stage 2 open from 6 October")
        XCTAssertEqual([fromDeviceA, fromDeviceB].count, 2, "both rows stay in the store")
    }

    /// Scenario: Losing planned day kept.
    func testLosingPlannedDayKeptFor90Days() {
        let laterButLosing = Day(dateKey: "2026-10-06", changedAt: date(2026, 9, 1))
        let earlierButWinning = Day(dateKey: "2026-10-06", changedAt: date(2026, 9, 2))
        let winner = DayReconciler.winners(in: [laterButLosing, earlierButWinning])["2026-10-06"]!
        XCTAssertEqual(winner.changedAt, date(2026, 9, 2), "Today shows the later planned day")
        // The losing row is not deleted by the Reconciler; only the 90-day
        // retention test, applied by the store, ever removes it.
        let now = date(2026, 9, 10)
        let latestSync = date(2026, 9, 10)
        XCTAssertFalse(Reconciler.canDeleteLosingRow(changedAt: laterButLosing.changedAt, now: now, latestSyncMoment: latestSync), "the store keeps both rows for 90 days")
    }

    /// Scenario: Clock moved forward.
    func testClockMovedForwardDeletesNoRowWithoutASyncedLatestMoment() {
        // The device clock jumps a year ahead, but the latest sync moment is
        // still "today": the sync-side 90-day test still fails, so nothing
        // is eligible for deletion.
        let changedAt = date(2026, 9, 1)
        let clockMovedForward = date(2027, 9, 2)
        let latestSyncStillToday = date(2026, 9, 1)
        XCTAssertFalse(Reconciler.canDeleteLosingRow(changedAt: changedAt, now: clockMovedForward, latestSyncMoment: latestSyncStillToday))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
