import Foundation

/// The Where control's four fixed chips (record spec, "Where chips").
public enum WhereChip: String, CaseIterable, Sendable {
    case home = "Home"
    case work = "Work"
    case out = "Out"
    case travelling = "Travelling"

    public static let fixed: [WhereChip] = [.home, .work, .out, .travelling]
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
