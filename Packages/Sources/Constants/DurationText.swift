import Foundation

/// A gap or a duration in whole hours and minutes, in the en-GB word form
/// with no separating comma: "2 hours 30 minutes", "3 hours", "1 minute",
/// "0 minutes" (regular-eating-plan spec, "Place slots in the plan
/// builder"; weekly-review spec, "The summary built from the record").
/// Nothing here reads the device locale.
public enum DurationText {
    public static func string(minutes: Int) -> String {
        let totalMinutes = max(0, minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append(hours == 1 ? "1 hour" : "\(hours) hours") }
        if mins > 0 || hours == 0 { parts.append(mins == 1 ? "1 minute" : "\(mins) minutes") }
        return parts.joined(separator: " ")
    }

    /// `seconds` rounded to the nearest whole minute.
    public static func string(seconds: TimeInterval) -> String {
        string(minutes: Int((seconds / 60).rounded()))
    }
}
