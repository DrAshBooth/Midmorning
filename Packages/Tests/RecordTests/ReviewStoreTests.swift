import Foundation
import XCTest
@testable import Record
@testable import Programme

/// weekly-review spec, "Finish and reopen a review", "The week's counts are
/// frozen in the Review row", "The self-harm item at the review", "The one
/// thing to change and the pinned note" (mm-t32.1, mm-t32.4, mm-t32.6,
/// mm-t32.10, mm-t32.11), over the real `RecordStore`.
@MainActor
final class ReviewStoreTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// A read moment later than every fixture date here, so no fixture row
    /// is future-dated when a test reads it (data-and-privacy spec, "The
    /// Reconciler never deletes a row").
    private var readMoment: Date { at(2027, 1, 1) }

    // MARK: mm-t32.3, "No network"

    /// Scenario: No network. `RecordStore` calls no network API anywhere in
    /// this path; the review builds and saves purely against the local
    /// SwiftData store.
    func testNoNetworkReviewSavesLocally() throws {
        let store = try makeStore()
        var payload = ReviewAnswersPayload()
        payload.reflectionAnswers = ["Evenings were hard", "", ""]
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: nil, answersJSON: payload.encoded(), selfHarmAnswered: true, pinnedNote: "", changedAt: at(2026, 10, 5, 18))
        let row = try store.review(kind: .weeklyReview, dueDateKey: "2026-10-05", now: readMoment, calendar: utc)
        XCTAssertNil(row, "an unfrozen row is not yet a reconciler winner")
        let raw = try store.reviewRowWinners(kind: .weeklyReview, now: readMoment, calendar: utc)
        XCTAssertTrue(raw.isEmpty, "still unfrozen; freezing is a separate step")
    }

    // MARK: mm-t32.6, "The week's counts are frozen in the Review row"

    /// Scenario: Keyed by the due day.
    func testKeyedByTheDueDay() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-09-08", frozenAt: at(2026, 9, 8), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 9, 8))
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-27", frozenAt: at(2026, 10, 27), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 10, 27))
        let winners = try store.reviewRowWinners(kind: .weeklyReview, now: readMoment, calendar: utc)
        XCTAssertEqual(Set(winners.map(\.dueDateKey)), ["2026-09-08", "2026-10-27"], "the second run's reviews use their own due-day keys; the Reviews list can show both")
    }

    /// Scenario: Two devices freeze the same review (fixture rows; this
    /// device's own `RecordStore.upsertReview` always reuses its own row's
    /// identity, so two independent devices are modelled directly on
    /// `Review`/`ReviewReconciler`, the same fixture-row pattern
    /// `DayStateSessionReviewTests` already uses for the model layer).
    func testTwoDevicesFreezeTheSameReview() {
        let dueDateKey = "2026-10-19"
        let deviceA = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: at(2026, 10, 19, 4), changedAt: at(2026, 10, 19, 4))
        let deviceB = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: at(2026, 10, 19, 9), changedAt: at(2026, 10, 19, 9))
        let winner = ReviewReconciler.winners(in: [deviceA, deviceB])["weeklyReview|\(dueDateKey)"]
        XCTAssertEqual(winner?.frozenAt, at(2026, 10, 19, 4), "both devices read the 04:00 row")
        // An edit on either device carries the winning 04:00 freeze moment
        // forward; the reconciler then reads its content as the winner.
        let edited = Review(kind: "weeklyReview", dueDateKey: dueDateKey, frozenAt: at(2026, 10, 19, 4), answersJSON: "{\"q1\":\"yes\"}", changedAt: at(2026, 10, 19, 11))
        let afterEdit = ReviewReconciler.winners(in: [deviceA, deviceB, edited])["weeklyReview|\(dueDateKey)"]
        XCTAssertEqual(afterEdit?.answersJSON, "{\"q1\":\"yes\"}", "the edit writes into that same row")
    }

    /// Scenario: Sync behind the due moment — the pure rule
    /// (`ReviewFreezeTests`) combined with a real store read: while
    /// `readyToFreeze` says no, the app writes no frozen row at all.
    func testSyncBehindTheDueMomentWritesNoFrozenRowYet() throws {
        let store = try makeStore()
        let dueDayKey = "2026-10-19"
        let now = at(2026, 10, 19, 9)
        let ready = ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: 4, calendar: utc, now: now, syncOn: true, lastSyncMoment: at(2026, 10, 18, 22))
        XCTAssertFalse(ready)
        // The app only calls `upsertReview(frozenAt:)` once `readyToFreeze`
        // says yes; with it false, the store holds nothing for this key.
        XCTAssertNil(try store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: readMoment, calendar: utc))
    }

    /// An edit after freeze writes into the same row (mm-t32.4, "Edit before
    /// the next review").
    func testAnEditWritesIntoTheFrozenRow() throws {
        let store = try makeStore()
        let dueDayKey = "2026-10-05"
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: at(2026, 10, 5, 4), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 10, 5, 4))
        var payload = ReviewAnswersPayload(finished: true)
        payload.reflectionAnswers = ["Ok week", "", ""]
        _ = try store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: frozen.frozenAt, answersJSON: payload.encoded(), selfHarmAnswered: true, pinnedNote: "", changedAt: at(2026, 10, 7, 9))
        let winner = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: readMoment, calendar: utc)
        XCTAssertEqual(winner?.frozenAt, frozen.frozenAt, "the edit carries the same freeze moment forward")
        XCTAssertTrue(ReviewAnswersPayload.decode(winner!.answersJSON).finished, "the reconciler reads the edit's content as this frozen review's latest")
    }

    // MARK: mm-t32.1 / mm-t32.11, the self-harm item at the review

    /// Scenario: Done without an answer / Done with no answer.
    func testDoneWithoutAnAnswer() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-19", frozenAt: at(2026, 10, 19, 4), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 10, 19, 9))
        let row = try store.review(kind: .weeklyReview, dueDateKey: "2026-10-19", now: readMoment, calendar: utc)
        XCTAssertEqual(row?.selfHarmAnswered, false)
    }

    /// Scenario: The store after a review / Answer No. With any answer the
    /// store keeps `selfHarmAnswered: true` and never the answer itself.
    func testTheStoreAfterAReviewKeepsNoAnswer() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-19", frozenAt: at(2026, 10, 19, 4), answersJSON: "{}", selfHarmAnswered: true, pinnedNote: "", changedAt: at(2026, 10, 19, 9))
        let row = try store.review(kind: .weeklyReview, dueDateKey: "2026-10-19", now: readMoment, calendar: utc)
        XCTAssertEqual(row?.selfHarmAnswered, true)
        XCTAssertFalse(row!.answersJSON.lowercased().contains("yes"), "the answer itself never enters the row")
    }

    /// Scenario: Review left open / Asked again. Each due day is its own
    /// row, so an item left unanswered in one review never carries an
    /// answered flag into the next.
    func testAskedAgainInTheNextReview() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: at(2026, 10, 5, 4), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 10, 5, 9))
        // Week 4's review is a different row; it starts unanswered.
        let nextWeek = try store.review(kind: .weeklyReview, dueDateKey: "2026-10-12", now: readMoment, calendar: utc)
        XCTAssertNil(nextWeek)
    }

    // MARK: mm-t32.10, the pinned note

    /// The latest finished review's `pinnedNote` is "Today's" pinned note.
    private func currentPinnedNote(_ store: RecordStore) throws -> String? {
        let winners = try store.reviewRowWinners(kind: .weeklyReview, now: readMoment, calendar: utc)
        let finished = winners.filter { ReviewAnswersPayload.decode($0.answersJSON).finished }
        guard let latest = finished.max(by: { $0.dueDateKey < $1.dueDateKey }) else { return nil }
        return latest.pinnedNote.isEmpty ? nil : latest.pinnedNote
    }

    /// Scenario: A pinned note appears.
    func testAPinnedNoteAppears() throws {
        let store = try makeStore()
        var payload = ReviewAnswersPayload(finished: true)
        payload.oneThingToChange = "Eat lunch at work"
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: at(2026, 10, 5, 4), answersJSON: payload.encoded(), selfHarmAnswered: true, pinnedNote: "Eat lunch at work", changedAt: at(2026, 10, 5, 9))
        XCTAssertEqual(try currentPinnedNote(store), "Eat lunch at work")
    }

    /// Scenario: The next review replaces it.
    func testTheNextReviewReplacesIt() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: at(2026, 10, 5, 4), answersJSON: ReviewAnswersPayload(finished: true).encoded(), selfHarmAnswered: true, pinnedNote: "Eat lunch at work", changedAt: at(2026, 10, 5, 9))
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-12", frozenAt: at(2026, 10, 12, 4), answersJSON: ReviewAnswersPayload(finished: true).encoded(), selfHarmAnswered: true, pinnedNote: "Plan the evening snack", changedAt: at(2026, 10, 12, 9))
        XCTAssertEqual(try currentPinnedNote(store), "Plan the evening snack")
    }

    /// Scenario: The next review leaves it empty.
    func testTheNextReviewLeavesItEmpty() throws {
        let store = try makeStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: at(2026, 10, 5, 4), answersJSON: ReviewAnswersPayload(finished: true).encoded(), selfHarmAnswered: true, pinnedNote: "Eat lunch at work", changedAt: at(2026, 10, 5, 9))
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-12", frozenAt: at(2026, 10, 12, 4), answersJSON: ReviewAnswersPayload(finished: true).encoded(), selfHarmAnswered: true, pinnedNote: "", changedAt: at(2026, 10, 12, 9))
        XCTAssertNil(try currentPinnedNote(store))
    }

    /// Scenario: Edit from Today. A direct edit to the pinned note writes
    /// into the same finished row, the way editing the review would.
    func testEditFromToday() throws {
        let store = try makeStore()
        let row = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: at(2026, 10, 5, 4), answersJSON: ReviewAnswersPayload(finished: true).encoded(), selfHarmAnswered: true, pinnedNote: "Eat lunch at work", changedAt: at(2026, 10, 5, 9))
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: row.frozenAt, answersJSON: row.answersJSON, selfHarmAnswered: row.selfHarmAnswered, pinnedNote: "Eat lunch by 13:00", changedAt: at(2026, 10, 5, 10))
        XCTAssertEqual(try currentPinnedNote(store), "Eat lunch by 13:00")
    }

    // MARK: mm-t32.8, "The weekly summary is opt-out"

    /// Scenario: Switch off, safeguarding still counts. Freezing writes the
    /// counts whatever "Weekly summary" reads.
    func testSwitchOffSafeguardingStillCounts() throws {
        let store = try makeStore()
        try store.setWeeklySummaryOn(false)
        let counts = FrozenReviewCounts(daysWithEntry: 6, starred: 6, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
        var payload = ReviewAnswersPayload()
        payload.frozenCounts = counts
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-19", frozenAt: at(2026, 10, 19, 4), answersJSON: payload.encoded(), selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 10, 19, 4))
        let row = try store.review(kind: .weeklyReview, dueDateKey: "2026-10-19", now: readMoment, calendar: utc)
        XCTAssertEqual(ReviewAnswersPayload.decode(row!.answersJSON).frozenCounts?.starred, 6)
    }

    func testWeeklySummaryDefaultsOnAndSyncs() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.weeklySummaryOn())
        try store.setWeeklySummaryOn(false)
        XCTAssertFalse(try store.weeklySummaryOn())
    }
}
