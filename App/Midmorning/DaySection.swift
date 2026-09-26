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
    /// opens at stage 2"): `PlanBuilderAccess.isOffered(stage2Open:)` gates
    /// this the same fixture-fact way `GapBand` reads `stage2Open`.
    let plan: PlanDaySection?

    var heading: String {
        let night = role == .current && RecordDay.isNight(Date(), calendar: .current)
        return DayHeading.text(for: interval.start, night: night)
    }

    var stateLine: String? {
        if states.contains(.didntRecord) { return "Didn't record" }
        if states.contains(.paused) { return role == .current ? nil : "Paused" }
        if states.contains(.fasting) { return "Fasting" }
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
            case .entry(let row): return "entry-\(row.id)"
            case .planned(let row): return "planned-\(row.slotIndex)"
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

    @MainActor
    static func load(dayKey: String, interval: DateInterval, role: RecordDayRole, store: RecordStore, stage2Open: Bool) -> DaySection {
        let entries = (try? store.entries(dayKey: dayKey)) ?? []
        let states = (try? store.dayStates(dateKey: dayKey)) ?? []
        let kept = try? store.collapseChoice(dateKey: dayKey)
        let isExpanded = entries.isEmpty || CollapseDefault.isExpanded(role: role, kept: kept ?? nil)
        let hasExemptState = states.contains(.didntRecord) || states.contains(.paused) || states.contains(.fasting)
        let gapIndexes = GapBand.indexesBeforeBand(
            sortedTimes: entries.map(\.time),
            stage2Open: stage2Open && role == .current,
            dayHasExemptState: hasExemptState,
            isCollapsed: !isExpanded,
            maxAwakeGapHours: ProgrammeConstants.default.maxAwakeGapHours
        )
        let plan = PlanBuilderAccess.isOffered(stage2Open: stage2Open)
            ? PlanToday.load(dateKey: dayKey, recordDay: interval, store: store, entries: entries, now: Date(), calendar: .current)
            : nil
        return DaySection(id: dayKey, interval: interval, role: role, entries: entries, states: states, isExpanded: isExpanded, gapBandIndexesBefore: gapIndexes, plan: plan)
    }
}
