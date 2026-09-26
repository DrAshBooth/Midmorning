import Foundation
import Constants

/// The closed-stage rule strings the Programme screen and each stage's row
/// show (programme spec, "Reading ahead is never blocked"). Each string with
/// a count carries a plural form; a one-sentence string never ends with a
/// full stop, and the stage 2 string is two sentences, each ending with one.
public enum StageRuleText {
    public static func plural(_ count: Int, _ singular: String, _ plural: String) -> String {
        count == 1 ? singular : plural
    }

    /// "Opens after %1$lld recorded days. You have %2$lld." (stage 2).
    public static func stage2(gate: Int, recordedDaysCount: Int) -> String {
        "Opens after \(gate) recorded \(plural(gate, "day", "days")). You have \(recordedDaysCount)."
    }

    /// "Opens after %1$lld days on your plan, or %2$lld weeks after your
    /// plan starts" (stage 3). `RECORD_DAYS_FOR_STAGE_3_FALLBACK` MUST be a
    /// multiple of 7, so `%2$lld` divides evenly.
    public static func stage3(constants: ProgrammeConstants) -> String {
        let days = constants.daysOnPlanForStage3
        let weeks = constants.recordDaysForStage3Fallback / 7
        return "Opens after \(days) days on your plan, or \(weeks) \(plural(weeks, "week", "weeks")) after your plan starts"
    }

    /// "Opens after your first urge outcome, or a week from now" (stage 4):
    /// fixed text, no placeholder.
    public static let stage4 = "Opens after your first urge outcome, or a week from now"

    /// "Opens %lld weeks after your plan starts" (stages 5 and 7).
    public static func weeksAfterPlanStarts(_ weeks: Int) -> String {
        "Opens \(weeks) \(plural(weeks, "week", "weeks")) after your plan starts"
    }

    /// "Opens after taking stock" (stage 6): fixed text, no placeholder.
    public static let stage6 = "Opens after taking stock"

    /// The closed-stage rule string for `stage`, or `nil` for stage 1, which
    /// has no gate.
    public static func string(for stage: Stage, constants: ProgrammeConstants, recordedDaysCount: Int) -> String? {
        switch stage {
        case .gettingStarted: return nil
        case .regularEating: return stage2(gate: constants.recordedDaysForStage2, recordedDaysCount: recordedDaysCount)
        case .alternatives: return stage3(constants: constants)
        case .problemSolving: return stage4
        case .takingStock: return weeksAfterPlanStarts(constants.weekOfTakingStock)
        case .modules: return stage6
        case .stayingOnTrack: return weeksAfterPlanStarts(constants.weekOfStayingOnTrack)
        }
    }

    /// The row text for a build that lacks `stage`'s own tool (decision
    /// 102, programme spec, "The Programme screen shows where the person
    /// is"): replaces the rule string and the "Now" marker alike.
    public static let comesInALaterVersion = "Comes in a later version"
}
