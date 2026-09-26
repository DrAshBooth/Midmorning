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

    /// The day that the next-day control (`delta` 1) or the previous-day
    /// control (`delta` -1) opens from `dayKey`, or `nil` when that day is
    /// not in `list`. The earlier-day screen stays inside the "Earlier days"
    /// range: from the day before the previous record day, the next-day
    /// control opens nothing, because Today shows the previous and the
    /// current record day, and "Today" goes there (mm-t12b.24).
    public static func step(from dayKey: String, by delta: Int, in list: [String]) -> String? {
        guard let day = date(fromKey: dayKey),
              let target = keyCalendar.date(byAdding: .day, value: delta, to: day)
        else { return nil }
        let targetKey = key(from: target)
        return list.contains(targetKey) ? targetKey : nil
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

extension RecordStore {
    /// The "Earlier days" list at `now` in `calendar`'s zone, under the
    /// "Day starts at" rows in force: the list screen shows it, and the
    /// earlier-day screen moves only inside it.
    public func earlierDayKeys(now: Date, calendar: Calendar) throws -> [String] {
        let schedule = try dayStartSchedule()
        let current = RecordDay.interval(containing: now, calendar: calendar, schedule: schedule)
        let previous = RecordDay.previous(current, calendar: calendar, schedule: schedule)
        let previousKey = RecordDay.key(containing: previous.start, calendar: calendar, schedule: schedule)
        return EarlierDays.list(dateKeysWithContent: try dateKeysWithContent(before: previousKey), previousRecordDayKey: previousKey)
    }
}
