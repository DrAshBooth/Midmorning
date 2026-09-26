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
