import Foundation
import SwiftData

/// An urge. Each device's session keeps its own id; readers treat the
/// earliest-started session of a record day as the open one and close every
/// other one silently at the day end (data-and-privacy spec, "Day states,
/// sessions and reviews"). `Urge` is the readable typealias.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Session {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var startedAt: Date = Date()
    @Attribute(.allowsCloudEncryption) public var startDayKey: String = ""
    /// Empty while open. `urge-toolkit` (3.1) owns the outcome vocabulary.
    @Attribute(.allowsCloudEncryption) public var outcome: String = ""
    @Attribute(.allowsCloudEncryption) public var outcomeAt: Date?
    @Attribute(.allowsCloudEncryption) public var outcomeDayKey: String = ""
    /// The entry the urge links to, when one exists. A key field, not a
    /// relationship.
    @Attribute(.allowsCloudEncryption) public var entryId: UUID?

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        startDayKey: String,
        outcome: String = "",
        outcomeAt: Date? = nil,
        outcomeDayKey: String = "",
        entryId: UUID? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.startDayKey = startDayKey
        self.outcome = outcome
        self.outcomeAt = outcomeAt
        self.outcomeDayKey = outcomeDayKey
        self.entryId = entryId
    }
}

/// Readable typealias for the neutral model name `Session`.
public typealias Urge = Session
