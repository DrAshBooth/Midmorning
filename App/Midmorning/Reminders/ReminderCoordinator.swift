import Foundation
import UIKit
import UserNotifications
import Constants
import Record
import Plan
import Programme

extension Foundation.Notification.Name {
    /// Posted after the app applied one or more queued actions to the
    /// store, so Today reloads and shows a queued "Skipped" the first time
    /// it appears (widgets-and-intents spec, "The action queue").
    static let reminderActionQueueApplied = Foundation.Notification.Name("uk.midmorning.reminderActionQueueApplied")
}

/// Gathers the real facts `Scheduler.requests` needs from `RecordStore` and
/// `Plan`, then replaces every pending local notification request with the
/// result (design.md, "The scheduler is a pure function over a rolling
/// horizon": "the app materialises every elapsed record day, then replaces
/// all pending requests with the result").
///
/// The first call starts the triggers. After that, the schedule computes
/// again after each store write (`RecordStore.didSaveNotification`: an
/// entry, "Pause for today", a plan, a template, a setting, a reminder
/// pause), when protected data becomes available, when the notification
/// handler writes to the action queue, and on a time-zone or significant
/// time change (reminders spec, "Scheduling is local, lazy and bounded"). Each run first applies the action queue, then
/// reads Notification Centre for the two stop counts, then schedules, then
/// takes finished reminders off Notification Centre.
///
/// Only the current record day can hold an entry, so only it needs a real
/// entry-vs-window match; every later day in the horizon has no entry yet,
/// so its planned meals are correctly unmatched and its midday/close-the-day
/// facts correctly read as "nothing yet" (reminders spec: a future day's
/// close-the-day reminder schedules ahead of time and cancels reactively
/// when an entry arrives). `stage2Open` is the live stage from
/// `ProgrammeModel`, read once per call and shared by every day in the
/// horizon.
@MainActor
enum ReminderCoordinator {
    private static weak var observedStore: RecordStore?
    private static var observers: [NSObjectProtocol] = []
    private static var recomputePending = false
    /// Above zero while the coordinator writes to the store itself, so its
    /// own writes do not start another run.
    private static var ownWriteDepth = 0
    private static var launchCleanupDone = false
    private static var registeredSnoozeMinutes: Int?

    /// Call on activation. Any other caller may call it too; the store's
    /// change signal already covers every write.
    static func recomputeAndApply(store: RecordStore, now: Date = Date(), calendar: Calendar = .current) {
        observe(store)
        // Both store files carry complete protection: with the device
        // locked, the next `protectedDataDidBecomeAvailable` runs this again.
        guard UIApplication.shared.isProtectedDataAvailable else { return }
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        let currentKey = RecordDay.key(containing: now, calendar: calendar, schedule: schedule)
        let applied: [QueuedAction]
        do {
            applied = try ownWrites { try ActionQueueFile.drain(into: store, currentRecordDayKey: currentKey) }
        } catch {
            // The store could not write: keep the queue and every pending
            // request (a snooze among them) until the next run.
            return
        }
        if !applied.isEmpty {
            NotificationCenter.default.post(name: .reminderActionQueueApplied, object: nil)
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let granted = NotificationPermissionAccess.permission(for: settings.authorizationStatus) == .granted
            DeliveredReminderCleanup.readDelivered { delivered in
                Task { @MainActor in
                    finish(store: store, granted: granted, delivered: delivered, now: now, calendar: calendar)
                }
            }
        }
    }

