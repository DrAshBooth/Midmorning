import XCTest
import Constants
@testable import Programme

/// The scheduler fixes from the code review of 26 September 2026
/// (mm-t24.26, mm-t24.27, mm-t24.28, mm-t24.30, mm-t24.31, mm-t24.32,
/// mm-t24.36). Each test drives `Scheduler.requests` or the pure rule that
/// the App target calls, and reads the output the App target hands to
/// `UNUserNotificationCenter`.
final class SchedulerReviewFixesTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func moment(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private func settings(
        quietHoursOn: Bool = false, quietHoursStart: String = "22:00", quietHoursEnd: String = "07:00",
        snoozeMinutes: Int = 15, switches: [ReminderKind: Bool] = [:], pausedAt: Date? = nil
    ) -> SchedulerSettings {
        SchedulerSettings(
            switches: switches, remindersPausedAt: pausedAt, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45",
            quietHoursOn: quietHoursOn, quietHoursStart: quietHoursStart, quietHoursEnd: quietHoursEnd, snoozeMinutes: snoozeMinutes
        )
    }

    /// A day with only planned meals: no midday, close-the-day or morning
    /// plan reminder.
    private func day(
        _ dayKey: String, start: Date, meals: [PlannedMealFact], paused: Bool = false,
        silentDaysStop: Bool = false, snoozes: [SnoozeFact] = [], closeTheDayMissing: Bool = false, middayFires: Bool = false
    ) -> SchedulerDay {
        SchedulerDay(
            dayKey: dayKey, dayStart: start, plannedMeals: meals, slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: !middayFires, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: !closeTheDayMissing, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: paused, silentDaysStop: silentDaysStop, snoozes: snoozes
        )
    }

    private func lunch(recorded: Bool = false) -> PlannedMealFact {
        PlannedMealFact(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false, recordedOrAnswered: recorded)
    }

    // MARK: mm-t24.30 — a paused day drops the other capabilities' reminders too

    /// A verifier run from the review: a paused 5 October with the weekly
    /// review at 18:00 and the weigh-in day at 07:30 gave both requests.
    func testAPausedDayDropsTheWeighInDayAndWeeklyReviewReminders() {
        let paused = day("2026-10-05", start: moment(10, 5, 4), meals: [lunch()], paused: true)
        let extras = [
            ReminderCandidate(kind: .weeklyReview, dayKey: "2026-10-05", time: "18:00"),
            ReminderCandidate(kind: .weighInDay, dayKey: "2026-10-05", time: "07:30"),
        ]
        let requests = Scheduler.requests(days: [paused], extraCandidates: extras, settings: settings(), calendar: calendar)
        XCTAssertEqual(requests, [])
    }

    func testTheDayAfterAPausedDayKeepsItsExtraReminders() {
        let paused = day("2026-10-05", start: moment(10, 5, 4), meals: [], paused: true)
        let next = day("2026-10-06", start: moment(10, 6, 4), meals: [])
        let extras = [ReminderCandidate(kind: .weighInDay, dayKey: "2026-10-06", time: "07:30")]
        let requests = Scheduler.requests(days: [paused, next], extraCandidates: extras, settings: settings(), calendar: calendar)
        XCTAssertEqual(requests.map(\.dayKey), ["2026-10-06"])
    }

    func testAPausedFarDayGetsNoFarReminder() {
        let today = day("2026-10-05", start: moment(10, 5, 4), meals: [])
        let far = day("2026-10-11", start: moment(10, 11, 4), meals: [], paused: true)
        XCTAssertEqual(Scheduler.requests(days: [today], farReminderDay: far, settings: settings(), calendar: calendar), [])
    }

    // MARK: mm-t24.26 — the snooze length and quiet hours off reach the userInfo

    private func lunchUserInfo(_ requests: [ReminderRequest]) -> ReminderUserInfo? {
        requests.first { $0.kind == .plannedMeal && $0.slotIndex == 2 }.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }
    }

    /// Scenario: The thirty-minute title — the userInfo the scheduler
    /// emits carries 30, so the snooze fires at 13:30.
    func testTheThirtyMinuteSnoozeFiresAt1330() {
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()])
        let requests = Scheduler.requests(days: [today], settings: settings(snoozeMinutes: 30), calendar: calendar)
        let info = try? XCTUnwrap(lunchUserInfo(requests))
        XCTAssertEqual(info?.snoozeMinutes, 30)
        guard let info, case .scheduleAt(let when) = SnoozeDecision.decide(userInfo: info, now: moment(10, 6, 13), calendar: calendar) else {
            return XCTFail("the snooze should schedule")
        }
        XCTAssertEqual(when, moment(10, 6, 13, 30))
    }

    func testTheDefaultSnoozeLengthIsFifteenMinutes() {
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()])
        let requests = Scheduler.requests(days: [today], settings: settings(), calendar: calendar)
        XCTAssertEqual(lunchUserInfo(requests)?.snoozeMinutes, ProgrammeConstants.default.snoozeMinutes)
    }

    /// With quiet hours off, a snooze into 22:00 to 07:00 still fires.
    func testQuietHoursOffLetsASnoozeFireAt2205() {
        let evening = PlannedMealFact(slotIndex: 5, time: "21:00", matchedBeforeReminderTime: false)
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [evening])
        let requests = Scheduler.requests(days: [today], settings: settings(quietHoursOn: false), calendar: calendar)
        let info = requests.first.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }
        XCTAssertEqual(info?.quietHoursStart, info?.quietHoursEnd, "quiet hours off travel as a start equal to the end")
        guard let info, case .scheduleAt(let when) = SnoozeDecision.decide(userInfo: info, now: moment(10, 6, 21, 50), calendar: calendar) else {
            return XCTFail("with quiet hours off the snooze should schedule")
        }
        XCTAssertEqual(when, moment(10, 6, 22, 5))
    }

    /// Scenario: A snooze into quiet hours — with quiet hours on, the same
    /// userInfo still drops the snooze.
    func testQuietHoursOnStillDropsASnoozeAt2205() {
        let evening = PlannedMealFact(slotIndex: 5, time: "21:00", matchedBeforeReminderTime: false)
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [evening])
        let requests = Scheduler.requests(days: [today], settings: settings(quietHoursOn: true), calendar: calendar)
        let info = requests.first.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }
        XCTAssertEqual(info?.quietHoursStart, "22:00")
        XCTAssertEqual(info?.quietHoursEnd, "07:00")
        XCTAssertEqual(info.map { SnoozeDecision.decide(userInfo: $0, now: moment(10, 6, 21, 50), calendar: calendar) }, .drop)
    }

    func testQuietHoursOffLetsAPlannedMealAt2230Fire() {
        let snack = PlannedMealFact(slotIndex: 5, time: "22:30", matchedBeforeReminderTime: false)
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [snack])
        XCTAssertEqual(Scheduler.requests(days: [today], settings: settings(quietHoursOn: false), calendar: calendar).map(\.body), ["22:30"])
        XCTAssertEqual(Scheduler.requests(days: [today], settings: settings(quietHoursOn: true), calendar: calendar), [])
    }

    // MARK: mm-t24.27 — the scheduler schedules each live snooze again

    /// Scenario: A snooze survives a restart — the snooze count and the tap
    /// moment from `Local.store` give the 13:15 reminder again, under the
    /// handler's own identifier.
    func testALiveSnoozeIsScheduledAgain() {
        let snooze = SnoozeFact(slotIndex: 2, count: 1, lastTapAt: moment(10, 6, 13))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()], snoozes: [snooze])
        let requests = Scheduler.requests(days: [today], settings: settings(), now: moment(10, 6, 13, 5), calendar: calendar)
        let snoozed = requests.first { $0.id.hasPrefix("snooze.") }
        XCTAssertEqual(snoozed?.id, SnoozeDecision.requestIdentifier(dayKey: "2026-10-06", slotIndex: 2, snoozeCount: 1))
        XCTAssertEqual(snoozed?.time, moment(10, 6, 13, 15))
        XCTAssertEqual(snoozed?.body, "13:00", "a snoozed reminder shows the same text")
        XCTAssertEqual(snoozed?.category, ReminderKind.plannedMeal.notificationCategory, "and the same actions")
        XCTAssertEqual(snoozed.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }?.snoozeCount, 1)
    }

    func testASnoozeThatAlreadyFiredIsNotScheduledAgain() {
        let snooze = SnoozeFact(slotIndex: 2, count: 1, lastTapAt: moment(10, 6, 13))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()], snoozes: [snooze])
        let requests = Scheduler.requests(days: [today], settings: settings(), now: moment(10, 6, 13, 20), calendar: calendar)
        XCTAssertFalse(requests.contains { $0.id.hasPrefix("snooze.") })
    }

    /// Scenario: A third snooze — the third tap is a drop, so the scheduler
    /// holds none either.
    func testAThirdSnoozeIsNotScheduledAgain() {
        let snooze = SnoozeFact(slotIndex: 2, count: 3, lastTapAt: moment(10, 6, 13, 30))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()], snoozes: [snooze])
        let requests = Scheduler.requests(days: [today], settings: settings(), now: moment(10, 6, 13, 31), calendar: calendar)
        XCTAssertFalse(requests.contains { $0.id.hasPrefix("snooze.") })
    }

    /// Scenario: Pause at 14:00 — "This MUST include snoozed reminders".
    func testAPausedDayCancelsASnooze() {
        let snooze = SnoozeFact(slotIndex: 2, count: 1, lastTapAt: moment(10, 6, 13))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()], paused: true, snoozes: [snooze])
        XCTAssertEqual(Scheduler.requests(days: [today], settings: settings(), now: moment(10, 6, 13, 5), calendar: calendar), [])
    }

    func testAReminderPauseOrTheSwitchCancelsASnooze() {
        let snooze = SnoozeFact(slotIndex: 2, count: 1, lastTapAt: moment(10, 6, 13))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch()], snoozes: [snooze])
        XCTAssertEqual(Scheduler.requests(days: [today], settings: settings(pausedAt: moment(10, 6, 13, 2)), now: moment(10, 6, 13, 5), calendar: calendar), [])
        let switchedOff = Scheduler.requests(days: [today], settings: settings(switches: [.plannedMeal: false]), now: moment(10, 6, 13, 5), calendar: calendar)
        XCTAssertFalse(switchedOff.contains { $0.id.hasPrefix("snooze.") })
    }

    func testARecordedOrSkippedMealCancelsItsSnooze() {
        let snooze = SnoozeFact(slotIndex: 2, count: 1, lastTapAt: moment(10, 6, 13))
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: [lunch(recorded: true)], snoozes: [snooze])
        let requests = Scheduler.requests(days: [today], settings: settings(), now: moment(10, 6, 13, 5), calendar: calendar)
        XCTAssertFalse(requests.contains { $0.id.hasPrefix("snooze.") })
    }

    // MARK: mm-t24.28 — the silent-days stop and the two stop counts

    /// Scenario: Seven silent days — no midday and no close-the-day
    /// reminder, and no far reminder.
    func testTheSilentDaysStopHoldsMiddayCloseTheDayAndTheFarReminder() {
        let stopped = day("2026-10-06", start: moment(10, 6, 4), meals: [], silentDaysStop: true, closeTheDayMissing: true, middayFires: true)
        let far = day("2026-10-12", start: moment(10, 12, 4), meals: [], silentDaysStop: true)
        XCTAssertEqual(Scheduler.requests(days: [stopped], farReminderDay: far, settings: settings(), calendar: calendar), [])
        let running = day("2026-10-06", start: moment(10, 6, 4), meals: [], closeTheDayMissing: true, middayFires: true)
        XCTAssertEqual(Set(Scheduler.requests(days: [running], settings: settings(), calendar: calendar).map(\.kind)), [.midday, .closeTheDay])
    }

    private func elapsed(_ dayKey: String, morningPlan: Bool = false, silent: Bool = false, entry: Bool = false, paused: Bool = false, set: Bool = false) -> ElapsedReminderDay {
        ElapsedReminderDay(dayKey: dayKey, morningPlanDelivered: morningPlan, middayOrCloseTheDayDelivered: silent, hadEntry: entry, wasPaused: paused, setItsOwnPlan: set)
    }

    /// Scenario: Days with no delivered reminder — Monday 5 October to
    /// Friday 16 October, delivered Monday to Saturday only: six, not
    /// eleven, and a second read of the same days adds nothing.
    func testDaysWithNoDeliveredReminder() {
        let days = (5...15).map { day in elapsed(String(format: "2026-10-%02d", day), morningPlan: day <= 10) }
        let zero = ReminderStopCounts(morningPlanUnanswered: 0, silentDays: 0)
        let first = ReminderStopFold.fold(zero, foldedThrough: nil, elapsedDays: days)
        XCTAssertEqual(first.counts.morningPlanUnanswered, 6)
        XCTAssertTrue(first.counts.morningPlanStopped)
        XCTAssertEqual(first.foldedThrough, "2026-10-15")
        let again = ReminderStopFold.fold(first.counts, foldedThrough: first.foldedThrough, elapsedDays: days)
        XCTAssertEqual(again.counts, first.counts)
    }

    /// Scenario: A paused day in the run.
    func testAPausedDayInTheRun() {
        var days = (5...10).map { elapsed(String(format: "2026-10-%02d", $0), silent: true) }
        days.append(elapsed("2026-10-11", paused: true))
        days.append(elapsed("2026-10-12", silent: true))
        let result = ReminderStopFold.fold(.init(morningPlanUnanswered: 0, silentDays: 0), foldedThrough: nil, elapsedDays: days)
        XCTAssertEqual(result.counts.silentDays, 7)
        XCTAssertTrue(result.counts.silentDaysStopped)
    }

    /// Scenario: An entry after the stop / Three unanswered days — an entry
    /// in the current record day, or a set plan, starts the stopped type
    /// again.
    func testAnEntryOrAPlanStartsTheStoppedTypesAgain() {
        let stopped = ReminderStopCounts(morningPlanUnanswered: 3, silentDays: 7)
        let afterEntry = ReminderStopFold.restart(stopped, currentDayHasEntry: true, currentOrNextDayIsSet: false, templatesChanged: false)
        XCTAssertEqual(afterEntry, .init(morningPlanUnanswered: 3, silentDays: 0))
        let afterPlan = ReminderStopFold.restart(stopped, currentDayHasEntry: false, currentOrNextDayIsSet: true, templatesChanged: false)
        XCTAssertEqual(afterPlan, .init(morningPlanUnanswered: 0, silentDays: 7))
        let afterTemplate = ReminderStopFold.restart(stopped, currentDayHasEntry: false, currentOrNextDayIsSet: false, templatesChanged: true)
        XCTAssertEqual(afterTemplate.morningPlanUnanswered, 0)
    }

    // MARK: mm-t24.31 — the weekly review reminder ahead of the due day

    /// The last activation is Sunday 11 October, the day before the week 2
    /// review becomes due on Monday 12 October (start day Monday 28
    /// September): the horizon holds the 18:00 reminder on 12 October.
    func testTheWeeklyReviewReminderIsScheduledBeforeTheDueDay() {
        let horizon = (11...16).map { String(format: "2026-10-%02d", $0) }
        let candidates = WeeklyReviewReminderRule.candidates(startDay: "2026-09-28", dayKeys: horizon, time: "18:00", calendar: calendar, isFinished: { _ in false })
        XCTAssertEqual(candidates, [ReminderCandidate(kind: .weeklyReview, dayKey: "2026-10-12", time: "18:00")])
    }

    /// Scenario: The review done early.
    func testAFinishedReviewGetsNoReminder() {
        let horizon = (11...16).map { String(format: "2026-10-%02d", $0) }
        let candidates = WeeklyReviewReminderRule.candidates(startDay: "2026-09-28", dayKeys: horizon, time: "18:00", calendar: calendar, isFinished: { $0 == 2 })
        XCTAssertEqual(candidates, [])
    }

    /// Scenario: Mid-week — no due day in the horizon, and the start day
    /// itself is never a due day.
    func testNoDueDayGivesNoReminder() {
        let horizon = (28...30).map { String(format: "2026-09-%02d", $0) } + (1...3).map { String(format: "2026-10-%02d", $0) }
        XCTAssertEqual(WeeklyReviewReminderRule.candidates(startDay: "2026-09-28", dayKeys: horizon, time: "18:00", calendar: calendar, isFinished: { _ in false }), [])
    }

    // MARK: mm-t24.32 — clock times between midnight and the day start

    /// regular-eating-plan spec, "A planned meal after midnight": 00:30 for
    /// Friday's record day fires on Saturday's date.
    func testAPlannedMealAfterMidnightFiresOnTheNextDate() {
        let friday = day("2026-10-09", start: moment(10, 9, 4), meals: [PlannedMealFact(slotIndex: 5, time: "00:30", matchedBeforeReminderTime: false)])
        let requests = Scheduler.requests(days: [friday], settings: settings(), calendar: calendar)
        XCTAssertEqual(requests.first?.time, moment(10, 10, 0, 30))
        XCTAssertEqual(requests.first?.dayKey, "2026-10-09")
    }

    /// reminders spec, "Scheduling is local, lazy and bounded", scenario "A
    /// later day start": 04:30 on Thursday's date for Wednesday.
    func testALaterDayStartPlacesTheTimeOnThursday() {
        let wednesday = day("2026-09-30", start: moment(9, 30, 5), meals: [PlannedMealFact(slotIndex: 0, time: "04:30", matchedBeforeReminderTime: false)])
        let requests = Scheduler.requests(days: [wednesday], settings: settings(), calendar: calendar)
        XCTAssertEqual(requests.first?.time, moment(10, 1, 4, 30))
        XCTAssertEqual(requests.first?.body, "04:30")
    }

    func testTheNextPlannedTimeAfterMidnightComesLast() {
        let meals = [
            PlannedMealFact(slotIndex: 4, time: "21:00", matchedBeforeReminderTime: false),
            PlannedMealFact(slotIndex: 5, time: "00:30", matchedBeforeReminderTime: false),
        ]
        let friday = day("2026-10-09", start: moment(10, 9, 4), meals: meals)
        let requests = Scheduler.requests(days: [friday], settings: settings(), calendar: calendar)
        let evening = requests.first { $0.slotIndex == 4 }.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }
        XCTAssertEqual(evening?.nextPlannedTime, "00:30")
        let late = requests.first { $0.slotIndex == 5 }.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }
        XCTAssertNil(late?.nextPlannedTime)
    }

    /// A snooze at 23:10 with the next planned meal at 00:30 is before the
    /// next planned meal, so it fires.
    func testASnoozeBeforeANextPlannedMealAfterMidnightFires() {
        let info = ReminderUserInfo(dayKey: "2026-10-09", slotIndex: 4, plannedTime: "23:00", nextPlannedTime: "00:30", snoozeCount: 0, quietHoursStart: "07:00", quietHoursEnd: "07:00", snoozeMinutes: 15)
        XCTAssertEqual(SnoozeDecision.decide(userInfo: info, now: moment(10, 9, 23, 10), calendar: calendar), .scheduleAt(moment(10, 9, 23, 25)))
        let late = ReminderUserInfo(dayKey: "2026-10-09", slotIndex: 4, plannedTime: "23:00", nextPlannedTime: "00:30", snoozeCount: 0, quietHoursStart: "07:00", quietHoursEnd: "07:00", snoozeMinutes: 30)
        XCTAssertEqual(SnoozeDecision.decide(userInfo: late, now: moment(10, 10, 0, 5), calendar: calendar), .drop)
    }

    func testAWindowThatEndsAfterMidnightStaysOpenInTheEvening() {
        let snack = DeliveredReminder(id: "plannedMeal.2026-10-09.5", kind: .plannedMeal, dayKey: "2026-10-09", windowEndTime: "00:45")
        XCTAssertEqual(DeliveredReminderRemoval.idsToRemove(delivered: [snack], currentRecordDayKey: "2026-10-09", nowClockTime: "22:00", dayStartMinute: 240), [])
        XCTAssertEqual(DeliveredReminderRemoval.idsToRemove(delivered: [snack], currentRecordDayKey: "2026-10-09", nowClockTime: "01:00", dayStartMinute: 240), [snack.id])
    }

    /// Scenario: An entry after the reminder.
    func testADeliveredReminderForARecordedMealIsRemoved() {
        let lunch = DeliveredReminder(id: "plannedMeal.2026-10-09.2", kind: .plannedMeal, dayKey: "2026-10-09", windowEndTime: "14:30", recordedOrAnswered: true)
        XCTAssertEqual(DeliveredReminderRemoval.idsToRemove(delivered: [lunch], currentRecordDayKey: "2026-10-09", nowClockTime: "13:20", dayStartMinute: 240), [lunch.id])
    }

    // MARK: mm-t24.36 — the same-minute shift moves only a taken minute

    private func c(_ kind: ReminderKind, _ time: String, slot: Int? = nil) -> ReminderCandidate {
        ReminderCandidate(kind: kind, dayKey: "2026-09-28", slotIndex: slot, time: time)
    }

    func testAPlannedMealIsNeverMovedForALowerPriorityReminder() {
        let result = SameMinuteShift.apply([c(.weighInDay, "07:30"), c(.morningPlan, "07:30"), c(.plannedMeal, "07:35", slot: 0)])
        XCTAssertEqual(result.first { $0.kind == .weighInDay }?.time, "07:30")
        XCTAssertEqual(result.first { $0.kind == .plannedMeal }?.time, "07:35")
        XCTAssertEqual(result.first { $0.kind == .morningPlan }?.time, "07:40")
    }

    func testAReminderWhoseMinuteIsFreeDoesNotMove() {
        let result = SameMinuteShift.apply([c(.weighInDay, "07:30"), c(.morningPlan, "07:30"), c(.closeTheDay, "07:33")])
        XCTAssertEqual(result.first { $0.kind == .closeTheDay }?.time, "07:33")
        XCTAssertEqual(result.first { $0.kind == .morningPlan }?.time, "07:35")
    }

    func testTheShiftOrdersATimeAfterMidnightAfterTheEvening() {
        let result = SameMinuteShift.apply([c(.plannedMeal, "00:00", slot: 5), c(.closeTheDay, "23:55"), c(.weighInDay, "23:55")], dayStartMinute: 240)
        XCTAssertEqual(result.first { $0.kind == .plannedMeal }?.time, "00:00")
        XCTAssertEqual(result.first { $0.kind == .closeTheDay }?.time, "23:55")
        XCTAssertEqual(result.first { $0.kind == .weighInDay }?.time, "00:05")
    }

    /// A moved planned meal keeps its planned time in the body and the
    /// userInfo.
    func testAMovedPlannedMealKeepsItsPlannedTime() {
        let meals = [
            PlannedMealFact(slotIndex: 1, time: "10:30", matchedBeforeReminderTime: false),
            PlannedMealFact(slotIndex: 2, time: "10:30", matchedBeforeReminderTime: false),
        ]
        let today = day("2026-10-06", start: moment(10, 6, 4), meals: meals)
        let requests = Scheduler.requests(days: [today], settings: settings(), calendar: calendar)
        let moved = requests.first { $0.slotIndex == 2 }
        XCTAssertEqual(moved?.time, moment(10, 6, 10, 35))
        XCTAssertEqual(moved?.body, "10:30")
        XCTAssertEqual(moved.flatMap { ReminderUserInfo(dictionary: $0.userInfo) }?.plannedTime, "10:30")
    }

    // MARK: mm-t24.34 — "Close the day" beside "Pause for today"

    func testCloseTheDayShowsAfter1700InStage1() {
        XCTAssertFalse(CloseTheDayRule.controlShows(nowClockTime: "16:59", dayStartMinute: 240, stage2Open: false, plannedMealTimes: []))
        XCTAssertTrue(CloseTheDayRule.controlShows(nowClockTime: "17:00", dayStartMinute: 240, stage2Open: false, plannedMealTimes: []))
        XCTAssertTrue(CloseTheDayRule.controlShows(nowClockTime: "01:00", dayStartMinute: 240, stage2Open: false, plannedMealTimes: []), "after midnight is still after 17:00 in the same record day")
        XCTAssertTrue(CloseTheDayRule.controlShows(nowClockTime: "18:00", dayStartMinute: 240, stage2Open: false, plannedMealTimes: ["19:00"]), "stage 1 ignores the plan")
    }

    func testCloseTheDayShowsAfterTheLastPlannedMealFromStage2() {
        let meals = ["08:00", "13:00", "21:00"]
        XCTAssertFalse(CloseTheDayRule.controlShows(nowClockTime: "20:59", dayStartMinute: 240, stage2Open: true, plannedMealTimes: meals))
        XCTAssertTrue(CloseTheDayRule.controlShows(nowClockTime: "21:00", dayStartMinute: 240, stage2Open: true, plannedMealTimes: meals))
        XCTAssertFalse(CloseTheDayRule.controlShows(nowClockTime: "23:00", dayStartMinute: 240, stage2Open: true, plannedMealTimes: meals + ["00:30"]), "a planned meal after midnight is the last one")
        XCTAssertTrue(CloseTheDayRule.controlShows(nowClockTime: "17:30", dayStartMinute: 240, stage2Open: true, plannedMealTimes: []), "no planned meal: the stage 1 time applies")
    }

    // MARK: mm-t24.25 — the denied line needs a switch that is on

    func testTheDeniedLineShowsOnlyWhileASwitchIsOn() {
        XCTAssertEqual(ReminderPermissionText.todayLine(permission: .denied, hasTappedDeniedLineOnce: false, anySwitchOn: true), ReminderPermissionText.todayLineDenied)
        XCTAssertNil(ReminderPermissionText.todayLine(permission: .denied, hasTappedDeniedLineOnce: false, anySwitchOn: false))
        XCTAssertEqual(ReminderPermissionText.todayLine(permission: .notDetermined, hasTappedDeniedLineOnce: false, anySwitchOn: false), ReminderPermissionText.todayLineBeforePermission)
    }
}
