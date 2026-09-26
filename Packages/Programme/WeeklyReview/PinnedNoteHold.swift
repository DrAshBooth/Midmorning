import Foundation

/// Whether Today MUST hold back the pinned note because of a starred entry
/// or an "I binged" urge outcome in the current record day (weekly-review
/// spec, "The one thing to change and the pinned note", decision 90).
/// `TodayCardSlot.next` calls this same predicate for the card slot
/// (programme spec, "No opening card after a binge in the same record
/// day"): "One predicate can serve the card hold and the pinned note hold."
public enum PinnedNoteHold {
    public static func isHeld(starredEntryOrOutcomeAt: Date?, currentRecordDay: DateInterval) -> Bool {
        starredEntryOrOutcomeAt.map(currentRecordDay.contains) ?? false
    }
}
