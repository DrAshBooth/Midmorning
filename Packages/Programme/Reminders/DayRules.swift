import Foundation
import Constants

// MARK: - The morning plan reminder (reminders spec, "The morning plan
// reminder while the plan needs setting")

/// Whether the morning plan reminder should schedule for one record day.
/// `isStopped` is `MorningPlanUnansweredTracker.stopped(count:)` for the
/// count as it stood before this day.
public struct MorningPlanFacts: Sendable, Equatable {
    public var stage2Open: Bool
    /// The person has saved the weekday or the weekend template.
    public var templatesExist: Bool
    /// The previous record day is a set day (`Plan`'s own definition):
    /// `RecordStore.isSetDay(dateKey:)` on the day before this one.
    public var previousDayIsSetDay: Bool
    /// The person set this day's own plan before the reminder time.
    public var currentDayAlreadySet: Bool
    public var isStopped: Bool

    public init(stage2Open: Bool, templatesExist: Bool, previousDayIsSetDay: Bool, currentDayAlreadySet: Bool, isStopped: Bool) {
        self.stage2Open = stage2Open
        self.templatesExist = templatesExist
        self.previousDayIsSetDay = previousDayIsSetDay
        self.currentDayAlreadySet = currentDayAlreadySet
        self.isStopped = isStopped
    }
}

public enum MorningPlanRule {
    public static func shouldSchedule(_ facts: MorningPlanFacts) -> Bool {
        guard facts.stage2Open, !facts.currentDayAlreadySet, !facts.isStopped else { return false }
        return !facts.templatesExist || facts.previousDayIsSetDay
    }
}

/// One elapsed record day's morning-plan-reminder outcome, folded by
/// `MorningPlanUnansweredTracker` (reminders spec: "the app MUST count at
/// most one unanswered day per elapsed record day with a delivered
/// reminder").
public struct MorningPlanDayOutcome: Sendable, Equatable {
    public var wasDelivered: Bool
    public var wasTapped: Bool
    public var daySetItsOwnPlan: Bool

    public init(wasDelivered: Bool, wasTapped: Bool, daySetItsOwnPlan: Bool) {
        self.wasDelivered = wasDelivered
        self.wasTapped = wasTapped
        self.daySetItsOwnPlan = daySetItsOwnPlan
    }
}

/// The count of consecutive unanswered mornings, and the stop at three
/// (reminders spec: "After three consecutive unanswered morning plan
/// reminders, the scheduler MUST stop the morning plan reminder.").
public enum MorningPlanUnansweredTracker {
    public static func count(startingAt initial: Int = 0, elapsedDays: [MorningPlanDayOutcome]) -> Int {
        var count = initial
        for day in elapsedDays {
            if day.wasTapped || day.daySetItsOwnPlan {
                count = 0
            } else if day.wasDelivered {
                count += 1
            }
            // A day with no delivered reminder neither resets nor
            // increments the count (reminders spec: "A record day with no
            // delivered reminder MUST NOT count").
        }
        return count
    }

    public static func stopped(count: Int) -> Bool { count >= 3 }
}

// MARK: - The midday reminder (reminders spec, "The midday reminder")

public struct MiddayFacts: Sendable, Equatable {
    public var hasEntryBeforeMidday: Bool
    public var hasPlannedMealBeforeMidday: Bool
    public var isFasting: Bool

    public init(hasEntryBeforeMidday: Bool, hasPlannedMealBeforeMidday: Bool, isFasting: Bool) {
        self.hasEntryBeforeMidday = hasEntryBeforeMidday
        self.hasPlannedMealBeforeMidday = hasPlannedMealBeforeMidday
        self.isFasting = isFasting
    }
}

public enum MiddayRule {
    public static let time = "12:00"

    public static func fires(_ facts: MiddayFacts) -> Bool {
        !facts.hasEntryBeforeMidday && !facts.hasPlannedMealBeforeMidday && !facts.isFasting
    }
}

// MARK: - Close the day (reminders spec, "Close the day")

