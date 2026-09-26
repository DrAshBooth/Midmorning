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

    /// A later response replaces an earlier one that did not open yet.
    func request(_ route: ReminderTapRoute) {
        pending = route
    }

    func take() -> ReminderTapRoute? {
        defer { pending = nil }
        return pending
    }
}

extension View {
    /// Opens the route in `ReminderRouteInbox` on Today. The weigh-in
    /// screen and the weekly review go onto Today's own navigation stack, so
    /// "Back" returns to Today. Every other route opens the sheet Today
    /// already uses for the same screen.
    func opensReminderRoutes(
        store: RecordStore,
        navigationPath: Binding<NavigationPath>,
        showingNewEntry: Binding<Bool>,
        newEntryInitialTime: Binding<Date?>,
        isShowingCloseTheDay: Binding<Bool>,
        planBuilderMode: Binding<PlanBuilderMode?>
    ) -> some View {
        modifier(ReminderRouteOpening(
            store: store,
            navigationPath: navigationPath,
            showingNewEntry: showingNewEntry,
            newEntryInitialTime: newEntryInitialTime,
            isShowingCloseTheDay: isShowingCloseTheDay,
            planBuilderMode: planBuilderMode
        ))
    }
}

private struct ReminderRouteOpening: ViewModifier {
    let store: RecordStore
    @Binding var navigationPath: NavigationPath
    @Binding var showingNewEntry: Bool
    @Binding var newEntryInitialTime: Date?
    @Binding var isShowingCloseTheDay: Bool
    @Binding var planBuilderMode: PlanBuilderMode?
    @EnvironmentObject private var routes: ReminderRouteInbox
    @EnvironmentObject private var appLockController: AppLockController

    func body(content: Content) -> some View {
        content
            .onAppear(perform: openPendingRoute)
            .onChange(of: routes.pending) { _, _ in openPendingRoute() }
            .onChange(of: appLockController.state) { _, _ in openPendingRoute() }
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
        _ = routes.take()
        let now = Date()
        let currentDayKey = RecordDay.key(containing: now, calendar: .current, schedule: (try? store.dayStartSchedule()) ?? .standard)
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
}
