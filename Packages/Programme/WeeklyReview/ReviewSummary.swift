import Foundation

/// The review's opening summary: one plain sentence per part, in this fixed
/// order (weekly-review spec, "The summary built from the record"; "What the
/// review never shows"). Every sentence is a template filled with numbers
/// and en_GB-formatted values; the app forms no other words at runtime
/// (design.md, "Pattern sentences and reviews are templates plus numbers").
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

    private static func daysWithEntryLine(_ facts: ReviewWeekFacts) -> String {
        "Days with an entry: \(daysWithEntryCount(facts))."
    }

    private static func starredLine(_ facts: ReviewWeekFacts) -> String {
        let thisWeek = starredCount(facts)
        guard let lastWeek = facts.previousWeekFrozenStarred else {
            return "Starred entries: \(thisWeek) this week."
        }
        return "Starred entries: \(thisWeek) this week, \(lastWeek) last week."
    }

    private static func planLine(_ facts: ReviewWeekFacts) -> String? {
        guard let count = facts.plannedMealsWithEntryCount else { return nil }
        return "Planned meals with an entry beside them: \(count)."
    }

    private static func pausedLine(_ facts: ReviewWeekFacts) -> String? {
        let count = pausedCount(facts)
        guard count > 0 else { return nil }
        return "Paused days: \(count)."
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
        let from = ReminderClock.string(from: best.first, calendar: calendar)
        let to = ReminderClock.string(from: best.second, calendar: calendar)
        return "Longest gap between entries: \(ReviewText.durationText(best.duration)), on \(weekday), from \(from) to \(to)."
    }

    private static func urgeLine(_ facts: ReviewWeekFacts) -> String? {
        guard facts.urgesCount > 0 else { return nil }
        return "Urges: \(facts.urgesCount). Passed: \(facts.urgesPassedCount)."
    }

    private static func weighInLine(_ facts: ReviewWeekFacts, calendar: Calendar) -> String? {
        guard let dayKey = facts.weighInDoneDayKey else { return nil }
        return "Weigh-in: done on \(ReviewText.weekdayName(dayKey: dayKey, calendar: calendar))."
    }

    /// The close-the-day words of the week, joined in record-day order, with
    /// a comma and a space — never reordered, changed or added to.
    private static func wordsLine(_ facts: ReviewWeekFacts) -> String? {
        let words = facts.weekDayKeys.compactMap { facts.closeTheDayWordsByDayKey[$0] }.filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        return "Your words this week: \(words.joined(separator: ", "))."
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

    /// "6 hours 20 minutes" — whole hours and minutes, en_GB word forms, no
    /// separating comma.
    public static func durationText(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int((seconds / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) \(hours == 1 ? "hour" : "hours")") }
        if minutes > 0 || hours == 0 { parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")") }
        return parts.joined(separator: " ")
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