    private static func finish(store: RecordStore, granted: Bool, delivered: [DeliveredReminder], now: Date, calendar: Calendar) {
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        let currentInterval = RecordDay.interval(containing: now, calendar: calendar, schedule: schedule)
        let currentKey = RecordDay.key(containing: now, calendar: calendar, schedule: schedule)
        ownWrites { updateStopCounts(store: store, delivered: delivered, currentInterval: currentInterval, schedule: schedule, calendar: calendar) }

        let snoozeMinutes = (try? store.remindAgainMinutes()) ?? ProgrammeConstants.default.snoozeMinutes
        if registeredSnoozeMinutes != snoozeMinutes {
            NotificationCategories.register(snoozeMinutes: snoozeMinutes)
            registeredSnoozeMinutes = snoozeMinutes
        }

        apply(requests: ownWrites { requests(store: store, now: now, calendar: calendar, notificationPermissionGranted: granted) })

        // reminders spec, "Delivered reminders are grouped and removed":
        // every delivered reminder off at launch, after the read above; on
        // a later run, each reminder of an earlier record day and each
        // planned meal reminder whose window ended or that an entry or an
        // answer settled.
        if !launchCleanupDone {
            launchCleanupDone = true
            DeliveredReminderCleanup.removeAllAtLaunch()
        } else {
            let current = settledPlannedMeals(store: store, dayKey: currentKey, dayInterval: currentInterval, calendar: calendar)
            let enriched = delivered.map { reminder -> DeliveredReminder in
                guard reminder.kind == .plannedMeal, reminder.dayKey == currentKey,
                      let slotIndex = slotIndex(ofDeliveredId: reminder.id), let meal = current[slotIndex] else { return reminder }
                var result = reminder
                result.windowEndTime = meal.windowEnd
                result.recordedOrAnswered = meal.recordedOrAnswered
                return result
            }
            let ids = DeliveredReminderRemoval.idsToRemove(
                delivered: enriched, currentRecordDayKey: currentKey,
                nowClockTime: ClockTime.string(from: now, calendar: calendar),
                dayStartMinute: ClockTime.minutesOfDay(of: currentInterval.start, calendar: calendar)
            )
            DeliveredReminderCleanup.remove(ids: ids)
        }
    }

    // MARK: Triggers

