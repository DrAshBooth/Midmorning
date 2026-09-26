import Foundation

/// "When do you want to start?" (onboarding spec, "Screen 3: the start
/// day"). "Today" is the record day containing `now`; "Tomorrow" is the
/// record day right after it, both computed with `RecordDay` so a day
/// starting after midnight (the "After midnight" scenario) reads correctly.
public enum StartDayChoice {
    public enum Choice: Sendable, Equatable {
        case today, tomorrow
    }

    /// The record-day key ("2026-09-24") the store keeps for a choice.
    public static func dayKey(for choice: Choice, now: Date, calendar: Calendar, schedule: DayStartSchedule) -> String {
        switch choice {
        case .today:
            return RecordDay.key(containing: now, calendar: calendar, schedule: schedule)
        case .tomorrow:
            return RecordDay.nextDayKey(after: now, calendar: calendar, schedule: schedule)
        }
    }

    /// "Today, %@" / "Tomorrow, %@", with the date from the en_GB formatter,
    /// for example "Today, Thursday 24 September".
    public static func label(for choice: Choice, now: Date, calendar: Calendar, schedule: DayStartSchedule) -> String {
        let key = dayKey(for: choice, now: now, calendar: calendar, schedule: schedule)
        let formatted = formattedDate(fromDayKey: key, calendar: calendar)
        switch choice {
        case .today: return "Today, \(formatted)"
        case .tomorrow: return "Tomorrow, \(formatted)"
        }
    }

    private static func formattedDate(fromDayKey key: String, calendar: Calendar) -> String {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return key }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        guard let date = calendar.date(from: components) else { return key }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }
}

/// "A day runs from %1$@ to %2$@." (onboarding spec, "Screen 3: the record
/// in three sentences"), filled from the day-start hour in force, on the
/// 24-hour clock.
public enum DayBoundaryLine {
    public static func text(startHour: Int) -> String {
        let endHour = (startHour + 23) % 24
        return "A day runs from \(Self.clock(startHour)) to \(Self.clock(endHour, minute: 59))."
    }

    private static func clock(_ hour: Int, minute: Int = 0) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}
