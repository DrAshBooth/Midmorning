import Foundation

/// Record-day key arithmetic and formatting, self-contained here (like
/// `Programme`'s own `DayKeyMath`) because a key never carries a time zone
/// and compares correctly as a plain string. Every date shown in the export
/// is en-GB, per product-rules "Dates and times in strings". Public: the app
/// target reuses `dayHeading` for the weigh-in page's own dates, so there is
/// one weekday-date-year formatter, not two.
public enum ExportDayKey {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midnight GMT of the calendar date `key` names. The app target uses
    /// this to give a `DatePicker` a `Date` for a day key; only the
    /// calendar-date components matter, never the time.
    public static func date(_ key: String) -> Date? {
        let pieces = key.split(separator: "-")
        guard pieces.count == 3, let y = Int(pieces[0]), let m = Int(pieces[1]), let d = Int(pieces[2]) else { return nil }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }

    public static func key(from date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// `key` plus `days` whole calendar days.
    public static func adding(_ days: Int, to key: String) -> String {
        guard let base = date(key), let moved = calendar.date(byAdding: .day, value: days, to: base) else { return key }
        return self.key(from: moved)
    }

    /// Every key from `from` to `to`, inclusive, in order. Empty when `to`
    /// is before `from`.
    public static func range(from: String, to: String) -> [String] {
        guard from <= to else { return [] }
        var keys: [String] = []
        var current = from
        while current <= to {
            keys.append(current)
            current = adding(1, to: current)
        }
        return keys
    }

    /// "Thursday 24 September 2026" (export spec, "The PDF is formatted like
    /// the paper record": "The heading MUST come from the en_GB formatter.").
    public static func dayHeading(_ key: String) -> String {
        guard let date = date(key) else { return key }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.dateFormat = "EEEE d MMMM y"
        return formatter.string(from: date)
    }

    /// "28 August – 24 September 2026", with the en_GB interval formatter's
    /// own thin spaces (U+2009) either side of the en dash (export spec,
    /// "The PDF is formatted like the paper record").
    public static func rangeText(from: String, to: String) -> String {
        guard let fromDate = date(from), let toDate = date(to) else { return "" }
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.dateTemplate = "d MMMM y"
        return formatter.string(from: fromDate, to: toDate)
    }
}
