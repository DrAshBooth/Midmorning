import Foundation
import SwiftData

/// A weekday or weekend set of plan slots (data-and-privacy spec, "CKRecord
/// types and model names are neutral"). Natural key: `kind`. Winner: later
/// `changedAt`. `regular-eating-plan` (2.3) owns the slot payload shape;
/// `slotsJSON` is an opaque, additively-grown store for it.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Template {
    public var id: UUID = UUID()
    /// "weekday" or "weekend".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    @Attribute(.allowsCloudEncryption) public var slotsJSON: String = "[]"
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), kind: String, slotsJSON: String = "[]", changedAt: Date) {
        self.id = id
        self.kind = kind
        self.slotsJSON = slotsJSON
        self.changedAt = changedAt
    }
}
