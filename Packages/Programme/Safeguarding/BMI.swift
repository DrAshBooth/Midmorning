import Foundation
import Constants

/// The one-time BMI's unit conversions and validation (onboarding spec,
/// "The one-time BMI"). The app never shows the BMI on any screen; it only
/// ever passes the value to `ScreeningRules`.
public enum BMI {
    public static let cmPerFoot = 30.48
    public static let cmPerInch = 2.54
    public static let kgPerStone = 6.35029
    public static let kgPerPound = 0.453592

    public static func heightCm(feet: Int, inches: Int) -> Double {
        Double(feet) * cmPerFoot + Double(inches) * cmPerInch
    }

    public static func weightKg(stone: Int, pounds: Int) -> Double {
        Double(stone) * kgPerStone + Double(pounds) * kgPerPound
    }

    /// Weight in kilograms divided by height in metres squared.
    public static func value(heightCm: Double, weightKg: Double) -> Double {
        let metres = heightCm / 100
        return weightKg / (metres * metres)
    }

    /// Rounds to two decimal places for comparison against the spec's
    /// worked examples (for example 20.76). The app itself never shows this.
    public static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

public enum HeightValidity: Sendable, Equatable {
    case valid, tooLow, tooHigh
}

public enum WeightValidity: Sendable, Equatable {
    case valid, tooLow
}

/// The height and weight limits and their messages (onboarding spec, "The
/// one-time BMI"). The limits come from `ProgrammeConstants`, never a
/// repeated literal.
public enum ScreeningLimits {
    public static func validate(heightCm: Double, constants: ProgrammeConstants = .default) -> HeightValidity {
        if heightCm < Double(constants.minHeightCm) { return .tooLow }
        if heightCm > Double(constants.maxHeightCm) { return .tooHigh }
        return .valid
    }

    public static func validate(weightKg: Double, constants: ProgrammeConstants = .default) -> WeightValidity {
        weightKg < Double(constants.minWeightKg) ? .tooLow : .valid
    }

    /// "Enter a height between %1$lld and %2$lld cm.", filled from the constants.
    public static func heightMessage(constants: ProgrammeConstants = .default) -> String {
        "Enter a height between \(constants.minHeightCm) and \(constants.maxHeightCm) cm."
    }

    /// "Enter a weight of %lld kg or more.", filled from the constant.
    public static func weightMessage(constants: ProgrammeConstants = .default) -> String {
        "Enter a weight of \(constants.minWeightKg) kg or more."
    }
}
