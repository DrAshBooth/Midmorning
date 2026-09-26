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

/// The height unit the person chose on screen 2 or at the re-screen
/// (onboarding spec, "Screen 2: the screening questions"). The weight unit
/// is `WeightUnit`, which the weigh-in also uses.
public enum HeightUnit: String, Sendable, Equatable, CaseIterable {
    case cm
    case ftIn
}

/// The height and weight limits and their messages (onboarding spec, "The
/// one-time BMI"). The limits come from `ProgrammeConstants`, never a
/// repeated literal. With "ft in" or "st lb" chosen, the message gives the
/// same limit in that unit, rounded inward, so that the app accepts every
/// value the message shows (ruling r13-11): "between 3 ft 4 in and 8 ft 2
/// in", "4 st 11 lb or more". The messages are keys in the app's string
/// catalogue with the "screening." prefix, which the content hash and the
/// clinical sign-off cover (ruling r13-01).
public enum ScreeningLimits {
    public static func validate(heightCm: Double, constants: ProgrammeConstants = .default) -> HeightValidity {
        if heightCm < Double(constants.minHeightCm) { return .tooLow }
        if heightCm > Double(constants.maxHeightCm) { return .tooHigh }
        return .valid
    }

    public static func validate(weightKg: Double, constants: ProgrammeConstants = .default) -> WeightValidity {
        weightKg < Double(constants.minWeightKg) ? .tooLow : .valid
    }

    /// "Enter a height between %1$@ and %2$@.", filled with the two limits
    /// in `unit`.
    public static func heightMessage(unit: HeightUnit = .cm, constants: ProgrammeConstants = .default) -> CatalogueText {
        switch unit {
        case .cm:
            // "between 100 and 250 cm": the unit follows the upper limit only.
            return .key("screening.limit.height", .key("screening.limit.number %lld", .count(constants.minHeightCm)), centimetres(constants.maxHeightCm))
        case .ftIn:
            let inches = heightLimitsInInches(constants: constants)
            return .key("screening.limit.height", feetAndInches(inches.lowerBound), feetAndInches(inches.upperBound))
        }
    }

    /// "Enter a weight of %@ or more.", filled with the limit in `unit`.
    public static func weightMessage(unit: WeightUnit = .kg, constants: ProgrammeConstants = .default) -> CatalogueText {
        switch unit {
        case .kg:
            return .key("screening.limit.weight", .key("screening.limit.kg %lld", .count(constants.minWeightKg)))
        case .stLb:
            let pounds = weightLimitInPounds(constants: constants)
            return .key("screening.limit.weight", .key("screening.limit.stLb", .key("screening.limit.st %lld", .count(pounds / 14)), .key("screening.limit.lb %lld", .count(pounds % 14))))
        }
    }

    /// The height limits in whole inches, rounded inward: the smallest and
    /// the largest total of inches that `validate(heightCm:)` accepts when
    /// the person types feet and inches.
    public static func heightLimitsInInches(constants: ProgrammeConstants = .default) -> ClosedRange<Int> {
        func validity(_ inches: Int) -> HeightValidity {
            validate(heightCm: BMI.heightCm(feet: inches / 12, inches: inches % 12), constants: constants)
        }
        // Start two inches outside the estimate, where the value is refused,
        // and move inward to the first accepted value.
        var lower = max(0, Int((Double(constants.minHeightCm) / BMI.cmPerInch).rounded(.down)) - 2)
        while validity(lower) == .tooLow { lower += 1 }
        var upper = Int((Double(constants.maxHeightCm) / BMI.cmPerInch).rounded(.up)) + 2
        while validity(upper) == .tooHigh { upper -= 1 }
        return lower...max(lower, upper)
    }

    /// The weight limit in whole pounds, rounded inward: the smallest total
    /// of pounds that `validate(weightKg:)` accepts when the person types
    /// stone and pounds.
    public static func weightLimitInPounds(constants: ProgrammeConstants = .default) -> Int {
        var pounds = max(0, Int((Double(constants.minWeightKg) / BMI.kgPerPound).rounded(.down)) - 2)
        while validate(weightKg: BMI.weightKg(stone: pounds / 14, pounds: pounds % 14), constants: constants) == .tooLow {
            pounds += 1
        }
        return pounds
    }

    private static func centimetres(_ value: Int) -> CatalogueText {
        .key("screening.limit.cm %lld", .count(value))
    }

    private static func feetAndInches(_ inches: Int) -> CatalogueText {
        .key("screening.limit.ftIn", .key("screening.limit.ft %lld", .count(inches / 12)), .key("screening.limit.in %lld", .count(inches % 12)))
    }
}
