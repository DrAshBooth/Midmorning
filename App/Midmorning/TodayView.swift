import SwiftUI
import Record

/// The record day's entries as a time-ordered column, like the paper
/// record (record spec, "The Today stack"). The order here is the only
/// order: the navigation bar (lock, Get support), the bottom toolbar
/// (Programme, Reviews, Settings), the pinned current-day header and its
/// rows, the previous-day section, and the "Earlier days" entry point.
///
/// `programme`, `regular-eating-plan` and `reminders` are not built yet, so
/// the card slot, the "Getting started" line, "Today's plan" and the
/// notification permission line stay empty slots this change adds no
/// content to (decision 91's three deferred slots); the owning capability
/// fills each one without touching this file (record spec, "The Today
/// stack": "Another capability MUST NOT add an element to Today except
/// through the card slot or a day section row").
struct TodayView: View {
    let store: RecordStore

    @Environment(\.scenePhase) private var scenePhase
    @State private var day = RecordDay.interval(containing: Date(), calendar: .current)
    @State private var currentSection: DaySection?
    @State private var previousSection: DaySection?
    @State private var earlierDaysAvailable = false
    @State private var showingNewEntry = false
    @State private var editingEntry: RecordRow?
    @State private var scrollTarget: UUID?
    @State private var navigationPath = NavigationPath()
    @AccessibilityFocusState private var addEntryFocused: Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        pinnedHeader
                        if let currentSection {
                            daySectionRows(currentSection)
                        }
                    }
                    if let previousSection, !previousSection.entries.isEmpty {
                        Section(header: dayHeadingView(previousSection)) {
                            if previousSection.isExpanded {
                                daySectionRows(previousSection, showBands: false)
                            } else {
                                collapsedCountRow(previousSection)
                            }
                        }
                    }
                }
                .recordListStyle()
                .onChange(of: scrollTarget) { _, target in
                    if let target { proxy.scrollTo(target) }
                }
            }
            .navigationTitle("today.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Placeholder: `app-lock` (1.5) wires the real cover and
                    // lock state. The control's presence and position are
                    // this change's own scope (decision 91).
                    Button {} label: {
                        Image(systemName: "lock")
                    }
                    .accessibilityLabel("today.lock.accessibilityLabel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // Placeholder: `onboarding-and-safeguarding` (1.4) wires
                    // the real Get support sheet.
                    Button {} label: {
                        Text("today.getSupport")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    // `weekly-review` (3.2) supplies the live "is a review
                    // due" fact; `false` is this build's fixture. "Settings"
                    // opens the real screen (settings spec, "One screen, one
                    // tap from Today"); "Programme" and "Reviews" stay no-op
                    // placeholders until their own build changes land.
                    ForEach(Array(BottomToolbar.items(reviewsDue: false).enumerated()), id: \.offset) { index, item in
                        if index > 0 { Spacer() }
                        if item == "Settings" {
                            NavigationLink("today.settings") {
                                SettingsView(store: store)
                            }
                        } else {
                            Button {} label: { Text(item) }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(store: store, day: day) { saved in
                    reload()
                    scrollTarget = saved.id
                    addEntryFocused = true
                }
            }
            .sheet(item: $editingEntry) { entry in
                EditEntryView(store: store, entry: entry, dayStartHour: RecordDay.startHour) { _ in
                    reload()
                } onDelete: {
                    reload()
                }
            }
            .navigationDestination(for: EarlierDaysRoute.self) { _ in
                EarlierDaysListView(store: store)
            }
            .navigationDestination(for: String.self) { dayKey in
                EarlierDayDetailView(store: store, initialDayKey: dayKey, navigationPath: $navigationPath)
            }
            .accessibilityAction(.magicTap) { showingNewEntry = true }
        }
        .privacySensitive()
        .redacted(reason: scenePhase == .active ? [] : .privacy)
        .onAppear(perform: reload)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
        .task(id: day.end) {
            // Refresh at 04:00 while Today is on screen.
            let wait = day.end.timeIntervalSinceNow
            if wait > 0, (try? await Task.sleep(for: .seconds(wait))) != nil { reload() }
        }
    }

    // MARK: Pinned header

    private var pinnedHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let currentSection {
                dayHeadingView(currentSection)
            }
            Button {
                showingNewEntry = true
            } label: {
                Text("today.addEntry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityFocused($addEntryFocused)
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 4)
    }

    // MARK: Day sections

    @ViewBuilder
    private func daySectionRows(_ section: DaySection, showBands: Bool = true) -> some View {
        if let stateLine = section.stateLine {
            Text(stateLine)
                .font(.body)
                .listRowSeparator(.hidden)
        }
        if section.isExpanded {
            ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                EntryRow(entry: entry)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture { editingEntry = entry }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            try? store.delete(entryId: entry.id, deletedAt: Date())
                            reload()
                        } label: {
                            Text("entry.delete.action")
                        }
                    }
                    .accessibilityAction(named: Text("entry.delete.action")) {
                        try? store.delete(entryId: entry.id, deletedAt: Date())
                        reload()
                    }
                if showBands, section.gapBandIndexesBefore.contains(index) {
                    GapBandRow()
                }
            }
            if section.role == .current {
                Button(section.states.contains(.paused) ? "today.pauseForToday.on" : "today.pauseForToday") {
                    togglePause(section)
                }
                .listRowSeparator(.hidden)
            }
        } else {
            collapsedCountRow(section)
        }
    }

    private func collapsedCountRow(_ section: DaySection) -> some View {
        let count = section.entries.count
        let text = count == 1 ? "1 entry" : "\(count) entries"
        return Text(text)
            .onTapGesture { setExpanded(section, expanded: true) }
    }

    private func dayHeadingView(_ section: DaySection) -> some View {
        HStack {
            Text(section.heading)
                .font(section.role == .current ? .largeTitle.bold() : .headline)
            Spacer()
            Menu {
                if !section.entries.isEmpty {
                    Button(section.isExpanded ? "today.collapseDay" : "today.expandDay") {
                        setExpanded(section, expanded: !section.isExpanded)
                    }
                }
                Toggle("today.fastingToday", isOn: Binding(
                    get: { section.states.contains(.fasting) },
                    set: { toggleState(.fasting, section: section, on: $0) }
                ))
                Toggle("today.didntRecord", isOn: Binding(
                    get: { section.states.contains(.didntRecord) },
                    set: { toggleState(.didntRecord, section: section, on: $0) }
                ))
                if section.role == .current, earlierDaysAvailable {
                    Button("today.earlierDays") {
                        navigationPath.append(EarlierDaysRoute.list)
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
            }
            .accessibilityLabel("today.dayMenu.accessibilityLabel")
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction(named: Text(section.isExpanded ? "today.collapseDay" : "today.expandDay")) {
            setExpanded(section, expanded: !section.isExpanded)
        }
        .accessibilityAction(named: Text("today.didntRecord")) {
            toggleState(.didntRecord, section: section, on: !section.states.contains(.didntRecord))
        }
    }

    // MARK: Actions

    private func togglePause(_ section: DaySection) {
        let on = !section.states.contains(.paused)
        try? store.setDayState(.paused, on: on, dateKey: section.id, changedAt: Date())
        reload()
    }

    private func toggleState(_ kind: DayStateKind, section: DaySection, on: Bool) {
        try? store.setDayState(kind, on: on, dateKey: section.id, changedAt: Date())
        reload()
    }

    private func setExpanded(_ section: DaySection, expanded: Bool) {
        try? store.setCollapseChoice(expanded ? .expanded : .collapsed, dateKey: section.id)
        reload()
    }

    private func reload() {
        let now = Date()
        day = RecordDay.interval(containing: now, calendar: .current)
        let previous = RecordDay.previous(day, calendar: .current)
        let currentKey = RecordDay.key(containing: now, calendar: .current)
        let previousKey = RecordDay.key(containing: previous.start, calendar: .current)
        currentSection = DaySection.load(dayKey: currentKey, interval: day, role: .current, store: store, stage2Open: false)
        previousSection = DaySection.load(dayKey: previousKey, interval: previous, role: .previous, store: store, stage2Open: false)
        earlierDaysAvailable = (try? EarlierDays.isAvailable(dateKeysWithContent: store.dateKeysWithContent(before: previousKey), previousRecordDayKey: previousKey)) ?? false
    }
}

/// One row: time, the asterisk when starred, What, Where and Context.
/// Every row has the same layout whatever the time since the previous
/// entry (record spec, "Today's appearance"; "Today shows Where and
/// Context").
struct EntryRow: View {
    let entry: RecordRow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(spacing: 2) {
                    Text(entry.clockTime)
                    if entry.feltLikeABinge {
                        Text(verbatim: "*")
                    }
                }
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
                if !entry.what.isEmpty {
                    Text(entry.what)
                        .font(.body)
                }
                if !entry.whereText.isEmpty {
                    Text(entry.whereText)
                        .font(.body)
                }
                Spacer(minLength: 0)
            }
            if !entry.context.isEmpty {
                Text(entry.context)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.accessibilityLabel)
    }
}

/// The gap band: a thin rule with no text, number or icon (record spec,
/// "The gap band").
struct GapBandRow: View {
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .secondaryLabel))
            .frame(height: 4)
            .listRowSeparator(.hidden)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(GapBand.accessibilityLabel(maxAwakeGapHours: 4))
    }
}
