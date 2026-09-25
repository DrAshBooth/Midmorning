import Foundation
import SwiftData

/// One row per settings key (data-and-privacy spec, "Slot labels and the day
/// start are Settings rows"). Natural key: `key`. Winner: later `changedAt`,
/// whole row. Slot labels are the six keys `slot.label.<index>`; the day
/// start is append-only rows, each holding an hour and the day key it takes
/// effect from.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Settings {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var key: String = ""
    @Attribute(.allowsCloudEncryption) public var value: String = ""
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), key: String, value: String, changedAt: Date) {
        self.id = id
        self.key = key
        self.value = value
        self.changedAt = changedAt
    }

    /// The `Settings` key for a slot label, `slot.label.<index>`.
    public static func slotLabelKey(_ index: Int) -> String { "slot.label.\(index)" }
}

/// One append-only day-start row: an hour and the day key it takes effect
/// from. Every device applies the row from that key (data-and-privacy spec,
/// "Slot labels and the day start are Settings rows"). Not itself one of the
/// sixteen neutral models — it is a `Settings` row shape, encoded as one
/// `Settings` row per `effectiveFromDayKey` with `key == "dayStart.<dayKey>"`.
public enum DayStartSetting {
    public static func key(effectiveFromDayKey dayKey: String) -> String { "dayStart.\(dayKey)" }
}