public struct CloseTheDayFacts: Sendable, Equatable {
    public var stage2Open: Bool
    /// Stage 1, or stage 2 with no planned meal that day: whether the day
    /// has an entry after 17:00.
    public var hasEntryAfter17: Bool
    /// `nil` when stage 2 is open but the day has no planned meal.
    public var lastPlannedMealTime: String?
    public var lastPlannedMealMatched: Bool
    public var hasEntryAtOrAfterLastPlannedMealTime: Bool

    public init(
        stage2Open: Bool, hasEntryAfter17: Bool, lastPlannedMealTime: String?,
        lastPlannedMealMatched: Bool, hasEntryAtOrAfterLastPlannedMealTime: Bool
    ) {
        self.stage2Open = stage2Open
        self.hasEntryAfter17 = hasEntryAfter17
        self.lastPlannedMealTime = lastPlannedMealTime
        self.lastPlannedMealMatched = lastPlannedMealMatched
        self.hasEntryAtOrAfterLastPlannedMealTime = hasEntryAtOrAfterLastPlannedMealTime
    }
}

public enum CloseTheDayRule {
    public static func somethingMissing(_ facts: CloseTheDayFacts) -> Bool {
        if facts.stage2Open, facts.lastPlannedMealTime != nil {
            return !facts.lastPlannedMealMatched && !facts.hasEntryAtOrAfterLastPlannedMealTime
        }
        return !facts.hasEntryAfter17
    }

    /// The stage 1 gate time for the "Close the day" control on Today.
    public static let stage1ControlTime = "17:00"

    /// Whether Today shows "Close the day" beside "Pause for today" (record
    /// spec, "The Today stack"; reminders spec, "Close the day": "Today
    /// shows a 'Close the day' control only after the last planned meal's
    /// time, or after 17:00 in stage 1."). From stage 2, on a day with no
    /// planned meal, the stage 1 time applies. Every time is ordered from
    /// the day start, so a planned meal after midnight is the last one.
    public static func controlShows(nowClockTime: String, dayStartMinute: Int, stage2Open: Bool, plannedMealTimes: [String]) -> Bool {
        let since = { (time: String) in ClockTime.minutesSinceDayStart(time, dayStartMinute: dayStartMinute) }
        let gate: String
        if stage2Open, let last = plannedMealTimes.max(by: { since($0) < since($1) }) {
            gate = last
        } else {
            gate = stage1ControlTime
        }
        return since(nowClockTime) >= since(gate)
    }
}

// MARK: - Seven silent days (reminders spec, "The midday and close-the-day
// reminders stop after seven silent days")

public struct SilentDayOutcome: Sendable, Equatable {
    public var hadDeliveredMiddayOrCloseDay: Bool
    public var hadEntry: Bool
    public var wasPaused: Bool

    public init(hadDeliveredMiddayOrCloseDay: Bool, hadEntry: Bool, wasPaused: Bool) {
        self.hadDeliveredMiddayOrCloseDay = hadDeliveredMiddayOrCloseDay
        self.hadEntry = hadEntry
        self.wasPaused = wasPaused
    }
}

public enum SilentDayTracker {
    /// Folds consecutive elapsed record days into the running streak. An
    /// entry resets it to zero. A paused day, or a day with neither reminder
    /// delivered, neither resets nor extends it.
    public static func streak(startingAt initial: Int = 0, elapsedDays: [SilentDayOutcome]) -> Int {
        var streak = initial
        for day in elapsedDays {
            if day.hadEntry {
                streak = 0
            } else if day.wasPaused {
                continue
            } else if day.hadDeliveredMiddayOrCloseDay {
                streak += 1
            }
        }
        return streak
    }

    public static func stopped(streak: Int) -> Bool { streak >= 7 }
}

// MARK: - The two stop counts on return (reminders spec, "The morning plan
// reminder while the plan needs setting", "The midday and close-the-day
// reminders stop after seven silent days", "Delivered reminders are grouped
// and removed")

