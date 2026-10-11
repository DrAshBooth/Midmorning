import SwiftUI
import Record
import Plan
import Programme
import AppLock

/// Keeps the last route a reminder response asked for until Today can open
/// it. `AppDelegate` owns the one inbox, so a response that arrives on a
/// cold launch, before the store opens or before onboarding ends, is not
/// lost: Today reads the inbox when it appears (reminders spec, "The
/// weigh-in day reminder", "The weekly review reminder", "Close the day",
/// "The midday reminder", "The morning plan reminder while the plan needs
/// setting").
@MainActor
final class ReminderRouteInbox: ObservableObject {
    @Published private(set) var pending: ReminderTapRoute?
    /// The screens that make a route wait while they show, by the id of
    /// each hold (`holdsReminderRoutes`, `holdsReminderRoutesWhileOpen`): a
    /// new-entry screen with input, a safeguarding page, and a screen that
    /// holds answers (`TodayRouteGate.Hold`).
    @Published private(set) var holds: [UUID: TodayRouteGate.Hold] = [:]

    /// A later response replaces an earlier one that did not open yet.
    func request(_ route: ReminderTapRoute) {
        pending = route
    }

    func take() -> ReminderTapRoute? {
        defer { pending = nil }
        return pending
    }

    /// Adds the hold `id` of the kind `hold`, or removes it when `hold` is
    /// nil.
    func setHold(_ id: UUID, _ hold: TodayRouteGate.Hold?) {
        if holds[id] != hold { holds[id] = hold }
    }
}

private struct ReminderRouteInboxKey: EnvironmentKey {
    static let defaultValue: ReminderRouteInbox? = nil
}

extension EnvironmentValues {
    /// The route inbox, on Today and on each screen and sheet that opens
    /// from Today (`opensReminderRoutes` sets it). `nil` in other places,
    /// for example in the cover window, so a screen there holds no route.
    var reminderRouteInbox: ReminderRouteInbox? {
        get { self[ReminderRouteInboxKey.self] }
        set { self[ReminderRouteInboxKey.self] = newValue }
    }
}

extension View {
    /// Opens the route in `ReminderRouteInbox` on Today. Every route but
    /// "Add" first empties Today's navigation path, so no screen that was
    /// on Today's stack (for example "Programme" or "Settings") stays
    /// (ruling r20-01, mm-t45.12). The weigh-in screen and the weekly review
    /// then go onto Today's own navigation stack, so "Back" returns to
    /// Today. Every other route opens the sheet Today already uses for the
    /// same screen, or only shows Today.
    ///
    /// `TodayRouteGate` tells when the route opens. It waits while a
    /// new-entry screen with input or a safeguarding page shows
    /// (`holdsReminderRoutes`), while a screen that holds answers is open
    /// (`holdsReminderRoutesWhileOpen`, ruling r22-01), and while a sheet of
    /// Today (`sheetOnScreen`) shows. An empty new-entry sheet closes first.
    /// A sheet or a screen that is the route's own screen stays, and the
    /// route opens nothing more (ruling r22-02).
    func opensReminderRoutes(
        store: RecordStore,
        navigationPath: Binding<NavigationPath>,
        showingNewEntry: Binding<Bool>,
        sheetOnScreen: TodayRouteGate.TodaySheet?,
        newEntryInitialTime: Binding<Date?>,
        isShowingCloseTheDay: Binding<Bool>,
        planBuilderMode: Binding<PlanBuilderMode?>
    ) -> some View {
        modifier(ReminderRouteOpening(
            store: store,
            navigationPath: navigationPath,
            showingNewEntry: showingNewEntry,
            sheetOnScreen: sheetOnScreen,
            newEntryInitialTime: newEntryInitialTime,
            isShowingCloseTheDay: isShowingCloseTheDay,
            planBuilderMode: planBuilderMode
        ))
    }

    /// While this view shows, a reminder route waits (`TodayRouteGate`),
    /// with the hold `hold`; nil holds nothing. The new-entry screen holds
    /// while it holds input (rulings r20-01 and r22-02). Each safeguarding
    /// page holds until "Done" (ruling r22-01; safeguarding spec, "The
    /// not-right-now page", "The GP suggestion page"). Put it on the
    /// screen's own `NavigationStack`: a screen that the stack pushes (for
    /// example the export screen of a page) does not end the hold. Outside
    /// Today (no `reminderRouteInbox`), it does nothing.
    func holdsReminderRoutes(_ hold: TodayRouteGate.Hold?) -> some View {
        modifier(ReminderRouteHold(hold: hold))
    }

