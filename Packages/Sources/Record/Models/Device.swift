import Foundation
import SwiftData

/// One row per install (data-and-privacy spec, "Every install has one device
/// row"). Natural key: `installId`. Winner: later `changedAt`.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Device {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var installId: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var joinedDay: String = ""
    @Attribute(.allowsCloudEncryption) public var lastSeenDay: String = ""
    @Attribute(.allowsCloudEncryption) public var leftAt: Date?
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), installId: UUID, joinedDay: String, lastSeenDay: String = "", leftAt: Date? = nil, changedAt: Date) {
        self.id = id
        self.installId = installId
        self.joinedDay = joinedDay
        self.lastSeenDay = lastSeenDay
        self.leftAt = leftAt
        self.changedAt = changedAt
    }
}
