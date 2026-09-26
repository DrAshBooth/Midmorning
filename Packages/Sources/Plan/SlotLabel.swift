import Foundation
import Constants

/// A slot's label, renamed in the plan builder (regular-eating-plan spec,
/// "Rename a slot in the plan builder"). The store keeps a renamed label as
/// the `Settings` row `slot.label.<index>` (`Settings.slotLabelKey(_:)`); an
/// empty or missing row means the slot's default label.
public enum SlotLabel {
    public static let maxLength = 20

    /// Truncates to `maxLength` characters, for a field that must not accept
    /// a 21st character.
    public static func truncated(_ text: String) -> String {
        String(text.prefix(maxLength))
    }

    /// True for "Midmorning" in any letter case. The `product-rules`
    /// capability owns the product-name rule; this reads it, not defines it.
    public static func isProductName(_ text: String) -> Bool {
        text.caseInsensitiveCompare("Midmorning") == .orderedSame
    }

    /// The label a slot shows: the stored value when one exists and is not
    /// empty, otherwise the slot's default label from the catalogue.
    public static func effective(stored: String?, defaultLabel: CatalogueText) -> CatalogueText {
        guard let stored, !stored.isEmpty else { return defaultLabel }
        return .verbatim(stored)
    }

    /// What "Save" does with the rename field's text (regular-eating-plan
    /// spec, "Rename a slot in the plan builder").
    public enum SaveOutcome: Equatable {
        /// Write this label (already trimmed and within `maxLength`).
        case save(String)
        /// Clear the stored row; the slot reverts to its default label.
        case revertToDefault
        /// Keep the field open with this message under it.
        case rejected(message: CatalogueText)
    }

    /// "That is the app's name. Choose another word."
    public static let productNameMessage: CatalogueText = .key("plan.rename.productName")

    public static func outcome(forSavedText text: String) -> SaveOutcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .revertToDefault }
        if isProductName(trimmed) { return .rejected(message: productNameMessage) }
        return .save(truncated(trimmed))
    }
}
