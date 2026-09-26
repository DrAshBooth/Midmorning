import SwiftUI
import Record
import Plan

/// What a day section's heading and rows ask their screen to do. Today and
/// an earlier day each fill one, so a day shows with the same rules on both
/// (record spec, "Earlier record days": "The day MUST show its entries with
/// the same rules as a day on Today"). A `nil` control is not offered.
struct DaySectionActions {
    var edit: (RecordRow) -> Void
    /// Asks "Delete this entry?" first; the screen deletes only on "Delete".
    var askToDelete: (RecordRow) -> Void
    var setExpanded: (Bool) -> Void
    var toggleState: (DayStateKind, Bool) -> Void
    var addPlannedMeal: (Date) -> Void
    var skipPlannedMeal: (Int) -> Void
    var openEarlierDays: (() -> Void)? = nil
    var openPlanBuilder: ((PlanBuilderMode) -> Void)? = nil
}

/// A day's heading and its menu (record spec, "The Today stack": "'Fasting
/// today', 'Didn't record' and 'Earlier days' MUST live in the day heading's
/// menu ... The heading MUST also offer them as custom actions"; "Collapse a
/// day to a count": "Each day heading with at least one entry MUST show a
/// control that collapses the day").
struct DaySectionHeading: View {
    let section: DaySection
    let actions: DaySectionActions

