import Foundation

/// Record-day key arithmetic. A key ("2026-09-24") never carries a time
/// zone and sorts correctly as a plain string, so the engine compares and
/// counts keys as strings and reaches for `Calendar` only to add whole days
/// to a key or to find the wall-clock moment a key's record day starts
/// (`../../../openspec/changes/programme-engine/design.md`, "Why a day key
/// is a plain, comparable string").
enum DayKeyMath {
    struct Parts: Equatable {
        let year: Int
        let month: Int
        let day: Int
    }

    static func parts(_ key: String) -> Parts? {
        let pieces = key.split(separator: "-")
        guard pieces.count == 3, let y = Int(pieces[0]), let m = Int(pieces[1]), let d = Int(pieces[2]) else { return nil }
        return Parts(year: y, month: m, day: d)
    }

    /// Midnight, in `calendar`'s zone, of the calendar date `key` names.
    /// Used only for arithmetic between keys; never shown or written as a
    /// real moment.
    static func midnight(_ key: String, calendar: Calendar) -> Date? {
        guard let p = parts(key) else { return nil }
        var components = DateComponents()
        components.year = p.year
        components.month = p.month
        components.day = p.day
        return calendar.date(from: components)
    }

    static func key(from date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// `key` plus `days` whole calendar days. Negative `days` moves back.
    static func adding(_ days: Int, to key: String, calendar: Calendar) -> String {
        guard let base = midnight(key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: base) else { return key }
        return self.key(from: moved, calendar: calendar)
    }

    /// The number of whole days from `a` to `b` (`b` minus `a`); negative
    /// when `b` is earlier.
    static func daysBetween(_ a: String, _ b: String, calendar: Calendar) -> Int {
        guard let da = midnight(a, calendar: calendar), let db = midnight(b, calendar: calendar) else { return 0 }
        return calendar.dateComponents([.day], from: da, to: db).day ?? 0
    }

    /// The wall-clock moment `key`'s record day begins, at `dayStart` hour.
    static func dayStartMoment(for key: String, dayStart: Int, calendar: Calendar) -> Date {
        guard let midnight = midnight(key, calendar: calendar) else { return .distantPast }
        return calendar.date(byAdding: .hour, value: dayStart, to: midnight) ?? midnight
    }

    /// The wall-clock moment right after `key`'s record day ends: the day
    /// start of the next calendar day (`v1-programme/design.md`, "the day
    /// start that ended the gate").
    static func nextDayStartMoment(after key: String, dayStart: Int, calendar: Calendar) -> Date {
        dayStartMoment(for: adding(1, to: key, calendar: calendar), dayStart: dayStart, calendar: calendar)
    }

    /// Whether `a` is chronologically before `b`. Plain string comparison
    /// works because the key format is a zero-padded ISO date.
    static func isBefore(_ a: String, _ b: String) -> Bool { a < b }

    /// The record-day key that contains `moment`, given `dayStart` and
    /// `calendar` (mirrors `Record`'s `RecordDay.key(containing:calendar:
    /// startHour:)`, self-contained here because `Programme` does not import
    /// `Record`). A moment before the calendar date's own day start belongs
    /// to the previous calendar date's record day.
    static func recordDayKey(containing moment: Date, dayStart: Int, calendar: Calendar) -> String {
        let calendarDateKey = key(from: moment, calendar: calendar)
        let startOfCalendarDate = dayStartMoment(for: calendarDateKey, dayStart: dayStart, calendar: calendar)
        return moment >= startOfCalendarDate ? calendarDateKey : adding(-1, to: calendarDateKey, calendar: calendar)
    }
}
