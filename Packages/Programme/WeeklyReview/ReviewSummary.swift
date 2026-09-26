import Foundation
import Constants

/// The review's opening summary: one plain sentence per part, in this fixed
/// order (weekly-review spec, "The summary built from the record"; "What the
/// review never shows"). Every sentence is a template filled with numbers
/// and en_GB-formatted values; the app forms no other words at runtime
/// (design.md, "Pattern sentences and reviews are templates plus numbers").
///
/// This is signed-off text. The content bundle holds a copy of each
/// template with a "review.summary." id, and a content test proves that each
/// sentence here equals its bundle copy, filled with the same values (ruling
/// r13-02). A bundle string holds at most one count (ruling r13-12). So the
/// starred part with a last-week count fills "Starred entries: %1$@, %2$@."
/// with "%lld this week" and "%lld last week", and the urge part is the two
/// sentences "Urges: %lld." and "Passed: %lld.", joined by one space.
public enum ReviewSummary {
    /// The summary's sentences, in the requirement's fixed order, leaving
    /// out any part `facts` has nothing for.
    public static func parts(_ facts: ReviewWeekFacts, calendar: Calendar) -> [String] {
        var lines: [String] = [daysWithEntryLine(facts), starredLine(facts)]
        if let plan = planLine(facts) { lines.append(plan) }
        if let paused = pausedLine(facts) { lines.append(paused) }
        if let gap = gapLine(facts, calendar: calendar) { lines.append(gap) }
        if let urge = urgeLine(facts) { lines.append(urge) }
        if let weighIn = weighInLine(facts, calendar: calendar) { lines.append(weighIn) }
        if let words = wordsLine(facts) { lines.append(words) }
        return lines
    }

    static func daysWithEntryCount(_ facts: ReviewWeekFacts) -> Int {
        let weekDays = Set(facts.weekDayKeys)
        return Set(facts.entries.map(\.dayKey).filter(weekDays.contains)).count
    }

    static func starredCount(_ facts: ReviewWeekFacts) -> Int {
        let weekDays = Set(facts.weekDayKeys)
        return facts.entries.filter { $0.starred && weekDays.contains($0.dayKey) }.count
    }

    static func pausedCount(_ facts: ReviewWeekFacts) -> Int {
        facts.pausedDayKeys.intersection(facts.weekDayKeys).count
    }

    // MARK: - The sentences, each filled with its values

    /// "Days with an entry: %lld." ("review.summary.days").
    public static func daysText(_ count: Int) -> String {
        "Days with an entry: \(count)."
    }

    /// "Starred entries: %lld this week." ("review.summary.starred") with
    /// no last-week count. With one, "Starred entries: %1$@, %2$@."
    /// ("review.summary.starred.twoweeks"), filled with "%lld this week"
    /// ("review.summary.starred.thisweek") and "%lld last week"
    /// ("review.summary.starred.lastweek").
    public static func starredText(thisWeek: Int, lastWeek: Int?) -> String {
        guard let lastWeek else { return "Starred entries: \(thisWeek) this week." }
        return "Starred entries: \(thisWeekPart(thisWeek)), \(lastWeekPart(lastWeek))."
    }

    private static func thisWeekPart(_ count: Int) -> String { "\(count) this week" }
    private static func lastWeekPart(_ count: Int) -> String { "\(count) last week" }

    /// "Planned meals with an entry beside them: %lld." ("review.summary.plan").
    public static func planText(_ count: Int) -> String {
        "Planned meals with an entry beside them: \(count)."
    }

    /// "Paused days: %lld." ("review.summary.paused").
    public static func pausedText(_ count: Int) -> String {
        "Paused days: \(count)."
    }

    /// "Longest gap between entries: %1$@, on %2$@, from %3$@ to %4$@."
    /// ("review.summary.gap"), with the en_GB duration, weekday and times.
    public static func gapText(duration: String, weekday: String, from: String, to: String) -> String {
        "Longest gap between entries: \(duration), on \(weekday), from \(from) to \(to)."
    }

    /// "Urges: %lld." ("review.summary.urges") and "Passed: %lld."
    /// ("review.summary.passed"), joined by one space.
    public static func urgeText(urges: Int, passed: Int) -> String {
        "Urges: \(urges)." + " " + "Passed: \(passed)."
    }

