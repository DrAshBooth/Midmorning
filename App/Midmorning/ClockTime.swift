import Foundation

/// Converts between a "HH:mm" setting value and a `Date` a `DatePicker` can
/// bind to. Every settings row that holds a time stores it as text; only the
/// picker needs a `Date`, and only its hour and minute, never its date.
enum ClockTime {
    static func date(from text: String, calendar: Calendar = .current) -> Date {
        let parts = text.split(separator: ":")
        let hour = parts.count == 2 ? Int(parts[0]) ?? 0 : 0
        let minute = parts.count == 2 ? Int(parts[1]) ?? 0 : 0
        return date(hour: hour, minute: minute, calendar: calendar)
    }

    static func date(hour: Int, minute: Int, calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    static func text(from date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }
}
