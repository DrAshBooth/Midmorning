import Foundation
import Constants

/// One planned meal already resolved for a horizon day — from the day's own
/// `Day` row when materialised, or from the weekday or weekend template
/// otherwise (reminders spec, "A reminder for every planned meal": "For a
/// record day the app has not materialised, the scheduler MUST use the
/// day's template."). The caller resolves that fallback (`RecordStore`
/// already holds the template-or-day read this needs); `Scheduler` only
/// ever sees the resolved list, so it stays a pure function over plain
/// facts and needs no `Plan` import.
public struct PlannedMealFact: Sendable, Equatable {
    public var slotIndex: Int
    public var time: String
    /// An entry matched this planned meal before its reminder's time
    /// (reminders spec: "the scheduler MUST cancel that reminder").
    public var matchedBeforeReminderTime: Bool
    /// An entry matched this planned meal at any time, or the person
    /// answered it ("Skipped"). A snoozed reminder for it then has no
    /// purpose, so the scheduler does not schedule the snooze again.
    public var recordedOrAnswered: Bool

    public init(slotIndex: Int, time: String, matchedBeforeReminderTime: Bool, recordedOrAnswered: Bool = false) {
        self.slotIndex = slotIndex
        self.time = time
        self.matchedBeforeReminderTime = matchedBeforeReminderTime
        self.recordedOrAnswered = recordedOrAnswered || matchedBeforeReminderTime
    }
}

/// One planned meal's live snooze, from `Local.store` (reminders spec,
/// "Snooze a reminder": "The app MUST apply it to `Local.store`, keyed by the
/// record day key and the slot index."). `count` is the snooze count after
/// the last tap. `lastTapAt` is the moment of that tap. Both come from the
/// action queue.
public struct SnoozeFact: Sendable, Equatable {
    public var slotIndex: Int
    public var count: Int
    public var lastTapAt: Date

    public init(slotIndex: Int, count: Int, lastTapAt: Date) {
        self.slotIndex = slotIndex
        self.count = count
        self.lastTapAt = lastTapAt
    }
}

/// One record day's resolved facts, the input `Scheduler.requests` folds
/// over the rolling horizon.
public struct SchedulerDay: Sendable, Equatable {
    public var dayKey: String
    /// The record day's own start instant, for placing each clock time on
    /// its calendar day.
    public var dayStart: Date
    public var plannedMeals: [PlannedMealFact]
    /// A slot's label, by index, for the explicit-wording title.
    public var slotLabels: [Int: String]
    public var morningPlan: MorningPlanFacts
    public var midday: MiddayFacts
    public var closeTheDay: CloseTheDayFacts
    /// "Pause for today" was tapped for this day.
    public var isPaused: Bool
    /// Seven silent days stopped the midday and close-the-day reminders
    /// (reminders spec, "The midday and close-the-day reminders stop after
    /// seven silent days"). The stop also holds the far reminder, because
    /// the far reminder is that day's close-the-day reminder.
    public var silentDaysStop: Bool
    /// Each live snooze of this day's planned meals.
    public var snoozes: [SnoozeFact]

    public init(
        dayKey: String, dayStart: Date, plannedMeals: [PlannedMealFact], slotLabels: [Int: String],
        morningPlan: MorningPlanFacts, midday: MiddayFacts, closeTheDay: CloseTheDayFacts, isPaused: Bool,
        silentDaysStop: Bool = false, snoozes: [SnoozeFact] = []
    ) {
        self.dayKey = dayKey
        self.dayStart = dayStart
        self.plannedMeals = plannedMeals
        self.slotLabels = slotLabels
        self.morningPlan = morningPlan
        self.midday = midday
        self.closeTheDay = closeTheDay
        self.isPaused = isPaused
        self.silentDaysStop = silentDaysStop
        self.snoozes = snoozes
    }
}

