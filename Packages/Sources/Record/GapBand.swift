import Foundation

/// The gap band between two consecutive entries of a record day (record
/// spec, "The gap band"). A pure function over the day's entry times and its
/// own state. The App target passes the live stage-2-open fact from
/// `programme-engine` (2.1) and MAX_AWAKE_GAP_HOURS from
/// `ProgrammeConstants`.
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

    /// The band's VoiceOver label (record spec, "Accessibility of the
    /// additions"): "Gap of more than %lld hours", filled from
    /// `maxAwakeGapHours`.
    public static func accessibilityLabel(maxAwakeGapHours: Int) -> String {
        "Gap of more than \(maxAwakeGapHours) hours"
    }
}
