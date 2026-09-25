import Foundation
import SwiftData

/// One entry as Today reads it: the winning `ItemVersion` of one `Item`,
/// reduced to the fields a screen needs. Not a stored type; `RecordStore`
/// computes it with `EntryWinner` on every read (data-and-privacy spec,
/// "Entries are append-only versions").
public struct RecordRow: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let time: Date
    public let utcOffsetSeconds: Int
    public let what: String
    public let feltLikeABinge: Bool
    public let createdAt: Date
    public let dayKey: String

    public init(id: UUID, time: Date, utcOffsetSeconds: Int, what: String, feltLikeABinge: Bool, createdAt: Date, dayKey: String) {
        self.id = id
        self.time = time
        self.utcOffsetSeconds = utcOffsetSeconds
        self.what = what
        self.feltLikeABinge = feltLikeABinge
        self.createdAt = createdAt
        self.dayKey = dayKey
    }

    init(entryId: UUID, winner: ItemVersion) {
        self.init(
            id: entryId,
            time: winner.time,
            utcOffsetSeconds: winner.utcOffsetSeconds,
            what: winner.what,
            feltLikeABinge: winner.feltLikeABinge,
            createdAt: winner.createdAt,
            dayKey: winner.dayKey
        )
    }
}

public extension RecordRow {
    /// The entry's time as "HH:mm" at the entry's own UTC offset.
    var clockTime: String {
        RecordRow.clockTime(for: time, utcOffsetSeconds: utcOffsetSeconds)
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

/// The only way to create and read entries. Opens two store configurations
/// in one directory: `Record.store` syncs; `Local.store` never does
/// (data-and-privacy spec, "Two store configurations in one directory").
@MainActor
public final class RecordStore {
    /// Thrown by the store. Carries no entry data.
    public enum Failure: Error {
        case saveFailed
    }

    public let container: ModelContainer
    /// Not `private`: `LocalSettingStore.swift`, in this same target, reads
    /// and writes `LocalSetting` rows through it.
    let context: ModelContext

    /// Opens the store from the two files in `directory`: `Record.store` and
    /// `Local.store`. Sync is off: both configurations carry
    /// `cloudKitDatabase: .none` (sync turns on in 4.1b, on CKSyncEngine, not
    /// SwiftData's own mirroring).
    public init(directory: URL) throws {
        let recordConfiguration = ModelConfiguration(
            "Record",
            schema: Schema(RecordSchema.models),
            url: directory.appendingPathComponent("Record.store"),
            cloudKitDatabase: .none
        )
        let localConfiguration = ModelConfiguration(
            "Local",
            schema: Schema(RecordSchema.localModels),
            url: directory.appendingPathComponent("Local.store"),
            cloudKitDatabase: .none
        )
        container = try ModelContainer(
            for: Schema(RecordSchema.models + RecordSchema.localModels),
            migrationPlan: RecordMigrationPlan.self,
            configurations: recordConfiguration, localConfiguration
        )
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    /// Opens the store on a single legacy file URL, for tests that predate
    /// the two-configuration split. Prefer `init(directory:)`.
    public convenience init(url: URL) throws {
        try self.init(directory: url.deletingLastPathComponent())
    }

    /// Saves one entry as a new `Item` and its first `ItemVersion`, and
    /// returns the row. Trims white space and line breaks from the ends of
    /// `what`. Truncates `time` to the minute. Throws on failure with no
    /// entry data in the error.
    @discardableResult
    public func add(time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int, dayStartHour: Int = RecordDay.startHour) throws -> RecordRow {
        let minute = Self.truncatedToMinute(time)
        let entryId = UUID()
        let item = Item(id: entryId)
        let version = ItemVersion(
            entryId: entryId,
            changedAt: createdAt,
            dayKey: RecordDay.key(for: minute, utcOffsetSeconds: utcOffsetSeconds, startHour: dayStartHour),
            time: minute,
            utcOffsetSeconds: utcOffsetSeconds,
            what: what.trimmingCharacters(in: .whitespacesAndNewlines),
            feltLikeABinge: feltLikeABinge,
            createdAt: createdAt
        )
        context.insert(item)
        context.insert(version)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
        return RecordRow(entryId: entryId, winner: version)
    }

    /// The winning row per entry id of the record day that contains `moment`
    /// in the calendar's zone, ordered by time, then by creation moment. An
    /// entry's day was fixed at save, so this matches by key, never by
    /// recomputing the entry's day.
    public func entries(recordDayContaining moment: Date, calendar: Calendar, dayStartHour: Int = RecordDay.startHour) throws -> [RecordRow] {
        try entries(dayKey: RecordDay.key(containing: moment, calendar: calendar, startHour: dayStartHour))
    }

    /// The winning, non-deleted row per entry id whose winning version keys
    /// to `dayKey`, ordered by time, then by creation moment.
    public func entries(dayKey: String) throws -> [RecordRow] {
        var descriptor = FetchDescriptor<ItemVersion>(predicate: #Predicate { $0.dayKey == dayKey })
        descriptor.includePendingChanges = false
        let versions = try context.fetch(descriptor)
        let winners = EntryWinner.winners(in: versions)
        return winners
            .filter { !$0.value.deleted }
            .map { RecordRow(entryId: $0.key, winner: $0.value) }
            .sorted { lhs, rhs in
                if lhs.time != rhs.time { return lhs.time < rhs.time }
                return lhs.createdAt < rhs.createdAt
            }
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}

/// The store directory inside the app's own `Application Support` directory
/// — never inside the App Group container (data-and-privacy spec, "The
/// store lives in the app's own container"). The App target's own
/// `StoreLocation.url()` builds this same path against the real sandbox;
/// this is the pure, non-isolated form a test can check with a fixed URL.
public enum StoreLayout {
    public static func storeDirectory(applicationSupportDirectory: URL) -> URL {
        applicationSupportDirectory.appendingPathComponent("Record", isDirectory: true)
    }
}

/// What the App Group container holds: only the widget snapshot and the
/// action queue, never the store (data-and-privacy spec, "The store lives in
/// the app's own container": "App Group content"). `widgets-and-intents`
/// (2.5) names the real files; this records the shape now so the store never
/// grows into the App Group by accident.
public enum AppGroupContent {
    public static let fileStems: Set<String> = ["snapshot", "queue"]
}
