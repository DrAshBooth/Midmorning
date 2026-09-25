import Foundation
import SwiftData

/// An alternative, a food rule, an avoided food, a ladder step, or a custom
/// place, told apart by `kind` (data-and-privacy spec, "CKRecord types and
/// model names are neutral"). Natural key: `id`. Winner: later `changedAt`;
/// two devices' new items union by id, ordered by `position` then
/// `changedAt`. `deleted` hides the row and its dependants without a cascade.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class ListItem {
    public var id: UUID = UUID()
    /// One of "alternative", "foodRule", "avoidedFood", "ladderStep", "customPlace".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    @Attribute(.allowsCloudEncryption) public var text: String = ""
    @Attribute(.allowsCloudEncryption) public var position: Int = 0
    @Attribute(.allowsCloudEncryption) public var deleted: Bool = false
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), kind: String, text: String, position: Int = 0, deleted: Bool = false, changedAt: Date) {
        self.id = id
        self.kind = kind
        self.text = text
        self.position = position
        self.deleted = deleted
        self.changedAt = changedAt
    }
}
