import Foundation
import SwiftData
import XCTest
@testable import Record
import RecordTestSupport
import Programme

/// data-and-privacy spec, "Rows reference each other by key": "An edit of a
/// row other than an entry MUST write into the winning row." Ash ruled on 26
/// September 2026 (r13-03, mm-t12.34) that the store follows the spec: an
/// edit of a non-entry row writes into the winning row in place, after a
/// reconciled fetch. Entries keep their version rows. Each test reads the
/// rows through a second context on the same container, the way a sync
/// or a restart reads them.
@MainActor
final class NonEntryEditInPlaceTests: XCTestCase {
    /// The review writes use UTC, so the future-dated test does not hang on
    /// the zone of the machine that runs the tests.
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Seconds after 12:00 UTC on 5 October 2026, the due day of the
    /// review rows here.
    private func moment(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_791_201_600 + seconds)
    }

    private func rows<Model: PersistentModel>(_ type: Model.Type, in store: RecordStore) throws -> [Model] {
        try ModelContext(store.container).fetch(FetchDescriptor<Model>())
    }

    /// Puts rows into the store from a second context, as a sync or an
    /// import does.
    private func insertFixture(_ models: [any PersistentModel], into store: RecordStore) throws {
        let context = ModelContext(store.container)
        for model in models { context.insert(model) }
        try context.save()
    }

    // MARK: Settings

    func testASettingEditWritesIntoItsOneRow() throws {
        let store = try makeTemporaryStore()
        try store.setGapBandsOn(false, changedAt: moment(1))
        try store.setGapBandsOn(true, changedAt: moment(2))
        try store.setGapBandsOn(false, changedAt: moment(3))
        let settings = try rows(Settings.self, in: store).filter { $0.key == "record.gapBands.enabled" }
        XCTAssertEqual(settings.count, 1, "three edits, one row")
        XCTAssertEqual(settings.first?.value, "false")
        XCTAssertEqual(settings.first?.changedAt, moment(3))
        XCTAssertFalse(try store.gapBandsOn())
    }

    /// Scenario: Edit after a conflict, over `Settings` rows. Two rows for
    /// one key exist; the edit writes into the winning row and the losing
    /// row stays as it is.
    func testEditAfterAConflictWritesIntoTheWinningSettingsRow() throws {
        let store = try makeTemporaryStore()
        let loser = Settings(key: "weighIn.unit", value: "kg", changedAt: moment(100))
        let winner = Settings(key: "weighIn.unit", value: "st lb", changedAt: moment(200))
        let loserId = loser.id, winnerId = winner.id
        try insertFixture([loser, winner], into: store)

        try store.setWeighInUnit("kg", changedAt: moment(300))

        let settings = try rows(Settings.self, in: store).filter { $0.key == "weighIn.unit" }
        XCTAssertEqual(settings.count, 2, "the edit adds no row")
        XCTAssertEqual(settings.first { $0.id == winnerId }?.value, "kg", "the edit is in the winning row")
        XCTAssertEqual(settings.first { $0.id == winnerId }?.changedAt, moment(300))
        XCTAssertEqual(settings.first { $0.id == loserId }?.changedAt, moment(100), "the losing row stays as it is")
        XCTAssertEqual(try store.weighInUnit(), "kg")
    }

    /// A write that is earlier than the winner loses, as a losing row did
    /// before: the winner keeps its value and its moment.
    func testAnEarlierSettingWriteChangesNothing() throws {
        let store = try makeTemporaryStore()
        try store.setWeighInUnit("st lb", changedAt: moment(200))
        try store.setWeighInUnit("kg", changedAt: moment(100))
        let settings = try rows(Settings.self, in: store).filter { $0.key == "weighIn.unit" }
        XCTAssertEqual(settings.count, 1)
        XCTAssertEqual(settings.first?.value, "st lb")
        XCTAssertEqual(settings.first?.changedAt, moment(200))
    }

    /// The day start rows stay append-only (data-and-privacy spec, "Slot
    /// labels and the day start are Settings rows"): each change is its own
    /// row, and the later row for one effective day wins.
    func testTheDayStartRowsStayAppendOnly() throws {
        let store = try makeTemporaryStore()
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let now = london.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 13))!
        try store.setDayStartHour(6, now: now, calendar: london, changedAt: moment(1))
        try store.setDayStartHour(7, now: now, calendar: london, changedAt: moment(2))
        XCTAssertEqual(try rows(Settings.self, in: store).filter { $0.key.hasPrefix("dayStart.") }.count, 2)
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-25"), 7)
    }

    // MARK: Day states

    func testADayStateToggleWritesIntoItsOneRow() throws {
        let store = try makeTemporaryStore()
        try store.setDayState(.paused, on: true, dateKey: "2026-10-06", changedAt: moment(1))
        try store.setDayState(.paused, on: false, dateKey: "2026-10-06", changedAt: moment(2))
        try store.setDayState(.fasting, on: true, dateKey: "2026-10-06", changedAt: moment(3))
        try store.setFeelingWord("Tired", dateKey: "2026-10-06", changedAt: moment(4))
        try store.setFeelingWord("Calm", dateKey: "2026-10-06", changedAt: moment(5))
        let states = try rows(DayState.self, in: store)
        XCTAssertEqual(states.count, 3, "one row per record day and state kind")
        XCTAssertEqual(try store.dayStates(dateKey: "2026-10-06"), [.fasting])
        XCTAssertEqual(try store.feelingWord(dateKey: "2026-10-06"), "Calm")
    }

    // MARK: The plan

    func testATemplateSaveWritesIntoItsOneRow() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON("[1]", kind: .weekday, changedAt: moment(1))
        try store.setTemplateSlotsJSON("[2]", kind: .weekday, changedAt: moment(2))
        try store.setTemplateSlotsJSON("[3]", kind: .weekend, changedAt: moment(3))
        XCTAssertEqual(try rows(Template.self, in: store).count, 2, "one row per kind")
        XCTAssertEqual(try store.templateSlotsJSON(.weekday), "[2]")
        XCTAssertEqual(try store.templateSlotsJSON(.weekend), "[3]")
    }

    /// An edit of a materialised day writes into the materialised row. The
    /// row keeps its window constants, and a later edit keeps the first set
    /// event: "set" is sticky.
    func testADayPlanEditWritesIntoTheMaterialisedRow() throws {
        let store = try makeTemporaryStore()
        try store.materialiseDayFromTemplate(dateKey: "2026-10-06", slotsJSON: "[0]", windowBeforeMinutes: 45, windowAfterMinutes: 75)
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: "[1]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: moment(10), setBy: "device", changedAt: moment(10))
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: "[2]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: moment(20), setBy: "device", changedAt: moment(20))
        let days = try rows(Day.self, in: store)
        XCTAssertEqual(days.count, 1, "materialised once, edited twice, one row")
        let plan = try XCTUnwrap(store.dayPlan(dateKey: "2026-10-06"))
        XCTAssertEqual(plan.slotsJSON, "[2]")
        XCTAssertEqual(plan.windowBeforeMinutes, 45, "the row keeps the window constants of its materialisation")
        XCTAssertEqual(plan.windowAfterMinutes, 75)
        XCTAssertEqual(plan.setAt, moment(10), "the first set event stays")
        XCTAssertEqual(days.first?.changedAt, moment(20))
    }

    /// Scenario: Losing planned day kept. An import brings a second planned
    /// day with an earlier change moment; an edit writes into the later row
    /// and keeps both rows.
    func testADayPlanEditAfterAnImportWritesIntoThePlanWinner() throws {
        let store = try makeTemporaryStore()
        let imported = Day(dateKey: "2026-10-06", slotsJSON: "[\"old\"]", changedAt: moment(1), setAt: moment(1), setBy: "import")
        let later = Day(dateKey: "2026-10-06", slotsJSON: "[\"later\"]", changedAt: moment(5))
        let importedId = imported.id, laterId = later.id
        try insertFixture([imported, later], into: store)

        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: "[\"edit\"]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: moment(9), setBy: "device", changedAt: moment(9))

        let days = try rows(Day.self, in: store)
        XCTAssertEqual(days.count, 2, "the edit adds no row, and the losing row stays")
        XCTAssertEqual(days.first { $0.id == laterId }?.slotsJSON, "[\"edit\"]")
        XCTAssertEqual(days.first { $0.id == importedId }?.slotsJSON, "[\"old\"]")
        XCTAssertEqual(try store.dayPlan(dateKey: "2026-10-06")?.slotsJSON, "[\"edit\"]")
        XCTAssertEqual(try store.dayPlan(dateKey: "2026-10-06")?.setAt, moment(1), "the earliest set event still wins on read")
    }

    func testAPlannedMealAnswerWritesIntoItsOneRow() throws {
        let store = try makeTemporaryStore()
        try store.setPlannedMealSkipped(dateKey: "2026-10-06", slotIndex: 2, changedAt: moment(1))
        try store.setPlannedMealAnswer("Had it", dateKey: "2026-10-06", slotIndex: 2, changedAt: moment(2))
        try store.setPlannedMealSkipped(dateKey: "2026-10-06", slotIndex: 3, changedAt: moment(3))
        XCTAssertEqual(try rows(Answer.self, in: store).count, 2, "one row per record day and slot index")
        XCTAssertEqual(try store.plannedMealAnswers(dateKey: "2026-10-06"), [2: "Had it", 3: "Skipped"])
    }

    func testACardAnswerWritesIntoItsOneRow() throws {
        let store = try makeTemporaryStore()
        try store.setCardAnswer("Open", id: "stage2.opening", changedAt: moment(1))
        try store.setCardAnswer("Close", id: "stage2.opening", changedAt: moment(2))
        XCTAssertEqual(try rows(Answer.self, in: store).count, 1, "one card answer row for each answered card")
        XCTAssertEqual(try store.cardAnswer(id: "stage2.opening"), "Close")
    }

    /// A stage opening is an event, not an edit: each one stays its own row
    /// (data-and-privacy spec, "The Reconciler never deletes a row": "Two
    /// stage-opened rows").
    func testStageOpeningsStayTheirOwnRows() throws {
        let store = try makeTemporaryStore()
        try store.recordStageOpened(2, at: moment(1), dayKey: "2026-10-05")
        try store.recordStageOpened(2, at: moment(2), dayKey: "2026-10-05")
        XCTAssertEqual(try store.stageOpenedRows().count, 2)
    }

    // MARK: The weigh-in

    /// weigh-in spec, "The store keeps the weigh-in on the device and away
    /// from HealthKit": "A change within the 10 minutes MUST write into the
    /// same row with a later `changedAt`."
    func testAWeighInChangeWritesIntoTheSameRow() throws {
        let store = try makeTemporaryStore()
        try store.saveWeighIn(dateKey: "2026-10-06", weightKg: 70.4, unit: "kg", at: moment(0))
        let changed = try store.saveWeighIn(dateKey: "2026-10-06", weightKg: 70.2, unit: "kg", at: moment(300))
        let measures = try rows(Measure.self, in: store)
        XCTAssertEqual(measures.count, 1)
        XCTAssertEqual(measures.first?.weightKg, 70.2)
        XCTAssertEqual(measures.first?.savedAt, moment(0), "savedAt does not change")
        XCTAssertEqual(measures.first?.changedAt, moment(300))
        XCTAssertEqual(changed.savedAt, moment(0))
    }

    // MARK: Reviews

    func testAReviewFreezeAndItsEditsShareOneRow() throws {
        let store = try makeTemporaryStore()
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(0), calendar: utc)
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: frozen.frozenAt, answersJSON: "{\"a\":1}", selfHarmAnswered: true, pinnedNote: "Lunch", changedAt: moment(60), calendar: utc)
        let reviews = try rows(Review.self, in: store)
        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.id, frozen.id)
        XCTAssertEqual(reviews.first?.frozenAt, moment(0))
        XCTAssertEqual(reviews.first?.answersJSON, "{\"a\":1}")
        XCTAssertEqual(reviews.first?.pinnedNote, "Lunch")
    }

    /// Scenario: Two frozen rows. The edit writes into the row with the
    /// earliest freeze moment, and the other row stays as it is.
    func testAReviewEditWritesIntoTheEarliestFrozenRow() throws {
        let store = try makeTemporaryStore()
        let deviceA = Review(kind: "weeklyReview", dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{\"from\":\"A\"}", changedAt: moment(0))
        let deviceB = Review(kind: "weeklyReview", dueDateKey: "2026-10-05", frozenAt: moment(1800), answersJSON: "{\"from\":\"B\"}", changedAt: moment(1800))
        let idA = deviceA.id, idB = deviceB.id
        try insertFixture([deviceA, deviceB], into: store)

        let edited = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{\"q1\":\"yes\"}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(3600), calendar: utc)

        let reviews = try rows(Review.self, in: store)
        XCTAssertEqual(reviews.count, 2)
        XCTAssertEqual(edited.id, idA)
        XCTAssertEqual(reviews.first { $0.id == idA }?.answersJSON, "{\"q1\":\"yes\"}")
        XCTAssertEqual(reviews.first { $0.id == idB }?.answersJSON, "{\"from\":\"B\"}", "the later-frozen row stays as it is")
        XCTAssertEqual(reviews.first { $0.id == idB }?.changedAt, moment(1800))
    }

    /// A frozen row keeps its freeze moment: a second freeze of the same
    /// key writes its content into that row and does not move the moment.
    func testAFrozenReviewKeepsItsFreezeMoment() throws {
        let store = try makeTemporaryStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(0), calendar: utc)
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(900), answersJSON: "{\"b\":2}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(900), calendar: utc)
        let reviews = try rows(Review.self, in: store)
        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.frozenAt, moment(0))
        XCTAssertEqual(reviews.first?.answersJSON, "{\"b\":2}")
    }

    /// An answer before the freeze and the freeze itself share one row.
    /// The freeze makes the calls of `WeeklyReviewModel.freezeIfNeeded`:
    /// it reads the unfrozen row and keeps its answers, its pinned note and
    /// its `selfHarmAnswered: true`.
    func testAFreezeWritesIntoTheUnfrozenRow() throws {
        let store = try makeTemporaryStore()
        var answers = ReviewAnswersPayload()
        answers.reflectionAnswers = ["Tired", "Work", "Walks"]
        let unfrozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: nil, answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(0), calendar: utc)
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: nil, answersJSON: answers.encoded(), selfHarmAnswered: true, pinnedNote: "Lunch", changedAt: moment(10), calendar: utc)
        XCTAssertNil(try store.review(kind: .weeklyReview, dueDateKey: "2026-10-05", now: moment(15), calendar: utc), "a read never shows an unfrozen row")

        let pending = try XCTUnwrap(store.reviewWriteTarget(kind: .weeklyReview, dueDateKey: "2026-10-05", now: moment(20), calendar: utc))
        let counts = FrozenReviewCounts(daysWithEntry: 5, starred: 2, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
        let values = ReviewFreeze.frozenValues(
            pending: ReviewRowValues(answersJSON: pending.answersJSON, selfHarmAnswered: pending.selfHarmAnswered, pinnedNote: pending.pinnedNote),
            counts: counts, runStartDay: "2026-09-28"
        )
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(20), answersJSON: values.answersJSON, selfHarmAnswered: values.selfHarmAnswered, pinnedNote: values.pinnedNote, changedAt: moment(20), calendar: utc)

        XCTAssertEqual(try rows(Review.self, in: store).count, 1)
        XCTAssertEqual(frozen.id, unfrozen.id)
        XCTAssertEqual(frozen.frozenAt, moment(20))
        let payload = ReviewAnswersPayload.decode(frozen.answersJSON)
        XCTAssertEqual(payload.frozenCounts, counts)
        XCTAssertEqual(payload.reflectionAnswers, ["Tired", "Work", "Walks"], "the answers from before the freeze stay")
        XCTAssertTrue(frozen.selfHarmAnswered)
        XCTAssertEqual(frozen.pinnedNote, "Lunch")
    }

    /// "When step 1 has an answer, the store MUST keep `selfHarmAnswered:
    /// true` for the review." A later write with `false` does not clear it.
    func testAReviewWriteNeverClearsSelfHarmAnswered() throws {
        let store = try makeTemporaryStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: nil, answersJSON: "{}", selfHarmAnswered: true, pinnedNote: "", changedAt: moment(0), calendar: utc)
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(20), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(20), calendar: utc)
        XCTAssertTrue(frozen.selfHarmAnswered)
        let edited = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(20), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(40), calendar: utc)
        XCTAssertTrue(edited.selfHarmAnswered)
    }

    /// The later-changedAt rule: an edit with an earlier `changedAt` than
    /// the frozen row's, after the device clock goes back or after a
    /// device with a clock ahead edits the row, changes nothing. A
    /// `selfHarmAnswered: true` in that edit still stays.
    func testAnEarlierReviewEditChangesNothing() throws {
        let store = try makeTemporaryStore()
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(0), calendar: utc)
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: frozen.frozenAt, answersJSON: "{\"newer\":1}", selfHarmAnswered: false, pinnedNote: "Newer", changedAt: moment(600), calendar: utc)

        let written = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: frozen.frozenAt, answersJSON: "{\"older\":1}", selfHarmAnswered: true, pinnedNote: "Older", changedAt: moment(300), calendar: utc)

        let reviews = try rows(Review.self, in: store)
        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.answersJSON, "{\"newer\":1}")
        XCTAssertEqual(reviews.first?.pinnedNote, "Newer")
        XCTAssertEqual(reviews.first?.changedAt, moment(600), "changedAt does not go back")
        XCTAssertEqual(reviews.first?.selfHarmAnswered, true)
        XCTAssertEqual(written.answersJSON, "{\"newer\":1}", "the write returns the row as the store holds it")
    }

    /// A freeze with an earlier `changedAt` than the unfrozen row still
    /// freezes the row, because the freeze must happen, and its `changedAt`
    /// does not go back.
    func testAnEarlierFreezeStillFreezesTheRow() throws {
        let store = try makeTemporaryStore()
        try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: nil, answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(600), calendar: utc)
        let frozen = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(300), answersJSON: "{\"counts\":1}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(300), calendar: utc)
        XCTAssertEqual(frozen.frozenAt, moment(300))
        XCTAssertEqual(frozen.answersJSON, "{\"counts\":1}")
        XCTAssertEqual(frozen.changedAt, moment(600))
        XCTAssertEqual(try store.review(kind: .weeklyReview, dueDateKey: "2026-10-05", now: moment(900), calendar: utc)?.id, frozen.id)
    }

    /// Scenario: Future-dated review. A row frozen later than the write's
    /// moment is ignored on read, so the write does not go into it and the
    /// store keeps it as it is.
    func testAWriteNeverChangesAFutureDatedReview() throws {
        let store = try makeTemporaryStore()
        let future = Review(kind: "weeklyReview", dueDateKey: "2026-10-05", frozenAt: moment(86_400), answersJSON: "{\"from\":\"future\"}", changedAt: moment(86_400))
        let futureId = future.id
        try insertFixture([future], into: store)

        let written = try store.upsertReview(kind: .weeklyReview, dueDateKey: "2026-10-05", frozenAt: moment(0), answersJSON: "{}", selfHarmAnswered: false, pinnedNote: "", changedAt: moment(0), calendar: utc)

        let reviews = try rows(Review.self, in: store)
        XCTAssertEqual(reviews.count, 2)
        XCTAssertNotEqual(written.id, futureId)
        XCTAssertEqual(reviews.first { $0.id == futureId }?.answersJSON, "{\"from\":\"future\"}")
        XCTAssertEqual(reviews.first { $0.id == futureId }?.frozenAt, moment(86_400))
    }

    // MARK: Profile

    /// Sync can bring a second `Profile` row with the fixed id. The read
    /// picks the later `changedAt`, and an edit writes into that row.
    func testAProfileEditWritesIntoTheWinningRow() throws {
        let store = try makeTemporaryStore()
        let older = Profile(heightCm: 160, onboardingBMI: 20, cautionFlag: false, askedAt: moment(0), changedAt: moment(0))
        try insertFixture([older], into: store)
        let newer = Profile(heightCm: 165, onboardingBMI: 21, cautionFlag: false, askedAt: moment(50), changedAt: moment(50))
        try insertFixture([newer], into: store)
        XCTAssertEqual(try store.profile()?.heightCm, 165)

        try store.setProfile(heightCm: 166, onboardingBMI: 21, cautionFlag: true, askedAt: moment(90), changedAt: moment(90))

        let profiles = try rows(Profile.self, in: store)
        XCTAssertEqual(profiles.count, 2, "the edit adds no row")
        XCTAssertEqual(profiles.map(\.heightCm).sorted(), [160, 166], "the older row stays as it is")
        XCTAssertEqual(try store.profile()?.cautionFlag, true)
    }

    /// A profile write that is earlier than the winning row, for example a
    /// re-screen after the device clock goes back, changes nothing.
    func testAnEarlierProfileWriteChangesNothing() throws {
        let store = try makeTemporaryStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: moment(200), changedAt: moment(200))
        try store.setProfile(heightCm: 160, onboardingBMI: 18, cautionFlag: true, askedAt: moment(100), changedAt: moment(100))
        let profiles = try rows(Profile.self, in: store)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.heightCm, 170)
        XCTAssertEqual(profiles.first?.cautionFlag, false)
        XCTAssertEqual(profiles.first?.changedAt, moment(200), "changedAt does not go back")
    }

    // MARK: List items

    /// Scenario: Edit after a conflict, over `ListItem` rows. Two versions
    /// of one custom place exist; a touch writes into the winning row, adds
    /// no row, and the losing row stays as it is.
    func testEditAfterAConflictWritesIntoTheWinningListItemRow() throws {
        let store = try makeTemporaryStore()
        let id = UUID()
        let deviceA = ListItem(id: id, kind: "customPlace", text: "Mum's", position: 0, changedAt: moment(100))
        let deviceB = ListItem(id: id, kind: "customPlace", text: "Mum's", position: 1, changedAt: moment(200))
        try insertFixture([deviceA], into: store)
        try insertFixture([deviceB], into: store)

        try store.touchCustomPlace("Mum's", at: moment(300))

        let items = try rows(ListItem.self, in: store)
        XCTAssertEqual(items.count, 2, "the touch adds no row")
        XCTAssertEqual(Set(items.map(\.id)), [id])
        XCTAssertEqual(items.first { $0.position == 1 }?.changedAt, moment(300), "the touch is in the winning row")
        XCTAssertEqual(items.first { $0.position == 0 }?.changedAt, moment(100), "the losing row stays as it is")
        XCTAssertEqual(try store.customPlaces(), ["Mum's"])
    }

    /// A touch that is earlier than the winning row changes nothing, so the
    /// place's recency moment never goes back.
    func testAnEarlierCustomPlaceTouchChangesNothing() throws {
        let store = try makeTemporaryStore()
        try store.touchCustomPlace("Mum's", at: moment(200))
        try store.touchCustomPlace("Mum's", at: moment(100))
        let items = try rows(ListItem.self, in: store)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.changedAt, moment(200))
    }

    // MARK: Entries keep their version rows

    func testAnEntryEditStillWritesANewVersion() throws {
        let store = try makeTemporaryStore()
        let entry = try store.add(time: moment(0), what: "Toast", feltLikeABinge: false, createdAt: moment(0), utcOffsetSeconds: 3600)
        try store.update(entryId: entry.id, time: moment(0), what: "Toast and tea", feltLikeABinge: false, whereText: "", context: "", editedAt: moment(60))
        XCTAssertEqual(try rows(ItemVersion.self, in: store).count, 2, "an entry edit writes one entry version row")
    }
}
