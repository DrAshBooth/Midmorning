import Foundation

/// The next-planned-meal line (regular-eating-plan spec, "The next-planned-
/// meal line"): the earliest planned meal later than the moment in question,
/// or the next record day's first planned meal when today has none left.
public enum NextPlannedMeal {
    /// `orderedTodayMeals` is today's planned meals in the record day's own
    /// order; `afterMinutesIntoDay` is the moment in question's own place in
    /// the record day (`PlanOrdering.minutesAfterDayStart`); `firstOfNextDay`
    /// is the next record day's plan or template, first planned meal.
    public static func find(orderedTodayMeals: [PlanMealFact], afterMinutesIntoDay: Int, dayStartHour: Int, firstOfNextDay: PlanMealFact?) -> PlanMealFact? {
        if let match = orderedTodayMeals.first(where: {
            PlanOrdering.minutesAfterDayStart(time: $0.time, dayStartHour: dayStartHour) > afterMinutesIntoDay
        }) {
            return match
        }
        return firstOfNextDay
    }

    /// "%1$@ at %2$@ still happens.", filled with the planned meal's label
    /// and time through the en_GB formatter.
    public static func line(for meal: PlanMealFact) -> String {
        "\(meal.label) at \(meal.time) still happens."
    }
}
