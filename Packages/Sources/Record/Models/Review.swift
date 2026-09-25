import Foundation
import SwiftData

/// A weekly review or a check-in, told apart by `kind`. Natural key: the due
/// day's `dateKey` — never a week number, so a restart's second run keeps its
/// own row (data-and-privacy spec, "Day states, sessions and reviews").
/// Winner: earliest freeze moment; a later edit writes into that row. The
/// store keeps only `selfHarmAnswered`, never the self-harm answer itself
/// (data-and-privacy spec, "Retention").
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Review {
    public var id: UUID = UUID()
    /// "weeklyReview" or "checkIn".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    @Attribute(.allowsCloudEncryption) public var dueDateKey: String = ""
    /// Set once, the first time a device's last sync moment passes the due
    /// moment. Never cleared.
    @Attribute(.allowsCloudEncryption) public var frozenAt: Date?
    /// Owned by `weekly-review` (3.2) and `staying-on-track` (3.6).
    @Attribute(.allowsCloudEncryption) public var answersJSON: String = "{}"
    @Attribute(.allowsCloudEncryption) public var selfHarmAnswered: Bool = false
    @Attribute(.allowsCloudEncryption) public var pinnedNote: String = ""
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        kind: String,
        dueDateKey: String,
        frozenAt: Date? = nil,
        answersJSON: String = "{}",
        selfHarmAnswered: Bool = false,
        pinnedNote: String = "",
        changedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.dueDateKey = dueDateKey
        self.frozenAt = frozenAt
        self.answersJSON = answersJSON
        self.selfHarmAnswered = selfHarmAnswered
        self.pinnedNote = pinnedNote
        self.changedAt = changedAt
    }
}