    /// From the first appearance of this view until the view leaves the
    /// hierarchy, a reminder route waits, with the hold `hold` (ruling
    /// r22-01): the weekly review, the check-in, the restart re-screen and
    /// the weigh-in screen stay until the person leaves them. The hold does
    /// not end when the screen disappears under its own full-screen page or
    /// under a sheet: it ends when SwiftUI removes the screen's state, after
    /// "Back", "Done" or the end of its sheet. Outside Today (no
    /// `reminderRouteInbox`), it does nothing.
    func holdsReminderRoutesWhileOpen(_ hold: TodayRouteGate.Hold) -> some View {
        modifier(ReminderRouteScreenHold(hold: hold))
    }
}

private struct ReminderRouteHold: ViewModifier {
    let hold: TodayRouteGate.Hold?
    @Environment(\.reminderRouteInbox) private var routes
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { routes?.setHold(id, hold) }
            .onChange(of: hold) { _, hold in routes?.setHold(id, hold) }
            .onDisappear { routes?.setHold(id, nil) }
    }
}

/// The hold of one open screen (`holdsReminderRoutesWhileOpen`). SwiftUI
/// keeps a `StateObject` while the screen is in the hierarchy, also while
/// a full-screen page covers it, and releases it when the screen leaves.
/// The release removes the hold one turn of the main queue later, so a page
/// that appears as the screen leaves (the not-right-now page after the
/// re-screen) adds its own hold first.
@MainActor
private final class ReminderRouteHoldToken: ObservableObject {
    let id = UUID()
    nonisolated(unsafe) private weak var routes: ReminderRouteInbox?

    func attach(_ routes: ReminderRouteInbox?, _ hold: TodayRouteGate.Hold) {
        guard let routes else { return }
        self.routes = routes
        routes.setHold(id, hold)
    }

    deinit {
        let id = id
        Task { @MainActor [weak routes] in routes?.setHold(id, nil) }
    }
}

private struct ReminderRouteScreenHold: ViewModifier {
    let hold: TodayRouteGate.Hold
    @Environment(\.reminderRouteInbox) private var routes
    @StateObject private var token = ReminderRouteHoldToken()

    func body(content: Content) -> some View {
        content
            .onAppear { token.attach(routes, hold) }
    }
}

private struct ReminderRouteOpening: ViewModifier {
    let store: RecordStore
    @Binding var navigationPath: NavigationPath
    @Binding var showingNewEntry: Bool
    /// The sheet of Today that shows, from its appearance until its
    /// dismissal has ended (TodayView's `onDismiss`). So a route that waits
    /// for a sheet opens after the sheet has gone, not during the
    /// animation, when a second sheet cannot show yet.
    let sheetOnScreen: TodayRouteGate.TodaySheet?
    @Binding var newEntryInitialTime: Date?
    @Binding var isShowingCloseTheDay: Bool
    @Binding var planBuilderMode: PlanBuilderMode?
    @EnvironmentObject private var routes: ReminderRouteInbox
    @EnvironmentObject private var appLockController: AppLockController

    func body(content: Content) -> some View {
        content
            .environment(\.reminderRouteInbox, routes)
            .onAppear(perform: openPendingRoute)
            .onChange(of: routes.pending) { _, _ in openPendingRoute() }
            .onChange(of: routes.holds) { _, _ in openPendingRoute() }
            .onChange(of: appLockController.state) { _, _ in openPendingRoute() }
            .onChange(of: sheetOnScreen) { _, _ in openPendingRoute() }
    }

