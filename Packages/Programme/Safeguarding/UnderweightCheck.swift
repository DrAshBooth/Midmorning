import Foundation

/// A rule of the underweight check (safeguarding spec, "The underweight
/// check"). Rule A alone shows the not-right-now page; Rule B and Rule C
/// share the GP suggestion page.
public enum UnderweightRule: Sendable, Equatable {
    case a, b, c
}

/// The facts the underweight check reads (safeguarding spec: "The check
/// MUST use the rolling average that `weigh-in` computes, the height, the
/// onboarding BMI and the caution flag."). `averageAtLeast28DaysEarlierKg`
/// is `nil` when no weigh-in is 28 or more days old
/// (`RollingAverage.averageAtLeastDaysEarlier`); Rule C then never applies.
public struct UnderweightCheckInput: Sendable, Equatable {
    public var heightCm: Double
    public var onboardingBMI: Double
    public var cautionFlag: Bool
    public var currentAverageKg: Double
    public var averageAtLeast28DaysEarlierKg: Double?

    public init(heightCm: Double, onboardingBMI: Double, cautionFlag: Bool, currentAverageKg: Double, averageAtLeast28DaysEarlierKg: Double?) {
        self.heightCm = heightCm
        self.onboardingBMI = onboardingBMI
        self.cautionFlag = cautionFlag
        self.currentAverageKg = currentAverageKg
        self.averageAtLeast28DaysEarlierKg = averageAtLeast28DaysEarlierKg
    }
}

/// The underweight check: three rules over the rolling average, the height,
/// the onboarding BMI and the caution flag (safeguarding spec, "The
/// underweight check"). A pure function; the App target calls it once per
/// saved weigh-in and never when no weigh-in exists.
public enum UnderweightCheck {
    private static let ruleAThresholdBMI = 18.5
    private static let ruleBThresholdBMI = 19.5
    private static let ruleBMinimumFallBMI = 1.0
    private static let ruleCThreshold = 0.05
    private static let ruleCCautionThreshold = 0.03

    /// Every rule that applies, in declaration order (A, then B, then C).
    /// Each comparison treats a value on its boundary as on it, also when
    /// `Double` puts it a few units in the last place off (`RuleBoundary`):
    /// a fall from 149.60 kg to 142.12 kg is exactly 5%, so Rule C applies.
    public static func rulesThatApply(_ input: UnderweightCheckInput) -> [UnderweightRule] {
        let impliedBMI = BMI.value(heightCm: input.heightCm, weightKg: input.currentAverageKg)
        var rules: [UnderweightRule] = []

        if RuleBoundary.isBelow(impliedBMI, ruleAThresholdBMI) {
            rules.append(.a)
        }
        if RuleBoundary.isBelow(impliedBMI, ruleBThresholdBMI),
           RuleBoundary.isAtOrAbove(input.onboardingBMI - impliedBMI, ruleBMinimumFallBMI) {
            rules.append(.b)
        }
        if let earlier = input.averageAtLeast28DaysEarlierKg {
            let threshold = input.cautionFlag ? ruleCCautionThreshold : ruleCThreshold
            if RuleBoundary.isAtOrBelow(input.currentAverageKg, earlier * (1 - threshold)) {
                rules.append(.c)
            }
        }
        return rules
    }

    /// The not-right-now page's reasons: the weight reason alone when Rule A
    /// applies, otherwise none (safeguarding spec: "Of Rules A to C, only
    /// Rule A shows the not-right-now page.").
    public static func notRightNowReasons(_ rules: [UnderweightRule]) -> [ExclusionReason] {
        rules.contains(.a) ? [.weight] : []
    }

    /// The GP suggestion page's reasons from Rule B and Rule C. Empty when
    /// Rule A applies (safeguarding spec: "When Rule A applies with another
    /// rule, the app MUST show the not-right-now page only.").
    public static func gpSuggestionReasons(_ rules: [UnderweightRule]) -> [GPSuggestionReason] {
        guard !rules.contains(.a) else { return [] }
        var reasons: [GPSuggestionReason] = []
        if rules.contains(.b) { reasons.append(.fallingWeight) }
        if rules.contains(.c) { reasons.append(.quickChange) }
        return reasons
    }
}