    private static func observe(_ store: RecordStore) {
        guard observedStore !== store else { return }
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observedStore = store
        let center = NotificationCenter.default
        observers = [
            // Posted on the main actor, by the store, after each save.
            center.addObserver(forName: RecordStore.didSaveNotification, object: store, queue: nil) { _ in
                MainActor.assumeIsolated {
                    guard ownWriteDepth == 0 else { return }
                    scheduleRecompute()
                }
            },
            center.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { scheduleRecompute() }
            },
            center.addObserver(forName: .reminderActionQueued, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { scheduleRecompute() }
            },
            // reminders spec, "Scheduling is local, lazy and bounded": "It
            // MUST compute it again on a time-zone change and on a
            // significant time change."
            center.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { scheduleRecompute() }
            },
            center.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { scheduleRecompute() }
            },
        ]
    }

    /// One run for a burst of writes: a save that writes several rows, or
    /// a screen that saves twice, gives one run a moment later.
    private static func scheduleRecompute() {
        guard !recomputePending else { return }
        recomputePending = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            recomputePending = false
            guard let store = observedStore else { return }
            recomputeAndApply(store: store)
        }
    }

    private static func ownWrites<T>(_ body: () throws -> T) rethrows -> T {
        ownWriteDepth += 1
        defer { ownWriteDepth -= 1 }
        return try body()
    }

    // MARK: The requests

    /// The pure part: every fact-gathering step, with no `UNUserNotificationCenter` call, so a caller with its own permission read can test this in isolation.
    static func requests(store: RecordStore, now: Date, calendar: Calendar, notificationPermissionGranted: Bool) -> [ReminderRequest] {
        let constants = ProgrammeConstants.default
        let stage2Open = ProgrammeModel.load(store: store, now: now, calendar: calendar).state.isOpen(.regularEating)
        let silentDaysStop = SilentDayTracker.stopped(streak: (try? store.silentDayStreak()) ?? 0)
        var days: [SchedulerDay] = []
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        var previousDayKey = RecordDay.key(containing: RecordDay.previous(RecordDay.interval(containing: now, calendar: calendar, schedule: schedule), calendar: calendar, schedule: schedule).start, calendar: calendar, schedule: schedule)
        var dayInterval = RecordDay.interval(containing: now, calendar: calendar, schedule: schedule)

        for index in 0..<constants.reminderHorizonDays {
            let dayKey = RecordDay.key(containing: dayInterval.start, calendar: calendar, schedule: schedule)
            days.append(schedulerDay(store: store, dayKey: dayKey, dayInterval: dayInterval, isCurrentDay: index == 0, previousDayKey: previousDayKey, stage2Open: stage2Open, silentDaysStop: silentDaysStop, calendar: calendar, constants: constants))
            previousDayKey = dayKey
            dayInterval = RecordDay.next(dayInterval, calendar: calendar, schedule: schedule)
        }
        let farDay = schedulerDay(store: store, dayKey: RecordDay.key(containing: dayInterval.start, calendar: calendar, schedule: schedule), dayInterval: dayInterval, isCurrentDay: false, previousDayKey: previousDayKey, stage2Open: stage2Open, silentDaysStop: silentDaysStop, calendar: calendar, constants: constants)

        let settings = schedulerSettings(store: store, notificationPermissionGranted: notificationPermissionGranted)
        let dayKeys = days.map(\.dayKey)
        let extraCandidates = weighInDayCandidates(store: store, dayKeys: dayKeys, calendar: calendar)
            + weeklyReviewCandidates(store: store, dayKeys: dayKeys, calendar: calendar, now: now)
        return Scheduler.requests(days: days, extraCandidates: extraCandidates, farReminderDay: farDay, settings: settings, now: now, calendar: calendar, constants: constants)
    }

    /// reminders spec, "The weekly review reminder": `weekly-review`'s own
    /// candidates, fed into the same scheduler as extra candidates. One
    /// candidate for each due day inside the horizon, not only a review
    /// already due, so the reminder fires on the due day also when the app
    /// does not run on that day. A finished review asks for none.
    private static func weeklyReviewCandidates(store: RecordStore, dayKeys: [String], calendar: Calendar, now: Date) -> [ReminderCandidate] {
        let startDay = WeeklyReviewModel.load(store: store, now: now, calendar: calendar).startDay
        let time = (try? store.reminderTime(.weeklyReview)) ?? RecordStore.ReminderTime.weeklyReview.defaultTime
        return WeeklyReviewReminderRule.candidates(startDay: startDay, dayKeys: dayKeys, time: time, calendar: calendar) { week in
            WeeklyReviewModel.isFinished(store: store, week: week, startDay: startDay, calendar: calendar, now: now)
        }
    }

    /// reminders spec, "The weigh-in day reminder": `weigh-in`'s own
    /// candidate, fed into the same scheduler as an extra candidate
    /// (design.md: "The same scheduler MUST schedule every reminder that
    /// another capability asks for").
    private static func weighInDayCandidates(store: RecordStore, dayKeys: [String], calendar: Calendar) -> [ReminderCandidate] {
        let weighInWeekday = (try? store.weighInDayChoice())?.weekday
        let time = (try? store.reminderTime(.weighIn)) ?? RecordStore.ReminderTime.weighIn.defaultTime
        return WeighInReminderRule.candidates(
            weighInWeekday: weighInWeekday, dayKeys: dayKeys, time: time,
            hasWeighIn: { dayKey in (try? store.weighIn(dateKey: dayKey)) != nil },
            calendar: calendar
        )
    }

    private static func schedulerDay(
        store: RecordStore, dayKey: String, dayInterval: DateInterval, isCurrentDay: Bool,
        previousDayKey: String, stage2Open: Bool, silentDaysStop: Bool, calendar: Calendar, constants: ProgrammeConstants
    ) -> SchedulerDay {
        let dayStartHour = (try? store.dayStartHour(effectiveOn: dayKey)) ?? RecordDay.startHour
        let plannedMealFacts = resolvedPlannedMeals(store: store, dayKey: dayKey, dayInterval: dayInterval, isCurrentDay: isCurrentDay, dayStartHour: dayStartHour, calendar: calendar, constants: constants)
        // reminders spec, "Discreet text by default": "The slot's label is
        // the person's label for that slot, or the default."
        let slotLabels = Dictionary(uniqueKeysWithValues: Slot.all.map { slot in
            (slot.index, SlotLabelText.effective(index: slot.index, stored: try? store.slotLabel(index: slot.index)))
        })

        let entries = isCurrentDay ? ((try? store.entries(dayKey: dayKey)) ?? []) : []
        let states = (try? store.dayStates(dateKey: dayKey)) ?? []
        let hasEntryBeforeMidday = entries.contains { ClockTime.minutesOfDay(of: $0.time, calendar: calendar) < 12 * 60 }
        let hasEntryAfter17 = entries.contains { ClockTime.minutesOfDay(of: $0.time, calendar: calendar) >= 17 * 60 }
        let hasPlannedMealBeforeMidday = plannedMealFacts.contains { ClockTime.minutesOfDay($0.time) < 12 * 60 }

        let midday = MiddayFacts(hasEntryBeforeMidday: hasEntryBeforeMidday, hasPlannedMealBeforeMidday: hasPlannedMealBeforeMidday, isFasting: states.contains(.fasting))

        let lastPlannedMeal = plannedMealFacts.max { ClockTime.minutesOfDay($0.time) < ClockTime.minutesOfDay($1.time) }
        let closeTheDay = CloseTheDayFacts(
            stage2Open: stage2Open,
            hasEntryAfter17: hasEntryAfter17,
            lastPlannedMealTime: lastPlannedMeal?.time,
            lastPlannedMealMatched: lastPlannedMeal?.matchedBeforeReminderTime ?? false,
            hasEntryAtOrAfterLastPlannedMealTime: lastPlannedMeal.map { meal in entries.contains { ClockTime.minutesOfDay(of: $0.time, calendar: calendar) >= ClockTime.minutesOfDay(meal.time) } } ?? false
        )

        let templatesExist = !(((try? store.templateSlotsJSON(.weekday)) ?? "[]") == "[]" && ((try? store.templateSlotsJSON(.weekend)) ?? "[]") == "[]")
        let morningPlan = MorningPlanFacts(
            stage2Open: stage2Open,
            templatesExist: templatesExist,
            previousDayIsSetDay: (try? store.isSetDay(dateKey: previousDayKey)) ?? false,
            currentDayAlreadySet: (try? store.isSetDay(dateKey: dayKey)) ?? false,
            isStopped: MorningPlanUnansweredTracker.stopped(count: (try? store.morningPlanUnansweredCount()) ?? 0)
        )

        return SchedulerDay(
            dayKey: dayKey, dayStart: dayInterval.start, plannedMeals: plannedMealFacts, slotLabels: slotLabels,
            morningPlan: morningPlan, midday: midday, closeTheDay: closeTheDay,
            isPaused: states.contains(.paused),
            silentDaysStop: silentDaysStop,
            snoozes: isCurrentDay ? snoozes(store: store, dayKey: dayKey) : []
        )
    }

    /// Each live snooze of `dayKey` from `Local.store` (reminders spec,
    /// "Snooze a reminder": "The app MUST apply it to `Local.store`, keyed by
    /// the record day key and the slot index.").
    private static func snoozes(store: RecordStore, dayKey: String) -> [SnoozeFact] {
        (0..<6).compactMap { slotIndex in
            guard let count = try? store.snoozeCount(dateKey: dayKey, slotIndex: slotIndex), count > 0,
                  let tap = try? store.snoozeTapMoment(dateKey: dayKey, slotIndex: slotIndex) else { return nil }
            return SnoozeFact(slotIndex: slotIndex, count: count, lastTapAt: tap)
        }
    }

    /// The day's planned meals, from its own `Day` row when materialised, or
    /// from the weekday/weekend template otherwise (reminders spec, "A
    /// reminder for every planned meal": "For a record day the app has not
    /// materialised, the scheduler MUST use the day's template.").
    private static func resolvedPlannedMeals(
        store: RecordStore, dayKey: String, dayInterval: DateInterval, isCurrentDay: Bool,
        dayStartHour: Int, calendar: Calendar, constants: ProgrammeConstants
    ) -> [PlannedMealFact] {
        // The one resolve that Today and the plan builder also use (mm-t23.23).
        guard let plan = try? store.resolvedPlan(dateKey: dayKey, constants: constants) else { return [] }
        let meals = plan.meals
        guard isCurrentDay, !meals.isEmpty else {
            return meals.map { PlannedMealFact(slotIndex: $0.slotIndex, time: $0.time, matchedBeforeReminderTime: false) }
        }

        let entries = (try? store.entries(dayKey: dayKey)) ?? []
        let answers = (try? store.plannedMealAnswers(dateKey: dayKey)) ?? [:]
        let dayMatch = PlanDayMatch(
            meals: meals, recordDay: dayInterval, dayStartHour: dayStartHour,
            beforeMinutes: plan.windowBeforeMinutes, afterMinutes: plan.windowAfterMinutes,
            entries: entries.map { PlanEntryFact(id: $0.id, time: $0.time) }, calendar: calendar
        )
        let windows = dayMatch.windows
        let matches = dayMatch.matches
        return meals.map { meal in
            let matchedEntryId = matches[meal.slotIndex]
            let matchedBefore = matchedEntryId.flatMap { id in entries.first { $0.id == id } }
                .map { $0.time < (windows.first { $0.slotIndex == meal.slotIndex }?.time ?? .distantFuture) } ?? false
            return PlannedMealFact(
                slotIndex: meal.slotIndex, time: meal.time, matchedBeforeReminderTime: matchedBefore,
                recordedOrAnswered: matchedEntryId != nil || answers[meal.slotIndex] != nil
            )
        }
    }

    /// The windows of the record day's resolved plan (mm-t23.23).
    private static func planWindows(
        store: RecordStore, dayKey: String, dayInterval: DateInterval, dayStartHour: Int, calendar: Calendar, constants: ProgrammeConstants
    ) -> [PlannedMealWindow] {
        guard let plan = try? store.resolvedPlan(dateKey: dayKey, constants: constants) else { return [] }
        return PlanWindows.windows(
            for: plan.meals, recordDay: dayInterval, dayStartHour: dayStartHour,
            beforeMinutes: plan.windowBeforeMinutes, afterMinutes: plan.windowAfterMinutes, calendar: calendar
        )
    }

    /// The current record day's planned meals by slot: each window's end as
    /// a clock time, and whether an entry or an answer settled the meal.
    private static func settledPlannedMeals(store: RecordStore, dayKey: String, dayInterval: DateInterval, calendar: Calendar) -> [Int: (windowEnd: String, recordedOrAnswered: Bool)] {
        let constants = ProgrammeConstants.default
        let dayStartHour = (try? store.dayStartHour(effectiveOn: dayKey)) ?? RecordDay.startHour
        let windows = planWindows(store: store, dayKey: dayKey, dayInterval: dayInterval, dayStartHour: dayStartHour, calendar: calendar, constants: constants)
        let settled = resolvedPlannedMeals(store: store, dayKey: dayKey, dayInterval: dayInterval, isCurrentDay: true, dayStartHour: dayStartHour, calendar: calendar, constants: constants)
        var result: [Int: (windowEnd: String, recordedOrAnswered: Bool)] = [:]
        for window in windows {
            let recorded = settled.first { $0.slotIndex == window.slotIndex }?.recordedOrAnswered ?? false
            result[window.slotIndex] = (ClockTime.string(from: window.interval.end, calendar: calendar), recorded)
        }
        return result
    }

    /// The slot index in a planned meal reminder's identifier:
    /// "plannedMeal.<dayKey>.<slot>" or "snooze.<dayKey>.<slot>.<count>".
    private static func slotIndex(ofDeliveredId id: String) -> Int? {
        let parts = id.split(separator: ".")
        switch parts.first {
        case "plannedMeal": return parts.count == 3 ? Int(parts[2]) : nil
        case "snooze": return parts.count == 4 ? Int(parts[2]) : nil
        default: return nil
        }
    }

    // MARK: The two stop counts (reminders spec, "The morning plan reminder
    // while the plan needs setting", "The midday and close-the-day reminders
    // stop after seven silent days")

    /// Notes which reminders Notification Centre holds for each record day,
    /// folds each elapsed record day into the two counts once, and applies
    /// the current record day's own restart. Writes only a value that
    /// changed.
    private static func updateStopCounts(store: RecordStore, delivered: [DeliveredReminder], currentInterval: DateInterval, schedule: DayStartSchedule, calendar: Calendar) {
        let currentKey = RecordDay.key(containing: currentInterval.start, calendar: calendar, schedule: schedule)
        let nextKey = RecordDay.key(containing: RecordDay.next(currentInterval, calendar: calendar, schedule: schedule).start, calendar: calendar, schedule: schedule)
        let counted: Set<ReminderKind> = [.morningPlan, .midday, .closeTheDay]

        let storedPending = (try? store.pendingDeliveredReminderKinds()) ?? [:]
        var pending = storedPending
        for reminder in delivered where counted.contains(reminder.kind) && reminder.dayKey <= currentKey {
            pending[reminder.dayKey, default: []].insert(reminder.kind.rawValue)
        }

        let storedFoldedThrough = try? store.reminderStopsFoldedThrough()
        var elapsedKeys: [String] = []
        if storedFoldedThrough != nil || pending.keys.contains(where: { $0 < currentKey }) {
            var interval = RecordDay.previous(currentInterval, calendar: calendar, schedule: schedule)
            for _ in 0..<60 {
                let key = RecordDay.key(containing: interval.start, calendar: calendar, schedule: schedule)
                if let storedFoldedThrough, key <= storedFoldedThrough { break }
                elapsedKeys.append(key)
                interval = RecordDay.previous(interval, calendar: calendar, schedule: schedule)
            }
        }
        let elapsedDays = elapsedKeys.map { key in
            let kinds = pending[key] ?? []
            return ElapsedReminderDay(
                dayKey: key,
                morningPlanDelivered: kinds.contains(ReminderKind.morningPlan.rawValue),
                middayOrCloseTheDayDelivered: kinds.contains(ReminderKind.midday.rawValue) || kinds.contains(ReminderKind.closeTheDay.rawValue),
                hadEntry: ((try? store.entryCount(dayKey: key)) ?? 0) > 0,
                wasPaused: ((try? store.dayStates(dateKey: key)) ?? []).contains(.paused),
                setItsOwnPlan: (try? store.isSetDay(dateKey: key)) ?? false
            )
        }

        let storedCounts = ReminderStopCounts(
            morningPlanUnanswered: (try? store.morningPlanUnansweredCount()) ?? 0,
            silentDays: (try? store.silentDayStreak()) ?? 0
        )
        let folded = ReminderStopFold.fold(storedCounts, foldedThrough: storedFoldedThrough, elapsedDays: elapsedDays)

        let templates = ((try? store.templateSlotsJSON(.weekday)) ?? "[]") + "|" + ((try? store.templateSlotsJSON(.weekend)) ?? "[]")
        let seenTemplates = try? store.templatesSeenByReminders()
        let counts = ReminderStopFold.restart(
            folded.counts,
            currentDayHasEntry: ((try? store.entryCount(dayKey: currentKey)) ?? 0) > 0,
            currentOrNextDayIsSet: ((try? store.isSetDay(dateKey: currentKey)) ?? false) || ((try? store.isSetDay(dateKey: nextKey)) ?? false),
            templatesChanged: seenTemplates.map { $0 != templates } ?? false
        )

        if counts.morningPlanUnanswered != storedCounts.morningPlanUnanswered { try? store.setMorningPlanUnansweredCount(counts.morningPlanUnanswered) }
        if counts.silentDays != storedCounts.silentDays { try? store.setSilentDayStreak(counts.silentDays) }
        let foldedThrough = folded.foldedThrough ?? RecordDay.key(containing: RecordDay.previous(currentInterval, calendar: calendar, schedule: schedule).start, calendar: calendar, schedule: schedule)
        if foldedThrough != storedFoldedThrough { try? store.setReminderStopsFoldedThrough(foldedThrough) }
        pending = pending.filter { $0.key > foldedThrough }
        if pending != storedPending { try? store.setPendingDeliveredReminderKinds(pending) }
        if seenTemplates != templates { try? store.setTemplatesSeenByReminders(templates) }
    }

    // MARK: Store reads

    private static func schedulerSettings(store: RecordStore, notificationPermissionGranted: Bool) -> SchedulerSettings {
        func on(_ kind: RecordStore.ReminderSwitch) -> Bool { (try? store.reminderSwitchOn(kind)) ?? RecordStore.Defaults.reminderSwitchOn }
        let quietHours = (try? store.quietHours()) ?? RecordStore.Defaults.quietHours
        let switches: [ReminderKind: Bool] = [
            .plannedMeal: on(.plannedMeals),
            .morningPlan: on(.setTodaysPlan),
            .midday: on(.midday),
            .closeTheDay: on(.closeTheDay),
            .weighInDay: on(.weighInDay),
            .weeklyReview: on(.weeklyReview),
        ]
        return SchedulerSettings(
            switches: switches,
            remindersPausedAt: try? store.remindersPausedAt(),
            explicitWordingOn: (try? store.explicitWordingOn()) ?? RecordStore.Defaults.explicitWordingOn,
            morningPlanTime: (try? store.reminderTime(.setTodaysPlan)) ?? RecordStore.ReminderTime.setTodaysPlan.defaultTime,
            closeTheDayTime: (try? store.reminderTime(.closeTheDay)) ?? RecordStore.ReminderTime.closeTheDay.defaultTime,
            quietHoursOn: quietHours.isOn,
            quietHoursStart: quietHours.start,
            quietHoursEnd: quietHours.end,
            notificationPermissionGranted: notificationPermissionGranted,
            snoozeMinutes: (try? store.remindAgainMinutes()) ?? RecordStore.Defaults.remindAgainMinutes
        )
    }

    /// Replaces every pending request with `requests` (design.md: "the app
    /// materialises every elapsed record day, then replaces all pending
    /// requests with the result"). A live snooze is among `requests`, so
    /// the replacement keeps it.
    private static func apply(requests: [ReminderRequest]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for request in requests {
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: request.time), repeats: false)
            let content = UNMutableNotificationContent()
            content.title = request.title.string
            content.body = request.body
            content.sound = .default
            content.threadIdentifier = request.threadIdentifier
            content.categoryIdentifier = request.category
            content.userInfo = request.userInfo
            center.add(UNNotificationRequest(identifier: request.id, content: content, trigger: trigger))
        }
    }
}
