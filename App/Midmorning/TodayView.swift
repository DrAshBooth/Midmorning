import SwiftUI
import Record
import Plan
import Programme
import AppLock

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

    // The app's one real `AppLockController` (mm-t13.9's own pattern):
    // shared through the environment, so the lock control here and the
    // cover `AppLockRootView` overlays agree on the lock state (app-lock
    // spec, "The lock control on Today").
    @EnvironmentObject private var appLockController: AppLockController
    @Environment(\.scenePhase) private var scenePhase
    @State private var day = RecordDay.interval(containing: Date(), calendar: .current)
    @State private var currentSection: DaySection?
    @State private var previousSection: DaySection?
    @State private var earlierDaysAvailable = false
    @State private var showingNewEntry = false
    @State private var newEntryInitialTime: Date?
    @State private var editingEntry: RecordRow?
    @State private var scrollTarget: UUID?
    @State private var navigationPath = NavigationPath()
    @AccessibilityFocusState private var addEntryFocused: Bool
    @State private var isShowingSupportSheet = false
    /// `programme-engine` (2.1) is not built, so this is a fixture fact, the
    /// same pattern `GapBand`'s own `stage2Open` already uses; `mm-t21.23`
    /// wires the live stage into both.
    @State private var stage2Open = false
    @State private var planBuilderMode: PlanBuilderMode?
    /// `mm-t24.21` wires the live notification-permission read (`onboarding`'s
    /// own permission request result) into this fact; a fresh install reads
    /// as not determined, the same fixture-fact pattern `stage2Open` uses
    /// ahead of `programme-engine`.
    @State private var notificationPermission: NotificationPermission = .notDetermined
    @State private var hasTappedNotificationsDeniedLineOnce = false
    @State private var isShowingCloseTheDay = false

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
                    // app-lock spec, "The lock control on Today": locks at
                    // once, with no grace period, whether or not the app
                    // lock is on (`AppLifecycleEvent.lockControlTapped`).
                    Button {
                        appLockController.handle(.lockControlTapped)
                    } label: {
                        Image(systemName: "lock")
                    }
                    .accessibilityLabel("today.lock.accessibilityLabel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSupportSheet = true
                    } label: {
                        Text("today.getSupport")
                    }
                    .accessibilityLabel("today.getSupport")
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
                NewEntryView(store: store, day: day, initialTime: newEntryInitialTime) { saved in
                    reload()
                    scrollTarget = saved.id
                    addEntryFocused = true
                }
            }
            .sheet(item: $planBuilderMode) { mode in
                PlanBuilderView(store: store, mode: mode) { reload() }
            }
            .sheet(item: $editingEntry) { entry in
                EditEntryView(store: store, entry: entry, dayStartHour: RecordDay.startHour) { _ in
                    reload()
                } onDelete: {
                    reload()
                }
            }
            .sheet(isPresented: $isShowingSupportSheet) {
                SupportSheetView()
            }
            .sheet(isPresented: $isShowingCloseTheDay) {
                if let currentSection {
                    CloseTheDayView(store: store, dateKey: currentSection.id) { reload() }
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
            if ReminderPermissionText.todayLine(permission: notificationPermission, hasTappedDeniedLineOnce: hasTappedNotificationsDeniedLineOnce) != nil {
                Button(action: tapNotificationsLine) {
                    if notificationPermission == .notDetermined {
                        Text("today.reminders.notDetermined")
                    } else {
                        Text("today.reminders.denied")
                    }
                }
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
            let items = section.displayItems
            ForEach(items) { item in
                switch item {
                case .entry(let entry):
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
                case .planned(let row):
                    PlannedMealRowView(row: row, dateKey: section.id, onAddIt: { time in
                        newEntryInitialTime = time
                        showingNewEntry = true
                    }, onSkip: { slotIndex in
                        try? store.setPlannedMealAnswer("Skipped", dateKey: section.id, slotIndex: slotIndex, changedAt: Date())
                        reload()
                    })
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture { if let entry = row.matchedEntry { editingEntry = entry } }
                }
                if showBands, let entryIndex = entryIndex(of: item, in: section.entries), section.gapBandIndexesBefore.contains(entryIndex) {
                    GapBandRow()
                }
            }
            if let trailingLine = section.plan?.trailingNextLine {
                Text(trailingLine)
                    .font(.body)
                    .listRowSeparator(.hidden)
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
                if section.role == .current {
                    Divider()
                    Button("closeTheDay.title") { isShowingCloseTheDay = true }
                }
                if section.role == .current, PlanBuilderAccess.isOffered(stage2Open: stage2Open) {
                    Divider()
                    Button("plan.today") {
                        planBuilderMode = .day(dateKey: section.id, titleKey: "plan.today", isCurrentDay: true)
                    }
                    Button("plan.tomorrow") {
                        let tomorrow = RecordDay.next(section.interval, calendar: .current)
                        planBuilderMode = .day(dateKey: RecordDay.key(containing: tomorrow.start, calendar: .current), titleKey: "plan.tomorrow", isCurrentDay: false)
                    }
                    Button("plan.weekday") {
                        planBuilderMode = .template(kind: .weekday, titleKey: "plan.weekday")
                    }
                    Button("plan.weekend") {
                        planBuilderMode = .template(kind: .weekend, titleKey: "plan.weekend")
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

    /// A tap makes the system permission request (when not determined) or
    /// opens the iOS Settings app (when denied), and hides the denied line
    /// after one tap (reminders spec, "Reminder types and their switches").
    /// `mm-t24.21` replaces the fixture request/open with the real
    /// `UNUserNotificationCenter`/`UIApplication.openSettingsURLString` call.
    private func tapNotificationsLine() {
        if notificationPermission == .denied {
            try? store.setHasTappedNotificationsDeniedLineOnce(true)
            hasTappedNotificationsDeniedLineOnce = true
        }
    }

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

    private func entryIndex(of item: DaySection.DisplayItem, in entries: [RecordRow]) -> Int? {
        guard case .entry(let row) = item else { return nil }
        return entries.firstIndex { $0.id == row.id }
    }

    private func reload() {
        let now = Date()
        day = RecordDay.interval(containing: now, calendar: .current)
        let previous = RecordDay.previous(day, calendar: .current)
        let currentKey = RecordDay.key(containing: now, calendar: .current)
        let previousKey = RecordDay.key(containing: previous.start, calendar: .current)
        currentSection = DaySection.load(dayKey: currentKey, interval: day, role: .current, store: store, stage2Open: stage2Open)
        previousSection = DaySection.load(dayKey: previousKey, interval: previous, role: .previous, store: store, stage2Open: stage2Open)
        earlierDaysAvailable = (try? EarlierDays.isAvailable(dateKeysWithContent: store.dateKeysWithContent(before: previousKey), previousRecordDayKey: previousKey)) ?? false
        hasTappedNotificationsDeniedLineOnce = (try? store.hasTappedNotificationsDeniedLineOnce()) ?? false
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
