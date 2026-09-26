import Foundation

/// A reason the app excludes a person, or shows the not-right-now page at a
/// re-screen. Declaration order is the exclusion page's own paragraph order:
/// self-harm, age, weight, pregnancy, treatment (safeguarding spec, "The
/// exclusion page"). `ExclusionPage.ordered(_:)` relies on this order.
public enum ExclusionReason: Sendable, Equatable, CaseIterable {
    case selfHarm, age, weight, pregnancy, treatment
}

/// The screening rules for age, pregnancy, treatment and BMI (safeguarding
/// spec, "Screening rules for age, pregnancy and treatment" and "Screening
/// rules for BMI"). Every rule is a pure function of the typed age; the app
/// never requests the Declared Age Range entitlement in V1.
public enum ScreeningRules {
    public static let minimumAge = 18
    public static let minimumBMI = 18.5
    public static let cautionUpperBoundBMI = 19.0

    public static func ageExcludes(_ age: Int) -> Bool { age < minimumAge }
    public static func pregnancyExcludes(_ answer: PregnancyAnswer) -> Bool { answer == .yes }
    public static func treatmentExcludes(_ answer: TreatmentAnswer) -> Bool { answer == .yes }
    /// Below 18.5 excludes. A BMI of exactly 18.5 does not, also when
    /// `Double` gives it a few units in the last place low
    /// (`RuleBoundary`).
    public static func bmiExcludes(_ bmi: Double) -> Bool { RuleBoundary.isBelow(bmi, minimumBMI) }

    /// The caution flag: set when the BMI is 18.5 or more and below 19.0.
    public static func cautionFlag(for bmi: Double) -> Bool {
        RuleBoundary.isAtOrAbove(bmi, minimumBMI) && RuleBoundary.isBelow(bmi, cautionUpperBoundBMI)
    }

    /// Every reason that applies at onboarding, in the exclusion page's
    /// order: self-harm, age, weight, pregnancy, treatment.
    public static func onboardingReasons(
        age: Int,
        pregnancy: PregnancyAnswer,
        treatment: TreatmentAnswer,
        bmi: Double,
        selfHarm: SelfHarmOutcome
    ) -> [ExclusionReason] {
        var reasons: [ExclusionReason] = []
        if selfHarm == .excludes { reasons.append(.selfHarm) }
        if ageExcludes(age) { reasons.append(.age) }
        if bmiExcludes(bmi) { reasons.append(.weight) }
        if pregnancyExcludes(pregnancy) { reasons.append(.pregnancy) }
        if treatmentExcludes(treatment) { reasons.append(.treatment) }
        return reasons
    }
}
