import Foundation

/// "Thursday 24 September": the weekday and date only, from the en_GB
/// formatter on the Gregorian calendar (product-rules spec, "Dates and
/// times in strings"). The day headings, the time-control segments and the
/// "Earlier days" rows use it (record spec, "Earlier record days": "Each row
/// in the list MUST show the weekday and date only").
///
/// A day key names a calendar date, not a moment. `weekdayAndDate(forKey:)`
/// reads the key as noon on that date in `calendar`'s zone and formats it in
/// the same zone, so the text shows the key's own date and weekday in every
/// zone, west of GMT too.
public enum DayKeyText {
    public static func weekdayAndDate(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    /// The key's weekday and date, or the key itself when it is malformed.
    public static func weekdayAndDate(forKey key: String, calendar: Calendar) -> String {
        guard let noon = RecordDay.noon(ofKey: key, calendar: calendar) else { return key }
        return weekdayAndDate(noon, calendar: calendar)
    }
}
