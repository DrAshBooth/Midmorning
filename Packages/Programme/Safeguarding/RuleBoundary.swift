import Foundation

/// Comparisons at the safeguarding rule boundaries (safeguarding spec,
/// "Screening rules for BMI" and "The underweight check"). A value that is
/// exactly on a boundary in decimal arithmetic can come out a few units in
/// the last place off in `Double`: 160 cm and 47.36 kg is a BMI of exactly
/// 18.5, but `BMI.value` gives 18.499999999999996, and 149.60 × 0.95 gives
/// 142.11999999999998, not 142.12. The rules treat a value within
/// `tolerance` of a boundary as on the boundary. No typed height or weight
/// can make a real difference as small as `tolerance`.
enum RuleBoundary {
    static let tolerance = 1e-9

    /// `value` is below `bound` and not on it.
    static func isBelow(_ value: Double, _ bound: Double) -> Bool {
        value < bound - tolerance
    }

    /// `value` is on `bound` or above it.
    static func isAtOrAbove(_ value: Double, _ bound: Double) -> Bool {
        value >= bound - tolerance
    }

    /// `value` is on `bound` or below it.
    static func isAtOrBelow(_ value: Double, _ bound: Double) -> Bool {
        value <= bound + tolerance
    }
}
