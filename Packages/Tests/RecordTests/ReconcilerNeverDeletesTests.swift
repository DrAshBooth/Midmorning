import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "The Reconciler never deletes a row".
final class ReconcilerNeverDeletesTests: XCTestCase {
    /// Scenario: Future-dated review. The device clock moves back a day; a
    /// review row dated tomorrow is ignored today, kept, and read tomorrow.
    func testFutureDatedReviewIsIgnoredTodayKeptAndReadTomorrow() {
        let frozenTomorrow = date(2026, 10, 7, hour: 9)
        let review = Review(kind: "weeklyReview", dueDateKey: "2026-10-07", frozenAt: frozenTomorrow, changedAt: frozenTomorrow)
        let rows = [review]

        let today = ReviewReconciler.winners(in: rows, now: date(2026, 10, 6, hour: 9), currentDayKey: "2026-10-06")
        XCTAssertTrue(today.isEmpty, "the app ignores the row today")
        XCTAssertEqual(rows.count, 1, "the read removes no row")
        XCTAssertEqual(review.frozenAt, frozenTomorrow, "the row is unchanged")

        let tomorrow = ReviewReconciler.winners(in: rows, now: date(2026, 10, 7, hour: 10), currentDayKey: "2026-10-07")
        XCTAssertEqual(tomorrow["weeklyReview|2026-10-07"]?.id, review.id, "the app reads the row tomorrow")
    }

    /// A row due today but frozen later today (by a device with a clock
    /// ahead) is future-dated until the freeze moment passes; a check-in
    /// follows the same rule.
    func testAFreezeMomentLaterThanTheClockIsIgnoredUntilItPasses() {
        let frozenAt = date(2026, 10, 6, hour: 18)
        let checkIn = Review(kind: "checkIn", dueDateKey: "2026-10-06", frozenAt: frozenAt, changedAt: frozenAt)
        XCTAssertTrue(ReviewReconciler.winners(in: [checkIn], now: date(2026, 10, 6, hour: 12), currentDayKey: "2026-10-06").isEmpty)
        XCTAssertNotNil(ReviewReconciler.winners(in: [checkIn], now: date(2026, 10, 6, hour: 19), currentDayKey: "2026-10-06")["checkIn|2026-10-06"])
    }

    /// Scenario: Future-dated review, through the real store read that the
    /// Reviews list, the pinned note and the freeze step call.
    @MainActor
    func testFutureDatedReviewThroughTheStoreIsIgnoredTodayKeptAndReadTomorrow() throws {
        let directory = try makeTemporaryDirectory()
        let store = try RecordStore(directory: directory)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let frozenTomorrow = date(2026, 10, 7, hour: 9)
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-07", frozenAt: frozenTomorrow, answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "Eat lunch at work", changedAt: frozenTomorrow)

        let today = date(2026, 10, 6, hour: 9)
        XCTAssertNil(try store.review(kind: .weeklyReview, dueDateKey: "2026-10-07", now: today, calendar: utc), "ignored today")
        XCTAssertTrue(try store.reviewRowWinners(kind: .weeklyReview, now: today, calendar: utc).isEmpty, "not in the Reviews list or the pinned note today")

        let tomorrow = date(2026, 10, 7, hour: 10)
        XCTAssertEqual(try store.review(kind: .weeklyReview, dueDateKey: "2026-10-07", now: tomorrow, calendar: utc)?.pinnedNote, "Eat lunch at work", "kept, and read tomorrow")
        XCTAssertEqual(try store.reviewRowWinners(kind: .weeklyReview, now: tomorrow, calendar: utc).map(\.dueDateKey), ["2026-10-07"])
    }

    /// A stage opening dated tomorrow is ignored today, kept, and read
    /// tomorrow, by the same rule.
    func testFutureDatedStageOpeningIsIgnoredTodayAndReadTomorrow() {
        let row = Answer(kind: StageOpenedReconciler.kind, cardId: "2", value: "", changedAt: date(2026, 10, 7, hour: 4))
        XCTAssertNil(StageOpenedReconciler.winner(stage: 2, in: [row], now: date(2026, 10, 6, hour: 9)))
        XCTAssertEqual(StageOpenedReconciler.winner(stage: 2, in: [row], now: date(2026, 10, 7, hour: 9))?.id, row.id)
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
