import Foundation

/// The "Earlier days" list (record spec, "Earlier record days"): every
/// record day before the previous record day that has an entry or a state,
/// most recent first. Date keys ("2026-09-24") compare lexicographically in
/// calendar order, so string comparison sorts them correctly.
public enum EarlierDays {
    public static func list(dateKeysWithContent: Set<String>, previousRecordDayKey: String) -> [String] {
        dateKeysWithContent.filter { $0 < previousRecordDayKey }.sorted(by: >)
    }

    /// Whether the current day heading's menu offers "Earlier days" at all.
    public static func isAvailable(dateKeysWithContent: Set<String>, previousRecordDayKey: String) -> Bool {
        !list(dateKeysWithContent: dateKeysWithContent, previousRecordDayKey: previousRecordDayKey).isEmpty
    }
}