/// The settings the scheduler reads (reminders spec, "Reminder types and
/// their switches", "Snooze a reminder", "Quiet hours", "Discreet text by
/// default").
public struct SchedulerSettings: Sendable, Equatable {
    public var switches: [ReminderKind: Bool]
    public var remindersPausedAt: Date?
    public var explicitWordingOn: Bool
    public var morningPlanTime: String
    public var closeTheDayTime: String
    public var quietHoursOn: Bool
    public var quietHoursStart: String
    public var quietHoursEnd: String
    /// When `false`, `Scheduler.requests` schedules nothing at all
    /// (reminders spec, "Reminder types and their switches": "When the
    /// person has not granted notification permission, the scheduler MUST
    /// schedule nothing."). Defaults to `true` so a caller that has no
    /// permission concern (most tests) never has to set it.
    public var notificationPermissionGranted: Bool
    /// SNOOZE_MINUTES, which the "Remind me again in" setting chooses
    /// (reminders spec, "Snooze a reminder").
    public var snoozeMinutes: Int

    public init(
        switches: [ReminderKind: Bool], remindersPausedAt: Date?, explicitWordingOn: Bool,
        morningPlanTime: String, closeTheDayTime: String,
        quietHoursOn: Bool, quietHoursStart: String, quietHoursEnd: String,
        notificationPermissionGranted: Bool = true,
        snoozeMinutes: Int = ProgrammeConstants.default.snoozeMinutes
    ) {
        self.switches = switches
        self.remindersPausedAt = remindersPausedAt
        self.explicitWordingOn = explicitWordingOn
        self.morningPlanTime = morningPlanTime
        self.closeTheDayTime = closeTheDayTime
        self.quietHoursOn = quietHoursOn
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.notificationPermissionGranted = notificationPermissionGranted
        self.snoozeMinutes = snoozeMinutes
    }

    /// The quiet-hours range every reminder and snooze reads: "off" (the
    /// start equal to the end) while the switch is off.
    public var effectiveQuietHours: (start: String, end: String) {
        QuietHours.effectiveRange(on: quietHoursOn, start: quietHoursStart, end: quietHoursEnd)
    }
}

/// The scheduler: a pure function over a rolling horizon (design.md, "The
/// scheduler is a pure function over a rolling horizon").
public enum Scheduler {
    /// Steps 1 to 3 and 5 to 7 of "The scheduler pipeline" (step 4, the
    /// reduced cadence, is a first-cut no-op: `mm-t36.17`/`mm-t36.21` add it,
    /// deferred.md). Operates on plain candidates, grouped by record day for
    /// the cap and the same-minute shift.
    ///
    /// `pausedDayKeys` holds each record day with "Pause for today" on.
    /// `dayStartMinutes` holds each record day's day-start clock minute, so
    /// the same-minute shift orders a time after midnight after a time in
    /// the evening. A day with no entry starts at 00:00.
    public static func pipeline(
        _ candidates: [ReminderCandidate],
        switches: [ReminderKind: Bool],
        remindersPausedAt: Date?,
        quietHoursOn: Bool,
        quietHoursStart: String,
        quietHoursEnd: String,
        pausedDayKeys: Set<String> = [],
        dayStartMinutes: [String: Int] = [:],
        constants: ProgrammeConstants = .default
    ) -> [ReminderCandidate] {
        // Step 1: the switches drop every type that is off.
        var result = candidates.filter { switches[$0.kind] ?? true }

        // Step 2: `remindersPausedAt`, when set, drops everything — every
        // day, until it is cleared (reminders spec: "The scheduler MUST
        // schedule nothing while it stays set.").
        guard remindersPausedAt == nil else { return [] }

        // Step 3: a paused day drops the rest of that day, the candidates
        // another capability asks for included (reminders spec: "the
        // scheduler MUST cancel every pending reminder for the rest of the
        // record day").
        result = result.filter { !pausedDayKeys.contains($0.dayKey) }

        // Step 4: the reduced cadence — first cut passes candidates through.

        // Step 5: the cap, per record day.
        result = byDay(result) { _, day in ReminderCap.apply(day, constants: constants) }

        // Step 6: the same-minute shift, per record day.
        result = byDay(result) { dayKey, day in SameMinuteShift.apply(day, dayStartMinute: dayStartMinutes[dayKey] ?? 0) }

        // Step 7: quiet hours.
        let quiet = QuietHours.effectiveRange(on: quietHoursOn, start: quietHoursStart, end: quietHoursEnd)
        result = result.filter { !QuietHours.contains(time: $0.time, start: quiet.start, end: quiet.end) }

        return result
    }

