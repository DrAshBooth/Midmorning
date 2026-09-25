import Foundation
import Record

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
            maxAwakeGapHours: 4
        )
        return DaySection(id: dayKey, interval: interval, role: role, entries: entries, states: states, isExpanded: isExpanded, gapBandIndexesBefore: gapIndexes)
    }
}
