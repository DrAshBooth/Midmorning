import Foundation
import Record

/// The weekday-and-date text every day heading and time-control segment
/// uses (record spec, "Today's appearance"; "The new-entry screen's
/// controls"). Always en-GB, the Gregorian calendar and the device zone
/// (product-rules spec, "Dates and times in strings"). A day key is read
/// and formatted in that one calendar, so its date never moves by a day
/// (`DayKeyText`).
enum DayHeading {
    /// The Gregorian calendar in the device zone.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    /// "Thursday 24 September" — no time, no year, no night suffix. Used by
    /// the new-entry and edit screens' time-control segments, and by the
    /// "Earlier days" list rows.
    static func dateOnly(_ date: Date) -> String {
        DayKeyText.weekdayAndDate(date, calendar: calendar)
    }

    /// Today's own day heading: the date, with ", night" appended for the
    /// current day between 00:00 and the day start (record spec, "Today's
    /// appearance").
    static func text(for date: Date, night: Bool) -> String {
        dateOnly(date) + (night ? ", night" : "")
    }

    /// "Thursday 24 September" from a record day key ("2026-09-24"), for the
    /// "Earlier days" list (record spec, "Earlier record days": "Each row in
    /// the list MUST show the weekday and date only").
    static func dateOnly(forDayKey dayKey: String) -> String {
        DayKeyText.weekdayAndDate(forKey: dayKey, calendar: calendar)
    }

    /// Noon on the key's calendar date in the device zone, so a weekday or
    /// date read from it with the device calendar is the key's own.
    static func dayKeyDate(_ dayKey: String) -> Date? {
        RecordDay.noon(ofKey: dayKey, calendar: calendar)
    }
}
