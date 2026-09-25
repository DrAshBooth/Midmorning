import Foundation
import SwiftData

/// One row per record day and state kind: paused, didn't record, fasting, or
/// the feeling word (data-and-privacy spec, "Day states, sessions and
/// reviews"). Natural key: `dateKey` + `kind`. Winner: later `changedAt`.
/// The collapse-or-expand choice is not a `DayState`; it lives in
/// `Local.store` by date key.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class DayState {
    public var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) public var dateKey: String = ""
    /// One of "paused", "didntRecord", "fasting", "feelingWord".
    @Attribute(.allowsCloudEncryption) public var kind: String = ""
    /// The feeling word, when `kind` is "feelingWord". Empty otherwise.
    @Attribute(.allowsCloudEncryption) public var value: String = ""
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = UUID(), dateKey: String, kind: String, value: String = "", changedAt: Date) {
        self.id = id
        self.dateKey = dateKey
        self.kind = kind
        self.value = value
        self.changedAt = changedAt
    }
}