    private func openPendingRoute() {
        guard let route = routes.pending else { return }
        if route == .addAction {
            // app-lock spec, "A new entry before authentication": the
            // pending route shows the new-entry screen with no cover.
            _ = routes.take()
            appLockController.handle(.pendingRouteRequested(.newEntry))
            return
        }
        // Every other route waits until no cover shows (app-lock spec, "The
        // cover"), so no screen with record content opens above it.
        guard appLockController.state.opensAReminderRoute else { return }
        let now = Date()
        let currentDayKey = RecordDay.key(containing: now, calendar: .current, schedule: (try? store.dayStartSchedule()) ?? .standard)
        // Rulings r20-01, r22-01 and r22-02 (mm-t45.12, mm-t45.23): a
        // new-entry screen with input stays, and the route waits until it
        // closes. A safeguarding page stays until "Done". The weekly review,
        // the re-screen and the weigh-in screen stay until the person leaves
        // them; when one of them is the route's own screen, it stays and
        // the route opens nothing.
        let holds = routes.holds.values
        let latestDueWeek: Int? = route == .weeklyReview && holds.contains(where: { if case .weeklyReview = $0 { return true } else { return false } })
            ? WeeklyReviewModel.load(store: store, now: now, calendar: .current).latestDueWeek : nil
        switch TodayRouteGate.step(
            held: !holds.isEmpty,
            holdsAreTheRouteScreen: !holds.isEmpty && holds.allSatisfy { $0.isScreen(of: route, latestDueWeek: latestDueWeek) },
            sheetOnScreen: sheetOnScreen,
            sheetIsClosing: sheetIsClosing,
            routeScreenShows: routeScreenShows(route, currentDayKey: currentDayKey)
        ) {
        case .wait:
            return
        case .closeTheNewEntrySheet:
            // `sheetOnScreen` clears when the dismissal ends, and the route
            // opens then.
            showingNewEntry = false
            return
        case .keep:
            _ = routes.take()
            navigationPath = NavigationPath()
            return
        case .keepTheScreen:
            _ = routes.take()
            return
        case .open:
            break
        }
        _ = routes.take()
        // Ruling r20-01 (mm-t45.12): go back to Today first. The route's own
        // screen then opens on Today, and "Back" from it shows Today.
        navigationPath = NavigationPath()
        switch route {
        case .today, .addAction:
            break
        case .newEntry:
            newEntryInitialTime = nil
            showingNewEntry = true
        case .todaysPlan:
            let stage2Open = ProgrammeModel.load(store: store, now: now, calendar: .current).state.isOpen(.regularEating)
            if stage2Open {
                planBuilderMode = .day(dateKey: currentDayKey, titleKey: "plan.today", isCurrentDay: true)
            }
        case .closeTheDay(let dayKey):
            // A tap after the record day ends opens Today: the close-the-day
            // screen is for the current record day only, as on Today.
            if dayKey == nil || dayKey == currentDayKey {
                isShowingCloseTheDay = true
            }
        case .weighIn:
            navigationPath.append(WeighInRoute())
        case .weeklyReview:
            // The latest due week, finished or not: a late tap after "Done"
            // reopens that review. Before the first review is due, Today.
            if let week = WeeklyReviewModel.load(store: store, now: now, calendar: .current).latestDueWeek {
                navigationPath.append(WeeklyReviewRoute(week: week))
            }
        }
    }

    /// The dismissal of `sheetOnScreen` started and did not end yet: the
    /// sheet's presentation value is already off. The bindings give the
    /// value at this moment, also before Today's body runs again. The edit
    /// screen's value is not here: the route waits for that sheet in each
    /// case (`TodayRouteGate`), so its dismissal changes no step.
    private var sheetIsClosing: Bool {
        switch sheetOnScreen {
        case .newEntry: return !showingNewEntry
        case .closeTheDay: return !isShowingCloseTheDay
        case .planBuilder: return planBuilderMode == nil
        case .editEntry, nil: return false
        }
    }

    /// The sheet of Today that shows is the screen that `route` opens: the
    /// new-entry screen for the midday reminder, "Today's plan" for the
    /// morning plan reminder, or the close-the-day screen of the current
    /// record day for the close-the-day reminder.
    private func routeScreenShows(_ route: ReminderTapRoute, currentDayKey: String) -> Bool {
        switch route {
        case .newEntry:
            return sheetOnScreen == .newEntry
        case .todaysPlan:
            return sheetOnScreen == .planBuilder && planBuilderMode?.id == PlanBuilderMode.day(dateKey: currentDayKey, titleKey: "plan.today", isCurrentDay: true).id
        case .closeTheDay(let dayKey):
            return sheetOnScreen == .closeTheDay && (dayKey == nil || dayKey == currentDayKey)
        case .today, .addAction, .weighIn, .weeklyReview:
            return false
        }
    }
}