    var body: some View {
        HStack {
            Text(section.heading)
                .font(section.role == .current ? .largeTitle.bold() : .headline)
                .foregroundStyle(.primary)
            Spacer()
            Menu {
                menuItems
            } label: {
                // product-rules spec, "Accessibility everywhere": a hit
                // area of at least 44 by 44 points.
                Image(systemName: "chevron.down")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("today.dayMenu.accessibilityLabel")
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityActions {
            if !section.entries.isEmpty {
                Button(section.isExpanded ? "today.collapseDay" : "today.expandDay") {
                    actions.setExpanded(!section.isExpanded)
                }
            }
            Button("today.fastingToday") {
                actions.toggleState(.fasting, !section.states.contains(.fasting))
            }
            Button("today.didntRecord") {
                actions.toggleState(.didntRecord, !section.states.contains(.didntRecord))
            }
            if let openEarlierDays = actions.openEarlierDays {
                Button("today.earlierDays", action: openEarlierDays)
            }
            if let openPlanBuilder = actions.openPlanBuilder {
                Button("plan.today") { openPlanBuilder(todaysPlan) }
            }
        }
    }

    private var todaysPlan: PlanBuilderMode {
        .day(dateKey: section.id, titleKey: "plan.today", isCurrentDay: true)
    }

    @ViewBuilder
    private var menuItems: some View {
        if !section.entries.isEmpty {
            Button(section.isExpanded ? "today.collapseDay" : "today.expandDay") {
                actions.setExpanded(!section.isExpanded)
            }
        }
        Toggle("today.fastingToday", isOn: Binding(
            get: { section.states.contains(.fasting) },
            set: { actions.toggleState(.fasting, $0) }
        ))
        Toggle("today.didntRecord", isOn: Binding(
            get: { section.states.contains(.didntRecord) },
            set: { actions.toggleState(.didntRecord, $0) }
        ))
        if let openEarlierDays = actions.openEarlierDays {
            Button("today.earlierDays", action: openEarlierDays)
        }
        if let openPlanBuilder = actions.openPlanBuilder {
            Divider()
            Button("plan.today") { openPlanBuilder(todaysPlan) }
            Button("plan.tomorrow") {
                let tomorrow = RecordDay.next(section.interval, calendar: .current)
                openPlanBuilder(.day(dateKey: RecordDay.key(containing: tomorrow.start, calendar: .current), titleKey: "plan.tomorrow", isCurrentDay: false))
            }
            Button("plan.weekday") {
                openPlanBuilder(.template(kind: .weekday, titleKey: "plan.weekday"))
            }
            Button("plan.weekend") {
                openPlanBuilder(.template(kind: .weekend, titleKey: "plan.weekend"))
            }
        }
    }
}

/// A day's rows: the state line, the entries and planned meals in time
/// order with the gap bands between them, and the next-planned-meal line;
/// or, on a collapsed day, the count line and nothing else (record spec,
/// "Collapse a day to a count"). Each row carries its scroll id, so Today
/// can scroll to a saved entry (record spec, "Save is quiet").
struct DaySectionRows: View {
    let section: DaySection
    let actions: DaySectionActions

    var body: some View {
        if section.isExpanded {
            if let stateLine = section.stateLine {
                Text(stateLine)
                    .font(.body)
                    .listRowSeparator(.hidden)
            }
            ForEach(section.displayItems) { item in
                row(item)
                    .id(section.scrollId(of: item))
                if let entryIndex = entryIndex(of: item), section.gapBandIndexesBefore.contains(entryIndex) {
                    GapBandRow()
                }
            }
            if let trailingLine = section.plan?.trailingNextLine {
                Text(trailingLine)
                    .font(.body)
                    .listRowSeparator(.hidden)
            }
        } else {
            collapsedCountRow
        }
    }

    @ViewBuilder
    private func row(_ item: DaySection.DisplayItem) -> some View {
        switch item {
        case .entry(let entry):
            EntryRow(entry: entry)
                .listRowSeparator(.hidden)
                .contentShape(Rectangle())
                .onTapGesture { actions.edit(entry) }
                .entryDeleteActions(for: entry, askToDelete: actions.askToDelete)
        case .planned(let row):
            PlannedMealRowView(row: row, dateKey: section.id, onAddIt: actions.addPlannedMeal, onSkip: actions.skipPlannedMeal)
                .listRowSeparator(.hidden)
                .contentShape(Rectangle())
                .onTapGesture { if let entry = row.matchedEntry { actions.edit(entry) } }
                .entryDeleteActions(for: row.matchedEntry, askToDelete: actions.askToDelete)
        }
    }

    private var collapsedCountRow: some View {
        let count = section.entries.count
        let text = count == 1 ? "1 entry" : "\(count) entries"
        return Text(text)
            .onTapGesture { actions.setExpanded(true) }
    }

    private func entryIndex(of item: DaySection.DisplayItem) -> Int? {
        guard let row = item.recordEntry else { return nil }
        return section.entries.firstIndex { $0.id == row.id }
    }
}

private extension View {
    /// The system's swipe to delete and the VoiceOver action "Delete" on a
    /// row that shows an entry (record spec, "Delete an entry"; "Accessibility
    /// of the additions"). Both only ask; the screen's
    /// `deleteEntryConfirmation` deletes. The swipe button has no
    /// destructive role, because that role removes the row before the
    /// person answers; `.red` keeps the system's swipe colour
    /// (product-rules spec, "Appearance").
    @ViewBuilder
    func entryDeleteActions(for entry: RecordRow?, askToDelete: @escaping (RecordRow) -> Void) -> some View {
        if let entry {
            self
                .swipeActions(edge: .trailing) {
                    Button {
                        askToDelete(entry)
                    } label: {
                        Text("entry.delete.action")
                    }
                    .tint(.red)
                }
                .accessibilityAction(named: Text("entry.delete.action")) { askToDelete(entry) }
        } else {
            self
        }
    }
}

extension View {
    /// Asks once before a delete: "Delete this entry?" with "Delete" and
    /// "Cancel" (record spec, "Delete an entry"). `pending` holds the entry
    /// that a swipe or the VoiceOver action chose; "Delete" calls
    /// `onDelete` with it.
    func deleteEntryConfirmation(_ pending: Binding<RecordRow?>, onDelete: @escaping (RecordRow) -> Void) -> some View {
        confirmationDialog(
            "entry.delete.confirmTitle",
            isPresented: Binding(get: { pending.wrappedValue != nil }, set: { if !$0 { pending.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: pending.wrappedValue
        ) { entry in
            Button("entry.delete.action", role: .destructive) { onDelete(entry) }
            Button("entry.cancel", role: .cancel) {}
        }
    }
}
