import SwiftUI
import Record

/// A route pushed onto Today's own navigation stack (product-rules spec,
/// "Appearance": "A screen that shows the record MUST open with a push onto
/// the navigation stack").
enum EarlierDaysRoute: Hashable {
    case list
}

/// "Earlier days": the list of record days from the earliest day with an
/// entry or a state to the day before the previous record day, most recent
/// first, with a row for a day that has neither (record spec, "Earlier
/// record days").
struct EarlierDaysListView: View {
    let store: RecordStore
    @State private var dayKeys: [String] = []

    var body: some View {
        List(dayKeys, id: \.self) { key in
            NavigationLink(value: key) {
                Text(DayHeading.dateOnly(forDayKey: key))
            }
        }
        .recordListStyle()
        .navigationTitle("today.earlierDays")
        .getSupport()
        .onAppear(perform: load)
    }

    private func load() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        dayKeys = (try? store.earlierDayKeys(now: Date(), calendar: calendar)) ?? []
    }
}

/// One earlier record day: its heading, its menu and its rows under the
/// same rules as a day on Today, and controls to move to the previous and
/// the next record day, and back to Today (record spec, "Earlier record
/// days"). The two controls move only inside the "Earlier days" list, so
/// the screen never shows the previous or the current record day; each
/// control turns off at an end of the list. A tap on a row opens the entry
/// for editing; a swipe or the VoiceOver action "Delete" asks before it
/// deletes; the menu offers "Didn't record", "Fasting today" and the
/// collapse control. No control creates an entry here.
struct EarlierDayDetailView: View {
    let store: RecordStore
    /// The record day stage 2 opened, or `nil` while stage 2 is closed: the
    /// plan and the gap bands show from that day on.
    let stage2OpenedDayKey: String?
    @Binding var navigationPath: NavigationPath
    @State private var dayKey: String
    /// The "Earlier days" list, read at each load (mm-t12b.24).
    @State private var earlierDayKeys: [String] = []
    @State private var section: DaySection?
    @State private var editingEntry: RecordRow?
    @State private var pendingDelete: RecordRow?

    init(store: RecordStore, initialDayKey: String, stage2OpenedDayKey: String?, navigationPath: Binding<NavigationPath>) {
        self.store = store
        self.stage2OpenedDayKey = stage2OpenedDayKey
        self._navigationPath = navigationPath
        self._dayKey = State(initialValue: initialDayKey)
    }

    var body: some View {
        List {
            if let section {
                Section {
                    DaySectionRows(section: section, actions: actions(for: section))
                } header: {
                    DaySectionHeading(section: section, actions: actions(for: section))
                }
            }
        }
        .recordListStyle()
        .navigationTitle(Text(DayHeading.dateOnly(forDayKey: dayKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // "Today" and "Get support" (safeguarding spec, "Get support on
            // every screen") share the trailing position; "Get support"
            // sits last, as the true trailing control, from `.getSupport()`
            // below.
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("today.earlierDays.today") {
                    navigationPath.removeLast(navigationPath.count)
                }
            }
        }
        .getSupport()
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    move(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("today.earlierDays.previousDay")
                .disabled(EarlierDays.step(from: dayKey, by: -1, in: earlierDayKeys) == nil)
                Spacer()
                Button {
                    move(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("today.earlierDays.nextDay")
                .disabled(EarlierDays.step(from: dayKey, by: 1, in: earlierDayKeys) == nil)
            }
            .padding()
        }
        .sheet(item: $editingEntry) { entry in
            EditEntryView(store: store, entry: entry) { _ in
                load()
            } onDelete: {
                load()
            }
        }
        .deleteEntryConfirmation($pendingDelete) { entry in
            try? store.delete(entryId: entry.id, deletedAt: Date())
            load()
        }
        .onAppear(perform: load)
        .onChange(of: dayKey) { _, _ in load() }
    }

    /// An earlier day offers no "Earlier days", no "Close the day", no plan
    /// builder and no control that creates an entry. "Add it" shows only
    /// before a record day ends, so it never shows on an earlier day.
    private func actions(for section: DaySection) -> DaySectionActions {
        DaySectionActions(
            edit: { editingEntry = $0 },
            askToDelete: { pendingDelete = $0 },
            setExpanded: { expanded in
                try? store.setCollapseChoice(expanded ? .expanded : .collapsed, dateKey: section.id)
                load()
            },
            toggleState: { kind, on in
                try? store.setDayState(kind, on: on, dateKey: section.id, changedAt: Date())
                load()
            },
            addPlannedMeal: { _ in },
            skipPlannedMeal: { slotIndex in
                try? store.setPlannedMealAnswer("Skipped", dateKey: section.id, slotIndex: slotIndex, changedAt: Date())
                load()
            }
        )
    }

    /// Moves one record day inside the "Earlier days" list; at an end of
    /// the list the control is off and nothing moves.
    private func move(by delta: Int) {
        guard let key = EarlierDays.step(from: dayKey, by: delta, in: earlierDayKeys) else { return }
        dayKey = key
    }

    private func load() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        let interval = RecordDay.interval(forKey: dayKey, calendar: calendar, schedule: schedule)
            ?? RecordDay.interval(containing: Date(), calendar: calendar, schedule: schedule)
        earlierDayKeys = (try? store.earlierDayKeys(now: Date(), calendar: calendar)) ?? []
        let planShows = stage2OpenedDayKey.map { dayKey >= $0 } ?? false
        section = DaySection.load(dayKey: dayKey, interval: interval, role: .earlier, store: store, stage2Open: planShows, stage2OpenedDayKey: stage2OpenedDayKey)
    }
}
