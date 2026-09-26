import Foundation

/// The one definition of a planned day (regular-eating-plan spec, "A planned
/// day"); every other capability refers to it.
public enum PlannedDay {
    /// `isSetDay` is true once a set event row exists for the record day, on
    /// this device or synced from another. `hasEntry` is true when any entry
    /// falls in the record day, whatever its source. A paused day is never a
    /// planned day, whatever else is true of it.
    public static func isPlanned(isPaused: Bool, isSetDay: Bool, hasEntry: Bool) -> Bool {
        guard !isPaused else { return false }
        return isSetDay || hasEntry
    }

    /// The count of days that are both planned and recorded, toward
    /// `DAYS_ON_PLAN_FOR_STAGE_3`. The days need not be consecutive.
    public static func countTowardStage3(_ days: [(isPlanned: Bool, isRecordedDay: Bool)]) -> Int {
        days.filter { $0.isPlanned && $0.isRecordedDay }.count
    }

    /// The length of a run of consecutive planned days: a paused day is
    /// transparent and never breaks the run, but any other non-planned day
    /// ends it (regular-eating-plan spec: "A paused day MUST NOT break a run
    /// of consecutive planned days"). `days` is in date order.
    public static func consecutiveRunLength(_ days: [(isPaused: Bool, isPlanned: Bool)]) -> Int {
        var count = 0
        for day in days {
            if day.isPaused { continue }
            guard day.isPlanned else { break }
            count += 1
        }
        return count
    }
}
