import Foundation

/// Which template applies to a record day, and the copy a record day's plan
/// starts as (regular-eating-plan spec, "Weekday and weekend templates").
/// Checking whether a `Day` row already exists, and writing the new one with
/// no `changedAt`, is the store's job (`RecordStore.materialiseDayFromTemplate`);
/// this holds the pure part.
public enum Materialisation {
    /// "weekday" for a record day starting Monday to Friday, "weekend" for
    /// Saturday or Sunday. `weekday` is `Calendar.Component.weekday`: 1 is
    /// Sunday, 7 is Saturday.
    public static func templateKind(forRecordDayStartingOnWeekday weekday: Int) -> String {
        (weekday == 1 || weekday == 7) ? "weekend" : "weekday"
    }

    /// "weekday" or "weekend" for the record day keyed `dateKey`
    /// ("2026-09-26"), or `nil` for a malformed key. A record day key is the
    /// calendar date on which the record day starts, so the weekday comes
    /// from the key alone. The time zone of the device does not change it.
    public static func templateKind(forDateKey dateKey: String) -> String? {
        guard let date = keyDate(dateKey) else { return nil }
        return templateKind(forRecordDayStartingOnWeekday: keyCalendar.component(.weekday, from: date))
    }

    /// The keys from `firstKey` to `lastKey`, both included, in date order.
    /// Empty when `firstKey` is after `lastKey` or a key is malformed.
    /// Materialisation walks these keys to find each elapsed record day
    /// that has no `Day` row (regular-eating-plan spec, "Weekday and
    /// weekend templates": "for every record day that started since the
    /// last copy").
    public static func dateKeys(from firstKey: String, through lastKey: String) -> [String] {
        guard var date = keyDate(firstKey), let last = keyDate(lastKey) else { return [] }
        var keys: [String] = []
        while date <= last {
            keys.append(key(for: date))
            guard let next = keyCalendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return keys
    }

    /// The key of the record day after the one keyed `dateKey`, or `nil`
    /// for a malformed key.
    public static func nextDateKey(after dateKey: String) -> String? {
        guard let date = keyDate(dateKey), let next = keyCalendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        return key(for: next)
    }

    /// Gregorian, in GMT. A key's date is noon on its calendar date, so no
    /// clock change and no time zone can move it to another date.
    private static let keyCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "GMT")!
        return calendar
    }()

    /// The year, month and day of `dateKey` ("2026-09-26"), or `nil` for a
    /// malformed key.
    public static func calendarDate(ofDateKey dateKey: String) -> (year: Int, month: Int, day: Int)? {
        let parts = dateKey.split(separator: "-")
        guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        return (year, month, day)
    }

    private static func keyDate(_ dateKey: String) -> Date? {
        guard let (year, month, day) = calendarDate(ofDateKey: dateKey) else { return nil }
        return keyCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    private static func key(for date: Date) -> String {
        let c = keyCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
