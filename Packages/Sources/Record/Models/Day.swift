import Foundation
import SwiftData

/// A planned day: `dateKey`, the plan payload, the planned-meal window
/// constants in force at materialisation, and the sticky "set" event
/// (`setAt`, `setBy`). Natural key: `dateKey`. Winner: later `changedAt` for
/// the plan payload; "set" is sticky and never reverts once written
/// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and lists").
/// `regular-eating-plan` (2.3) owns the slot payload shape; `slotsJSON` is an
/// opaque, additively-grown store for it.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Day {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var dateKey: String = ""
    @Attribute(.allowsCloudEncryption) public var slotsJSON: String = "[]"
    /// The planned-meal window constants in force when this row was
    /// materialised. A later constants change never moves an existing row.
    @Attribute(.allowsCloudEncryption) public var windowBeforeMinutes: Int = 60
    @Attribute(.allowsCloudEncryption) public var windowAfterMinutes: Int = 90
    /// `changedAt` of the plan payload. Materialisation never writes this
    /// (data-and-privacy spec, "Materialisation MUST NOT write `changedAt`
    /// on a Day row").
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()
    /// Sticky: once set, a later sync never clears it.
    @Attribute(.allowsCloudEncryption) public var setAt: Date?
    @Attribute(.allowsCloudEncryption) public var setBy: String = ""

    public init(
        id: UUID = UUID(),
        dateKey: String,
        slotsJSON: String = "[]",
        windowBeforeMinutes: Int = 60,
        windowAfterMinutes: Int = 90,
        changedAt: Date,
        setAt: Date? = nil,
        setBy: String = ""
    ) {
        self.id = id
        self.dateKey = dateKey
        self.slotsJSON = slotsJSON
        self.windowBeforeMinutes = windowBeforeMinutes
        self.windowAfterMinutes = windowAfterMinutes
        self.changedAt = changedAt
        self.setAt = setAt
        self.setBy = setBy
    }
}
