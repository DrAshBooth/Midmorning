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
    public func add(time: Date, what: String, feltLikeABinge: Bool, createdAt: Date, utcOffsetSeconds: Int, dayStartHour: Int = RecordDay.startHour) throws -> Entry {
        let minute = Self.truncatedToMinute(time)
        let entry = Entry(
            id: UUID(),
            time: minute,
            utcOffsetSeconds: utcOffsetSeconds,
            what: what.trimmingCharacters(in: .whitespacesAndNewlines),
            feltLikeABinge: feltLikeABinge,
            createdAt: createdAt,
            dayKey: RecordDay.key(for: minute, utcOffsetSeconds: utcOffsetSeconds, startHour: dayStartHour)
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

    /// The entries of the record day that contains `moment` in the calendar's
    /// zone, ordered by time, then by creation moment. An entry's day was fixed
    /// at save, so this matches by key, never by recomputing the entry's day.
    public func entries(recordDayContaining moment: Date, calendar: Calendar, dayStartHour: Int = RecordDay.startHour) throws -> [Entry] {
        try entries(dayKey: RecordDay.key(containing: moment, calendar: calendar, startHour: dayStartHour))
    }

    /// The entries of one record day, ordered by time, then by creation moment.
    public func entries(dayKey: String) throws -> [Entry] {
        var descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.dayKey == dayKey },
            sortBy: [SortDescriptor(\.time), SortDescriptor(\.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor)
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}
