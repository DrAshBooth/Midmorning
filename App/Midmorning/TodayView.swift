import SwiftUI
import Record
import Plan
import Programme
import AppLock

/// The record day's entries as a time-ordered column, like the paper
/// record (record spec, "The Today stack"). The order here is the only
/// order: the navigation bar (lock, Get support), the bottom toolbar
/// (Programme, Reviews, Settings), the card slot, the "Getting started"
/// line, the pinned current-day header and its rows, the previous-day
/// section, and the "Earlier days" entry point.
///
/// `programme-engine` (2.1) fills the card slot and the "Getting started"
/// line (decision 91's deferred slots); `regular-eating-plan` and
/// `reminders` still own "Today's plan" and the notification permission
/// line (record spec, "The Today stack": "Another capability MUST NOT add
/// an element to Today except through the card slot or a day section row").
/// Pushed onto Today's own navigation stack, alongside `EarlierDaysRoute` and
/// a plain `String` day key (product-rules spec, "Appearance"): the
/// Programme screen, a stage screen, and one content card.
enum ProgrammeRoute: Hashable {
    case screen
}

struct CardRoute: Hashable {
    let cardId: String
}

/// The weigh-in screen (weigh-in spec, "The app accepts a weight on the
/// weigh-in day only": "From Today the route is 'Programme', then 'Getting
/// started', then 'Weigh-in'."). One route value; the screen reads every
/// fact it needs from `store`, so the route carries no payload.
struct WeighInRoute: Hashable {}

