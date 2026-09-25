import Foundation
import SwiftData

/// Entry identity. `RecordStore.add` creates one `Item` together with the
/// entry's first `ItemVersion`. Winner: none — `Item` carries no content and
/// no conflict; every conflict lives in `ItemVersion`.
///
/// `Entry` is the readable typealias (data-and-privacy spec, "CKRecord types
/// and model names are neutral").
@Model
public final class Item {
    public var id: UUID = UUID()

    public init(id: UUID) {
        self.id = id
    }
}

/// Readable typealias for the neutral model name `Item` (data-and-privacy
/// spec, "Typealias in the code").
public typealias Entry = Item

/// One save, edit or delete of an entry (data-and-privacy spec, "Entries are
/// append-only versions"). The store never changes or deletes a row here
/// before the retention rule; it applies the conflict rule on read, with
/// `EntryWinner.pick`.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class ItemVersion {
    /// This version's own id (the tie-break of last resort).
    public var id: UUID = UUID()
    /// The entry this version belongs to. A key field, not a relationship
    /// (data-and-privacy spec, "Rows reference each other by key").
    @Attribute(.allowsCloudEncryption) public var entryId: UUID = UUID()
    /// The app-written change moment. The store never reads a CKRecord's
    /// system dates (data-and-privacy spec, "Every synced row carries its
    /// own change moment").
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()
    /// On when this version is a deletion. The row stays; nothing hard-deletes it.
    @Attribute(.allowsCloudEncryption) public var deleted: Bool = false
    /// The record day key, written once at save from the entry's own time,
    /// offset and the day start in force (data-and-privacy spec, "Date-keyed
    /// rows keep the key written at creation").
    @Attribute(.allowsCloudEncryption) public var dayKey: String = ""
    /// The moment the person set, to the minute.
    @Attribute(.allowsCloudEncryption) public var time: Date = Date()
    /// The device's UTC offset when the person saved.
    @Attribute(.allowsCloudEncryption) public var utcOffsetSeconds: Int = 0
    /// Free text. Can be empty.
    @Attribute(.allowsCloudEncryption) public var what: String = ""
    /// The "felt like a binge" star. The person's judgement, never the app's.
    @Attribute(.allowsCloudEncryption) public var feltLikeABinge: Bool = false
    /// The moment the app saved this version. Never shown to the person.
    @Attribute(.allowsCloudEncryption) public var createdAt: Date = Date()

    public init(
        id: UUID = UUID(),
        entryId: UUID,
        changedAt: Date,
        deleted: Bool = false,
        dayKey: String,
        time: Date,
        utcOffsetSeconds: Int,
        what: String,
        feltLikeABinge: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.entryId = entryId
        self.changedAt = changedAt
        self.deleted = deleted
        self.dayKey = dayKey
        self.time = time
        self.utcOffsetSeconds = utcOffsetSeconds
        self.what = what
        self.feltLikeABinge = feltLikeABinge
        self.createdAt = createdAt
    }
}

/// Readable typealias for the neutral model name `ItemVersion`.
public typealias EntryVersion = ItemVersion
