import Constants

/// The deterioration rule (safeguarding spec, "The deterioration rule";
/// weekly-review spec, "The deterioration rule at the review"). Reads the
/// frozen starred counts of the last `DETERIORATION_WEEKS + 1` reviews, the
/// current one last (`weekly-review` freezes each week's count into its
/// Review row; this rule never recomputes a count itself).
public enum DeteriorationRule {
    /// `counts` MUST hold exactly `constants.deteriorationWeeks + 1` frozen
    /// starred counts, oldest first, current last. Fires when each of the
    /// last `deteriorationWeeks` counts exceeds the count before it, the
    /// latest is at least 4, and the latest is at least twice the first.
    /// `false` when fewer than four reviews exist yet.
    public static func fires(lastFrozenStarredCounts counts: [Int], constants: ProgrammeConstants = .default) -> Bool {
        let needed = constants.deteriorationWeeks + 1
        guard counts.count == needed else { return false }
        for i in 1..<needed where !(counts[i] > counts[i - 1]) { return false }
        let latest = counts[needed - 1]
        guard latest >= 4 else { return false }
        return latest >= 2 * counts[0]
    }
}
