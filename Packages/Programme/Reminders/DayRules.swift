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
