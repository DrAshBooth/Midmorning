import Foundation
import SwiftData

/// The only way to create and read entries.
@MainActor
public final class RecordStore {
    /// Thrown by the store. Carries no entry data.
    public enum Failure: Error {
        case saveFailed
    }

    public let container: ModelContainer
    private let context: ModelContext

    /// Opens the store on `url`. Sync is off: `cloudKitDatabase` is `.none`.
    public init(url: URL) throws {
        let configuration = ModelConfiguration(url: url, cloudKitDatabase: .none)
        container = try ModelContainer(for: Entry.self, configurations: configuration)
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    /// Saves one entry and returns it. Trims white space and line breaks from
    /// the ends of `what`. Truncates `time` to the minute. Throws on failure
    /// with no entry data in the error.
    @discardableResult
    public func add(time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int) throws -> Entry {
        let entry = Entry(
            id: UUID(),
            time: Self.truncatedToMinute(time),
            utcOffsetSeconds: utcOffsetSeconds,
            what: what.trimmingCharacters(in: .whitespacesAndNewlines),
            feltLikeABinge: feltLikeABinge,
            createdAt: createdAt
        )
        context.insert(entry)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
        return entry
    }

    /// The entries in the record day that contains `moment`, ordered by time,
    /// then by creation moment.
    public func entries(recordDayContaining moment: Date, calendar: Calendar) throws -> [Entry] {
        try entries(in: RecordDay.interval(containing: moment, calendar: calendar))
    }

    /// The entries whose time is in `interval`, ordered by time, then by
    /// creation moment.
    public func entries(in interval: DateInterval) throws -> [Entry] {
        let start = interval.start
        let end = interval.end
        var descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.time >= start && $0.time < end },
            sortBy: [SortDescriptor(\.time), SortDescriptor(\.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor)
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}
