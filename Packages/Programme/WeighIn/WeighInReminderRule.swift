import Foundation

/// The weigh-in day reminder's own candidate (reminders spec, "The weigh-in
/// day reminder"; design.md, "The same scheduler MUST schedule every
/// reminder that another capability asks for"). `weigh-in` builds this and
/// feeds it into `Scheduler.requests(extraCandidates:)`, alongside the
/// weekly review, worksheet review and check-in candidates each of those
/// capabilities builds the same way.
public enum WeighInReminderRule {
    /// One `.weighInDay` candidate for each of `dayKeys` whose weekday is
    /// `weighInWeekday`, at `time`, skipping a day `hasWeighIn` already
    /// reports saved (reminders spec: "When a weigh-in exists for the
    /// weigh-in day before that time, the scheduler MUST cancel the
    /// reminder." — the app recomputes the whole schedule from scratch on
    /// every save, so simply not offering the candidate has the same
    /// effect). Empty when `weighInWeekday` is `nil` ("I won't be
    /// weighing"): the scheduler then holds no weigh-in day reminder at all.
    public static func candidates(
        weighInWeekday: Int?,
        dayKeys: [String],
        time: String,
        hasWeighIn: (String) -> Bool,
        calendar: Calendar
    ) -> [ReminderCandidate] {
        guard let weighInWeekday else { return [] }
        return dayKeys
            .filter { WeighInDayRule.isWeighInDay(dayKey: $0, weighInWeekday: weighInWeekday, calendar: calendar) }
            .filter { !hasWeighIn($0) }
            .map { ReminderCandidate(kind: .weighInDay, dayKey: $0, time: time) }
    }
}
