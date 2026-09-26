import Foundation
import Constants

/// The weigh-in screen's own fixed strings, quoted from the weigh-in spec.
/// "Weigh-in day" and "I won't be weighing" reuse `Screen3Content`'s own
/// constants (onboarding already ships the identical label and choice).
/// Each string is a key in the app's string catalogue, never English
/// (content spec, "Strings live in catalogues"). The unit keys also label
/// the onboarding height and weight fields.
public enum WeighInContent {
    public static let title: CatalogueText = .key("weighIn.title")
    public static let chooseADayHeading: CatalogueText = .key("weighIn.chooseADay")
    public static let weightLabel: CatalogueText = .key("weighIn.weight")
    public static let unitLabel: CatalogueText = .key("unit.label")
    public static let kgChoice: CatalogueText = .key("unit.kg")
    public static let stLbChoice: CatalogueText = .key("unit.stLb")
    public static let stoneAccessibilityLabel: CatalogueText = .key("weighIn.stone")
    public static let poundsAccessibilityLabel: CatalogueText = .key("weighIn.pounds")
    public static let rollingAverageAccessibilityLabel: CatalogueText = .key("weighIn.rollingAverage")
    /// The chart's date axis, which the chart's audio graph reads.
    public static let chartDateLabel: CatalogueText = .key("weighIn.chart.date")
}

/// weigh-in spec, "The one-line explanation" (mm-t22.7). Shown under the
/// chart whenever it shows; no other text about the trend.
public enum WeighInExplanation {
    public static func text(unit: WeightUnit) -> CatalogueText {
        switch unit {
        case .kg: return .key("weighIn.explanation.kg")
        case .stLb: return .key("weighIn.explanation.stLb")
        }
    }
}
