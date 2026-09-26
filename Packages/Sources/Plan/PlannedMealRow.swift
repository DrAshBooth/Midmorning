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
    /// A matched entry: its time and What show beside the slot. A skipped
    /// answer, if any, MUST NOT show — the entry always wins
    /// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and
    /// lists": "readers MUST show the entry").
    case matched(entryTime: String, what: String)

    public static func content(matchedEntry: (time: String, what: String)?, isSkipped: Bool) -> PlannedMealDisplay {
        if let matchedEntry { return .matched(entryTime: matchedEntry.time, what: matchedEntry.what) }
        if isSkipped { return .skipped }
        return .pending
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
