import Foundation
import Constants

/// The weigh-in day and the six-day gate (weigh-in spec, "The weigh-in day",
/// "The app accepts a weight on the weigh-in day only"). `weekday` matches
/// `Calendar`'s own `weekday` component (1 is Sunday, 7 is Saturday), the
/// same numbering `Weekday` and `RecordStore.WeighInDayChoice` use.
public enum WeighInDayRule {
    /// The record day's own weekday, from the midnight of its key.
    static func weekday(of dayKey: String, calendar: Calendar) -> Int? {
        guard let midnight = DayKeyMath.midnight(dayKey, calendar: calendar) else { return nil }
        return calendar.component(.weekday, from: midnight)
    }

    /// True when `dayKey`'s own weekday is the chosen weigh-in weekday.
    public static func isWeighInDay(dayKey: String, weighInWeekday: Int, calendar: Calendar) -> Bool {
        weekday(of: dayKey, calendar: calendar) == weighInWeekday
    }

    /// "The app MUST NOT accept a weigh-in less than six days after the last
    /// one." True with no earlier weigh-in at all.
    public static func sixDayGatePasses(candidateDayKey: String, lastWeighInDayKey: String?, calendar: Calendar, minimumGapDays: Int = 6) -> Bool {
        guard let lastWeighInDayKey else { return true }
        return DayKeyMath.daysBetween(lastWeighInDayKey, candidateDayKey, calendar: calendar) >= minimumGapDays
    }

    /// The next record day, strictly after `dayKey`, whose weekday is
    /// `weighInWeekday` and that passes the six-day gate against
    /// `lastWeighInDayKey`. Scans forward at most two weeks, which always
    /// finds a match: the gate's own six-day minimum never blocks both of a
    /// weekday's two nearest occurrences (seven days apart).
    public static func nextAcceptedDayKey(strictlyAfter dayKey: String, weighInWeekday: Int, lastWeighInDayKey: String?, calendar: Calendar) -> String {
        var candidate = DayKeyMath.adding(1, to: dayKey, calendar: calendar)
        for _ in 0..<14 {
            if weekday(of: candidate, calendar: calendar) == weighInWeekday,
               sixDayGatePasses(candidateDayKey: candidate, lastWeighInDayKey: lastWeighInDayKey, calendar: calendar) {
                return candidate
            }
            candidate = DayKeyMath.adding(1, to: candidate, calendar: calendar)
        }
        return candidate
    }

    /// "Monday 28 September" — the en_GB weekday and date, no year (weigh-in
    /// spec, "The app accepts a weight on the weigh-in day only": "Both
    /// values MUST come from the en_GB formatter.").
    public static func formattedDate(dayKey: String, calendar: Calendar) -> String {
        guard let midnight = DayKeyMath.midnight(dayKey, calendar: calendar) else { return dayKey }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: midnight)
    }
}

/// The refusal text (weigh-in spec, "The app accepts a weight on the
/// weigh-in day only"). The words are a key in the app's string catalogue
/// (content spec, "Strings live in catalogues").
public enum WeighInRefusalText {
    /// "Your weigh-in day is %1$@. The app asks once a week, because
    /// day-to-day numbers move on their own. Next: %2$@."
    public static func text(dayName: String, nextDate: String) -> CatalogueText {
        .key("weighIn.refusal", .verbatim(dayName), .verbatim(nextDate))
    }
}