/// One elapsed record day, as the app reads it on return: which reminders
/// Notification Centre still held for that day, and the day's own facts.
public struct ElapsedReminderDay: Sendable, Equatable {
    public var dayKey: String
    public var morningPlanDelivered: Bool
    public var middayOrCloseTheDayDelivered: Bool
    public var hadEntry: Bool
    public var wasPaused: Bool
    public var setItsOwnPlan: Bool

    public init(dayKey: String, morningPlanDelivered: Bool, middayOrCloseTheDayDelivered: Bool, hadEntry: Bool, wasPaused: Bool, setItsOwnPlan: Bool) {
        self.dayKey = dayKey
        self.morningPlanDelivered = morningPlanDelivered
        self.middayOrCloseTheDayDelivered = middayOrCloseTheDayDelivered
        self.hadEntry = hadEntry
        self.wasPaused = wasPaused
        self.setItsOwnPlan = setItsOwnPlan
    }
}

/// The morning-plan unanswered count and the silent-day streak, as
/// `Local.store` keeps them.
public struct ReminderStopCounts: Sendable, Equatable {
    public var morningPlanUnanswered: Int
    public var silentDays: Int

    public init(morningPlanUnanswered: Int, silentDays: Int) {
        self.morningPlanUnanswered = morningPlanUnanswered
        self.silentDays = silentDays
    }

    public var morningPlanStopped: Bool { MorningPlanUnansweredTracker.stopped(count: morningPlanUnanswered) }
    public var silentDaysStopped: Bool { SilentDayTracker.stopped(streak: silentDays) }
}

public enum ReminderStopFold {
    /// Folds each elapsed record day after `foldedThrough` into the two
    /// counts, once, in day order. A day at or before `foldedThrough` was
    /// folded on an earlier return, so it does not count again (reminders
    /// spec: "the app MUST count at most one unanswered day per elapsed
    /// record day"; "at most one silent day per elapsed record day").
    /// Answers the new counts and the new `foldedThrough`.
    public static func fold(
        _ counts: ReminderStopCounts, foldedThrough: String?, elapsedDays: [ElapsedReminderDay]
    ) -> (counts: ReminderStopCounts, foldedThrough: String?) {
        let fresh = elapsedDays
            .filter { day in foldedThrough.map { day.dayKey > $0 } ?? true }
            .sorted { $0.dayKey < $1.dayKey }
        guard let last = fresh.last else { return (counts, foldedThrough) }
        let morningPlan = MorningPlanUnansweredTracker.count(
            startingAt: counts.morningPlanUnanswered,
            elapsedDays: fresh.map { MorningPlanDayOutcome(wasDelivered: $0.morningPlanDelivered, wasTapped: false, daySetItsOwnPlan: $0.setItsOwnPlan) }
        )
        let silent = SilentDayTracker.streak(
            startingAt: counts.silentDays,
            elapsedDays: fresh.map { SilentDayOutcome(hadDeliveredMiddayOrCloseDay: $0.middayOrCloseTheDayDelivered, hadEntry: $0.hadEntry, wasPaused: $0.wasPaused) }
        )
        return (ReminderStopCounts(morningPlanUnanswered: morningPlan, silentDays: silent), last.dayKey)
    }

    /// The current record day's own restart of both stops. An entry saved
    /// in the current record day ends the silent run (reminders spec: "The
    /// scheduler MUST start both types again when the person saves an
    /// entry."). A set plan for the current or the next record day, or a
    /// changed template, starts the morning plan reminder again with the
    /// count at zero ("when the person saves a plan or a template").
    public static func restart(
        _ counts: ReminderStopCounts, currentDayHasEntry: Bool, currentOrNextDayIsSet: Bool, templatesChanged: Bool
    ) -> ReminderStopCounts {
        var result = counts
        if currentDayHasEntry { result.silentDays = 0 }
        if currentOrNextDayIsSet || templatesChanged { result.morningPlanUnanswered = 0 }
        return result
    }
}
