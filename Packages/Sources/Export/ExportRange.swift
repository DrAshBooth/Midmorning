import Foundation

/// The export screen's date-range rules (export spec, "Choose a date
/// range"), pure over record day keys so a test drives them with fixed
/// keys, no live clock.
public enum ExportRange {
    /// export spec: "'From' MUST default to 27 days before the current
    /// record day. When the earliest record day with an entry is later,
    /// 'From' MUST default to that day. 'To' MUST default to the current
    /// record day."
    public static func defaultRange(currentDayKey: String, earliestEntryDayKey: String?) -> (from: String, to: String) {
        let candidateFrom = ExportDayKey.adding(-27, to: currentDayKey)
        let from: String
        if let earliest = earliestEntryDayKey, earliest > candidateFrom {
            from = earliest
        } else {
            from = candidateFrom
        }
        return (from: from, to: currentDayKey)
    }

    /// export spec: "'To' MUST NOT be after the current record day." and
    /// "'From' MUST NOT be after 'To'." The screen's own "To" control never
    /// offers a date later than `currentDayKey`; this checks a candidate
    /// "From" against a chosen "To".
    public static func isFromAllowed(candidateFromDayKey: String, toDayKey: String) -> Bool {
        candidateFromDayKey <= toDayKey
    }

    public static func isToAllowed(candidateToDayKey: String, currentDayKey: String) -> Bool {
        candidateToDayKey <= currentDayKey
    }
}
