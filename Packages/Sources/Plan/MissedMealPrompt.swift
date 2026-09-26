import Foundation
import Constants

/// One planned meal's own facts for the missed-planned-meal-prompt rule
/// (regular-eating-plan spec, "A missed planned meal gets one prompt"),
/// already resolved by the caller from the plan, the entries and the
/// answers. `meals` passed to `MissedMealPrompt.active` MUST be in the
/// record day's own time order.
public struct MissedPlannedMeal: Sendable, Equatable {
    public let slotIndex: Int
    public let windowEnd: Date
    public let hasMatchedEntry: Bool
    public let hasSkippedAnswer: Bool
    /// True when a later entry exists: one that matches a later planned
    /// meal, or has a time at or after the next planned meal's time.
    public let hasLaterEntry: Bool
    /// True once any later slot in the day already carries an answer
    /// (regular-eating-plan spec: "Today MUST NOT show a second prompt on an
    /// earlier missed planned meal after the person answers").
    public let laterSlotAnswered: Bool
    public let windowEndsInQuietHours: Bool
    /// An unmatched entry after this meal's own time and before the next
    /// planned meal's time, if any (`MissedMealPrompt.candidateEntry`). The
    /// first cut always passes `nil`, so Today shows only "Skipped" and
    /// "Add it" (mm-t23.22). mm-t33.14 passes the candidate when it builds
    /// "That was it".
    public let candidateEntryTime: Date?

    public init(
        slotIndex: Int,
        windowEnd: Date,
        hasMatchedEntry: Bool,
        hasSkippedAnswer: Bool,
        hasLaterEntry: Bool,
        laterSlotAnswered: Bool,
        windowEndsInQuietHours: Bool,
        candidateEntryTime: Date? = nil
    ) {
        self.slotIndex = slotIndex
        self.windowEnd = windowEnd
        self.hasMatchedEntry = hasMatchedEntry
        self.hasSkippedAnswer = hasSkippedAnswer
        self.hasLaterEntry = hasLaterEntry
        self.laterSlotAnswered = laterSlotAnswered
        self.windowEndsInQuietHours = windowEndsInQuietHours
        self.candidateEntryTime = candidateEntryTime
    }
}

public enum MissedMealPrompt {
    public enum Form: Sendable, Equatable {
        /// "Skipped, or not recorded yet?" with "Skipped" and "Add it".
        case skippedOrNotRecorded
        /// "Skipped, or was that %@?" with "Skipped" and "That was it". The
        /// first cut does not show this form (mm-t23.22); mm-t33.14 builds
        /// it with its "That was it" action.
        case skippedOrWasThat(candidateTime: Date)
    }

    public struct State: Sendable, Equatable {
        public let slotIndex: Int
        public let form: Form
    }

    /// A planned meal is missed when its window has ended with no matched
    /// entry and no "Skipped" answer, and no later fact already rules it out.
    public static func isMissed(_ meal: MissedPlannedMeal, now: Date) -> Bool {
        now >= meal.windowEnd
            && !meal.hasMatchedEntry
            && !meal.hasSkippedAnswer
            && !meal.hasLaterEntry
            && !meal.laterSlotAnswered
    }

    /// The one prompt Today shows, if any: the latest eligible missed
    /// planned meal of the day, never shown once the record day has ended
    /// (regular-eating-plan spec, "A missed planned meal gets one prompt").
    public static func active(meals: [MissedPlannedMeal], now: Date, recordDayHasEnded: Bool) -> State? {
        guard !recordDayHasEnded else { return nil }
        guard let latest = meals.filter({ isMissed($0, now: now) }).last else { return nil }
        guard !latest.windowEndsInQuietHours else { return nil }
        if let candidateTime = latest.candidateEntryTime {
            return State(slotIndex: latest.slotIndex, form: .skippedOrWasThat(candidateTime: candidateTime))
        }
        return State(slotIndex: latest.slotIndex, form: .skippedOrNotRecorded)
    }

    /// The prompt's own text, `timeText` filling "was that %@?" through the
    /// caller's en_GB time formatter.
    public static func line(for form: Form, timeText: (Date) -> String) -> CatalogueText {
        switch form {
        case .skippedOrNotRecorded:
            return .key("plan.missedPrompt.notRecordedYet")
        case .skippedOrWasThat(let candidateTime):
            return .key("plan.missedPrompt.wasThat", .verbatim(timeText(candidateTime)))
        }
    }

    /// The earliest unmatched entry after `mealTime` and before `boundary`
    /// (the next planned meal's own time, or the record day's end when there
    /// is none) — the candidate the "was that %@?" form names. Finding this
    /// candidate is built here; matching it to the planned meal ("That was
    /// it") is deferred to mm-t33.14.
    public static func candidateEntry(after mealTime: Date, before boundary: Date, unmatchedEntries: [PlanEntryFact]) -> PlanEntryFact? {
        unmatchedEntries
            .filter { $0.time > mealTime && $0.time < boundary }
            .min { $0.time < $1.time }
    }
}
