import Foundation
import Constants

/// Moves a lower-priority reminder five minutes later, repeated, until no
/// two of one record day's candidates share a minute (reminders spec, "Two
/// reminders never share a minute").
public enum SameMinuteShift {
    /// Walks the occupied minutes from the earliest to the latest. At each
    /// minute that holds two or more candidates, the highest-priority one
    /// stays and every other one moves five minutes later. A moved
    /// candidate can then share its new minute with another candidate, and
    /// the same rule applies there. A candidate whose minute no other
    /// candidate holds never moves.
    ///
    /// `dayStartMinute` is the clock minute the record day starts at. The
    /// walk orders minutes from the day start, so a time after midnight
    /// comes after a time in the evening of the same record day.
    public static func apply(_ candidates: [ReminderCandidate], dayStartMinute: Int = 0) -> [ReminderCandidate] {
        var minutes = candidates.map { ClockTime.minutesSinceDayStart($0.time, dayStartMinute: dayStartMinute) }
        var moved = Array(repeating: false, count: candidates.count)
        while true {
            let byMinute = Dictionary(grouping: minutes.indices, by: { minutes[$0] })
            guard let minute = byMinute.keys.filter({ byMinute[$0]!.count > 1 }).min(), let occupants = byMinute[minute] else { break }
            let keeper = occupants.min { a, b in
                let ra = priorityRank(candidates[a].kind), rb = priorityRank(candidates[b].kind)
                if ra != rb { return ra < rb }
                return (candidates[a].slotIndex ?? Int.max, a) < (candidates[b].slotIndex ?? Int.max, b)
            }!
            for index in occupants where index != keeper {
                minutes[index] += 5
                moved[index] = true
            }
        }
        var result = candidates
        for index in result.indices where moved[index] {
            let clock = (minutes[index] + dayStartMinute) % 1440
            result[index].time = ClockTime.string(hour: clock / 60, minute: clock % 60)
        }
        return result
    }

    private static func priorityRank(_ kind: ReminderKind) -> Int {
        ReminderKind.sameMinutePriorityOrder.firstIndex(of: kind) ?? Int.max
    }
}
