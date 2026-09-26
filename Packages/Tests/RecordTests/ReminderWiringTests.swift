import Foundation
import XCTest
import Programme
@testable import Record
import RecordTestSupport

/// The store half of the reminder wiring from the code review of 26
/// September 2026 (mm-t24.23, mm-t24.24, mm-t24.27, mm-t24.28, mm-t24.33).
/// No App-target test runner exists, so each test does what
/// `ReminderCoordinator` does with a real `RecordStore`, a temporary queue
/// file and the real `Programme` rules.
@MainActor
final class ReminderWiringTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func at(_ hour: Int, _ minute: Int = 0, day: Int = 6) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: mm-t24.23 — one change signal for every write

    /// "Pause for today", an entry, a plan, a template and a reminder pause
    /// each post the store's one change signal, which the App target's
    /// scheduler listens for.
    func testEveryWriteThatTheSchedulerReadsPostsTheChangeSignal() throws {
        let store = try makeTemporaryStore()
        var signals = 0
        let observer = NotificationCenter.default.addObserver(forName: RecordStore.didSaveNotification, object: store, queue: nil) { _ in signals += 1 }
        defer { NotificationCenter.default.removeObserver(observer) }

        try store.setDayState(.paused, on: true, dateKey: "2026-10-06", changedAt: at(14))
        XCTAssertEqual(signals, 1, "Pause for today")
        try store.add(time: at(12, 40), what: "soup", feltLikeABinge: false, createdAt: at(12, 40), utcOffsetSeconds: 0)
        XCTAssertEqual(signals, 2, "an entry")
        try store.setTemplateSlotsJSON("[]", kind: .weekday, changedAt: at(9))
        XCTAssertEqual(signals, 3, "a template")
        try store.pauseReminders(at: at(10))
        XCTAssertEqual(signals, 4, "the re-screen weight pause")
        try store.setPlannedMealAnswer("Skipped", dateKey: "2026-10-06", slotIndex: 2, changedAt: at(13, 5))
        XCTAssertEqual(signals, 5, "a planned meal answered")
    }

    /// Scenario: Pause at 14:00 — the paused day the store now holds gives
    /// no reminder for the rest of that record day.
    func testPauseForTodayLeavesNoReminderForTheRestOfTheDay() throws {
        let store = try makeTemporaryStore()
        try store.setDayState(.paused, on: true, dateKey: "2026-10-06", changedAt: at(14))
        let meals = [
            PlannedMealFact(slotIndex: 3, time: "16:00", matchedBeforeReminderTime: false),
            PlannedMealFact(slotIndex: 4, time: "19:00", matchedBeforeReminderTime: false),
        ]
        let day = schedulerDay(store: store, dayKey: "2026-10-06", meals: meals, closeTheDayMissing: true)
        let requests = Scheduler.requests(days: [day], settings: settings(), now: at(14), calendar: calendar)
        XCTAssertEqual(requests, [])
    }

    // MARK: mm-t24.24 — the queue file is applied through the store and emptied

    /// Scenario: Skipped while the app is closed, and Snooze count applied:
    /// the queue file the handler wrote reaches the store with each
    /// action's own moment, and the file is then empty.
    func testTheQueueFileIsAppliedWithEachMomentAndThenEmptied() throws {
        let store = try makeTemporaryStore()
        let queueURL = try makeTemporaryDirectory().appendingPathComponent("queue.json")
        let skipped = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40))
        let snooze = QueuedAction(kind: .snooze, dayKey: "2026-10-06", slotIndex: 3, plannedTime: "16:00", snoozeCount: 1, moment: at(16))
        try ActionQueueCodec.appending(snooze, to: ActionQueueCodec.appending(skipped, to: Data())).write(to: queueURL)

        // An in-app answer at 13:50 comes after the queued 13:40 skip, so
        // it wins: the skip carries its own moment, not the moment the app
        // opened at 14:10.
        try store.setPlannedMealAnswer("Had it", dateKey: "2026-10-06", slotIndex: 2, changedAt: at(13, 50))

        // What `ActionQueueFile.drain(into:)` does: read, apply, empty.
        let applied = try store.applyQueuedActions(ActionQueueCodec.decode(Data(contentsOf: queueURL)), currentRecordDayKey: "2026-10-06")
        try ActionQueueCodec.encode([]).write(to: queueURL)

        XCTAssertEqual(applied.count, 2)
        XCTAssertEqual(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2), "Had it")
        XCTAssertEqual(try store.snoozeCount(dateKey: "2026-10-06", slotIndex: 3), 1)
        XCTAssertEqual(try store.snoozeTapMoment(dateKey: "2026-10-06", slotIndex: 3), at(16))
        XCTAssertNil(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 3), "Record.store holds no snooze count")
        XCTAssertEqual(ActionQueueCodec.decode(try Data(contentsOf: queueURL)), [], "the queue is empty")
    }

    func testAQueuedSkipWithNoLaterAnswerSetsTheMealSkipped() throws {
        let store = try makeTemporaryStore()
        let skipped = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40))
        try store.applyQueuedActions([skipped], currentRecordDayKey: "2026-10-06")
        XCTAssertEqual(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2), "Skipped")
    }

    // MARK: mm-t24.27 — a snooze survives a recompute

    /// Scenario: A snooze survives a restart — after the queue reaches the
    /// store, the scheduler schedules the 13:15 reminder again from
    /// `Local.store` alone, so replacing every pending request keeps it.
    func testASnoozeFromTheQueueIsScheduledAgainAfterARecompute() throws {
        let directory = try makeTemporaryDirectory()
        do {
            let store = try RecordStore(directory: directory)
            let snooze = QueuedAction(kind: .snooze, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 1, moment: at(13))
            try store.applyQueuedActions([snooze], currentRecordDayKey: "2026-10-06")
        }
        let restarted = try RecordStore(directory: directory)
        let count = try restarted.snoozeCount(dateKey: "2026-10-06", slotIndex: 2)
        let tap = try XCTUnwrap(restarted.snoozeTapMoment(dateKey: "2026-10-06", slotIndex: 2))
        let lunch = PlannedMealFact(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)
        var day = schedulerDay(store: restarted, dayKey: "2026-10-06", meals: [lunch])
        day.snoozes = [SnoozeFact(slotIndex: 2, count: count, lastTapAt: tap)]

        let requests = Scheduler.requests(days: [day], settings: settings(), now: at(13, 5), calendar: calendar)

        let snoozed = requests.first { $0.id == SnoozeDecision.requestIdentifier(dayKey: "2026-10-06", slotIndex: 2, snoozeCount: 1) }
        XCTAssertEqual(snoozed?.time, at(13, 15))
    }

    // MARK: mm-t24.28 — the stop counts live in Local.store

    func testTheStopCountsAndTheFoldMarkSurviveARestart() throws {
        let directory = try makeTemporaryDirectory()
        do {
            let store = try RecordStore(directory: directory)
            let days = (5...11).map { ElapsedReminderDay(dayKey: String(format: "2026-10-%02d", $0), morningPlanDelivered: false, middayOrCloseTheDayDelivered: true, hadEntry: false, wasPaused: false, setItsOwnPlan: false) }
            let folded = ReminderStopFold.fold(.init(morningPlanUnanswered: try store.morningPlanUnansweredCount(), silentDays: try store.silentDayStreak()), foldedThrough: try store.reminderStopsFoldedThrough(), elapsedDays: days)
            try store.setSilentDayStreak(folded.counts.silentDays)
            try store.setMorningPlanUnansweredCount(folded.counts.morningPlanUnanswered)
            if let mark = folded.foldedThrough { try store.setReminderStopsFoldedThrough(mark) }
            try store.setPendingDeliveredReminderKinds(["2026-10-12": ["closeTheDay"]])
        }
        let restarted = try RecordStore(directory: directory)
        XCTAssertEqual(try restarted.silentDayStreak(), 7)
        XCTAssertTrue(SilentDayTracker.stopped(streak: try restarted.silentDayStreak()))
        XCTAssertEqual(try restarted.reminderStopsFoldedThrough(), "2026-10-11")
        XCTAssertEqual(try restarted.pendingDeliveredReminderKinds(), ["2026-10-12": ["closeTheDay"]])
    }

    // MARK: Helpers

    private func settings() -> SchedulerSettings {
        SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: true, quietHoursStart: "22:00", quietHoursEnd: "07:00")
    }

    /// The same facts `ReminderCoordinator.schedulerDay` reads from the
    /// store for one record day.
    private func schedulerDay(store: RecordStore, dayKey: String, meals: [PlannedMealFact], closeTheDayMissing: Bool = false) -> SchedulerDay {
        let states = (try? store.dayStates(dateKey: dayKey)) ?? []
        return SchedulerDay(
            dayKey: dayKey, dayStart: at(4), plannedMeals: meals, slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: false, isFasting: states.contains(.fasting)),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: !closeTheDayMissing, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: states.contains(.paused)
        )
    }
}
