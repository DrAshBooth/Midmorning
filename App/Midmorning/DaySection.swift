import Foundation
import Record
import Plan
import Constants

/// One day section's data, computed from the store (record spec, "The Today
/// stack"; "Collapse a day to a count"; "The gap band"). A value the view
/// renders and holds no rule in, per design.md's "Pure seams" screen-model
/// pattern.
struct DaySection: Identifiable {
    let id: String // the record day's date key
    let interval: DateInterval
    let role: RecordDayRole
    let entries: [RecordRow]
    let states: Set<DayStateKind>
    let isExpanded: Bool
    let gapBandIndexesBefore: [Int]
    /// `nil` before stage 2 (regular-eating-plan spec, "The plan builder
    /// opens at stage 2"): the live `stage2Open` fact gates it.
    let plan: PlanDaySection?

    var heading: String {
        let night = role == .current && RecordDay.isNight(Date(), inRecordDay: interval, calendar: .current)
        return DayHeading.text(for: interval.start, night: night)
    }

    /// "Didn't record", "Paused" (not on the current day, where "Paused for
    /// today" shows) or "Fasting".
    var stateLine: CatalogueText? {
        if states.contains(.didntRecord) { return .key("today.stateLine.didntRecord") }
        if states.contains(.paused) { return role == .current ? nil : .key("today.stateLine.paused") }
        if states.contains(.fasting) { return .key("today.stateLine.fasting") }
        return nil
    }

    /// The unmatched entries and the planned meal rows, merged into one
    /// time-ordered column (regular-eating-plan spec, "Today shows the plan
    /// beside the record": "Today MUST place them in time order with the
    /// entries").
    enum DisplayItem: Identifiable {
        case entry(RecordRow)
        case planned(PlanRowModel)

        var id: String {
            switch self {
            case .entry(let row): return TodayRowId.entry(row.id)
            case .planned(let row): return TodayRowId.planned(slotIndex: row.slotIndex)
            }
        }

        var time: Date {
            switch self {
            case .entry(let row): return row.time
            case .planned(let row): return row.sortTime
            }
        }
    }

    var displayItems: [DisplayItem] {
        let matchedIds = plan?.matchedEntryIds ?? []
        let plainEntries = entries.filter { !matchedIds.contains($0.id) }.map(DisplayItem.entry)
        let plannedRows = (plan?.rows ?? []).map(DisplayItem.planned)
        return (plainEntries + plannedRows).sorted { $0.time < $1.time }
    }

    /// The id a row carries across the whole of Today, for the scroll after
    /// a save (record spec, "Save is quiet").
    func scrollId(of item: DisplayItem) -> String {
        TodayRowId.scrollId(dateKey: id, rowId: item.id)
    }

    /// The scroll id of the row that shows `entryId`: the planned meal row
    /// that the entry matches, or else the entry's own row.
    func scrollId(forEntry entryId: UUID) -> String {
        let matchedSlot = plan?.rows.first { $0.matchedEntry?.id == entryId }?.slotIndex
        return TodayRowId.scrollId(forEntry: entryId, dateKey: id, matchedSlotIndex: matchedSlot)
    }

    @MainActor
    /// `stage2OpenedDayKey` is the record day stage 2 opened, or `nil`
    /// while stage 2 is closed: bands show on that day and every later day
    /// while the "Gap bands" switch is on (record spec, "The gap band").
    static func load(dayKey: String, interval: DateInterval, role: RecordDayRole, store: RecordStore, stage2Open: Bool, stage2OpenedDayKey: String?) -> DaySection {
        let entries = (try? store.entries(dayKey: dayKey)) ?? []
        let states = (try? store.dayStates(dateKey: dayKey)) ?? []
        let kept = try? store.collapseChoice(dateKey: dayKey)
        let isExpanded = entries.isEmpty || CollapseDefault.isExpanded(role: role, kept: kept ?? nil)
        let hasExemptState = states.contains(.didntRecord) || states.contains(.paused) || states.contains(.fasting)
        let gapBandsOn = (try? store.gapBandsOn()) ?? RecordStore.Defaults.gapBandsOn
        let gapIndexes = GapBand.indexesBeforeBand(
            sortedTimes: entries.map(\.time),
            stage2Open: GapBand.applies(toDayKey: dayKey, stage2OpenedDayKey: stage2OpenedDayKey, switchOn: gapBandsOn),
            dayHasExemptState: hasExemptState,
            isCollapsed: !isExpanded,
            maxAwakeGapHours: ProgrammeConstants.default.maxAwakeGapHours
        )
        let plan = stage2Open
            ? PlanToday.load(dateKey: dayKey, recordDay: interval, store: store, entries: entries, now: Date(), calendar: .current)
            : nil
        return DaySection(id: dayKey, interval: interval, role: role, entries: entries, states: states, isExpanded: isExpanded, gapBandIndexesBefore: gapIndexes, plan: plan)
    }
}
