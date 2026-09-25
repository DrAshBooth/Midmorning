import Foundation
import SwiftData

/// A planned-meal answer (`dateKey` + `slotIndex`) or a card answer (`cardId`,
/// optional `dayKey`) (data-and-privacy spec, "Conflict rules for the plan,
/// weigh-ins and lists"; "Card answers live in the record"). Winner: later
/// `changedAt`. The snooze count never lives here; it stays in `Local.store`.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Answer {
    public var id: UUID = UUID()
    /// "plannedMeal" or "card".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    @Attribute(.allowsCloudEncryption) public var dateKey: String = ""
    @Attribute(.allowsCloudEncryption) public var slotIndex: Int = -1
    /// The card or suggestion-template id, for `kind == "card"`.
    @Attribute(.allowsCloudEncryption) public var cardId: String = ""
    /// "Skipped", "Add it", "That was it", or a card's answer text.
    @Attribute(.allowsCloudEncryption) public var value: String = ""
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        kind: String,
        dateKey: String = "",
        slotIndex: Int = -1,
        cardId: String = "",
        value: String,
        changedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.dateKey = dateKey
        self.slotIndex = slotIndex
        self.cardId = cardId
        self.value = value
        self.changedAt = changedAt
    }
}
