import Foundation
import Record
import Plan

/// One planned meal row's already-resolved display facts for Today
/// (regular-eating-plan spec, "Today shows the plan beside the record"; "A
/// missed planned meal gets one prompt"; "The next-planned-meal line"). A
/// value the view renders and holds no rule in (design.md, "Pure seams the
/// packages expose"): every rule lives in `Plan`; this only gathers the
/// store's facts and calls it.
struct PlanRowModel: Identifiable, Equatable {
    let slotIndex: Int
    let label: String
    let time: String
    let sortTime: Date
    let display: PlannedMealDisplay
    let matchedEntry: RecordRow?
    let prompt: MissedMealPrompt.Form?
    /// The next-planned-meal line, when this row is its target.
    let nextLine: String?

    var id: Int { slotIndex }
}

/// A record day's plan (or `nil` when stage 2 is not open or the day has no
/// planned meals), plus the trailing next-planned-meal line when the target
/// falls on the next record day (regular-eating-plan spec, "The
/// next-planned-meal line": "Today MUST then show the line as the last row
/// of the current day section").
struct PlanDaySection: Equatable {
    let rows: [PlanRowModel]
    let matchedEntryIds: Set<UUID>
    /// Set only when no row above carries `nextLine` and the trigger's
    /// target is tomorrow's first planned meal.
    let trailingNextLine: String?
}

