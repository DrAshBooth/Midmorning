import Foundation
import Constants

/// The weigh-in's unit choice (weigh-in spec, "The number and its unit";
/// settings spec, "The Weigh-in group"). `.kg` is the default.
public enum WeightUnit: String, Sendable, Equatable, CaseIterable {
    case kg
    case stLb

    public static let `default` = WeightUnit.kg
}

/// A validated weight the person entered, or the below-range refusal
/// (weigh-in spec, "The number and its unit").
public enum WeighInWeightValidity: Sendable, Equatable {
    case valid(kg: Double)
    case belowRange
}

/// Unit conversion, validation, storage rounding and display rounding for a
/// weigh-in's kilogram value (weigh-in spec, "The number and its unit").
/// Every conversion reuses `BMI`'s own stone/pound constants, the one place
/// this package already holds them.
public enum WeighInWeight {
    public static let belowRangeMessage = "That number is outside the range the app accepts. Check it and try again."

    /// Kilograms from a stone-and-pounds entry.
    public static func kg(stone: Int, pounds: Int) -> Double {
        BMI.weightKg(stone: stone, pounds: pounds)
    }

    /// The app MUST accept any weight of `minWeightKg` or more, with no
    /// upper bound (weigh-in spec, "The number and its unit"). This reuses
    /// `ProgrammeConstants.minWeightKg`, the same floor onboarding's own BMI
    /// screening already uses (`ScreeningLimits`).
    public static func validate(kg value: Double, constants: ProgrammeConstants = .default) -> WeighInWeightValidity {
        value >= Double(constants.minWeightKg) ? .valid(kg: value) : .belowRange
    }

    /// The store keeps each weigh-in as kilograms to two decimal places.
    public static func storedKg(_ raw: Double) -> Double {
        (raw * 100).rounded() / 100
    }

    /// Display in kilograms to one decimal place, for example "66.8".
    public static func displayKg(_ kg: Double) -> String {
        String(format: "%.1f", kg)
    }

    /// The nearest whole stone and pound for `kg` (weigh-in spec: "With the
    /// unit 'st lb' the app MUST show every value to the nearest whole
    /// pound."). Rounds the total pounds once, so 13 lb never rounds up
    /// into a 14th pound of the same stone.
    public static func stoneAndPounds(fromKg kg: Double) -> (stone: Int, pounds: Int) {
        let totalPounds = Int((kg / BMI.kgPerPound).rounded())
        return (totalPounds / 14, totalPounds % 14)
    }

    /// "10 st 7 lb", the display text for `kg` in stone and pounds.
    public static func displayStoneAndPounds(fromKg kg: Double) -> String {
        let (stone, pounds) = stoneAndPounds(fromKg: kg)
        return "\(stone) st \(pounds) lb"
    }

    /// The display text for `kg` in `unit`: "66.8 kg" or "10 st 7 lb".
    public static func display(kg: Double, unit: WeightUnit) -> String {
        switch unit {
        case .kg: return "\(displayKg(kg)) kg"
        case .stLb: return displayStoneAndPounds(fromKg: kg)
        }
    }
}
