import Foundation
import Constants

/// The Where control's four fixed chips (record spec, "Where chips"). The
/// raw value is the Where an entry saves, a stored value; the chip shows
/// `label`, from the catalogue.
public enum WhereChip: String, CaseIterable, Sendable {
    case home = "Home"
    case work = "Work"
    case out = "Out"
    case travelling = "Travelling"

    public static let fixed: [WhereChip] = [.home, .work, .out, .travelling]

    /// The chip's text: "Home", "Work", "Out" or "Travelling".
    public var label: CatalogueText {
        switch self {
        case .home: return .key("entry.where.home")
        case .work: return .key("entry.where.work")
        case .out: return .key("entry.where.out")
        case .travelling: return .key("entry.where.travelling")
        }
    }
}

/// Orders the custom Where chips, most recently used first, capped at
/// `maxChips` (record spec, "Where chips": "at most eight custom chips,
/// most recently used first"). Two rows with the same text (a union from two
/// devices, or a stale row this device never deleted) collapse to the one
/// with the later `changedAt`.
public enum CustomPlaces {
    public static let maxChips = 8

    public static func ordered(_ rows: [ListItem]) -> [String] {
        var latestByText: [String: Date] = [:]
        for row in rows {
            if let existing = latestByText[row.text], existing >= row.changedAt { continue }
            latestByText[row.text] = row.changedAt
        }
        return latestByText
            .sorted { $0.value > $1.value }
            .prefix(maxChips)
            .map(\.key)
    }
}

/// The custom places that the person adds on the new-entry screen of a
/// pending route (the reminder "Add"). App-lock spec, "A new entry before
/// authentication", ruling r13-04 (mm-t15.19): on that screen, nothing
/// saves before Save. A custom place is a `ListItem` in `Record.store`,
/// which syncs, so the screen keeps each new place in memory only. After
/// Save succeeds, `RecordStore.touchCustomPlaces(_:)` keeps each place with
/// the moment the person added it. On a cancel or a failure of the request
/// at Save, and on "Cancel", the store gets no place.
public struct UnsavedPlaces: Equatable, Sendable {
    public struct Place: Equatable, Sendable {
        public let text: String
        public let addedAt: Date
    }

    /// The places, in the order the person added them.
    public private(set) var places: [Place] = []

    public init() {}

    /// Keeps `text` in memory, as `RecordStore.touchCustomPlace` keeps it in
    /// the store: an empty text or a fixed chip's text adds nothing, and a
    /// place that is here already gets the new moment.
    public mutating func add(_ text: String, at moment: Date) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !WhereChip.fixed.map(\.rawValue).contains(trimmed) else { return }
        places.removeAll { $0.text == trimmed }
        places.append(Place(text: trimmed, addedAt: moment))
    }

    /// The custom chips the screen shows: the places in memory, most recent
    /// first, then the saved custom places, capped at
    /// `CustomPlaces.maxChips` (record spec, "Where chips").
    public func chips(savedPlaces: [String]) -> [String] {
        let unsaved = places.reversed().map(\.text)
        let saved = savedPlaces.filter { !unsaved.contains($0) }
        return Array((unsaved + saved).prefix(CustomPlaces.maxChips))
    }
}
