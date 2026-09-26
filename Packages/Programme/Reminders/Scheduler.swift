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

    public init(slotIndex: Int, time: String, matchedBeforeReminderTime: Bool) {
        self.slotIndex = slotIndex
        self.time = time
        self.matchedBeforeReminderTime = matchedBeforeReminderTime
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

    public init(
        dayKey: String, dayStart: Date, plannedMeals: [PlannedMealFact], slotLabels: [Int: String],
        morningPlan: MorningPlanFacts, midday: MiddayFacts, closeTheDay: CloseTheDayFacts, isPaused: Bool
    ) {
        self.dayKey = dayKey
        self.dayStart = dayStart
        self.plannedMeals = plannedMeals
        self.slotLabels = slotLabels
        self.morningPlan = morningPlan
        self.midday = midday
        self.closeTheDay = closeTheDay
        self.isPaused = isPaused
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

    public init(
        switches: [ReminderKind: Bool], remindersPausedAt: Date?, explicitWordingOn: Bool,
        morningPlanTime: String, closeTheDayTime: String,
        quietHoursOn: Bool, quietHoursStart: String, quietHoursEnd: String,
        notificationPermissionGranted: Bool = true
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
    }
}

/// The scheduler: a pure function over a rolling horizon (design.md, "The
/// scheduler is a pure function over a rolling horizon").
public enum Scheduler {
    /// Steps 1 to 3 and 5 to 7 of "The scheduler pipeline" (step 4, the
    /// reduced cadence, is a first-cut no-op: `mm-t36.17`/`mm-t36.21` add it,
    /// deferred.md). Operates on plain candidates, grouped by record day for
    /// the cap and the same-minute shift.
    public static func pipeline(
        _ candidates: [ReminderCandidate],
        switches: [ReminderKind: Bool],
        remindersPausedAt: Date?,
        quietHoursOn: Bool,
        quietHoursStart: String,
        quietHoursEnd: String,
        constants: ProgrammeConstants = .default
    ) -> [ReminderCandidate] {
        // Step 1: the switches drop every type that is off.
        var result = candidates.filter { switches[$0.kind] ?? true }

        // Step 2: `remindersPausedAt`, when set, drops everything — every
        // day, until it is cleared (reminders spec: "The scheduler MUST
        // schedule nothing while it stays set.").
        guard remindersPausedAt == nil else { return [] }

        // Step 3: a paused day drops the rest of that day — the caller
        // passes only unpaused days' candidates in, since a paused day
        // contributes none in the first place (`requests(days:)` below).

        // Step 4: the reduced cadence — first cut passes candidates through.

        // Step 5: the cap, per record day.
        result = byDay(result) { ReminderCap.apply($0, constants: constants) }

        // Step 6: the same-minute shift, per record day.
        result = byDay(result) { SameMinuteShift.apply($0) }

        // Step 7: quiet hours.
        let quietHoursActive = quietHoursOn && ReminderQuietHours.isOn(start: quietHoursStart, end: quietHoursEnd)
        if quietHoursActive {
            result = result.filter { !ReminderQuietHours.contains(time: $0.time, start: quietHoursStart, end: quietHoursEnd) }
        }

        return result
    }

    private static func byDay(_ candidates: [ReminderCandidate], _ transform: ([ReminderCandidate]) -> [ReminderCandidate]) -> [ReminderCandidate] {
        var byDayKey: [String: [ReminderCandidate]] = [:]
        var order: [String] = []
        for candidate in candidates {
            if byDayKey[candidate.dayKey] == nil { order.append(candidate.dayKey) }
            byDayKey[candidate.dayKey, default: []].append(candidate)
        }
        return order.flatMap { transform(byDayKey[$0] ?? []) }
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
        if MiddayRule.fires(day.midday) {
            result.append(ReminderCandidate(kind: .midday, dayKey: day.dayKey, time: MiddayRule.time))
        }
        if CloseTheDayRule.somethingMissing(day.closeTheDay) {
            result.append(ReminderCandidate(kind: .closeTheDay, dayKey: day.dayKey, time: settings.closeTheDayTime))
        }
        return result
    }

    /// The full horizon: this capability's own candidates for every day,
    /// plus `extraCandidates` other capabilities ask for (the weigh-in day,
    /// weekly review, worksheet review and check-in reminders), through the
    /// pipeline, mapped to `ReminderRequest` values, capped at
    /// `MAX_PENDING_REQUESTS = 60` by dropping the farthest days first
    /// (reminders spec, "Scheduling is local, lazy and bounded").
    public static func requests(
        days: [SchedulerDay],
        extraCandidates: [ReminderCandidate] = [],
        farReminderDay: SchedulerDay? = nil,
        settings: SchedulerSettings,
        calendar: Calendar = Calendar(identifier: .gregorian),
        constants: ProgrammeConstants = .default
    ) -> [ReminderRequest] {
        guard settings.notificationPermissionGranted else { return [] }

        var dayStarts: [String: Date] = [:]
        var slotLabelsByDay: [String: [Int: String]] = [:]
        var allCandidates: [ReminderCandidate] = []
        for day in days {
            dayStarts[day.dayKey] = day.dayStart
            slotLabelsByDay[day.dayKey] = day.slotLabels
            allCandidates += candidates(for: day, settings: settings)
        }
        allCandidates += extraCandidates

        var isFarReminder = false
        if let farDay = farReminderDay, !farDay.isPaused {
            dayStarts[farDay.dayKey] = farDay.dayStart
            // The far reminder counts as that day's own close-the-day
            // reminder (reminders spec: "The scheduler MUST count the far
            // reminder as that day's close-the-day reminder.").
            allCandidates.append(ReminderCandidate(kind: .closeTheDay, dayKey: farDay.dayKey, time: settings.closeTheDayTime))
            isFarReminder = true
        }

        let scheduled = pipeline(
            allCandidates,
            switches: settings.switches,
            remindersPausedAt: settings.remindersPausedAt,
            quietHoursOn: settings.quietHoursOn,
            quietHoursStart: settings.quietHoursStart,
            quietHoursEnd: settings.quietHoursEnd,
            constants: constants
        )

        var requests: [ReminderRequest] = []
        for candidate in scheduled {
            guard let dayStart = dayStarts[candidate.dayKey], let time = ReminderClock.date(atTime: candidate.time, on: dayStart, calendar: calendar) else { continue }
            let farAndCloseTheDay = isFarReminder && candidate.kind == .closeTheDay && candidate.dayKey == farReminderDay?.dayKey
            let slotLabel = candidate.slotIndex.flatMap { slotLabelsByDay[candidate.dayKey]?[$0] }
            let title = DiscreetText.title(kind: candidate.kind, explicitWordingOn: settings.explicitWordingOn, slotLabel: slotLabel)
            let body = DiscreetText.body(time: candidate.time)
            let userInfo: [String: String]
            if candidate.kind == .plannedMeal, let slotIndex = candidate.slotIndex {
                let next = nextPlannedMealTime(after: candidate, in: scheduled)
                userInfo = ReminderUserInfo(
                    dayKey: candidate.dayKey, slotIndex: slotIndex, plannedTime: candidate.time,
                    nextPlannedTime: next, snoozeCount: 0,
                    quietHoursStart: settings.quietHoursStart, quietHoursEnd: settings.quietHoursEnd,
                    snoozeMinutes: 15
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

        requests.sort { $0.time < $1.time }
        if requests.count > constants.maxPendingReminderRequests {
            requests = Array(requests.prefix(constants.maxPendingReminderRequests))
        }
        return requests
    }

    private static func nextPlannedMealTime(after candidate: ReminderCandidate, in scheduled: [ReminderCandidate]) -> String? {
        scheduled
            .filter { $0.kind == .plannedMeal && $0.dayKey == candidate.dayKey && ReminderClock.minutesOfDay($0.time) > ReminderClock.minutesOfDay(candidate.time) }
            .min { ReminderClock.minutesOfDay($0.time) < ReminderClock.minutesOfDay($1.time) }?
            .time
    }
}
