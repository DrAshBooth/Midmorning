import Foundation

/// One planned meal's computed window, adjusted for overlap with its
/// neighbours and clipped to the record day (regular-eating-plan spec, "The
/// window of a planned meal"; design.md, "A planned meal matches entries by
/// a window").
public struct PlannedMealWindow: Sendable, Equatable {
    public let slotIndex: Int
    public let time: Date
    /// Half-open: includes `interval.start`, excludes `interval.end`.
    public let interval: DateInterval

    public init(slotIndex: Int, time: Date, interval: DateInterval) {
        self.slotIndex = slotIndex
        self.time = time
        self.interval = interval
    }

    /// True for a moment inside `interval`, honouring the half-open bound
    /// (regular-eating-plan spec: "The window includes its start and
    /// excludes its end"). `DateInterval.contains` is unsuitable: it treats
    /// both ends as inclusive.
    public func contains(_ moment: Date) -> Bool {
        moment >= interval.start && moment < interval.end
    }
}

public enum PlanWindows {
    /// The day's planned-meal windows, in time order (regular-eating-plan
    /// spec, "The window of a planned meal"). `recordDay` is the half-open
    /// record-day interval; `beforeMinutes`/`afterMinutes` are the Day row's
    /// own window constants, fixed at materialisation.
    ///
    /// The app sorts by time, ends the earlier window of any overlapping
    /// adjacent pair at the midpoint between their times, starts the later
    /// window there, and only then clips every window to the record day.
    public static func windows(
        for meals: [PlannedMeal],
        recordDay: DateInterval,
        dayStartHour: Int,
        beforeMinutes: Int,
        afterMinutes: Int,
        calendar: Calendar
    ) -> [PlannedMealWindow] {
        let ordered = PlanOrdering.sorted(meals, dayStartHour: dayStartHour)
        guard !ordered.isEmpty else { return [] }
        let times = ordered.map { absoluteTime($0, recordDay: recordDay, dayStartHour: dayStartHour, calendar: calendar) }
        var starts = times.map { $0.addingTimeInterval(-Double(beforeMinutes) * 60) }
        var ends = times.map { $0.addingTimeInterval(Double(afterMinutes) * 60) }
        for i in 0..<(times.count - 1) where ends[i] > starts[i + 1] {
            let midpoint = times[i].addingTimeInterval(times[i + 1].timeIntervalSince(times[i]) / 2)
            ends[i] = midpoint
            starts[i + 1] = midpoint
        }
        return (0..<ordered.count).map { i in
            let clippedStart = max(starts[i], recordDay.start)
            let clippedEnd = min(max(ends[i], clippedStart), recordDay.end)
            return PlannedMealWindow(slotIndex: ordered[i].slotIndex, time: times[i], interval: DateInterval(start: clippedStart, end: clippedEnd))
        }
    }

    /// The planned meal's absolute moment inside `recordDay`: on
    /// `recordDay.start`'s calendar date when its time is at or after
    /// `dayStartHour`, otherwise on the next calendar date (regular-eating-
    /// plan spec, "A planned meal after midnight").
    public static func absoluteTime(_ meal: PlannedMeal, recordDay: DateInterval, dayStartHour: Int, calendar: Calendar) -> Date {
        let (hour, minute) = meal.hourAndMinute
        let sameCalendarDate = hour * 60 + minute >= dayStartHour * 60
        let baseDate = sameCalendarDate ? recordDay.start : calendar.date(byAdding: .day, value: 1, to: recordDay.start)!
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }
}
