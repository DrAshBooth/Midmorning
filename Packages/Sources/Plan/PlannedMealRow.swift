import Foundation

/// What a planned meal row shows beside the record (regular-eating-plan
/// spec, "Today shows the plan beside the record"). A pure decision from
/// already-resolved facts: whether an entry matches, or the answer is
/// "Skipped". The row's own visual layout is the app target's job; this is
/// the seam a test can drive with fixed inputs.
public enum PlannedMealDisplay: Sendable, Equatable {
    /// The window has not ended and no entry matches: the row shows the slot
    /// and the time only.
    case pending
    /// No matched entry, and the answer is "Skipped".
    case skipped
    /// A matched entry: its time, What, star and Where show beside the slot,
    /// and its Context shows under the What, the same way an entry row
    /// shows them (record spec, "Today shows Where and Context";
    /// mm-t23.20). A skipped answer, if any, MUST NOT show — the entry
    /// always wins (data-and-privacy spec, "Conflict rules for the plan,
    /// weigh-ins and lists": "readers MUST show the entry").
    case matched(MatchedEntryText)

    public static func content(matchedEntry: MatchedEntryText?, isSkipped: Bool) -> PlannedMealDisplay {
        if let matchedEntry { return .matched(matchedEntry) }
        if isSkipped { return .skipped }
        return .pending
    }
}

/// The text of the entry that a planned meal row shows beside the slot.
public struct MatchedEntryText: Sendable, Equatable {
    /// The entry's time, "HH:mm".
    public let time: String
    public let what: String
    /// Empty when the entry has no Where.
    public let whereText: String
    /// Empty when the entry has no Context.
    public let context: String
    public let starred: Bool

    public init(time: String, what: String, whereText: String = "", context: String = "", starred: Bool = false) {
        self.time = time
        self.what = what
        self.whereText = whereText
        self.context = context
        self.starred = starred
    }
}

/// The planned meal row's VoiceOver label (regular-eating-plan spec,
/// "Accessibility of the plan"): the slot label, then the planned time, then
/// the matched entry's own label or "Skipped", then the missed planned meal
/// prompt's text when it shows on this row.
public enum PlannedMealAccessibility {
    public static func label(
        slotLabel: String,
        time: String,
        matchedEntryAccessibilityLabel: String?,
        isSkipped: Bool,
        prompt: MissedMealPrompt.Form?,
        timeText: (Date) -> String
    ) -> String {
        var parts = [slotLabel, time]
        if let matchedEntryAccessibilityLabel {
            parts.append(matchedEntryAccessibilityLabel)
        } else if isSkipped {
            parts.append("Skipped")
        }
        if let prompt {
            parts.append(MissedMealPrompt.line(for: prompt, timeText: timeText))
        }
        return parts.joined(separator: ", ")
    }
}