    private static func byDay(_ candidates: [ReminderCandidate], _ transform: (String, [ReminderCandidate]) -> [ReminderCandidate]) -> [ReminderCandidate] {
        var byDayKey: [String: [ReminderCandidate]] = [:]
        var order: [String] = []
        for candidate in candidates {
            if byDayKey[candidate.dayKey] == nil { order.append(candidate.dayKey) }
            byDayKey[candidate.dayKey, default: []].append(candidate)
        }
        return order.flatMap { transform($0, byDayKey[$0] ?? []) }
    }

    /// The candidates this capability's own four types contribute for one
    /// day, before the pipeline runs: every planned meal not already
    /// matched, plus the morning plan, midday and close-the-day reminders
    /// when their own rule fires. A paused day contributes none.
    public static func candidates(for day: SchedulerDay, settings: SchedulerSettings) -> [ReminderCandidate] {
        guard !day.isPaused else { return [] }
        var result: [ReminderCandidate] = []
        for meal in day.plannedMeals where !meal.matchedBeforeReminderTime {
            result.append(ReminderCandidate(kind: .plannedMeal, dayKey: day.dayKey, slotIndex: meal.slotIndex, time: meal.time))
        }
        if MorningPlanRule.shouldSchedule(day.morningPlan) {
            result.append(ReminderCandidate(kind: .morningPlan, dayKey: day.dayKey, time: settings.morningPlanTime))
        }
        if !day.silentDaysStop, MiddayRule.fires(day.midday) {
            result.append(ReminderCandidate(kind: .midday, dayKey: day.dayKey, time: MiddayRule.time))
        }
        if !day.silentDaysStop, CloseTheDayRule.somethingMissing(day.closeTheDay) {
            result.append(ReminderCandidate(kind: .closeTheDay, dayKey: day.dayKey, time: settings.closeTheDayTime))
        }
        return result
    }

