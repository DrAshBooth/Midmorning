import Foundation
import Record
import Plan
import Constants

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
    /// Set when the line points to the next record day's first planned
    /// meal and the record day has not ended.
    let trailingNextLine: String?
}

enum PlanToday {
    /// Loads `dateKey`'s planned rows. `entries` is the day's own entries,
    /// already loaded by the caller (`RecordStore.entries(dayKey:)`). The
    /// steps: resolve the day's plan, match its windows to the entries,
    /// compute the rows in `Plan`, then add the labels and the text.
    @MainActor
    static func load(dateKey: String, recordDay: DateInterval, store: RecordStore, entries: [RecordRow], now: Date, calendar: Calendar) -> PlanDaySection {
        guard let plan = try? store.resolvedPlan(dateKey: dateKey), !plan.meals.isEmpty else {
            return PlanDaySection(rows: [], matchedEntryIds: [], trailingNextLine: nil)
        }
        let match = plan.match(entries: entries.map { PlanEntryFact(id: $0.id, time: $0.time) }, recordDay: recordDay, calendar: calendar)
        let computed = PlanTodayRows.compute(
            match: match,
            entries: entries.map { PlanDayEntry(id: $0.id, time: $0.time, starred: $0.feltLikeABinge) },
            answers: (try? store.plannedMealAnswers(dateKey: dateKey)) ?? [:],
            quietHours: quietHours(store: store),
            recordDay: recordDay, now: now, calendar: calendar
        )

        let rows = computed.rows.map { row -> PlanRowModel in
            let matchedEntry = row.matchedEntryId.flatMap { id in entries.first { $0.id == id } }
            let label = label(for: row.slotIndex, store: store)
            return PlanRowModel(
                slotIndex: row.slotIndex, label: label, time: row.time, sortTime: row.sortTime,
                display: PlannedMealDisplay.content(matchedEntry: matchedEntry.map(matchedEntryText), isSkipped: row.isSkipped),
                matchedEntry: matchedEntry, prompt: row.prompt,
                nextLine: row.showsNextLine ? nextLine(slotIndex: row.slotIndex, time: row.time, label: label) : nil
            )
        }
        let trailingNextLine = computed.showsTrailingNextLine ? firstPlannedMealLine(after: dateKey, store: store) : nil
        return PlanDaySection(rows: rows, matchedEntryIds: computed.matchedEntryIds, trailingNextLine: trailingNextLine)
    }

    /// The line for the next record day's first planned meal, from its
    /// plan or its template, or `nil` when that day has no planned meal.
    @MainActor
    private static func firstPlannedMealLine(after dateKey: String, store: RecordStore) -> String? {
        guard let nextKey = Materialisation.nextDateKey(after: dateKey),
              let first = (try? store.resolvedPlan(dateKey: nextKey))?.orderedMeals.first
        else { return nil }
        return nextLine(slotIndex: first.slotIndex, time: first.time, label: label(for: first.slotIndex, store: store))
    }

    private static func nextLine(slotIndex: Int, time: String, label: String) -> String {
        NextPlannedMeal.line(for: PlanMealFact(label: label, time: time, kind: Slot.at(index: slotIndex)?.kind ?? .meal))
    }

    @MainActor
    private static func label(for slotIndex: Int, store: RecordStore) -> String {
        SlotLabel.effective(stored: try? store.slotLabel(index: slotIndex), defaultLabel: Slot.at(index: slotIndex)?.defaultLabel ?? "")
    }

    @MainActor
    private static func quietHours(store: RecordStore) -> QuietHours {
        (try? store.quietHours()) ?? RecordStore.Defaults.quietHours
    }

    private static func matchedEntryText(_ entry: RecordRow) -> MatchedEntryText {
        MatchedEntryText(time: entry.clockTime, what: entry.what, whereText: entry.whereText, context: entry.context, starred: entry.feltLikeABinge)
    }
}

extension DaySection.DisplayItem {
    /// The entry this item shows: a plain entry row's own entry, or the
    /// entry that a planned meal row matches. Today puts the gap band after
    /// the row that shows the earlier entry of the gap (record spec, "The
    /// gap band"; mm-t23.18).
    var recordEntry: RecordRow? {
        switch self {
        case .entry(let row): return row
        case .planned(let row): return row.matchedEntry
        }
    }
}
