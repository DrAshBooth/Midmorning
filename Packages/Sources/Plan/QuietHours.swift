import Foundation

/// Whether a time of day falls inside quiet hours (regular-eating-plan spec,
/// "Place slots in the plan builder": "This time is in quiet hours. The
/// reminder will not be sent."). The `reminders` capability (2.4) owns quiet
/// hours; this is the minimal, interim check this change's own scenarios
/// need ahead of that build, over the same start/end settings
/// `RecordStore.quietHoursStart`/`quietHoursEnd` already keep.
public enum QuietHours {
    /// Shown under a planned meal placed inside quiet hours (regular-eating-
    /// plan spec, "Place slots in the plan builder").
    public static let reminderNotSentMessage = "This time is in quiet hours. The reminder will not be sent."

    /// True for `time` inside the half-open range `start` to `end`. Handles
    /// a range that wraps past midnight (the default, 22:00 to 07:00).
    public static func contains(time: String, start: String, end: String) -> Bool {
        let t = PlanTime.minutesOfDay(time)
        let s = PlanTime.minutesOfDay(start)
        let e = PlanTime.minutesOfDay(end)
        if s <= e {
            return t >= s && t < e
        }
        return t >= s || t < e
    }
}
