import Foundation
import SwiftData

/// A card view. Natural key: `id`. Winner: none.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Seen {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var cardId: String = ""
    @Attribute(.allowsCloudEncryption) public var seenAt: Date = Date()

    public init(id: UUID = UUID(), cardId: String, seenAt: Date) {
        self.id = id
        self.cardId = cardId
        self.seenAt = seenAt
    }
}