/// The "Reviews" list, and one review by its own week number (weekly-review
/// spec, "Finish and reopen a review").
struct ReviewsListRoute: Hashable {}
struct WeeklyReviewRoute: Hashable { let week: Int }

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
    @State private var scrollTarget: String?
    @State private var pendingDelete: RecordRow?
    @State private var navigationPath = NavigationPath()
    @AccessibilityFocusState private var addEntryFocused: Bool
    @State private var isShowingSupportSheet = false
    @State private var programmeSnapshot: ProgrammeModel.Snapshot?
    @State private var weeklyReviewSnapshot: WeeklyReviewModel.Snapshot?
    @State private var pinnedNoteHeld = false
    @State private var pendingCard: PendingCard?
    @State private var openCardId: String?
    @State private var planBuilderMode: PlanBuilderMode?
    /// `mm-t24.21` wires the live notification-permission read (`onboarding`'s
    /// own permission request result) into this fact; a fresh install reads
    /// as not determined, the same fixture-fact pattern `stage2Open` uses
    /// ahead of `programme-engine`.
    @State private var notificationPermission: NotificationPermission = .notDetermined
    @State private var hasTappedNotificationsDeniedLineOnce = false
    @State private var isShowingCloseTheDay = false

    /// The live stage 2 state (programme spec, "Stage 2 opens after five
    /// recorded days"); `GapBand`, `PlanBuilderAccess` and `DaySection` all
    /// read this same value.
    private var stage2Open: Bool { programmeSnapshot?.state.isOpen(.regularEating) ?? false }

    /// The record day stage 2 opened, or `nil` while it is closed: the gap
    /// bands show from that day on (record spec, "The gap band").
    private var stage2OpenedDayKey: String? { programmeSnapshot?.state.stageOpenedDayKey[.regularEating] }

    /// The pinned note Today shows, or `nil` while a starred entry or an "I
    /// binged" outcome holds it back for the rest of this record day
    /// (weekly-review spec, "The one thing to change and the pinned note",
    /// decision 90).
    private var pinnedNoteText: String? {
        guard !pinnedNoteHeld, let note = weeklyReviewSnapshot?.pinnedNote, !note.isEmpty else { return nil }
        return note
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        if let note = pinnedNoteText {
                            Button {
                                if let week = weeklyReviewSnapshot?.pinnedNoteWeek { navigationPath.append(WeeklyReviewRoute(week: week)) }
                            } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Image(systemName: "pin.fill")
                                    Text(verbatim: note).font(.body)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(.primary)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(note)
                            .listRowSeparator(.hidden)
                        }
                        if let dueWeek = weeklyReviewSnapshot?.dueWeek {
                            Button {
                                navigationPath.append(WeeklyReviewRoute(week: dueWeek))
                            } label: {
                                Text("today.weeklyReview")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowSeparator(.hidden)
                        }
                        if let pendingCard {
                            TodayCardSlotView(card: pendingCard, onPrimary: { primaryCardAction(pendingCard) }, onClose: { answerCard(pendingCard, value: "Close") })
                        }
                        if !stage2Open {
                            Button {
                                navigationPath.append(Stage.gettingStarted)
                            } label: {
                                Text("today.gettingStarted")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    // record spec, "The Today stack": the current day
                    // heading and "Add an entry" form a pinned section
                    // header, which stays on screen while the rows scroll.
                    Section {
                        if ReminderPermissionText.todayLine(permission: notificationPermission, hasTappedDeniedLineOnce: hasTappedNotificationsDeniedLineOnce) != nil {
                            Button(action: tapNotificationsLine) {
                                if notificationPermission == .notDetermined {
                                    Text("today.reminders.notDetermined")
                                } else {
                                    Text("today.reminders.denied")
                                }
                            }
                        }
                        if let currentSection {
                            DaySectionRows(section: currentSection, actions: actions(for: currentSection))
                            // "Pause for today" sits under the rows, also on
                            // a collapsed day (record spec, "'Pause for
                            // today'").
                            Button(currentSection.states.contains(.paused) ? "today.pauseForToday.on" : "today.pauseForToday") {
                                togglePause(currentSection)
                            }
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        pinnedHeader
                    }
                    if let previousSection, !previousSection.entries.isEmpty {
                        Section {
                            DaySectionRows(section: previousSection, actions: actions(for: previousSection))
                        } header: {
                            DaySectionHeading(section: previousSection, actions: actions(for: previousSection))
                        }
                    }
                }
                .recordListStyle()
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    proxy.scrollTo(target, anchor: .center)
                    scrollTarget = nil
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
                    // "Settings" opens the real screen (settings spec, "One
                    // screen, one tap from Today"); "Reviews" shows from the
                    // moment the first weekly review becomes due
                    // (`weeklyReviewSnapshot.reviewsControlShows`, record
                    // spec, "The Today stack").
                    ForEach(Array(BottomToolbar.items(reviewsDue: weeklyReviewSnapshot?.reviewsControlShows ?? false).enumerated()), id: \.offset) { index, item in
                        if index > 0 { Spacer() }
                        if item == "Settings" {
                            NavigationLink("today.settings") {
                                SettingsView(store: store)
                            }
                        } else if item == "Programme" {
                            Button(item) { navigationPath.append(ProgrammeRoute.screen) }
                        } else if item == "Reviews" {
                            Button(item) { navigationPath.append(ReviewsListRoute()) }
                        } else {
                            Button {} label: { Text(item) }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(store: store, day: day, initialTime: newEntryInitialTime) { saved in
                    expandDayOfSavedEntry(saved)
                    reload()
                    scrollTarget = scrollId(forSaved: saved)
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
            .deleteEntryConfirmation($pendingDelete) { entry in
                try? store.delete(entryId: entry.id, deletedAt: Date())
                reload()
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
                EarlierDayDetailView(store: store, initialDayKey: dayKey, stage2OpenedDayKey: stage2OpenedDayKey, navigationPath: $navigationPath)
            }
            .navigationDestination(for: ProgrammeRoute.self) { _ in
                ProgrammeScreenView(store: store)
            }
            .navigationDestination(for: Stage.self) { stage in
                StageScreenView(store: store, stage: stage)
            }
            .navigationDestination(for: CardRoute.self) { route in
                CardScreenView(store: store, cardId: route.cardId, recordsAnswerOnAppear: openCardId == route.cardId)
            }
            .navigationDestination(for: WeighInRoute.self) { _ in
                WeighInScreenView(store: store)
            }
            .navigationDestination(for: ReviewsListRoute.self) { _ in
                ReviewsListView(store: store, openWeek: { week in navigationPath.append(WeeklyReviewRoute(week: week)) })
            }
            .navigationDestination(for: WeeklyReviewRoute.self) { route in
                ReviewScreenView(store: store, week: route.week, onDone: { reload() })
            }
            .accessibilityAction(.magicTap) { openNewEntry() }
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

    /// The current day heading and "Add an entry", the header of the
    /// current day's section (record spec, "The Today stack").
    private var pinnedHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let currentSection {
                DaySectionHeading(section: currentSection, actions: actions(for: currentSection))
            }
            Button {
                openNewEntry()
            } label: {
                Text("today.addEntry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityFocused($addEntryFocused)
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    // MARK: Day sections

    /// What a day section's heading and rows do on Today. Only the current
    /// day offers "Earlier days", "Close the day" and the plan builder.
    private func actions(for section: DaySection) -> DaySectionActions {
        let isCurrent = section.role == .current
        return DaySectionActions(
            edit: { editingEntry = $0 },
            askToDelete: { pendingDelete = $0 },
            setExpanded: { setExpanded(section, expanded: $0) },
            toggleState: { toggleState($0, section: section, on: $1) },
            addPlannedMeal: { time in
                newEntryInitialTime = time
                showingNewEntry = true
            },
            skipPlannedMeal: { slotIndex in
                try? store.setPlannedMealAnswer("Skipped", dateKey: section.id, slotIndex: slotIndex, changedAt: Date())
                reload()
            },
            openEarlierDays: isCurrent && earlierDaysAvailable ? { navigationPath.append(EarlierDaysRoute.list) } : nil,
            closeTheDay: isCurrent ? { isShowingCloseTheDay = true } : nil,
            openPlanBuilder: isCurrent && PlanBuilderAccess.isOffered(stage2Open: stage2Open) ? { planBuilderMode = $0 } : nil
        )
    }

    // MARK: The card slot (programme spec, "A stage opening shows one
    // card", "Two stage 1 cards come to Today", "A card when the plan is
    // not set")

    /// Writes the card's answer and performs its control's own action
    /// (programme spec, "The card's answer is kept in the record"): "Open"
    /// pushes the stage screen, "Read" pushes the card screen, "Set it up"
    /// opens the plan builder. "Close" only ever answers and reloads.
    private func primaryCardAction(_ card: PendingCard) {
        switch card.kind {
        case .opening:
            answerCard(card, value: "Open")
            if let stage = card.openingStage { navigationPath.append(stage) }
        case .stage1:
            answerCard(card, value: "Read")
            openCardId = card.id
            navigationPath.append(CardRoute(cardId: card.id))
        case .plan:
            answerCard(card, value: "Set it up")
            planBuilderMode = .template(kind: .weekday, titleKey: "plan.weekday")
        }
    }

    private func answerCard(_ card: PendingCard, value: String) {
        try? store.setCardAnswer(value, id: card.id, changedAt: Date())
        reload()
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

    /// "Add an entry" and the two-finger double tap open the new-entry
    /// screen at the current time, never at a planned meal's time that an
    /// earlier "Add it" set.
    private func openNewEntry() {
        newEntryInitialTime = nil
        showingNewEntry = true
    }

    /// A save into a collapsed day expands that day and keeps the choice
    /// (record spec, "Collapse a day to a count"). A new entry goes into
    /// the current or the previous record day.
    private func expandDayOfSavedEntry(_ saved: RecordRow) {
        let role: RecordDayRole = saved.dayKey == currentSection?.id ? .current : .previous
        let kept = (try? store.collapseChoice(dateKey: saved.dayKey)) ?? nil
        if let choice = CollapseDefault.choiceAfterSave(role: role, kept: kept) {
            try? store.setCollapseChoice(choice, dateKey: saved.dayKey)
        }
    }

    /// The scroll id of the row that shows the saved entry, after `reload`
    /// (record spec, "Save is quiet").
    private func scrollId(forSaved saved: RecordRow) -> String? {
        [currentSection, previousSection]
            .compactMap { $0 }
            .first { $0.id == saved.dayKey }?
            .scrollId(forEntry: saved.id)
    }

    private func reload() {
        let now = Date()
        programmeSnapshot = ProgrammeModel.load(store: store, now: now, calendar: .current)
        day = RecordDay.interval(containing: now, calendar: .current)
        let previous = RecordDay.previous(day, calendar: .current)
        let currentKey = RecordDay.key(containing: now, calendar: .current)
        let previousKey = RecordDay.key(containing: previous.start, calendar: .current)
        currentSection = DaySection.load(dayKey: currentKey, interval: day, role: .current, store: store, stage2Open: stage2Open, stage2OpenedDayKey: stage2OpenedDayKey)
        previousSection = DaySection.load(dayKey: previousKey, interval: previous, role: .previous, store: store, stage2Open: stage2Open, stage2OpenedDayKey: stage2OpenedDayKey)
        earlierDaysAvailable = (try? EarlierDays.isAvailable(dateKeysWithContent: store.dateKeysWithContent(before: previousKey), previousRecordDayKey: previousKey)) ?? false
        hasTappedNotificationsDeniedLineOnce = (try? store.hasTappedNotificationsDeniedLineOnce()) ?? false

        let starredToday = currentSection?.entries.contains { $0.feltLikeABinge } ?? false
        if let snapshot = programmeSnapshot {
            pendingCard = ProgrammeModel.nextTodayCard(snapshot, starredEntryOrOutcomeAt: starredToday ? now : nil, currentRecordDay: day)
        } else {
            pendingCard = nil
        }
        pinnedNoteHeld = WeeklyReviewModel.pinnedNoteHeld(starredEntryOrOutcomeAt: starredToday ? now : nil, currentRecordDay: day)
        weeklyReviewSnapshot = WeeklyReviewModel.load(store: store, now: now, calendar: .current)
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
