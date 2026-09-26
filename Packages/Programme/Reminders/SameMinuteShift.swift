import Foundation

/// Moves a lower-priority reminder five minutes later, repeated, until no
/// two of one record day's candidates share a minute (reminders spec, "Two
/// reminders never share a minute").
public enum SameMinuteShift {
    /// Assigns each candidate a final minute in one forward sweep, walking
    /// the candidates in (natural minute, priority) order and pushing each
    /// one at least five minutes past the last assigned minute when its own
    /// natural minute would collide. This resolves every cascade in one
    /// pass: a later, lower-priority candidate that lands on an
    /// already-shifted minute shifts again from there.
    public static func apply(_ candidates: [ReminderCandidate]) -> [ReminderCandidate] {
        let order = candidates.enumerated().sorted { a, b in
            let ma = ReminderClock.minutesOfDay(a.element.time)
            let mb = ReminderClock.minutesOfDay(b.element.time)
            if ma != mb { return ma < mb }
            return priorityRank(a.element.kind) < priorityRank(b.element.kind)
        }
        var result = candidates
        var lastMinutes = Int.min
        for (offset, candidate) in order.map({ ($0.offset, $0.element) }) {
            let natural = ReminderClock.minutesOfDay(candidate.time)
            let assigned = natural <= lastMinutes ? lastMinutes + 5 : natural
            result[offset].time = ReminderClock.string(hour: (assigned / 60) % 24, minute: assigned % 60)
            lastMinutes = assigned
        }
        return result
    }

    private static func priorityRank(_ kind: ReminderKind) -> Int {
        ReminderKind.sameMinutePriorityOrder.firstIndex(of: kind) ?? Int.max
    }
}
