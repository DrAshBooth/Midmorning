import Foundation

/// The plan builder's control labels (regular-eating-plan spec, "Place slots
/// in the plan builder": "%@ time", "Remove %@"; "Rename a slot in the plan
/// builder": "Rename %@"). Each is filled with the slot's own label, so a
/// rename applies at once wherever the app shows that slot.
public enum PlanBuilderAccessibility {
    public static func timeControlLabel(slotLabel: String) -> String { "\(slotLabel) time" }
    public static func removeControlLabel(slotLabel: String) -> String { "Remove \(slotLabel)" }
    public static func renameControlLabel(slotLabel: String) -> String { "Rename \(slotLabel)" }
}