    /// The full horizon: this capability's own candidates for every day,
    /// plus `extraCandidates` other capabilities ask for (the weigh-in day,
    /// weekly review, worksheet review and check-in reminders), through the
    /// pipeline, mapped to `ReminderRequest` values, capped at
    /// `MAX_PENDING_REQUESTS = 60` by dropping the farthest days first
    /// (reminders spec, "Scheduling is local, lazy and bounded"). Each live
    /// snooze comes back through `SnoozeDecision.decide` (reminders spec,
    /// "Snooze a reminder": "The handler and the scheduler MUST both call
    /// that function."); a snooze that fires at or before `now` does not.
    public static func requests(
        days: [SchedulerDay],
        extraCandidates: [ReminderCandidate] = [],
        farReminderDay: SchedulerDay? = nil,
        settings: SchedulerSettings,
        now: Date? = nil,
        calendar: Calendar = Calendar(identifier: .gregorian),
        constants: ProgrammeConstants = .default
    ) -> [ReminderRequest] {
        guard settings.notificationPermissionGranted else { return [] }

        var dayStarts: [String: Date] = [:]
        var dayStartMinutes: [String: Int] = [:]
        var pausedDayKeys: Set<String> = []
        var plannedTimes: [String: [Int: String]] = [:]
        var slotLabelsByDay: [String: [Int: String]] = [:]
        var allCandidates: [ReminderCandidate] = []
        for day in days {
            dayStarts[day.dayKey] = day.dayStart
            dayStartMinutes[day.dayKey] = ClockTime.minutesOfDay(of: day.dayStart, calendar: calendar)
            if day.isPaused { pausedDayKeys.insert(day.dayKey) }
            plannedTimes[day.dayKey] = Dictionary(day.plannedMeals.map { ($0.slotIndex, $0.time) }, uniquingKeysWith: { first, _ in first })
            slotLabelsByDay[day.dayKey] = day.slotLabels
            allCandidates += candidates(for: day, settings: settings)
        }
        allCandidates += extraCandidates

        var isFarReminder = false
        if let farDay = farReminderDay {
            dayStarts[farDay.dayKey] = farDay.dayStart
            dayStartMinutes[farDay.dayKey] = ClockTime.minutesOfDay(of: farDay.dayStart, calendar: calendar)
            if farDay.isPaused { pausedDayKeys.insert(farDay.dayKey) }
            // The far reminder counts as that day's own close-the-day
            // reminder (reminders spec: "The scheduler MUST count the far
            // reminder as that day's close-the-day reminder."), so the
            // silent-days stop holds it too.
            if !farDay.isPaused, !farDay.silentDaysStop {
                allCandidates.append(ReminderCandidate(kind: .closeTheDay, dayKey: farDay.dayKey, time: settings.closeTheDayTime))
                isFarReminder = true
            }
        }

        let scheduled = pipeline(
            allCandidates,
            switches: settings.switches,
            remindersPausedAt: settings.remindersPausedAt,
            quietHoursOn: settings.quietHoursOn,
            quietHoursStart: settings.quietHoursStart,
            quietHoursEnd: settings.quietHoursEnd,
            pausedDayKeys: pausedDayKeys,
            dayStartMinutes: dayStartMinutes,
            constants: constants
        )
        let quiet = settings.effectiveQuietHours

        var requests: [ReminderRequest] = []
        for candidate in scheduled {
            guard let dayStart = dayStarts[candidate.dayKey], let time = ClockTime.date(atTime: candidate.time, on: dayStart, calendar: calendar) else { continue }
            let farAndCloseTheDay = isFarReminder && candidate.kind == .closeTheDay && candidate.dayKey == farReminderDay?.dayKey
            let slotLabel = candidate.slotIndex.flatMap { slotLabelsByDay[candidate.dayKey]?[$0] }
            let title = DiscreetText.title(kind: candidate.kind, explicitWordingOn: settings.explicitWordingOn, slotLabel: slotLabel)
            // A planned meal reminder always names its own planned time,
            // also after the same-minute shift moved it.
            let plannedTime = candidate.slotIndex.flatMap { plannedTimes[candidate.dayKey]?[$0] } ?? candidate.time
            let body = DiscreetText.body(time: candidate.kind == .plannedMeal ? plannedTime : candidate.time)
            let userInfo: [String: String]
            if candidate.kind == .plannedMeal, let slotIndex = candidate.slotIndex {
                let next = nextPlannedMealTime(after: plannedTime, dayKey: candidate.dayKey, in: scheduled, plannedTimes: plannedTimes, dayStartMinute: dayStartMinutes[candidate.dayKey] ?? 0)
                userInfo = ReminderUserInfo(
                    dayKey: candidate.dayKey, slotIndex: slotIndex, plannedTime: plannedTime,
                    nextPlannedTime: next, snoozeCount: 0,
                    quietHoursStart: quiet.start, quietHoursEnd: quiet.end,
                    snoozeMinutes: settings.snoozeMinutes
                ).dictionary
            } else {
                userInfo = ["dayKey": candidate.dayKey, "kind": candidate.kind.rawValue]
            }
            requests.append(ReminderRequest(
                id: farAndCloseTheDay ? "far.\(candidate.dayKey)" : "\(candidate.kind.rawValue).\(candidate.dayKey).\(candidate.slotIndex.map(String.init) ?? "-")",
                kind: candidate.kind, dayKey: candidate.dayKey, slotIndex: candidate.slotIndex, time: time,
                title: title, body: body, userInfo: userInfo,
                category: candidate.kind.notificationCategory
            ))
        }

        requests += snoozeRequests(
            days: days, scheduled: scheduled, pausedDayKeys: pausedDayKeys, plannedTimes: plannedTimes,
            dayStartMinutes: dayStartMinutes, settings: settings, now: now, calendar: calendar, constants: constants
        )

        requests.sort { $0.time < $1.time }
        if requests.count > constants.maxPendingReminderRequests {
            requests = Array(requests.prefix(constants.maxPendingReminderRequests))
        }
        return requests
    }

