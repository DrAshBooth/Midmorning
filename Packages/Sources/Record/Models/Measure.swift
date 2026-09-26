import Foundation
import SwiftData

/// A weigh-in. Natural key: the weigh-in day's `dateKey`. Winner: later
/// `changedAt`, whole row; the store never averages two versions
/// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and
/// lists"). `WeighIn` is the readable typealias.
///
/// `unit` and `savedAt` are additive fields `weigh-in` (2.2) adds to
/// model-foundation's row (weigh-in spec, "The store keeps the weigh-in on
/// the device and away from HealthKit": "The row holds its record day key,
/// its kilogram value, its unit, its `savedAt` and its `changedAt`.").
/// `savedAt` is the first save's own moment and never changes; a later edit
/// of the same record day keeps `savedAt` and writes only a new `changedAt`
/// (`RecordStore.saveWeighIn`).
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Measure {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var dateKey: String = ""
    @Attribute(.allowsCloudEncryption) public var weightKg: Double = 0
    @Attribute(.allowsCloudEncryption) public var unit: String = "kg"
    @Attribute(.allowsCloudEncryption) public var savedAt: Date = Date()
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), dateKey: String, weightKg: Double, unit: String = "kg", savedAt: Date? = nil, changedAt: Date) {
        self.id = id
        self.dateKey = dateKey
        self.weightKg = weightKg
        self.unit = unit
        self.savedAt = savedAt ?? changedAt
        self.changedAt = changedAt
    }
}

/// Readable typealias for the neutral model name `Measure`.
public typealias WeighIn = Measure
