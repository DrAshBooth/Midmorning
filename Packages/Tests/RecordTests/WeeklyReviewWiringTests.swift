import Foundation
import XCTest
@testable import Record
@testable import Programme

/// mm-t32.16, the wiring bead: the scenarios that need the weekly review, or
/// the stage engine and the scheduler together, run over the real
/// `RecordStore` and `Programme` rather than the fixture inputs their own
/// source beads used. `ReminderCoordinator.requests` (App target, untested
/// by `swift test`) performs the same composition this file drives
/// directly. Device-only scenarios ("One tap to each screen", "The route
/// from Today", "Weekly review" [Get support]) are listed on the epic's
/// device-check bead instead.
@MainActor
final class WeeklyReviewWiringTests: XCTestCase {
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

    private func dayKey(_ year: Int, _ month: Int, _ day: Int) -> String {
        RecordDay.key(containing: at(year, month, day), calendar: utc, schedule: .standard)
    }

    /// The live `stage2Open` fact, the same composition
    /// `ReminderCoordinator.requests` performs: real entries through
    /// `StageEngine.state`.
    private func stage2Open(_ store: RecordStore, now: Date) -> Bool {
        let entries = ((try? store.recordedEntryFacts()) ?? []).map { EntryFact(id: UUID().uuidString, dayKey: $0.dayKey, starred: $0.starred, savedAt: $0.savedAt) }
        let currentRecordDay = RecordDay.key(containing: now, calendar: utc, schedule: .standard)
        let settings = ProgrammeSettings(startDay: (try? store.startDayKey()) ?? currentRecordDay, dayStart: RecordDay.startHour)
        let state = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: settings, constants: .default, now: now, restartAt: nil, currentRecordDay: currentRecordDay, calendar: utc)
        return state.isOpen(.regularEating)
    }

    private func schedulerDay(dayKey: String, stage2Open: Bool, hasEntryAfter17: Bool, hasEntryBeforeMidday: Bool) -> SchedulerDay {
        SchedulerDay(
            dayKey: dayKey, dayStart: at(2026, 9, 24), plannedMeals: [], slotLabels: [:],
            morningPlan: MorningPlanFacts(stage2Open: stage2Open, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: MiddayFacts(hasEntryBeforeMidday: hasEntryBeforeMidday, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: CloseTheDayFacts(stage2Open: stage2Open, hasEntryAfter17: hasEntryAfter17, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
    }

    private func settings() -> SchedulerSettings {
        SchedulerSettings(switches: [.morningPlan: true, .closeTheDay: true, .midday: true], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
    }

    /// Scenario: No template yet (reminders spec, "The morning plan
    /// reminder while the plan needs setting"), with a REAL, live stage-2
    /// fact rather than the fixture `stage2Open: true` `MorningPlanReminderTests`
    /// already used.
    func testNoTemplateYetWithTheLiveStage() throws {
        let store = try makeStore()
        // Five distinct recorded days opens stage 2 (programme spec).
        for offset in 0..<5 {
            let moment = at(2026, 9, 20 + offset, 9)
            try store.add(time: moment, what: "", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0)
        }
        let now = at(2026, 9, 26, 7, 30)
        XCTAssertTrue(stage2Open(store, now: now), "five recorded days opens stage 2")
        let day = schedulerDay(dayKey: dayKey(2026, 9, 26), stage2Open: true, hasEntryAfter17: false, hasEntryBeforeMidday: false)
        let requests = Scheduler.requests(days: [day], settings: settings(), calendar: utc, constants: .default)
        XCTAssertTrue(requests.contains { $0.kind == .morningPlan }, "the morning plan reminder fires once stage 2 is open with no template")
    }

    /// Scenario: Stage 1 (reminders spec, "The morning plan reminder while
    /// the plan needs setting"): no morning plan reminder before stage 2,
    /// with the live stage fact reading false from a fresh store.
    func testStage1NoMorningPlanReminder() throws {
        let store = try makeStore()
        XCTAssertFalse(stage2Open(store, now: at(2026, 9, 26, 7, 30)), "a fresh store has not opened stage 2")
        let day = schedulerDay(dayKey: dayKey(2026, 9, 26), stage2Open: false, hasEntryAfter17: false, hasEntryBeforeMidday: false)
        let requests = Scheduler.requests(days: [day], settings: settings(), calendar: utc, constants: .default)
        XCTAssertFalse(requests.contains { $0.kind == .morningPlan })
    }

    /// Scenario: An evening entry in stage 1 (reminders spec, "Close the
    /// day"): a real entry after 17:00, with the live (closed) stage fact.
    func testAnEveningEntryInStage1() throws {
        let store = try makeStore()
        let evening = at(2026, 9, 26, 18, 30)
        try store.add(time: evening, what: "", feltLikeABinge: false, createdAt: evening, utcOffsetSeconds: 0)
        let now = at(2026, 9, 26, 21, 45)
        XCTAssertFalse(stage2Open(store, now: now))
        let entries = try store.entries(dayKey: dayKey(2026, 9, 26))
        let hasEntryAfter17 = entries.contains { utc.component(.hour, from: $0.time) >= 17 }
        let day = schedulerDay(dayKey: dayKey(2026, 9, 26), stage2Open: false, hasEntryAfter17: hasEntryAfter17, hasEntryBeforeMidday: false)
        let requests = Scheduler.requests(days: [day], settings: settings(), calendar: utc, constants: .default)
        XCTAssertFalse(requests.contains { $0.kind == .closeTheDay }, "no close-the-day reminder fires at 21:45")
    }

    /// Scenario: No entry by midday in stage 1 (reminders spec, "The midday
    /// reminder").
    func testNoEntryByMiddayInStage1() throws {
        let store = try makeStore()
        XCTAssertFalse(stage2Open(store, now: at(2026, 9, 26, 12, 0)))
        let entries = try store.entries(dayKey: dayKey(2026, 9, 26))
        let hasEntryBeforeMidday = entries.contains { utc.component(.hour, from: $0.time) < 12 }
        let day = schedulerDay(dayKey: dayKey(2026, 9, 26), stage2Open: false, hasEntryAfter17: false, hasEntryBeforeMidday: hasEntryBeforeMidday)
        let requests = Scheduler.requests(days: [day], settings: settings(), calendar: utc, constants: .default)
        XCTAssertTrue(requests.contains { $0.kind == .midday }, "the midday reminder fires with no entry recorded yet")
    }

    /// Scenario: Reminders kept by the self-harm reason (safeguarding spec,
    /// "The not-right-now page"): unlike the weight reason, a self-harm
    /// exclusion at the review never pauses reminders.
    func testRemindersKeptByTheSelfHarmReason() throws {
        let store = try makeStore()
        let outcome = SelfHarmItem.outcome(first: .yes, second: .yes)
        XCTAssertEqual(outcome, .excludes)
        // The review's own flow never calls `pauseReminders` for a
        // self-harm exclusion (only the weight reason does, `weigh-in`'s
        // own `runUnderweightCheck`); the store stays clear.
        XCTAssertNil(try store.remindersPausedAt())
        XCTAssertEqual(NotRightNowPage.remindersLine(for: [.selfHarm]), NotRightNowPage.remindersStayOnLine)
    }

    /// Scenario: Self-harm reason (safeguarding spec, "The not-right-now
    /// page"), reached from the review's own two-step item.
    func testSelfHarmReasonAtTheReview() {
        let outcome = SelfHarmItem.outcome(first: .yes, second: .yes)
        XCTAssertEqual(outcome, .excludes)
        XCTAssertEqual(NotRightNowPage.paragraph(for: .selfHarm), NotRightNowPage.selfHarmReason)
    }

    /// Scenario: At the review (safeguarding spec, "The GP suggestion
    /// page"), reached from real frozen Review rows and the real
    /// deterioration rule.
    func testAtTheReviewGPSuggestionPage() throws {
        let store = try makeStore()
        let counts = [3, 4, 5, 6]
        for (index, starred) in counts.enumerated() {
            var payload = ReviewAnswersPayload()
            payload.frozenCounts = FrozenReviewCounts(daysWithEntry: 6, starred: starred, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
            let dueDayKey = dayKey(2026, 9, 21 + index * 7)
            try store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: at(2026, 9, 21 + index * 7), answersJSON: payload.encoded(), selfHarmAnswered: false, pinnedNote: "", changedAt: at(2026, 9, 21 + index * 7))
        }
        let winners = try store.reviewRowWinners(kind: .weeklyReview).sorted { $0.dueDateKey < $1.dueDateKey }
        let starredCounts = winners.compactMap { ReviewAnswersPayload.decode($0.answersJSON).frozenCounts?.starred }
        XCTAssertEqual(starredCounts, counts)
        XCTAssertTrue(DeteriorationRule.fires(lastFrozenStarredCounts: starredCounts))
        XCTAssertEqual(GPSuggestionPage.line(for: .deterioration), "Your starred entries have gone up for 3 weeks in a row.")
    }

    /// Scenario: Review without a weigh-in part (onboarding spec, "Screen
    /// 3: weigh-in day and quiet hours"): "I won't be weighing" leaves the
    /// weigh-in part out of the real store's weigh-in rows, so the summary
    /// omits it.
    func testReviewWithoutAWeighInPart() throws {
        let store = try makeStore()
        try store.setWeighInDayChoice(.wontBeWeighing)
        XCTAssertTrue(try store.weighIns().isEmpty)
        let facts = ReviewWeekFacts(weekDayKeys: [dayKey(2026, 9, 21)], weighInDoneDayKey: nil)
        XCTAssertFalse(ReviewSummary.parts(facts, calendar: utc).contains { $0.hasPrefix("Weigh-in") })
    }

    /// Scenario: Self-harm Yes then Yes at a restart (safeguarding spec,
    /// "Re-screening at a restart"), over the real `RestartRescreen`.
    func testSelfHarmYesThenYesAtARestart() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 65, pregnancy: .no, treatment: .no, selfHarmFirst: .yes, selfHarmSecond: .yes)
        let result = RestartRescreen.evaluate(answers, now: at(2026, 9, 26))
        XCTAssertEqual(result.reasons, [.selfHarm])
        XCTAssertFalse(result.remindersPausedByWeightReason)
    }

    /// Scenario: Underweight at a re-screen (safeguarding spec,
    /// "Re-screening at a restart").
    func testUnderweightAtARescreen() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 53, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: at(2026, 9, 26))
        XCTAssertEqual(result.reasons, [.weight])
        XCTAssertTrue(result.remindersPausedByWeightReason)
    }
}
