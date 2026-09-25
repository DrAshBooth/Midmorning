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
}
