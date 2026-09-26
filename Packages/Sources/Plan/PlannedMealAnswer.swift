import Foundation

/// The values a planned meal's answer row holds (regular-eating-plan spec,
/// "The missed planned meal prompt"). A stored value, not text the person
/// reads: Today shows the catalogue key "plan.skipped" for it.
public enum PlannedMealAnswer {
    /// The person answered "Skipped", on Today or from a reminder action.
    public static let skipped = "Skipped"
}
