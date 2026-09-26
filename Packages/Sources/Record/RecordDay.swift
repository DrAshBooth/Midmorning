import Foundation

/// The "Day starts at" rows as one value (data-and-privacy spec, "Slot labels
/// and the day start are Settings rows"): each change holds an hour and the
/// record day key it applies from. A day key with no change at or before it
/// uses `RecordDay.startHour`. `RecordStore.dayStartSchedule()` reads it from
/// the store; every record-day computation takes it, so no caller can put
/// the 04:00 constant in place of the setting (record spec, "The record
/// day": "The key comes from the entry's time, its UTC offset and the day
/// start in force").
public struct DayStartSchedule: Sendable, Equatable {
    public struct Change: Sendable, Equatable {
        public let effectiveFromDayKey: String
        public let hour: Int

        public init(effectiveFromDayKey: String, hour: Int) {
            self.effectiveFromDayKey = effectiveFromDayKey
            self.hour = hour
        }
    }

    /// Sorted by `effectiveFromDayKey`, earliest first.
    public let changes: [Change]

    public init(changes: [Change]) {
        self.changes = changes.sorted { $0.effectiveFromDayKey < $1.effectiveFromDayKey }
    }

    /// No "Day starts at" row yet: every record day starts at 04:00.
    public static let standard = DayStartSchedule(changes: [])

    /// One hour for every record day, for a caller or a test that fixes the
    /// day start.
    public static func constant(_ hour: Int) -> DayStartSchedule {
        DayStartSchedule(changes: [Change(effectiveFromDayKey: "", hour: hour)])
    }

    /// The hour in force for the record day `dayKey`: the latest change whose
    /// key is `dayKey` or earlier.
    public func hour(effectiveOn dayKey: String) -> Int {
        changes.last { $0.effectiveFromDayKey <= dayKey }?.hour ?? RecordDay.startHour
    }
}

/// A record day starts at the day start (04:00 by default) and ends at the
/// next record day's start. An entry's record day is fixed at save from the
/// entry's own UTC offset, so it never moves when the person travels. The
/// current record day comes from the device zone.
///
/// Each record day takes its own start hour from the schedule, so the day
/// before a change to an earlier start is shorter than 24 hours, and the day
/// before a change to a later start is longer (record spec, "The record
/// day": a record day "ends one minute before the next day start").
public enum RecordDay {
    /// The default day start, for a day key that no "Day starts at" row
    /// covers. Read it only through `DayStartSchedule`.
    public static let startHour = 4

    /// The hours "Day starts at" offers: 00:00 to 12:00 (settings spec, "The
    /// Record group").
    public static let startHourChoices = 0...12

    // MARK: Under a day-start schedule

