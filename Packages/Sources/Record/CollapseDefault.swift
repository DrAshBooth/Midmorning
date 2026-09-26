import Foundation

/// A record day's role in Today's list, for the default collapse-or-expand
/// state (record spec, "Collapse a day to a count").
public enum RecordDayRole: Sendable {
    case current, previous, earlier
}

/// The default-and-kept collapse-or-expand rule: the current day defaults
/// expanded, the previous day defaults collapsed, a day before that defaults
/// expanded; a kept choice always wins over the default.
public enum CollapseDefault {
    public static func isExpanded(role: RecordDayRole, kept: CollapseChoiceValue?) -> Bool {
        if let kept { return kept == .expanded }
        return role != .previous
    }

    /// The choice to keep after the person saves an entry into a day
    /// (record spec, "Collapse a day to a count": "When the person saves an
    /// entry into a collapsed day, the app MUST expand that day. The app
    /// MUST then keep the expanded state as the last choice"). Returns
    /// `.expanded` when the day shows collapsed, by default or by a kept
    /// choice, and `nil` when the day already shows expanded.
    public static func choiceAfterSave(role: RecordDayRole, kept: CollapseChoiceValue?) -> CollapseChoiceValue? {
        isExpanded(role: role, kept: kept) ? nil : .expanded
    }
}
