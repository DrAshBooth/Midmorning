import Foundation

/// The gap band between two consecutive entries of a record day (record
/// spec, "The gap band"). A pure function over the day's entry times and its
/// own state, because `programme-engine` (2.1) is not built yet; a wiring
/// bead there (mm-t21.23) supplies the live stage-2-open fact.
public enum GapBand {
    /// The indexes in `sortedTimes` after which a band shows: a band sits
    /// between `sortedTimes[i]` and `sortedTimes[i + 1]` when that gap is
    /// over `maxAwakeGapHours`. A gap of exactly `maxAwakeGapHours` shows no
    /// band. Returns no index when `stage2Open` is false, when the day
    /// carries an exempt state ("didn't record", "paused" or "fasting"), or
    /// when the day is collapsed.
    public static func indexesBeforeBand(
        sortedTimes: [Date],
        stage2Open: Bool,
        dayHasExemptState: Bool,
        isCollapsed: Bool,
        maxAwakeGapHours: Int
    ) -> [Int] {
        guard stage2Open, !dayHasExemptState, !isCollapsed, sortedTimes.count > 1 else { return [] }
        let threshold = TimeInterval(maxAwakeGapHours) * 3600
        var result: [Int] = []
        for i in 0..<(sortedTimes.count - 1) {
            if sortedTimes[i + 1].timeIntervalSince(sortedTimes[i]) > threshold {
                result.append(i)
            }
        }
        return result
    }

    /// Whether bands can show at all on the record day keyed `dayKey`
    /// (record spec, "The gap band": "From the record day stage 2 opened, a
    /// day MUST show a band ... The app MUST NOT show a band on a day before
    /// that record day. The settings screen MUST hold a 'Gap bands' switch").
    /// The caller passes the result as `indexesBeforeBand`'s `stage2Open`.
    /// `stage2OpenedDayKey` is `nil` while stage 2 is closed. Every day on
    /// or after that key qualifies: the current day, the previous day and
    /// an earlier day.
    public static func applies(toDayKey dayKey: String, stage2OpenedDayKey: String?, switchOn: Bool) -> Bool {
        guard switchOn, let stage2OpenedDayKey else { return false }
        return dayKey >= stage2OpenedDayKey
    }

    /// The band's VoiceOver label (record spec, "Accessibility of the
    /// additions"): "Gap of more than %lld hours", filled from
    /// `maxAwakeGapHours`.
    public static func accessibilityLabel(maxAwakeGapHours: Int) -> String {
        "Gap of more than \(maxAwakeGapHours) hours"
    }
}
