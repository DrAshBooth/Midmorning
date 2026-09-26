import Foundation

/// A week's own weigh-in status, for `weekly-review` and `staying-on-track`
/// to read (weigh-in spec, "A missed weigh-in day": "The app MUST make the
/// status of each week's weigh-in, done or not done, available to
/// `weekly-review`."). The weigh-in screen itself never shows this; only the
/// review and the check-in do, once each of those capabilities builds.
public enum WeighInWeekStatus: Sendable, Equatable {
    case done
    case notDone
    /// No weigh-in day exists, so no week has a missed weigh-in (weigh-in
    /// spec: "With no weigh-in day, no week has a missed weigh-in.").
    case noWeighInDay
}

public enum MissedWeighIn {
    /// `weekDayKey` is the record day key of the weigh-in weekday that week
    /// (`weekly-review`'s own week builder finds it); `hasWeighIn` reads a
    /// real `RecordStore.weighIn(dateKey:)`.
    public static func status(weighInWeekday: Int?, weekDayKey: String, hasWeighIn: (String) -> Bool) -> WeighInWeekStatus {
        guard weighInWeekday != nil else { return .noWeighInDay }
        return hasWeighIn(weekDayKey) ? .done : .notDone
    }
}
