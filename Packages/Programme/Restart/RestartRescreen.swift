import Foundation
import Constants

/// Whether "Start week 1 again" MUST re-screen before the start-day choice
/// (safeguarding spec, "Re-screening at a restart"). 84 is the record-day
/// threshold the requirement's own text states; it is not one of
/// `ProgrammeConstants`' named thresholds.
public enum RestartGate {
    public static let recordDaysBeforeRescreen = 84

    /// `askedAt` is the Profile field of the same name: the moment of the
    /// last screening (onboarding or the latest re-screen with no
    /// exclusion). `nil` never happens after onboarding; a `nil` here
    /// re-screens, the safe default.
    public static func rescreenRequired(askedAt: Date?, now: Date, currentRecordDay: String, dayStart: Int, calendar: Calendar) -> Bool {
        guard let askedAt else { return true }
        if askedAt > now { return true }
        let askedAtDayKey = DayKeyMath.recordDayKey(containing: askedAt, dayStart: dayStart, calendar: calendar)
        return DayKeyMath.daysBetween(askedAtDayKey, currentRecordDay, calendar: calendar) > recordDaysBeforeRescreen
    }
}

/// The re-screen's own answers (safeguarding spec, "Re-screening at a
/// restart": "The re-screen MUST ask height and weight... pregnancy,
/// treatment and the self-harm item... MUST NOT ask the age again.").
public struct RescreenAnswers: Sendable, Equatable {
    public var heightCm: Double
    public var weightKg: Double
    public var pregnancy: PregnancyAnswer
    public var treatment: TreatmentAnswer
    public var selfHarmFirst: SelfHarmFirstAnswer
    public var selfHarmSecond: SelfHarmSecondAnswer?

    public init(heightCm: Double, weightKg: Double, pregnancy: PregnancyAnswer, treatment: TreatmentAnswer, selfHarmFirst: SelfHarmFirstAnswer, selfHarmSecond: SelfHarmSecondAnswer?) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.pregnancy = pregnancy
        self.treatment = treatment
        self.selfHarmFirst = selfHarmFirst
        self.selfHarmSecond = selfHarmSecond
    }
}

/// The re-screen's result: either the reasons that exclude (no restart, no
/// Profile write beyond `remindersPausedAt` on the weight reason), or the
/// replacement Profile fields when no rule excludes.
public struct RescreenResult: Sendable, Equatable {
    public var reasons: [ExclusionReason]
    public var newHeightCm: Double
    public var newOnboardingBMI: Double
    public var newCautionFlag: Bool
    public var newAskedAt: Date

    public var excluded: Bool { !reasons.isEmpty }
    public var selfHarmSupportLineShows: Bool

    public var remindersPausedByWeightReason: Bool { reasons.contains(.weight) }
}

/// Evaluates a restart re-screen's answers, reusing the onboarding screening
/// rules and the not-right-now page's fixed reason order (safeguarding
/// spec, "Re-screening at a restart": "The app MUST apply every screening
/// rule except the age rule to the answers."). The rules read the unrounded
/// BMI, and the Profile keeps it unrounded, as at onboarding ("The app MUST
/// compute the BMI as `onboarding` defines"; onboarding spec, "The one-time
/// BMI": "The app MUST pass the unrounded BMI to `safeguarding`.").
public enum RestartRescreen {
    public static func evaluate(_ answers: RescreenAnswers, now: Date) -> RescreenResult {
        let bmi = BMI.value(heightCm: answers.heightCm, weightKg: answers.weightKg)
        let selfHarm = SelfHarmItem.outcome(first: answers.selfHarmFirst, second: answers.selfHarmSecond)
        var reasons: [ExclusionReason] = []
        if selfHarm == .excludes { reasons.append(.selfHarm) }
        if ScreeningRules.bmiExcludes(bmi) { reasons.append(.weight) }
        if ScreeningRules.pregnancyExcludes(answers.pregnancy) { reasons.append(.pregnancy) }
        if ScreeningRules.treatmentExcludes(answers.treatment) { reasons.append(.treatment) }
        return RescreenResult(
            reasons: NotRightNowPage.ordered(reasons),
            newHeightCm: answers.heightCm,
            newOnboardingBMI: bmi,
            newCautionFlag: ScreeningRules.cautionFlag(for: bmi),
            newAskedAt: now,
            selfHarmSupportLineShows: selfHarm == .supportLine
        )
    }
}
