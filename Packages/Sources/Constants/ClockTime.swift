import Foundation

/// "HH:mm" clock-time text and arithmetic, on the 24-hour clock and
/// independent of the device locale (product-rules spec, "Dates and times
/// in strings"). Every package and the App target use this one copy: the
/// plan, the reminders, the settings rows and the time pickers.
public enum ClockTime {
    /// "HH:mm" for `hour` and `minute`.
    public static func string(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// "HH:mm" for the hour and the minute of `date` in `calendar`.
    public static func string(from date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return string(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    /// Parses "HH:mm" back to its components, or `nil` for a malformed string.
    public static func parse(_ time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return (hour, minute)
    }

    /// Minutes since midnight, 0 to 1439, for a malformed string 0.
    public static func minutesOfDay(_ time: String) -> Int {
        guard let (hour, minute) = parse(time) else { return 0 }
        return hour * 60 + minute
    }

    /// The clock minute of `date` in `calendar` (for example 240 for 04:00).
    public static func minutesOfDay(of date: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// The minutes from the day start's clock time to `time`, from 0 to
    /// 1439. Use this, not `minutesOfDay`, to order or compare two clock
    /// times of one record day: a time after midnight comes after a time
    /// in the evening.
    public static func minutesSinceDayStart(_ time: String, dayStartMinute: Int) -> Int {
        ((minutesOfDay(time) - dayStartMinute) % 1440 + 1440) % 1440
    }

    /// `time` ("HH:mm") inside the record day that starts at `dayStart`, or
    /// `nil` when `time` does not parse. A clock time earlier than the day
    /// start's own clock time falls after midnight, so it goes on the next
    /// calendar date (regular-eating-plan spec, "A planned meal after
    /// midnight"; reminders spec, "Scheduling is local, lazy and bounded",
    /// scenario "A later day start").
    public static func date(atTime time: String, on dayStart: Date, calendar: Calendar) -> Date? {
        guard let (hour, minute) = parse(time),
              let sameDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart)
        else { return nil }
        guard sameDate < dayStart else { return sameDate }
        return calendar.date(byAdding: .day, value: 1, to: sameDate)
    }

    /// A `Date` with only this hour and minute, for a time picker that
    /// shows the hour and the minute only.
    public static func date(hour: Int, minute: Int, calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    /// A time picker's `Date` for an "HH:mm" setting value; 00:00 for a
    /// malformed string.
    public static func date(from time: String, calendar: Calendar = .current) -> Date {
        let (hour, minute) = parse(time) ?? (0, 0)
        return date(hour: hour, minute: minute, calendar: calendar)
    }
}
