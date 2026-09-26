import Foundation
import Constants

/// The new-entry and edit screens' control order (record spec, "The
/// new-entry screen's controls"; "Accessibility of the additions"). The view
/// iterates this array to lay the controls out, so the visual order can
/// never drift from the tested order.
public enum NewEntryField: Sendable, CaseIterable {
    case what, whereField, star, context, time

    /// What, Where, "felt like a binge", Context, Time — the new-entry
    /// screen's order from the top, and the reading order VoiceOver follows.
    public static let order: [NewEntryField] = [.what, .whereField, .star, .context, .time]
}

/// The Context field's label, which the star toggles (record spec, "The
/// Context field"): "Context", or "What was going on just before?" while
/// the star is on.
public enum ContextLabel {
    public static func text(starOn: Bool) -> CatalogueText {
        .key(starOn ? "entry.context.starred" : "entry.context")
    }
}

/// A second tap on the selected Where chip clears it; any other tap selects
/// the tapped chip (record spec, "Where chips": "A second tap on the
/// selected chip MUST clear the Where").
public enum WhereSelection {
    public static func afterTap(current: String?, tapped: String) -> String? {
        current == tapped ? nil : tapped
    }

    /// The Where an entry saves with, and the custom place to keep. A place
    /// still typed in "Add a place" when the person taps Save wins over the
    /// selected chip (record spec, "Where chips", scenario "Add a custom
    /// place"). `pendingPlace` is `nil` when the field is closed.
    public static func onSave(selection: String?, pendingPlace: String?) -> (whereText: String, placeToKeep: String?) {
        let typed = (pendingPlace ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty { return (typed, typed) }
        return (selection ?? "", nil)
    }
}

/// Resolves the new-entry and edit screens' time wheel against the selected
/// segment's own calendar date (record spec, "The new-entry screen's
/// controls"): a time before the day start sits on the calendar date after
/// the segment's date, not on the segment's own date.
public enum NewEntryTime {
    /// - Parameters:
    ///   - segmentDate: Midnight of the selected segment's own calendar
    ///     date, in `calendar`.
    ///   - hour: The wheel's chosen hour (24-hour clock).
    ///   - minute: The wheel's chosen minute.
    public static func resolve(segmentDate: Date, hour: Int, minute: Int, dayStartHour: Int, calendar: Calendar) -> Date {
        let baseDate = hour < dayStartHour
            ? calendar.date(byAdding: .day, value: 1, to: segmentDate)!
            : segmentDate
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)!
    }

    /// The times the time control may offer in `segment`: from the record
    /// day's start to one minute before its end, and never after `now`
    /// (record spec, "The new-entry screen's controls": "The wheel MUST
    /// offer only times inside the selected record day, up to the current
    /// moment").
    public static func range(of segment: DateInterval, notAfter now: Date) -> ClosedRange<Date> {
        let lower = segment.start
        let upper = min(segment.end.addingTimeInterval(-60), now)
        return lower...max(lower, upper)
    }

    /// The moment the wheel's hour and minute name inside `segment`, kept
    /// inside `range(of:notAfter:)`. The wheel keeps only a clock time, so the
    /// screen calls this on every turn of the wheel and on every change of
    /// segment; the calendar date the wheel itself carries never counts.
    ///
    /// On most days one of the two moments with that clock time (on the
    /// segment's date or on the date after) falls inside the record day, and
    /// that moment is the one `resolve` gives. On the day before a later day
    /// start the record day is longer than 24 hours, so both can fall inside
    /// it; then the one nearer `near` (the time before the turn) wins, so the
    /// wheel moves by the turn only.
    public static func wheelTime(hour: Int, minute: Int, segment: DateInterval, dayStartHour: Int, notAfter now: Date, near: Date? = nil, calendar: Calendar) -> Date {
        let segmentDate = calendar.startOfDay(for: segment.start)
        let candidates = [0, 1].compactMap { days -> Date? in
            guard let date = calendar.date(byAdding: .day, value: days, to: segmentDate) else { return nil }
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        }.filter { segment.start <= $0 && $0 < segment.end }
        let resolved: Date
        if candidates.count == 1 {
            resolved = candidates[0]
        } else if candidates.count > 1, let near {
            resolved = candidates.min { abs($0.timeIntervalSince(near)) < abs($1.timeIntervalSince(near)) }!
        } else {
            resolved = resolve(segmentDate: segmentDate, hour: hour, minute: minute, dayStartHour: dayStartHour, calendar: calendar)
        }
        return clamp(resolved, to: range(of: segment, notAfter: now))
    }

    /// The VoiceOver value after one swipe on the adjustable "Time" element
    /// (record spec, "Accessibility of the additions"): the next quarter hour
    /// up for `steps` 1, or down for -1, kept inside `range`. The range spans
    /// both record days of the new-entry screen, so a VoiceOver user can
    /// reach last night's evening from the morning.
    public static func stepped(_ time: Date, by steps: Int, within range: ClosedRange<Date>, calendar: Calendar) -> Date {
        let stepMinutes = 15
        let seconds = calendar.component(.second, from: time)
        let wholeMinute = time.addingTimeInterval(-TimeInterval(seconds))
        let offPast = calendar.component(.minute, from: wholeMinute) % stepMinutes
        var moved = wholeMinute
        if steps > 0 {
            moved = wholeMinute.addingTimeInterval(TimeInterval((stepMinutes - offPast) * 60 + (steps - 1) * stepMinutes * 60))
        } else if steps < 0 {
            let first = offPast == 0 ? stepMinutes : offPast
            moved = wholeMinute.addingTimeInterval(-TimeInterval(first * 60 + (-steps - 1) * stepMinutes * 60))
        }
        return clamp(moved, to: range)
    }

    static func clamp(_ time: Date, to range: ClosedRange<Date>) -> Date {
        min(max(time, range.lowerBound), range.upperBound)
    }
}