    /// The half-open interval of the record day that contains `moment`,
    /// computed in the calendar's time zone. On a clock-change date the
    /// interval is 23 or 25 hours long.
    public static func interval(containing moment: Date, calendar: Calendar, schedule: DayStartSchedule) -> DateInterval {
        let ownStart = start(onCalendarDateOf: moment, calendar: calendar, schedule: schedule)
        if ownStart <= moment {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: ownStart)!
            return DateInterval(start: ownStart, end: start(onCalendarDateOf: nextDate, calendar: calendar, schedule: schedule))
        }
        let previousDate = calendar.date(byAdding: .day, value: -1, to: moment)!
        return DateInterval(start: start(onCalendarDateOf: previousDate, calendar: calendar, schedule: schedule), end: ownStart)
    }

    /// The key ("2026-09-24") of the record day that contains `moment` in
    /// the calendar's zone.
    public static func key(containing moment: Date, calendar: Calendar, schedule: DayStartSchedule) -> String {
        calendarDateKey(of: interval(containing: moment, calendar: calendar, schedule: schedule).start, calendar: calendar)
    }

    /// The key of the record day that holds `time` at `utcOffsetSeconds`.
    /// Fixed at save; never recomputed.
    public static func key(for time: Date, utcOffsetSeconds: Int, schedule: DayStartSchedule) -> String {
        key(containing: time, calendar: offsetCalendar(utcOffsetSeconds), schedule: schedule)
    }

    /// The interval of the record day keyed `key`, in the calendar's zone, or
    /// `nil` for a malformed key.
    public static func interval(forKey key: String, calendar: Calendar, schedule: DayStartSchedule) -> DateInterval? {
        guard let noon = noon(ofKey: key, calendar: calendar) else { return nil }
        let nextNoon = calendar.date(byAdding: .day, value: 1, to: noon)!
        return DateInterval(
            start: start(onCalendarDateOf: noon, calendar: calendar, schedule: schedule),
            end: start(onCalendarDateOf: nextNoon, calendar: calendar, schedule: schedule)
        )
    }

    /// The record day before `interval`.
    public static func previous(_ interval: DateInterval, calendar: Calendar, schedule: DayStartSchedule) -> DateInterval {
        self.interval(containing: interval.start.addingTimeInterval(-60), calendar: calendar, schedule: schedule)
    }

    /// The record day after `interval` (record spec, "Earlier record days":
    /// "The day MUST show controls to move to the previous and the next
    /// record day").
    public static func next(_ interval: DateInterval, calendar: Calendar, schedule: DayStartSchedule) -> DateInterval {
        self.interval(containing: interval.end.addingTimeInterval(60), calendar: calendar, schedule: schedule)
    }

    /// The key of the record day right after the one that contains `moment`.
    /// A new "Day starts at" hour takes effect from this key, never from
    /// `moment`'s own day, so no saved entry's record day moves (settings
    /// spec, "The Record group").
    public static func nextDayKey(after moment: Date, calendar: Calendar, schedule: DayStartSchedule) -> String {
        let current = interval(containing: moment, calendar: calendar, schedule: schedule)
        return key(containing: current.end, calendar: calendar, schedule: schedule)
    }

    /// True when `moment` falls after midnight but before the day start, so
    /// the record day that holds it began on the calendar date before
    /// (record spec, "Today's appearance": ", night"). Between 00:00 and
    /// 03:59 with the default day start.
    public static func isNight(_ moment: Date, inRecordDay recordDay: DateInterval, calendar: Calendar) -> Bool {
        recordDay.start < calendar.startOfDay(for: moment)
    }

    /// Noon on the calendar date `key` names, in the calendar's zone, or
    /// `nil` for a malformed key. A caller that formats the result in the
    /// same calendar gets the key's own weekday and date in any zone.
    public static func noon(ofKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    // MARK: With one fixed start hour

    /// The key of the record day that holds `time` at `utcOffsetSeconds`,
    /// with every day starting at `startHour`.
    public static func key(for time: Date, utcOffsetSeconds: Int, startHour: Int) -> String {
        key(for: time, utcOffsetSeconds: utcOffsetSeconds, schedule: .constant(startHour))
    }

    public static func key(containing moment: Date, calendar: Calendar, startHour: Int) -> String {
        key(containing: moment, calendar: calendar, schedule: .constant(startHour))
    }

    public static func interval(containing moment: Date, calendar: Calendar, startHour: Int) -> DateInterval {
        interval(containing: moment, calendar: calendar, schedule: .constant(startHour))
    }

    public static func previous(_ interval: DateInterval, calendar: Calendar, startHour: Int) -> DateInterval {
        previous(interval, calendar: calendar, schedule: .constant(startHour))
    }

    public static func next(_ interval: DateInterval, calendar: Calendar, startHour: Int) -> DateInterval {
        next(interval, calendar: calendar, schedule: .constant(startHour))
    }

    public static func nextDayKey(after moment: Date, calendar: Calendar, startHour: Int) -> String {
        nextDayKey(after: moment, calendar: calendar, schedule: .constant(startHour))
    }

    // MARK: Helpers

    private static func offsetCalendar(_ utcOffsetSeconds: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt
        return calendar
    }

    private static func calendarDateKey(of date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// The day start on `date`'s own calendar date, at the hour the schedule
    /// holds for the record day keyed by that date.
    private static func start(onCalendarDateOf date: Date, calendar: Calendar, schedule: DayStartSchedule) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = schedule.hour(effectiveOn: calendarDateKey(of: date, calendar: calendar))
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
}
