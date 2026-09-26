import Foundation

/// Whether a clock time falls inside quiet hours (reminders spec, "Quiet
/// hours"). The one copy the scheduler, the snooze rule, the plan builder,
/// Today's planned meal rows and the settings screen read. The range is
/// the half-open range from `start`, included, to `end`, excluded, and it
/// wraps past midnight when `end` is earlier than `start`.
public struct QuietHours: Sendable, Equatable {
    /// The "Quiet hours" switch.
    public let isOn: Bool
    public let start: String
    public let end: String

    public init(isOn: Bool, start: String, end: String) {
        self.isOn = isOn
        self.start = start
        self.end = end
    }

    /// True for `time` inside the range while the switch is on. Always
    /// false while the switch is off or the start equals the end.
    public func contains(_ time: String) -> Bool {
        let range = Self.effectiveRange(on: isOn, start: start, end: end)
        return Self.contains(time: time, start: range.start, end: range.end)
    }

    /// False when `start` equals `end` (reminders spec: "When the start
    /// equals the end, quiet hours are off").
    public static func isOn(start: String, end: String) -> Bool {
        start != end
    }

    /// The range the scheduler and the snooze rule read: the person's own
    /// range while the "Quiet hours" switch is on, or an "off" range (the
    /// start equal to the end) while it is off. This is the one place that
    /// holds the on/off rule.
    public static func effectiveRange(on: Bool, start: String, end: String) -> (start: String, end: String) {
        on ? (start, end) : (start, start)
    }

    /// True for `time` inside the range from `start` to `end`. Always false
    /// when the start equals the end.
    public static func contains(time: String, start: String, end: String) -> Bool {
        guard isOn(start: start, end: end) else { return false }
        let t = ClockTime.minutesOfDay(time)
        let s = ClockTime.minutesOfDay(start)
        let e = ClockTime.minutesOfDay(end)
        if s <= e { return t >= s && t < e }
        return t >= s || t < e
    }
}
