import Foundation

/// The "Earlier days" list (record spec, "Earlier record days"): every
/// record day from the earliest record day with an entry or a state to the
/// day before the previous record day, most recent first. A day in that
/// range with no entry and no state is still a row. Date keys
/// ("2026-09-24") compare lexicographically in calendar order, so string
/// comparison sorts them correctly.
public enum EarlierDays {
    public static func list(dateKeysWithContent: Set<String>, previousRecordDayKey: String) -> [String] {
        guard let earliest = dateKeysWithContent.filter({ $0 < previousRecordDayKey }).min(),
              let first = date(fromKey: earliest),
              let previous = date(fromKey: previousRecordDayKey)
        else { return [] }
        var keys: [String] = []
        var day = first
        while day < previous {
            keys.append(key(from: day))
            guard let next = keyCalendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return keys.reversed()
    }

    /// Whether the current day heading's menu offers "Earlier days" at all.
    public static func isAvailable(dateKeysWithContent: Set<String>, previousRecordDayKey: String) -> Bool {
        dateKeysWithContent.contains { $0 < previousRecordDayKey }
    }

    /// A date key names a calendar date, not a moment, so the steps between
    /// keys use the Gregorian calendar at GMT, where every day has 24 hours.
    private static let keyCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return keyCalendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private static func key(from date: Date) -> String {
        let c = keyCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
