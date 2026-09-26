import Foundation

/// The ids of Today's rows (record spec, "Save is quiet": "Today MUST scroll
/// so that the saved entry is on screen"). A day section merges its
/// unmatched entries and its planned meal rows into one column
/// (regular-eating-plan spec, "Today shows the plan beside the record"), so
/// an entry that matches a planned meal shows on that planned meal's row,
/// not on a row of its own.
public enum TodayRowId {
    /// The id of an entry's own row inside its day section.
    public static func entry(_ entryId: UUID) -> String { "entry-\(entryId.uuidString)" }

    /// The id of a planned meal row inside its day section.
    public static func planned(slotIndex: Int) -> String { "planned-\(slotIndex)" }

    /// The row's id across the whole of Today. Two days can each have a
    /// planned meal row for the same slot, so the day's key comes first.
    public static func scrollId(dateKey: String, rowId: String) -> String { "\(dateKey)/\(rowId)" }

    /// The row to scroll to after a save: the planned meal row that the
    /// saved entry matches, or else the entry's own row.
    public static func scrollId(forEntry entryId: UUID, dateKey: String, matchedSlotIndex: Int?) -> String {
        scrollId(dateKey: dateKey, rowId: matchedSlotIndex.map { planned(slotIndex: $0) } ?? entry(entryId))
    }
}
