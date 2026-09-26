import Foundation

/// Fixed "HH:mm" text and en-GB duration wording, independent of the device
/// locale (product-rules spec, "Dates and times in strings": every clock
/// time in a string uses the 24-hour clock). A named home, not a system
/// formatter, so the wording stays the same under test and across OS
/// versions (design.md, "Pure seams the packages expose").
public enum PlanTime {
    /// "HH:mm" for `hour` and `minute`.
    public static func string(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
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
}

/// A gap or a duration, filled through the en_GB formatter (regular-eating-
/// plan spec, "Place slots in the plan builder": "for example '2 hours 30
/// minutes' or '3 hours'"). This is the fixed word form the formatter
/// always produces; nothing here reads the device locale.
public enum PlanDuration {
    public static func string(minutes: Int) -> String {
        let totalMinutes = max(0, minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append(hours == 1 ? "1 hour" : "\(hours) hours") }
        if mins > 0 { parts.append(mins == 1 ? "1 minute" : "\(mins) minutes") }
        return parts.isEmpty ? "0 minutes" : parts.joined(separator: " ")
    }
}
