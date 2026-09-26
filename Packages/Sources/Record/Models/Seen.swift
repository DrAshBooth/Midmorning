import Foundation
import SwiftData

/// A card view. Natural key: `id`. Winner: none — every view is its own row
/// (content spec, "The store keeps which content version the person saw").
/// `contentVersion` added by `programme-engine` (2.1), additively, per the
/// frozen-schema growth rule; see `FrozenSchema.json`.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Seen {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var cardId: String = ""
    @Attribute(.allowsCloudEncryption) public var seenAt: Date = Date()
    /// The content version in force when the person opened the card. `0` on
    /// a row from before this field existed.
    @Attribute(.allowsCloudEncryption) public var contentVersion: Int = 0

    public init(id: UUID = UUID(), cardId: String, seenAt: Date, contentVersion: Int = 0) {
        self.id = id
        self.cardId = cardId
        self.seenAt = seenAt
        self.contentVersion = contentVersion
    }
}
