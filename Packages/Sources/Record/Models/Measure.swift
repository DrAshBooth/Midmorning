import Foundation
import SwiftData

/// A weigh-in. Natural key: the weigh-in day's `dateKey`. Winner: later
/// `changedAt`, whole row; the store never averages two versions
/// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and
/// lists"). `WeighIn` is the readable typealias.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Measure {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var dateKey: String = ""
    @Attribute(.allowsCloudEncryption) public var weightKg: Double = 0
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), dateKey: String, weightKg: Double, changedAt: Date) {
        self.id = id
        self.dateKey = dateKey
        self.weightKg = weightKg
        self.changedAt = changedAt
    }
}

/// Readable typealias for the neutral model name `Measure`.
public typealias WeighIn = Measure
