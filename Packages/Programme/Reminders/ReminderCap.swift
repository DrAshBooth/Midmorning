import Foundation
import Constants

/// The cap of `MAX_OTHER_REMINDERS_PER_DAY` (reminders spec, "The cap of two
/// other reminders a day"). Operates on one record day's candidates.
public enum ReminderCap {
    /// Drops candidates in `ReminderKind.dropOrder` until at most
    /// `constants.maxOtherRemindersPerDay` "other" candidates (every kind
    /// but `.plannedMeal`) remain. `.plannedMeal` never counts and never
    /// drops. `.weeklyReview` counts toward the total but is absent from
    /// `dropOrder`, so it is never itself dropped.
    public static func apply(_ candidates: [ReminderCandidate], constants: ProgrammeConstants = .default) -> [ReminderCandidate] {
        let plannedMeals = candidates.filter { $0.kind == .plannedMeal }
        var others = candidates.filter { $0.kind != .plannedMeal }
        var toDrop = others.count - constants.maxOtherRemindersPerDay
        guard toDrop > 0 else { return candidates }
        for kind in ReminderKind.dropOrder where toDrop > 0 {
            if let index = others.firstIndex(where: { $0.kind == kind }) {
                others.remove(at: index)
                toDrop -= 1
            }
        }
        return plannedMeals + others
    }
}