    /// Each live snooze, scheduled again at the moment
    /// `SnoozeDecision.decide` gives for its last tap. Steps 1 to 3 of the
    /// pipeline hold a snooze too: the "Planned meals" switch, a reminder
    /// pause and a paused day each drop it (reminders spec, "A paused day
    /// and a reminder pause silence everything": "This MUST include snoozed
    /// reminders"). A snooze does not count toward the cap.
    private static func snoozeRequests(
        days: [SchedulerDay], scheduled: [ReminderCandidate], pausedDayKeys: Set<String>, plannedTimes: [String: [Int: String]],
        dayStartMinutes: [String: Int], settings: SchedulerSettings, now: Date?, calendar: Calendar, constants: ProgrammeConstants
    ) -> [ReminderRequest] {
        guard settings.switches[.plannedMeal] ?? true, settings.remindersPausedAt == nil else { return [] }
        let quiet = settings.effectiveQuietHours
        var result: [ReminderRequest] = []
        for day in days where !pausedDayKeys.contains(day.dayKey) {
            for snooze in day.snoozes where snooze.count > 0 {
                guard let meal = day.plannedMeals.first(where: { $0.slotIndex == snooze.slotIndex }), !meal.recordedOrAnswered else { continue }
                let next = nextPlannedMealTime(after: meal.time, dayKey: day.dayKey, in: scheduled, plannedTimes: plannedTimes, dayStartMinute: dayStartMinutes[day.dayKey] ?? 0)
                var userInfo = ReminderUserInfo(
                    dayKey: day.dayKey, slotIndex: meal.slotIndex, plannedTime: meal.time, nextPlannedTime: next,
                    snoozeCount: snooze.count - 1, quietHoursStart: quiet.start, quietHoursEnd: quiet.end,
                    snoozeMinutes: settings.snoozeMinutes
                )
                guard case .scheduleAt(let moment) = SnoozeDecision.decide(userInfo: userInfo, now: snooze.lastTapAt, calendar: calendar, constants: constants) else { continue }
                if let now, moment <= now { continue }
                userInfo.snoozeCount = snooze.count
                result.append(ReminderRequest(
                    id: SnoozeDecision.requestIdentifier(dayKey: day.dayKey, slotIndex: meal.slotIndex, snoozeCount: snooze.count),
                    kind: .plannedMeal, dayKey: day.dayKey, slotIndex: meal.slotIndex, time: moment,
                    title: DiscreetText.title(kind: .plannedMeal, explicitWordingOn: settings.explicitWordingOn, slotLabel: day.slotLabels[meal.slotIndex]),
                    body: DiscreetText.body(time: meal.time), userInfo: userInfo.dictionary,
                    category: ReminderKind.plannedMeal.notificationCategory
                ))
            }
        }
        return result
    }

    /// The next scheduled planned meal's planned time after `plannedTime`
    /// in the same record day, ordered from the day start, so a planned
    /// meal after midnight comes last.
    private static func nextPlannedMealTime(
        after plannedTime: String, dayKey: String, in scheduled: [ReminderCandidate],
        plannedTimes: [String: [Int: String]], dayStartMinute: Int
    ) -> String? {
        let after = ClockTime.minutesSinceDayStart(plannedTime, dayStartMinute: dayStartMinute)
        return scheduled
            .filter { $0.kind == .plannedMeal && $0.dayKey == dayKey }
            .compactMap { candidate in candidate.slotIndex.flatMap { plannedTimes[dayKey]?[$0] } ?? candidate.time }
            .filter { ClockTime.minutesSinceDayStart($0, dayStartMinute: dayStartMinute) > after }
            .min { ClockTime.minutesSinceDayStart($0, dayStartMinute: dayStartMinute) < ClockTime.minutesSinceDayStart($1, dayStartMinute: dayStartMinute) }
    }
}
