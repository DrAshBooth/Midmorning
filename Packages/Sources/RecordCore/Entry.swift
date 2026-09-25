import Foundation
import SwiftData

/// One entry in the record. `RecordStore.add` is the only way to create one.
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Entry {
    public var id: UUID = UUID()
    /// The moment the person set, to the minute.
    @Attribute(.allowsCloudEncryption) public var time: Date = Date()
    /// The device's UTC offset when the person saved.
    @Attribute(.allowsCloudEncryption) public var utcOffsetSeconds: Int = 0
    /// Free text. Can be empty.
    @Attribute(.allowsCloudEncryption) public var what: String = ""
    /// The "felt like a binge" star. The person's judgement, never the app's.
    @Attribute(.allowsCloudEncryption) public var feltLikeABinge: Bool = false
    /// The moment the app saved the entry. Never shown to the person.
    @Attribute(.allowsCloudEncryption) public var createdAt: Date = Date()
    /// The record day the entry belongs to, fixed at save from its own time,
    /// offset and the day start in force. Never changes after save.
    @Attribute(.allowsCloudEncryption) public var dayKey: String = ""

    init(id: UUID, time: Date, utcOffsetSeconds: Int, what: String, feltLikeABinge: Bool, createdAt: Date, dayKey: String) {
        self.id = id
        self.time = time
        self.utcOffsetSeconds = utcOffsetSeconds
        self.what = what
        self.feltLikeABinge = feltLikeABinge
        self.createdAt = createdAt
        self.dayKey = dayKey
    }
}

public extension Entry {
    /// The entry's time as "HH:mm" at the entry's own UTC offset.
    var clockTime: String {
        Entry.clockTime(for: time, utcOffsetSeconds: utcOffsetSeconds)
    }

    /// The VoiceOver label for the row: time, then What when not empty,
    /// then "felt like a binge" when the star is on.
    var accessibilityLabel: String {
        var parts = [clockTime]
        if !what.isEmpty { parts.append(what) }
        if feltLikeABinge { parts.append("felt like a binge") }
        return parts.joined(separator: ", ")
    }

    static func clockTime(for time: Date, utcOffsetSeconds: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}
