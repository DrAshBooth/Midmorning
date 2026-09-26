import Foundation

/// Orders planned meals by their place in the record day, not by raw clock
/// time: a time before "Day starts at" belongs to the end of the record day
/// (regular-eating-plan spec, "Slots and planned meals": "The app MUST order
/// the planned meals of a day by time"; "A planned meal after midnight").
public enum PlanOrdering {
    /// Minutes from the record day's start to `time`, wrapping a time before
    /// `dayStartHour` to the next calendar day.
    public static func minutesAfterDayStart(time: String, dayStartHour: Int) -> Int {
        let minutesOfDay = PlanTime.minutesOfDay(time)
        let startMinutes = dayStartHour * 60
        return ((minutesOfDay - startMinutes) % 1440 + 1440) % 1440
    }

    /// `meals`, ordered by their place in the record day.
    public static func sorted(_ meals: [PlannedMeal], dayStartHour: Int) -> [PlannedMeal] {
        meals.sorted { minutesAfterDayStart(time: $0.time, dayStartHour: dayStartHour) < minutesAfterDayStart(time: $1.time, dayStartHour: dayStartHour) }
    }
}