enum PlanToday {
    /// Loads `dateKey`'s planned rows. `entries` is the day's own entries,
    /// already loaded by the caller (`RecordStore.entries(dayKey:)`).
    @MainActor
    static func load(dateKey: String, recordDay: DateInterval, store: RecordStore, entries: [RecordRow], now: Date, calendar: Calendar) -> PlanDaySection {
        guard let dayStartHour = try? store.dayStartHour(effectiveOn: dateKey) else {
            return PlanDaySection(rows: [], matchedEntryIds: [], trailingNextLine: nil)
        }
        let plan = try? store.dayPlan(dateKey: dateKey)
        let slotsJSON: String
        if let plan {
            slotsJSON = plan.slotsJSON
        } else {
            let weekday = calendar.component(.weekday, from: recordDay.start)
            let kind = RecordStore.TemplateKind(rawValue: Materialisation.templateKind(forRecordDayStartingOnWeekday: weekday)) ?? .weekday
            slotsJSON = (try? store.templateSlotsJSON(kind)) ?? "[]"
        }
        let slots = PlanCodec.decode(slotsJSON)
        guard !slots.isEmpty else { return PlanDaySection(rows: [], matchedEntryIds: [], trailingNextLine: nil) }

        let windowBefore = plan?.windowBeforeMinutes ?? 60
        let windowAfter = plan?.windowAfterMinutes ?? 90
        let windows = PlanWindows.windows(for: slots, recordDay: recordDay, dayStartHour: dayStartHour, beforeMinutes: windowBefore, afterMinutes: windowAfter, calendar: calendar)
        let ordered = PlanOrdering.sorted(slots, dayStartHour: dayStartHour)
        let entryFacts = entries.map { PlanEntryFact(id: $0.id, time: $0.time) }
        let matches = PlanMatching.match(windows: windows, entries: entryFacts)
        let matchedIds = Set(matches.values)
        let answers = (try? store.plannedMealAnswers(dateKey: dateKey)) ?? [:]
        let quietOn = (try? store.quietHoursOn()) ?? true
        let quietStart = (try? store.quietHoursStart()) ?? "22:00"
        let quietEnd = (try? store.quietHoursEnd()) ?? "07:00"
        let recordDayHasEnded = now >= recordDay.end

        func window(for slotIndex: Int) -> PlannedMealWindow? { windows.first { $0.slotIndex == slotIndex } }
        func label(for slotIndex: Int) -> String {
            let slot = Slot.at(index: slotIndex)
            let stored = try? store.slotLabel(index: slotIndex)
            return SlotLabel.effective(stored: stored, defaultLabel: slot?.defaultLabel ?? "")
        }

        var missedFacts: [MissedPlannedMeal] = []
        var rowsByIndex: [Int: PlanRowModel] = [:]

        for (i, meal) in ordered.enumerated() {
            guard let w = window(for: meal.slotIndex) else { continue }
            let matchedId = matches[meal.slotIndex]
            let matchedEntry = matchedId.flatMap { id in entries.first { $0.id == id } }
            let isSkipped = answers[meal.slotIndex] == "Skipped"
            let display = PlannedMealDisplay.content(matchedEntry: matchedEntry.map { ($0.clockTime, $0.what) }, isSkipped: isSkipped)

            let nextSlot = i + 1 < ordered.count ? ordered[i + 1] : nil
            let nextSlotTime = nextSlot.flatMap { window(for: $0.slotIndex)?.time }
            let hasLaterEntry = (nextSlot.map { s in matches[s.slotIndex] != nil } ?? false)
                || (nextSlotTime.map { t in entries.contains { $0.time >= t } } ?? false)
                || ordered[(i + 1)...].contains { matches[$0.slotIndex] != nil }
            let laterSlotAnswered = ordered[(i + 1)...].contains { answers[$0.slotIndex] != nil && !(answers[$0.slotIndex] ?? "").isEmpty }
            let windowEndsInQuietHours = quietOn && {
                let c = calendar.dateComponents([.hour, .minute], from: w.interval.end)
                return QuietHours.contains(time: PlanTime.string(hour: c.hour ?? 0, minute: c.minute ?? 0), start: quietStart, end: quietEnd)
            }()
            let candidateBoundary = nextSlotTime ?? recordDay.end
            let unmatched = entries.filter { !matchedIds.contains($0.id) }.map { PlanEntryFact(id: $0.id, time: $0.time) }
            let candidate = MissedMealPrompt.candidateEntry(after: w.time, before: candidateBoundary, unmatchedEntries: unmatched)

            missedFacts.append(MissedPlannedMeal(
                slotIndex: meal.slotIndex, windowEnd: w.interval.end, hasMatchedEntry: matchedEntry != nil,
                hasSkippedAnswer: isSkipped, hasLaterEntry: hasLaterEntry, laterSlotAnswered: laterSlotAnswered,
                windowEndsInQuietHours: windowEndsInQuietHours, candidateEntryTime: candidate?.time
            ))

            // The next-planned-meal line: only while this row is still
            // pending (no match, no answer) and its own window has not
            // ended — once it has, the missed prompt takes over.
            var nextLine: String? = nil
            if case .pending = display, now < w.interval.end {
                let previous = i > 0 ? ordered[i - 1] : nil
                let previousTime = previous.flatMap { window(for: $0.slotIndex)?.time } ?? recordDay.start
                let previousSkippedNoMatch = previous.map { answers[$0.slotIndex] == "Skipped" && matches[$0.slotIndex] == nil } ?? false
                let starredBetween = entries.contains { $0.feltLikeABinge && $0.time >= previousTime && $0.time < w.time }
                if NextPlannedMeal.isTriggered(previousSlotSkippedWithNoMatch: previousSkippedNoMatch, hasStarredEntryBetweenPreviousAndThis: starredBetween) {
                    nextLine = NextPlannedMeal.line(for: PlanMealFact(label: label(for: meal.slotIndex), time: meal.time, kind: Slot.at(index: meal.slotIndex)?.kind ?? .meal))
                }
            }

            rowsByIndex[meal.slotIndex] = PlanRowModel(
                slotIndex: meal.slotIndex, label: label(for: meal.slotIndex), time: meal.time, sortTime: w.time,
                display: display, matchedEntry: matchedEntry, prompt: nil, nextLine: nextLine
            )
        }

        // The one active missed-planned-meal prompt, if any.
        if let active = MissedMealPrompt.active(meals: missedFacts, now: now, recordDayHasEnded: recordDayHasEnded), let row = rowsByIndex[active.slotIndex] {
            rowsByIndex[active.slotIndex] = PlanRowModel(
                slotIndex: row.slotIndex, label: row.label, time: row.time, sortTime: row.sortTime,
                display: row.display, matchedEntry: row.matchedEntry, prompt: active.form, nextLine: nil
            )
        }

        // The tail case: the day's own slots show no line, but the last
        // slot's own outcome (or a trailing starred entry) points past the
        // end of today, to tomorrow's first planned meal.
        var trailingNextLine: String? = nil
        if !rowsByIndex.values.contains(where: { $0.nextLine != nil }), let last = ordered.last, let lastWindow = window(for: last.slotIndex) {
            let lastSkippedNoMatch = answers[last.slotIndex] == "Skipped" && matches[last.slotIndex] == nil
            let starredAfter = entries.contains { $0.feltLikeABinge && $0.time >= lastWindow.time && $0.time < recordDay.end }
            if NextPlannedMeal.isTriggered(previousSlotSkippedWithNoMatch: lastSkippedNoMatch, hasStarredEntryBetweenPreviousAndThis: starredAfter) {
                let schedule = (try? store.dayStartSchedule()) ?? .standard
                let nextDay = RecordDay.next(recordDay, calendar: calendar, schedule: schedule)
                let nextDateKey = RecordDay.key(containing: nextDay.start, calendar: calendar, schedule: schedule)
                let nextPlan = try? store.dayPlan(dateKey: nextDateKey)
                let nextSlotsJSON: String
                if let nextPlan {
                    nextSlotsJSON = nextPlan.slotsJSON
                } else {
                    let weekday = calendar.component(.weekday, from: nextDay.start)
                    let kind = RecordStore.TemplateKind(rawValue: Materialisation.templateKind(forRecordDayStartingOnWeekday: weekday)) ?? .weekday
                    nextSlotsJSON = (try? store.templateSlotsJSON(kind)) ?? "[]"
                }
                let nextDayStartHour = (try? store.dayStartHour(effectiveOn: nextDateKey)) ?? dayStartHour
                if let first = PlanOrdering.sorted(PlanCodec.decode(nextSlotsJSON), dayStartHour: nextDayStartHour).first {
                    trailingNextLine = NextPlannedMeal.line(for: PlanMealFact(label: label(for: first.slotIndex), time: first.time, kind: Slot.at(index: first.slotIndex)?.kind ?? .meal))
                }
            }
        }

        let sortedRows = ordered.compactMap { rowsByIndex[$0.slotIndex] }
        return PlanDaySection(rows: sortedRows, matchedEntryIds: matchedIds, trailingNextLine: trailingNextLine)
    }
}