    /// "Weigh-in: done on %@." ("review.summary.weighin").
    public static func weighInText(weekday: String) -> String {
        "Weigh-in: done on \(weekday)."
    }

    /// "Your words this week: %@." ("review.summary.words").
    public static func wordsText(_ words: String) -> String {
        "Your words this week: \(words)."
    }

    // MARK: - The parts, from the week's facts

    private static func daysWithEntryLine(_ facts: ReviewWeekFacts) -> String {
        daysText(daysWithEntryCount(facts))
    }

    private static func starredLine(_ facts: ReviewWeekFacts) -> String {
        starredText(thisWeek: starredCount(facts), lastWeek: facts.previousWeekFrozenStarred)
    }

    private static func planLine(_ facts: ReviewWeekFacts) -> String? {
        guard let count = facts.plannedMealsWithEntryCount else { return nil }
        return planText(count)
    }

    private static func pausedLine(_ facts: ReviewWeekFacts) -> String? {
        let count = pausedCount(facts)
        guard count > 0 else { return nil }
        return pausedText(count)
    }

    /// The largest gap, by entry time, between two consecutive entries on
    /// one recorded day of the week — a "didn't record" day, a fasting day
    /// and a day with fewer than two entries never count.
    private static func gapLine(_ facts: ReviewWeekFacts, calendar: Calendar) -> String? {
        let byDay = Dictionary(grouping: facts.entries, by: \.dayKey)
        var best: (duration: TimeInterval, dayKey: String, first: Date, second: Date)?
        for dayKey in facts.weekDayKeys where !facts.exemptDayKeys.contains(dayKey) {
            let times = (byDay[dayKey] ?? []).map(\.time).sorted()
            guard times.count >= 2 else { continue }
            for i in 0..<(times.count - 1) {
                let duration = times[i + 1].timeIntervalSince(times[i])
                if duration > (best?.duration ?? -1) {
                    best = (duration, dayKey, times[i], times[i + 1])
                }
            }
        }
        guard let best else { return nil }
        let weekday = ReviewText.weekdayName(dayKey: best.dayKey, calendar: calendar)
        let from = ClockTime.string(from: best.first, calendar: calendar)
        let to = ClockTime.string(from: best.second, calendar: calendar)
        return gapText(duration: DurationText.string(seconds: best.duration), weekday: weekday, from: from, to: to)
    }

    private static func urgeLine(_ facts: ReviewWeekFacts) -> String? {
        guard facts.urgesCount > 0 else { return nil }
        return urgeText(urges: facts.urgesCount, passed: facts.urgesPassedCount)
    }

    private static func weighInLine(_ facts: ReviewWeekFacts, calendar: Calendar) -> String? {
        guard let dayKey = facts.weighInDoneDayKey else { return nil }
        return weighInText(weekday: ReviewText.weekdayName(dayKey: dayKey, calendar: calendar))
    }

    /// The close-the-day words of the week, joined in record-day order, with
    /// a comma and a space — never reordered, changed or added to.
    private static func wordsLine(_ facts: ReviewWeekFacts) -> String? {
        let words = facts.weekDayKeys.compactMap { facts.closeTheDayWordsByDayKey[$0] }.filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        return wordsText(words.joined(separator: ", "))
    }
}

/// Small text helpers `ReviewSummary` and the "Reviews" list share.
public enum ReviewText {
    public static func weekdayName(dayKey: String, calendar: Calendar) -> String {
        guard let midnight = DayKeyMath.midnight(dayKey, calendar: calendar) else { return dayKey }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: midnight)
    }

    /// "12–18 October" — the en_GB day-and-month range, the year left out,
    /// the month named once when both days share it.
    public static func weekDateRangeText(firstDayKey: String, lastDayKey: String, calendar: Calendar) -> String {
        guard let start = DayKeyMath.midnight(firstDayKey, calendar: calendar),
              let end = DayKeyMath.midnight(lastDayKey, calendar: calendar) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = calendar.timeZone
        let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
        formatter.dateFormat = sameMonth ? "d" : "d MMMM"
        let startText = formatter.string(from: start)
        formatter.dateFormat = "d MMMM"
        let endText = formatter.string(from: end)
        return "\(startText)–\(endText)"
    }
}
