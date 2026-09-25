import Foundation

/// The new-entry and edit screens' control order (record spec, "The
/// new-entry screen's controls"; "Accessibility of the additions"). The view
/// iterates this array to lay the controls out, so the visual order can
/// never drift from the tested order.
public enum NewEntryField: Sendable, CaseIterable {
    case what, whereField, star, context, time

    /// What, Where, "felt like a binge", Context, Time — the new-entry
    /// screen's order from the top, and the reading order VoiceOver follows.
    public static let order: [NewEntryField] = [.what, .whereField, .star, .context, .time]
}

/// The Context field's label, which the star toggles (record spec, "The
/// Context field").
public enum ContextLabel {
    public static func text(starOn: Bool) -> String {
        starOn ? "What was going on just before?" : "Context"
    }
}

/// A second tap on the selected Where chip clears it; any other tap selects
/// the tapped chip (record spec, "Where chips": "A second tap on the
/// selected chip MUST clear the Where").
public enum WhereSelection {
    public static func afterTap(current: String?, tapped: String) -> String? {
        current == tapped ? nil : tapped
    }
}

/// Resolves the new-entry and edit screens' time wheel against the selected
/// segment's own calendar date (record spec, "The new-entry screen's
/// controls"): a time before the day start sits on the calendar date after
/// the segment's date, not on the segment's own date.
public enum NewEntryTime {
    /// - Parameters:
    ///   - segmentDate: Midnight of the selected segment's own calendar
    ///     date, in `calendar`.
    ///   - hour: The wheel's chosen hour (24-hour clock).
    ///   - minute: The wheel's chosen minute.
    public static func resolve(segmentDate: Date, hour: Int, minute: Int, dayStartHour: Int, calendar: Calendar) -> Date {
        let baseDate = hour < dayStartHour
            ? calendar.date(byAdding: .day, value: 1, to: segmentDate)!
            : segmentDate
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)!
    }
}
