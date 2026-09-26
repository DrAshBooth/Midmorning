import Foundation

/// The four values the store keeps from a screening (onboarding spec, "What
/// onboarding keeps and what it never keeps"): the height in centimetres,
/// the onboarding BMI (unrounded), the caution flag and `askedAt`, the
/// moment of the screening.
public struct ScreeningKeptValues: Sendable, Equatable {
    public let heightCm: Double
    public let onboardingBMI: Double
    public let cautionFlag: Bool
    public let askedAt: Date

    public init(heightCm: Double, onboardingBMI: Double, cautionFlag: Bool, askedAt: Date) {
        self.heightCm = heightCm
        self.onboardingBMI = onboardingBMI
        self.cautionFlag = cautionFlag
        self.askedAt = askedAt
    }
}

/// What follows "Continue" on onboarding screen 2 when every question has a
/// valid answer (safeguarding spec, "Screening rules for age, pregnancy and
/// treatment" and "Screening rules for BMI").
public enum OnboardingScreeningOutcome: Sendable, Equatable {
    /// The exclusion page, with every reason that applies.
    case excluded([ExclusionReason])
    /// The caution sheet, then "Your start". The caution flag is set.
    case cautionSheet(ScreeningKeptValues)
    /// "Your start", with the caution flag off.
    case continues(ScreeningKeptValues)
}

/// The screen 2 decision. Onboarding holds the kept values in memory and
/// writes them to the store only at "Start" (onboarding spec, "Finish":
/// "The app MUST NOT keep answers from an unfinished onboarding."), so an
/// exclusion or an unfinished onboarding leaves no Profile row (safeguarding
/// spec, "The app keeps nothing from an exclusion").
public enum OnboardingScreening {
    public static func evaluate(
        age: Int,
        heightCm: Double,
        weightKg: Double,
        pregnancy: PregnancyAnswer,
        treatment: TreatmentAnswer,
        selfHarm: SelfHarmOutcome,
        now: Date
    ) -> OnboardingScreeningOutcome {
        // "The app MUST pass the unrounded BMI to `safeguarding`."
        let bmi = BMI.value(heightCm: heightCm, weightKg: weightKg)
        let reasons = ScreeningRules.onboardingReasons(age: age, pregnancy: pregnancy, treatment: treatment, bmi: bmi, selfHarm: selfHarm)
        guard reasons.isEmpty else { return .excluded(reasons) }
        let caution = ScreeningRules.cautionFlag(for: bmi)
        let kept = ScreeningKeptValues(heightCm: heightCm, onboardingBMI: bmi, cautionFlag: caution, askedAt: now)
        return caution ? .cautionSheet(kept) : .continues(kept)
    }
}
