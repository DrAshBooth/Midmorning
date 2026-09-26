import Foundation
import Plan

/// The label a slot shows on Today, in the plan builder and in a planned
/// meal reminder's explicit title: the person's label, or the slot's default
/// label from the catalogue (regular-eating-plan spec, "Rename a slot in the
/// plan builder"; reminders spec, "Discreet text by default").
enum SlotLabelText {
    static func effective(index: Int, stored: String?) -> String {
        guard let slot = Slot.at(index: index) else { return stored ?? "" }
        return SlotLabel.effective(stored: stored, defaultLabel: slot.defaultLabel).string
    }
}
