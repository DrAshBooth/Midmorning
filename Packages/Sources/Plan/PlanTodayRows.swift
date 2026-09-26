import Foundation

/// One entry of the record day, as the planned meal rows on Today need it:
/// its id, its time and its star. `Plan` never sees a whole `Record` entry
/// (design.md, "Pure seams the packages expose").
public struct PlanDayEntry: Sendable, Equatable {
    public let id: UUID
    public let time: Date
    public let starred: Bool

    public init(id: UUID, time: Date, starred: Bool) {
        self.id = id
        self.time = time
        self.starred = starred
    }

    public var fact: PlanEntryFact { PlanEntryFact(id: id, time: time) }
}

/// The quiet hours settings, as "HH:mm" text.
public struct PlanQuietHours: Sendable, Equatable {
    public let isOn: Bool
    public let start: String
    public let end: String

    public init(isOn: Bool, start: String, end: String) {
        self.isOn = isOn
        self.start = start
        self.end = end
    }
}

/// One planned meal row's facts for Today, before the app adds the slot
/// label and the entry's own text.
public struct PlanTodayRow: Sendable, Equatable {
    public let slotIndex: Int
    /// The planned time, "HH:mm".
    public let time: String
    /// The planned meal's moment inside the record day. Today places the
    /// row in time order with the entries by this moment.
    public let sortTime: Date
    public let matchedEntryId: UUID?
    public let isSkipped: Bool
    /// The missed planned meal prompt, when this row holds it.
    public let prompt: MissedMealPrompt.Form?
    /// True when the next-planned-meal line shows on this row.
    public let showsNextLine: Bool
}

/// The planned meal rows of one record day on Today (regular-eating-plan
/// spec, "Today shows the plan beside the record"; "A missed planned meal
/// gets one prompt"; "The next-planned-meal line"). Every rule for the rows
/// is here. The app target reads the store's facts, calls `compute`, and
/// adds the labels and the text.
public struct PlanTodayRows: Sendable, Equatable {
    public let rows: [PlanTodayRow]
    public let matchedEntryIds: Set<UUID>
    /// True when the next-planned-meal line points to the next record
    /// day's first planned meal. Today then shows the line as the last row
    /// of the current day section.
    public let showsTrailingNextLine: Bool

    public static func compute(
        match: PlanDayMatch,
        entries: [PlanDayEntry],
        answers: [Int: String],
        quietHours: PlanQuietHours,
        recordDay: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> PlanTodayRows {
        let ordered = match.orderedMeals.filter { match.window(for: $0.slotIndex) != nil }
        let recordDayHasEnded = now >= recordDay.end
        let nextLine = nextLineTargets(match: match, ordered: ordered, entries: entries, answers: answers)

        var missedFacts: [MissedPlannedMeal] = []
        var rows: [PlanTodayRow] = []
        for (i, meal) in ordered.enumerated() {
            guard let window = match.window(for: meal.slotIndex) else { continue }
            let later = ordered[(i + 1)...]
            let nextTime = later.first.flatMap { match.window(for: $0.slotIndex)?.time }
            let matchedEntryId = match.matches[meal.slotIndex]
            let answer = answers[meal.slotIndex] ?? ""
            let isSkipped = answer == "Skipped"

            let hasLaterEntry = later.contains { match.matches[$0.slotIndex] != nil }
                || (nextTime.map { t in entries.contains { $0.time >= t } } ?? false)
            let laterSlotAnswered = later.contains { !(answers[$0.slotIndex] ?? "").isEmpty }
            let windowEndsInQuietHours = quietHours.isOn && QuietHours.contains(
                time: clockText(window.interval.end, calendar: calendar), start: quietHours.start, end: quietHours.end
            )
            // First cut: the prompt always takes the "Skipped" and "Add it"
            // form. mm-t33.14 passes `MissedMealPrompt.candidateEntry` here
            // when it builds "That was it" (mm-t23.22).
            missedFacts.append(MissedPlannedMeal(
                slotIndex: meal.slotIndex, windowEnd: window.interval.end, hasMatchedEntry: matchedEntryId != nil,
                hasSkippedAnswer: isSkipped, hasLaterEntry: hasLaterEntry, laterSlotAnswered: laterSlotAnswered,
                windowEndsInQuietHours: windowEndsInQuietHours, candidateEntryTime: nil
            ))

            // The line stays until the planned meal matches an entry, the
            // person answers it, or its window ends.
            let showsNextLine = nextLine.targets.contains(meal.slotIndex)
                && matchedEntryId == nil && answer.isEmpty && now < window.interval.end
            rows.append(PlanTodayRow(
                slotIndex: meal.slotIndex, time: meal.time, sortTime: window.time,
                matchedEntryId: matchedEntryId, isSkipped: isSkipped, prompt: nil, showsNextLine: showsNextLine
            ))
        }

        if let active = MissedMealPrompt.active(meals: missedFacts, now: now, recordDayHasEnded: recordDayHasEnded),
           let index = rows.firstIndex(where: { $0.slotIndex == active.slotIndex }) {
            let row = rows[index]
            rows[index] = PlanTodayRow(
                slotIndex: row.slotIndex, time: row.time, sortTime: row.sortTime,
                matchedEntryId: row.matchedEntryId, isSkipped: row.isSkipped, prompt: active.form, showsNextLine: false
            )
        }

        return PlanTodayRows(
            rows: rows,
            matchedEntryIds: match.matchedEntryIds,
            showsTrailingNextLine: nextLine.pointsToNextDay && !recordDayHasEnded
        )
    }

    /// The planned meals that the next-planned-meal line points to
    /// (regular-eating-plan spec, "The next-planned-meal line"). Two events
    /// start the line. A "Skipped" answer with no matched entry points to
    /// the next planned meal after the skipped one. A starred entry points
    /// to the next planned meal after the entry's time, but never to the
    /// planned meal that the entry matches. When the day has no such
    /// planned meal, the line points to the next record day.
    static func nextLineTargets(
        match: PlanDayMatch,
        ordered: [PlannedMeal],
        entries: [PlanDayEntry],
        answers: [Int: String]
    ) -> (targets: Set<Int>, pointsToNextDay: Bool) {
        var targets: Set<Int> = []
        var pointsToNextDay = false

        func point(after moment: Date, excluding excludedSlot: Int?) {
            let next = ordered.first { meal in
                meal.slotIndex != excludedSlot && (match.window(for: meal.slotIndex).map { $0.time > moment } ?? false)
            }
            if let next {
                targets.insert(next.slotIndex)
            } else {
                pointsToNextDay = true
            }
        }

        for meal in ordered where answers[meal.slotIndex] == "Skipped" && match.matches[meal.slotIndex] == nil {
            if let time = match.window(for: meal.slotIndex)?.time {
                point(after: time, excluding: nil)
            }
        }
        for entry in entries where entry.starred {
            point(after: entry.time, excluding: match.slotIndex(matching: entry.id))
        }
        return (targets, pointsToNextDay)
    }

    private static func clockText(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return PlanTime.string(hour: c.hour ?? 0, minute: c.minute ?? 0)
    }
}
