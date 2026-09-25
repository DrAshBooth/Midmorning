import Foundation

/// The weekday-and-date text every day heading and time-control segment
/// uses (record spec, "Today's appearance"; "The new-entry screen's
/// controls"). Always en-GB, the Gregorian calendar and the record's zone
/// (product-rules spec, "Dates and times in strings").
enum DayHeading {
    /// "Thursday 24 September" — no time, no year, no night suffix. Used by
    /// the new-entry and edit screens' time-control segments, and by the
    /// "Earlier days" list rows.
    static func dateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    /// Today's own day heading: the date, with ", night" appended for the
    /// current day between 00:00 and 03:59 (record spec, "Today's
    /// appearance").
    static func text(for date: Date, night: Bool) -> String {
        dateOnly(date) + (night ? ", night" : "")
    }

    /// "Thursday 24 September" from a record day key ("2026-09-24"), for the
    /// "Earlier days" list (record spec, "Earlier record days": "Each row in
    /// the list MUST show the weekday and date only").
    static func dateOnly(forDayKey dayKey: String) -> String {
        guard let date = dayKeyDate(dayKey) else { return dayKey }
        return dateOnly(date)
    }

    static func dayKeyDate(_ dayKey: String) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }
}
