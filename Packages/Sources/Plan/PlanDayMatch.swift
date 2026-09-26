import Foundation

/// A record day's planned meals in time order, their windows and the entry
/// each one matches, computed in one step (regular-eating-plan spec, "The
/// window of a planned meal"). Today, the plan builder and the reminder
/// scheduler read a day's match through this one type, so the three
/// readers cannot disagree (mm-t23.23).
public struct PlanDayMatch: Sendable, Equatable {
    /// The planned meals in the record day's own time order.
    public let orderedMeals: [PlannedMeal]
    /// The windows, in the same order as `orderedMeals`.
    public let windows: [PlannedMealWindow]
    /// The matched entry id per slot index.
    public let matches: [Int: UUID]

    /// `beforeMinutes` and `afterMinutes` are the window constants on the
    /// day's own `Day` row, or the current constants for a day that has no
    /// `Day` row yet.
    public init(
        meals: [PlannedMeal],
        recordDay: DateInterval,
        dayStartHour: Int,
        beforeMinutes: Int,
        afterMinutes: Int,
        entries: [PlanEntryFact],
        calendar: Calendar
    ) {
        orderedMeals = PlanOrdering.sorted(meals, dayStartHour: dayStartHour)
        windows = PlanWindows.windows(
            for: meals, recordDay: recordDay, dayStartHour: dayStartHour,
            beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, calendar: calendar
        )
        matches = PlanMatching.match(windows: windows, entries: entries)
    }

    /// The window of the planned meal at `slotIndex`, if the day has one.
    public func window(for slotIndex: Int) -> PlannedMealWindow? {
        windows.first { $0.slotIndex == slotIndex }
    }

    /// Every entry that matches a planned meal.
    public var matchedEntryIds: Set<UUID> { Set(matches.values) }

    /// The slot index of the planned meal that `entryId` matches, if any.
    public func slotIndex(matching entryId: UUID) -> Int? {
        matches.first { $0.value == entryId }?.key
    }
}
