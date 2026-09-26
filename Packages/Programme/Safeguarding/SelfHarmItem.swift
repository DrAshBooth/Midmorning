import Foundation

/// The self-harm item's two steps and what follows each pair of answers
/// (safeguarding spec, "The self-harm item"). This capability owns the
/// wording and the routing; `onboarding`, `weekly-review` and
/// `staying-on-track` place the item on their own screens.
public enum SelfHarmOutcome: Sendable, Equatable {
    /// "No" or "I'd rather not say": no line, no second question, no exclusion.
    case noFollowUp
    /// "Yes" then "No": the support line shows and the screen continues.
    case supportLine
    /// "Yes" then "Yes": the app excludes with the self-harm reason.
    case excludes
}

public enum SelfHarmItem {
    /// The second question shows only after "Yes" to the first.
    public static func showsSecondQuestion(after first: SelfHarmFirstAnswer) -> Bool {
        first == .yes
    }

    /// The outcome for a first answer and, when the first is "Yes", a second
    /// answer. A missing second answer after "Yes" is treated as `.supportLine`,
    /// the same as "No" to the second question, because the screen never
    /// advances without answering the shown question (onboarding spec,
    /// "Screen 2: the screening questions").
    public static func outcome(first: SelfHarmFirstAnswer, second: SelfHarmSecondAnswer?) -> SelfHarmOutcome {
        switch first {
        case .no, .ratherNotSay:
            return .noFollowUp
        case .yes:
            return second == .yes ? .excludes : .supportLine
        }
    }

    /// "That deserves a person. Samaritans are there any time, on 116 123."
    public static let supportLine = "That deserves a person. Samaritans are there any time, on 116 123."
}
