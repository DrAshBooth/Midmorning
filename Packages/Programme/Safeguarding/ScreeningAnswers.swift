import Foundation

/// The screening answers `onboarding` collects and passes to `safeguarding`
/// (safeguarding spec, "Screening rules for age, pregnancy and treatment").
/// A value type: `Programme` takes value facts and never imports `Record`
/// (design.md, "One umbrella package, five targets").
public enum PregnancyAnswer: Sendable, Equatable {
    case no, yes, doesNotApply
}

public enum TreatmentAnswer: Sendable, Equatable {
    case no
    case yesWithAgreement
    case yes
}

/// The self-harm item's first question: "Over the last two weeks, have you
/// had thoughts that you'd be better off dead, or of hurting yourself?"
public enum SelfHarmFirstAnswer: Sendable, Equatable {
    case no, yes, ratherNotSay
}

/// The self-harm item's second question, asked only after "Yes" to the
/// first: "Have you thought about how you would do it?"
public enum SelfHarmSecondAnswer: Sendable, Equatable {
    case no, yes
}
