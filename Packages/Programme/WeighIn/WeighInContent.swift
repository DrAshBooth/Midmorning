import Foundation

/// The weigh-in screen's own fixed strings, quoted from the weigh-in spec.
/// "Weigh-in day" and "I won't be weighing" reuse `Screen3Content`'s own
/// constants (onboarding already ships the identical label and choice).
public enum WeighInContent {
    public static let title = "Weigh-in"
    public static let chooseADayHeading = "Choose a weigh-in day"
    public static let weightLabel = "Weight"
    public static let unitLabel = "Unit"
    public static let kgChoice = "kg"
    public static let stLbChoice = "st lb"
    public static let stoneAccessibilityLabel = "Stone"
    public static let poundsAccessibilityLabel = "Pounds"
    public static let rollingAverageAccessibilityLabel = "Rolling average"
}

/// weigh-in spec, "The one-line explanation" (mm-t22.7). Shown under the
/// chart whenever it shows; no other text about the trend.
public enum WeighInExplanation {
    public static func text(unit: WeightUnit) -> String {
        switch unit {
        case .kg: return "Weekly swings of a kilo or two are normal and mean nothing on their own."
        case .stLb: return "Weekly swings of two or three pounds are normal and mean nothing on their own."
        }
    }
}
