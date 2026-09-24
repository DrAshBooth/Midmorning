import Foundation

/// A record day starts at 04:00 and ends at 03:59 the next calendar day.
public enum RecordDay {
    public static let startHour = 4

    /// The half-open interval of the record day that contains `moment`,
    /// computed in the calendar's time zone. On a clock-change date the
    /// interval is 23 or 25 hours long.
    public static func interval(containing moment: Date, calendar: Calendar) -> DateInterval {
        let start = start(onCalendarDateOf: moment, calendar: calendar)
        if start <= moment {
            return DateInterval(start: start, end: nextStart(after: start, calendar: calendar))
        }
        let previousDate = calendar.date(byAdding: .day, value: -1, to: moment)!
        let previousStart = self.start(onCalendarDateOf: previousDate, calendar: calendar)
        return DateInterval(start: previousStart, end: start)
    }

    /// The record day before `interval`.
    public static func previous(_ interval: DateInterval, calendar: Calendar) -> DateInterval {
        self.interval(containing: interval.start.addingTimeInterval(-60), calendar: calendar)
    }

    /// True between 00:00 and 03:59 in the calendar's time zone.
    public static func isNight(_ moment: Date, calendar: Calendar) -> Bool {
        calendar.component(.hour, from: moment) < startHour
    }

    private static func start(onCalendarDateOf date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }

    private static func nextStart(after start: Date, calendar: Calendar) -> Date {
        let nextDate = calendar.date(byAdding: .day, value: 1, to: start)!
        return self.start(onCalendarDateOf: nextDate, calendar: calendar)
    }
}
