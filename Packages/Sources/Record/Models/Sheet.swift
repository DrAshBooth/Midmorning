import Foundation
import SwiftData

/// A worksheet, the maintenance plan, taking stock, a reintroduction, or a
/// Feeling fat note, told apart by `kind` (data-and-privacy spec, "CKRecord
/// types and model names are neutral"). Natural key: `id`; the maintenance
/// plan uses `Sheet.maintenancePlanId`, a fixed id. Winner: later `changedAt`.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Sheet {
    public var id: UUID = UUID()
    /// One of "worksheet", "maintenancePlan", "takingStock", "reintroduction", "feelingFatNote".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    /// Owned by the capability each `kind` belongs to.
    @Attribute(.allowsCloudEncryption) public var payloadJSON: String = "{}"
    /// The entry a Feeling fat note links, when `kind == "feelingFatNote"`.
    @Attribute(.allowsCloudEncryption) public var entryId: UUID?
    @Attribute(.allowsCloudEncryption) public var deleted: Bool = false
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), kind: String, payloadJSON: String = "{}", entryId: UUID? = nil, deleted: Bool = false, changedAt: Date) {
        self.id = id
        self.kind = kind
        self.payloadJSON = payloadJSON
        self.entryId = entryId
        self.deleted = deleted
        self.changedAt = changedAt
    }

    /// The maintenance plan's one fixed id (design.md, "Model names,
    /// singletons and the account binding").
    public static let maintenancePlanId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}
