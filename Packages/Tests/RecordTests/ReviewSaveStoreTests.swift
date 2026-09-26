import Foundation
import XCTest
@testable import Record
@testable import Programme

/// The review fixes of the code review of 26 September 2026 (mm-t32.19,
/// mm-t32.20, mm-t32.21, mm-t32.22, mm-t32.23), over the real
/// `RecordStore`. There is no App-target test runner (`./verify` only builds
/// the App), so each helper below makes the same calls, in the same order,
/// as the named `WeeklyReviewModel` function in
/// `App/Midmorning/WeeklyReview/WeeklyReviewModel.swift`. The rules
/// themselves are the `Programme` functions that the App calls.
@MainActor
final class ReviewSaveStoreTests: XCTestCase {
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

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private let startDay = "2026-09-28"

    private func dueDayKey(_ week: Int, startDay: String? = nil) -> String {
        ReviewDue.dueDayKey(week: week, startDay: startDay ?? self.startDay, calendar: utc)
    }

    private func values(_ row: RecordStore.ReviewRow) -> ReviewRowValues {
        ReviewRowValues(answersJSON: row.answersJSON, selfHarmAnswered: row.selfHarmAnswered, pinnedNote: row.pinnedNote)
    }

    /// `WeeklyReviewModel.freezeIfNeeded`'s write.
    private func freeze(_ store: RecordStore, week: Int, starred: Int = 0, startDay: String? = nil, at moment: Date) throws {
        var payload = ReviewAnswersPayload()
        payload.frozenCounts = FrozenReviewCounts(daysWithEntry: 5, starred: starred, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
        payload.runStartDay = startDay ?? self.startDay
        try store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey(week, startDay: startDay), frozenAt: moment, answersJSON: payload.encoded(), selfHarmAnswered: false, pinnedNote: "", changedAt: moment)
    }

    /// `WeeklyReviewModel.save`.
    private func save(
        _ mode: ReviewSave.Mode, _ store: RecordStore, week: Int, startDay: String? = nil,
        reflection: [String] = ["", "", ""], oneThing: String = "", selfHarmStepOneAnswered: Bool, at moment: Date
    ) throws {
        let key = dueDayKey(week, startDay: startDay)
        let existing = try store.review(kind: .weeklyReview, dueDateKey: key)
        let result = ReviewSave.values(
            existing: existing.map(values), mode: mode, week: week, runStartDay: startDay ?? self.startDay,
            reflectionAnswers: reflection, oneThingToChange: oneThing, weekOneAnswers: nil,
            selfHarmStepOneAnswered: selfHarmStepOneAnswered
        )
        try store.upsertReview(kind: .weeklyReview, dueDateKey: key, frozenAt: existing?.frozenAt, answersJSON: result.answersJSON, selfHarmAnswered: result.selfHarmAnswered, pinnedNote: result.pinnedNote, changedAt: moment)
    }

    /// `WeeklyReviewModel.currentPinnedNote`.
    private func pinnedNote(_ store: RecordStore) throws -> String? {
        let latest = try store.reviewRowWinners(kind: .weeklyReview)
            .filter { ReviewAnswersPayload.decode($0.answersJSON).finished }
            .max { $0.dueDateKey < $1.dueDateKey }
        guard let latest, !latest.pinnedNote.isEmpty else { return nil }
        return latest.pinnedNote
    }

