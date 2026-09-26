import Foundation
import UserNotifications
import Constants
import Record
import Plan
import Programme

/// Gathers the real facts `Scheduler.requests` needs from `RecordStore` and
/// `Plan`, then replaces every pending local notification request with the
/// result (design.md, "The scheduler is a pure function over a rolling
/// horizon": "the app materialises every elapsed record day, then replaces
/// all pending requests with the result").
///
/// Only the current record day can hold an entry, so only it needs a real
/// entry-vs-window match; every later day in the horizon has no entry yet,
/// so its planned meals are correctly unmatched and its midday/close-the-day
/// facts correctly read as "nothing yet" (reminders spec: a future day's
/// close-the-day reminder schedules ahead of time and cancels reactively
/// when an entry arrives). `stage2Open` stays a fixture `false`, the same
/// pattern `GapBand`/`PlanBuilderAccess` already use ahead of
/// `programme-engine` (2.1); `mm-t21.23` wires the live stage into all three
/// at once.
@MainActor
enum ReminderCoordinator {
    /// Call on activation, when protected data becomes available, and after
    /// any plan, setting or entry change the reminders spec names.
    static func recomputeAndApply(store: RecordStore, now: Date = Date(), calendar: Calendar = .current) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            Task { @MainActor in
                apply(requests: requests(store: store, now: now, calendar: calendar, notificationPermissionGranted: granted))
            }
        }
    }

    /// The pure part: every fact-gathering step, with no `UNUserNotificationCenter` call, so a caller with its own permission read can test this in isolation.
    static func requests(store: RecordStore, now: Date, calendar: Calendar, notificationPermissionGranted: Bool) -> [ReminderRequest] {
        let constants = ProgrammeConstants.default
        var days: [SchedulerDay] = []
        var previousDayKey = RecordDay.key(containing: RecordDay.previous(RecordDay.interval(containing: now, calendar: calendar), calendar: calendar).start, calendar: calendar)
        var dayInterval = RecordDay.interval(containing: now, calendar: calendar)

        for index in 0..<constants.reminderHorizonDays {
            let dayKey = RecordDay.key(containing: dayInterval.start, calendar: calendar)
            days.append(schedulerDay(store: store, dayKey: dayKey, dayInterval: dayInterval, isCurrentDay: index == 0, previousDayKey: previousDayKey, calendar: calendar, constants: constants))
            previousDayKey = dayKey
            dayInterval = RecordDay.next(dayInterval, calendar: calendar)
        }
        let farDay = schedulerDay(store: store, dayKey: RecordDay.key(containing: dayInterval.start, calendar: calendar), dayInterval: dayInterval, isCurrentDay: false, previousDayKey: previousDayKey, calendar: calendar, constants: constants)

        let settings = schedulerSettings(store: store, notificationPermissionGranted: notificationPermissionGranted)
        let extraCandidates = weighInDayCandidates(store: store, dayKeys: days.map(\.dayKey), calendar: calendar)
        return Scheduler.requests(days: days, extraCandidates: extraCandidates, farReminderDay: farDay, settings: settings, calendar: calendar, constants: constants)
    }

    /// reminders spec, "The weigh-in day reminder": `weigh-in`'s own
    /// candidate, fed into the same scheduler as an extra candidate
    /// (design.md: "The same scheduler MUST schedule every reminder that
    /// another capability asks for").
    private static func weighInDayCandidates(store: RecordStore, dayKeys: [String], calendar: Calendar) -> [ReminderCandidate] {
        let weighInWeekday: Int?
        switch try? store.weighInDayChoice() {
        case .weekday(let weekday): weighInWeekday = weekday
        case .wontBeWeighing, nil: weighInWeekday = nil
        }
        let time = (try? store.reminderTime(.weighIn)) ?? RecordStore.ReminderTime.weighIn.defaultTime
        return WeighInReminderRule.candidates(
            weighInWeekday: weighInWeekday, dayKeys: dayKeys, time: time,
            hasWeighIn: { dayKey in (try? store.weighIn(dateKey: dayKey)) != nil },
            calendar: calendar
        )
    }

    private static func schedulerDay(
        store: RecordStore, dayKey: String, dayInterval: DateInterval, isCurrentDay: Bool,
        previousDayKey: String, calendar: Calendar, constants: ProgrammeConstants
    ) -> SchedulerDay {
        let dayStartHour = (try? store.dayStartHour(effectiveOn: dayKey)) ?? RecordDay.startHour
        let plannedMealFacts = resolvedPlannedMeals(store: store, dayKey: dayKey, dayInterval: dayInterval, isCurrentDay: isCurrentDay, dayStartHour: dayStartHour, calendar: calendar, constants: constants)
        let slotLabels = Dictionary(uniqueKeysWithValues: (0..<6).compactMap { index -> (Int, String)? in
            guard let label = try? store.slotLabel(index: index), !label.isEmpty else { return nil }
            return (index, label)
        })

        let entries = isCurrentDay ? ((try? store.entries(dayKey: dayKey)) ?? []) : []
        let states = (try? store.dayStates(dateKey: dayKey)) ?? []
        let hasEntryBeforeMidday = entries.contains { clockMinutes($0.time, calendar: calendar) < 12 * 60 }
        let hasEntryAfter17 = entries.contains { clockMinutes($0.time, calendar: calendar) >= 17 * 60 }
        let hasPlannedMealBeforeMidday = plannedMealFacts.contains { ReminderClock.minutesOfDay($0.time) < 12 * 60 }

        let midday = MiddayFacts(hasEntryBeforeMidday: hasEntryBeforeMidday, hasPlannedMealBeforeMidday: hasPlannedMealBeforeMidday, isFasting: states.contains(.fasting))

        let lastPlannedMeal = plannedMealFacts.max { ReminderClock.minutesOfDay($0.time) < ReminderClock.minutesOfDay($1.time) }
        let closeTheDay = CloseTheDayFacts(
            stage2Open: false,
            hasEntryAfter17: hasEntryAfter17,
            lastPlannedMealTime: lastPlannedMeal?.time,
            lastPlannedMealMatched: lastPlannedMeal?.matchedBeforeReminderTime ?? false,
            hasEntryAtOrAfterLastPlannedMealTime: lastPlannedMeal.map { meal in entries.contains { clockMinutes($0.time, calendar: calendar) >= ReminderClock.minutesOfDay(meal.time) } } ?? false
        )

        let templatesExist = !(((try? store.templateSlotsJSON(.weekday)) ?? "[]") == "[]" && ((try? store.templateSlotsJSON(.weekend)) ?? "[]") == "[]")
        let morningPlan = MorningPlanFacts(
            stage2Open: false,
            templatesExist: templatesExist,
            previousDayIsSetDay: (try? store.isSetDay(dateKey: previousDayKey)) ?? false,
            currentDayAlreadySet: (try? store.isSetDay(dateKey: dayKey)) ?? false,
            isStopped: MorningPlanUnansweredTracker.stopped(count: (try? store.morningPlanUnansweredCount()) ?? 0)
        )

        return SchedulerDay(
            dayKey: dayKey, dayStart: dayInterval.start, plannedMeals: plannedMealFacts, slotLabels: slotLabels,
            morningPlan: morningPlan, midday: midday, closeTheDay: closeTheDay,
            isPaused: states.contains(.paused)
        )
    }

    /// The day's planned meals, from its own `Day` row when materialised, or
    /// from the weekday/weekend template otherwise (reminders spec, "A
    /// reminder for every planned meal": "For a record day the app has not
    /// materialised, the scheduler MUST use the day's template.").
    private static func resolvedPlannedMeals(
        store: RecordStore, dayKey: String, dayInterval: DateInterval, isCurrentDay: Bool,
        dayStartHour: Int, calendar: Calendar, constants: ProgrammeConstants
    ) -> [PlannedMealFact] {
        let plan = try? store.dayPlan(dateKey: dayKey)
        let slotsJSON: String
        let beforeMinutes: Int
        let afterMinutes: Int
        if let plan {
            slotsJSON = plan.slotsJSON
            beforeMinutes = plan.windowBeforeMinutes
            afterMinutes = plan.windowAfterMinutes
        } else {
            let weekday = calendar.component(.weekday, from: dayInterval.start)
            let kind = Materialisation.templateKind(forRecordDayStartingOnWeekday: weekday)
            slotsJSON = (try? store.templateSlotsJSON(kind == "weekend" ? .weekend : .weekday)) ?? "[]"
            beforeMinutes = constants.plannedMealWindowBeforeMinutes
            afterMinutes = constants.plannedMealWindowAfterMinutes
        }
        let meals = PlanCodec.decode(slotsJSON)
        guard isCurrentDay, !meals.isEmpty else {
            return meals.map { PlannedMealFact(slotIndex: $0.slotIndex, time: $0.time, matchedBeforeReminderTime: false) }
        }

        let entries = (try? store.entries(dayKey: dayKey)) ?? []
        let windows = PlanWindows.windows(for: meals, recordDay: dayInterval, dayStartHour: dayStartHour, beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, calendar: calendar)
        let facts = entries.map { PlanEntryFact(id: $0.id, time: $0.time) }
        let matches = PlanMatching.match(windows: windows, entries: facts)
        return meals.map { meal in
            let matchedEntryId = matches[meal.slotIndex]
            let matchedBefore = matchedEntryId.flatMap { id in entries.first { $0.id == id } }
                .map { $0.time < (windows.first { $0.slotIndex == meal.slotIndex }?.time ?? .distantFuture) } ?? false
            return PlannedMealFact(slotIndex: meal.slotIndex, time: meal.time, matchedBeforeReminderTime: matchedBefore)
        }
    }

    private static func clockMinutes(_ date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func schedulerSettings(store: RecordStore, notificationPermissionGranted: Bool) -> SchedulerSettings {
        func on(_ kind: RecordStore.ReminderSwitch) -> Bool { (try? store.reminderSwitchOn(kind)) ?? true }
        let switches: [ReminderKind: Bool] = [
            .plannedMeal: on(.plannedMeals),
            .morningPlan: on(.setTodaysPlan),
            .midday: on(.midday),
            .closeTheDay: on(.closeTheDay),
            .weighInDay: on(.weighInDay),
        ]
        return SchedulerSettings(
            switches: switches,
            remindersPausedAt: try? store.remindersPausedAt(),
            explicitWordingOn: (try? store.explicitWordingOn()) ?? false,
            morningPlanTime: (try? store.reminderTime(.setTodaysPlan)) ?? RecordStore.ReminderTime.setTodaysPlan.defaultTime,
            closeTheDayTime: (try? store.reminderTime(.closeTheDay)) ?? RecordStore.ReminderTime.closeTheDay.defaultTime,
            quietHoursOn: (try? store.quietHoursOn()) ?? true,
            quietHoursStart: (try? store.quietHoursStart()) ?? "22:00",
            quietHoursEnd: (try? store.quietHoursEnd()) ?? "07:00",
            notificationPermissionGranted: notificationPermissionGranted
        )
    }

    /// Replaces every pending request with `requests` (design.md: "the app
    /// materialises every elapsed record day, then replaces all pending
    /// requests with the result").
    private static func apply(requests: [ReminderRequest]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for request in requests {
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: request.time), repeats: false)
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.sound = .default
            content.threadIdentifier = request.threadIdentifier
            content.categoryIdentifier = request.category
            content.userInfo = request.userInfo
            center.add(UNNotificationRequest(identifier: request.id, content: content, trigger: trigger))
        }
    }
}
