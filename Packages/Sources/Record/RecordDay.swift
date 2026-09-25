import Foundation

/// A record day starts at 04:00 by default and ends at 03:59 the next calendar day.
/// An entry's record day is fixed at save from the entry's own UTC offset, so it
/// never moves when the person travels. The current record day comes from the
/// device zone.
public enum RecordDay {
    public static let startHour = 4

    /// The key ("2026-09-24") of the record day that holds `time` at `utcOffsetSeconds`,
    /// with the day starting at `startHour`. Fixed at save; never recomputed.
    public static func key(for time: Date, utcOffsetSeconds: Int, startHour: Int = startHour) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt
        return key(containing: time, calendar: calendar, startHour: startHour)
    }

    /// The key of the record day that contains `moment` in the calendar's zone.
    public static func key(containing moment: Date, calendar: Calendar, startHour: Int = startHour) -> String {
        let start = interval(containing: moment, calendar: calendar, startHour: startHour).start
        let c = calendar.dateComponents([.year, .month, .day], from: start)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// The half-open interval of the record day that contains `moment`,
    /// computed in the calendar's time zone. On a clock-change date the
    /// interval is 23 or 25 hours long.
    public static func interval(containing moment: Date, calendar: Calendar, startHour: Int = startHour) -> DateInterval {
        let start = start(onCalendarDateOf: moment, calendar: calendar, startHour: startHour)
        if start <= moment {
            return DateInterval(start: start, end: nextStart(after: start, calendar: calendar, startHour: startHour))
        }
        let previousDate = calendar.date(byAdding: .day, value: -1, to: moment)!
        let previousStart = self.start(onCalendarDateOf: previousDate, calendar: calendar, startHour: startHour)
        return DateInterval(start: previousStart, end: start)
    }

    /// The record day before `interval`.
    public static func previous(_ interval: DateInterval, calendar: Calendar) -> DateInterval {
        self.interval(containing: interval.start.addingTimeInterval(-60), calendar: calendar)
    }

    /// The record day after `interval` (record spec, "Earlier record days":
    /// "The day MUST show controls to move to the previous and the next
    /// record day").
    public static func next(_ interval: DateInterval, calendar: Calendar) -> DateInterval {
        self.interval(containing: interval.end.addingTimeInterval(60), calendar: calendar)
    }

    /// True between 00:00 and 03:59 in the calendar's time zone.
    public static func isNight(_ moment: Date, calendar: Calendar) -> Bool {
        calendar.component(.hour, from: moment) < startHour
    }

    private static func start(onCalendarDateOf date: Date, calendar: Calendar, startHour: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }

    private static func nextStart(after start: Date, calendar: Calendar, startHour: Int) -> Date {
        let nextDate = calendar.date(byAdding: .day, value: 1, to: start)!
        return self.start(onCalendarDateOf: nextDate, calendar: calendar, startHour: startHour)
    }
}