    /// `WeeklyReviewModel.isFinished`.
    private func isFinished(_ store: RecordStore, week: Int) throws -> Bool {
        guard let row = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(week)) else { return false }
        return ReviewAnswersPayload.decode(row.answersJSON).finished
    }

    /// `WeeklyReviewModel.opensWithDeteriorationPage`.
    private func opensWithDeteriorationPage(_ store: RecordStore, week: Int, at moment: Date) throws -> Bool {
        let needed = ReviewDeteriorationGate.countsNeeded()
        guard week >= needed else { return false }
        var counts: [Int] = []
        for checkedWeek in (week - needed + 1)...week {
            guard let row = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(checkedWeek)),
                  let starred = ReviewAnswersPayload.decode(row.answersJSON).frozenCounts?.starred else { return false }
            counts.append(starred)
        }
        guard let current = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(week)),
              ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: counts, reviewAnswersJSON: current.answersJSON) else { return false }
        let marked = ReviewSave.deteriorationPageShown(existing: values(current))
        try store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey(week), frozenAt: current.frozenAt, answersJSON: marked.answersJSON, selfHarmAnswered: marked.selfHarmAnswered, pinnedNote: marked.pinnedNote, changedAt: moment)
        return true
    }

    // MARK: mm-t32.19

    /// Scenario: Tap it, and leave without "Done". Week 2 stays unfinished,
    /// so Today keeps the "Weekly review" line, and Today's pinned note is
    /// still week 1's.
    func testGettingWorseKeepsTheReviewDueAndThePinnedNote() throws {
        let store = try makeStore()
        try freeze(store, week: 1, at: at(2026, 10, 5, 4))
        try save(.done, store, week: 1, oneThing: "Eat lunch at work", selfHarmStepOneAnswered: true, at: at(2026, 10, 5, 9))
        try freeze(store, week: 2, at: at(2026, 10, 12, 4))

        try save(.answersSoFar, store, week: 2, reflection: ["", "Evenings were hard", ""], oneThing: "", selfHarmStepOneAnswered: false, at: at(2026, 10, 12, 9))

        XCTAssertFalse(try isFinished(store, week: 2), "the review is still due")
        XCTAssertEqual(try pinnedNote(store), "Eat lunch at work", "the pinned note stays until Done on the next review")
        let row = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(2))
        XCTAssertEqual(ReviewAnswersPayload.decode(row!.answersJSON).reflectionAnswers[1], "Evenings were hard", "the store keeps the answers so far")
        XCTAssertEqual(ReviewAnswersPayload.decode(row!.answersJSON).frozenCounts?.daysWithEntry, 5, "the frozen counts stay")
    }

    /// Scenario: Yes, then Yes. The answers stay; the review stays due.
    func testYesThenYesSavesWithoutFinishing() throws {
        let store = try makeStore()
        try freeze(store, week: 2, at: at(2026, 10, 12, 4))
        try save(.answersSoFar, store, week: 2, reflection: ["", "Evenings were hard", ""], selfHarmStepOneAnswered: true, at: at(2026, 10, 12, 9))
        let row = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(2))
        XCTAssertEqual(row?.selfHarmAnswered, true)
        XCTAssertFalse(try isFinished(store, week: 2))
        XCTAssertNil(try pinnedNote(store))
    }

    // MARK: mm-t32.20

    /// Answer No, tap "Done", reopen (the item is hidden, so it has no
    /// answer on this visit) and tap "Done" again: the row keeps `true`.
    func testReopenThenDoneKeepsSelfHarmAnswered() throws {
        let store = try makeStore()
        try freeze(store, week: 2, at: at(2026, 10, 12, 4))
        try save(.done, store, week: 2, selfHarmStepOneAnswered: true, at: at(2026, 10, 12, 9))
        try save(.done, store, week: 2, reflection: ["Better", "", ""], selfHarmStepOneAnswered: false, at: at(2026, 10, 14, 9))
        XCTAssertEqual(try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(2))?.selfHarmAnswered, true, "the app does not ask the item again")
        try save(.answersSoFar, store, week: 2, selfHarmStepOneAnswered: false, at: at(2026, 10, 14, 10))
        XCTAssertEqual(try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(2))?.selfHarmAnswered, true)
    }

    // MARK: mm-t32.21

    /// Scenario: Three rising weeks. The page shows when the review of
    /// week 5 first opens, and not on a reopen.
    func testTheDeteriorationPageShowsOncePerReview() throws {
        let store = try makeStore()
        for (week, starred) in [(2, 2), (3, 3), (4, 4), (5, 5)] {
            try freeze(store, week: week, starred: starred, at: at(2026, 9, 28 + 7 * week, 4))
        }
        XCTAssertTrue(try opensWithDeteriorationPage(store, week: 5, at: at(2026, 11, 2, 9)))
        XCTAssertFalse(try opensWithDeteriorationPage(store, week: 5, at: at(2026, 11, 2, 10)), "a reopen from Today does not show it")
        try save(.done, store, week: 5, selfHarmStepOneAnswered: true, at: at(2026, 11, 2, 11))
        XCTAssertFalse(try opensWithDeteriorationPage(store, week: 5, at: at(2026, 11, 20, 9)), "a reopen from the Reviews list does not show it")
        let row = try store.review(kind: .weeklyReview, dueDateKey: dueDayKey(5))
        XCTAssertEqual(ReviewAnswersPayload.decode(row!.answersJSON).frozenCounts?.starred, 5, "the frozen count stays")
    }

    // MARK: mm-t32.22

    /// Scenario: Keyed by the due day. After "Start week 1 again" the
    /// finished first-run reviews keep their own weeks, and the second run
    /// uses its own due-day keys.
    func testTheReviewsListShowsBothRunsAfterARestart() throws {
        let store = try makeStore()
        try store.setStartDayKey(startDay, changedAt: at(2026, 9, 28))
        for week in 1...3 {
            try freeze(store, week: week, starred: week, at: at(2026, 9, 28 + 7 * week, 4))
            try save(.done, store, week: week, selfHarmStepOneAnswered: true, at: at(2026, 9, 28 + 7 * week, 9))
        }
        let newStartDay = "2027-01-04"
        try store.setStartDayKey(newStartDay, changedAt: at(2027, 1, 4))
        try freeze(store, week: 1, starred: 1, startDay: newStartDay, at: at(2027, 1, 11, 4))
        try save(.done, store, week: 1, startDay: newStartDay, selfHarmStepOneAnswered: true, at: at(2027, 1, 11, 9))

        // `WeeklyReviewModel.runWeeks`, as `reviewsListRows` calls it.
        let winners = try store.reviewRowWinners(kind: .weeklyReview)
        let rows = winners.map { ReviewRuns.Row(dueDayKey: $0.dueDateKey, runStartDay: ReviewAnswersPayload.decode($0.answersJSON).runStartDay) }
        let runs = ReviewRuns.runWeeks(rows: rows, currentStartDay: try store.startDayKey()!, calendar: utc)
        XCTAssertEqual(runs.count, 4, "every finished review has a row")
        XCTAssertEqual(runs[dueDayKey(3)], ReviewRunWeek(week: 3, runStartDay: startDay))
        XCTAssertEqual(runs[dueDayKey(1)], ReviewRunWeek(week: 1, runStartDay: startDay))
        XCTAssertEqual(runs[dueDayKey(1, startDay: newStartDay)], ReviewRunWeek(week: 1, runStartDay: newStartDay))
    }

    // MARK: mm-t32.23

    /// Scenario: I won't be weighing. The store keeps the weigh-in, and the
    /// summary leaves the part out until the person chooses a day again.
    func testIWontBeWeighingOverTheRealStore() throws {
        let store = try makeStore()
        try store.setWeighInDayChoice(.weekday(2), changedAt: at(2026, 9, 28))
        _ = try store.saveWeighIn(dateKey: "2026-10-05", weightKg: 70, unit: "kg", at: at(2026, 10, 5))
        try store.setWeighInDayChoice(.wontBeWeighing, changedAt: at(2026, 10, 6))

        // `WeeklyReviewModel.weekFacts`'s weigh-in read.
        func weighInDayKey() throws -> String? {
            let chosen: Bool
            if case .weekday = try store.weighInDayChoice() { chosen = true } else { chosen = false }
            let week = ReviewDue.weekDayKeys(week: 2, startDay: startDay, calendar: utc)
            return ReviewWeekFacts.weighInDoneDayKey(weighInDayKeys: try store.weighIns().map(\.dateKey), weekDayKeys: week, weighInDayChosen: chosen)
        }
        XCTAssertEqual(try store.weighIns().count, 1, "the store keeps the weigh-in")
        XCTAssertNil(try weighInDayKey(), "no weigh-in part after I won't be weighing")
        try store.setWeighInDayChoice(.weekday(2), changedAt: at(2026, 10, 20))
        XCTAssertEqual(try weighInDayKey(), "2026-10-05", "the part comes back when the person chooses a day")
    }
}
