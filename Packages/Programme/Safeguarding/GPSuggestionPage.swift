import Foundation
import Constants

/// The GP suggestion page's fixed content (safeguarding spec, "The GP
/// suggestion page"). `mm-t22` (the underweight check, Rules B and C) and
/// `mm-t32` (the deterioration rule and "I'm getting worse") open this page
/// from their own triggers; this change builds the page and its content only.
public enum GPSuggestionReason: Sendable, Equatable {
    case fallingWeight, quickChange, deterioration, gettingWorse
}

public enum GPSuggestionPage {
    public static let heading = "It might help to see your GP"
    public static let diagnosisLine = "This is not a diagnosis, and nothing here is closed to you."

    /// A reason's line MUST NOT give a cause for the weight change.
    public static func line(for reason: GPSuggestionReason, constants: ProgrammeConstants = .default) -> String {
        switch reason {
        case .fallingWeight:
            return "Your weight has come down since you started."
        case .quickChange:
            return "Your weight has changed quickly over the last four weeks."
        case .deterioration:
            return "Your starred entries have gone up for \(constants.deteriorationWeeks) weeks in a row."
        case .gettingWorse:
            return "You said things are getting worse."
        }
    }

    public static func supportingLine(for reason: GPSuggestionReason) -> String {
        switch reason {
        case .fallingWeight, .quickChange:
            return "Your plan stays on. It's worth a word with your GP."
        case .deterioration, .gettingWorse:
            return "That's worth talking through with your GP. Your plan stays on."
        }
    }
}
