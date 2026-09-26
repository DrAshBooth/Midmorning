import SwiftUI
import UIKit
import Record
import AppLock

/// The `LocalSetting` keys the app lock owns in `Local.store`
/// (data-and-privacy spec, "Two store configurations in one directory").
enum AppLockSettingsKeys {
    static let enabled = "appLock.enabled"
    static let faceOrTouchOnly = "appLock.faceOrTouchOnly"
    static let lockAfterSeconds = "appLock.lockAfterSeconds"
    static let enrolmentStateHash = "appLock.enrolmentStateHash"
}

/// The app's root: opens `RecordStore` lazily, only once protected data is
/// available, and shows one of four phases (data-and-privacy spec, "Launch
/// safety", "File protection": "Launch before the first unlock"; design.md,
/// "Store opening is lazy and checks protected data first").
@MainActor
struct AppLockRootView: View {
    private enum Phase {
        case waitingForProtectedData
        case running(RecordStore, AppLockController)
        /// data-and-privacy spec, "Launch safety": the third consecutive
        /// launch with an uncleared marker. Skips onboarding gating, the
        /// app lock cover and the reminder scheduler; shows only Export and
        /// Get support (`mm-t42.13`, proved end to end by `mm-t42.20`).
        case safeMode(RecordStore)
        case deleted(DeletedScreen.Kind)
        case failedToOpen
    }

    let metricKitSubscriber: MetricKitSubscriber

    @State private var phase: Phase = .waitingForProtectedData

    var body: some View {
        Group {
            switch phase {
            case .waitingForProtectedData:
                WaitingForProtectedDataView()
            case .running(let store, let controller):
                OnboardingGatedRootView(
                    store: store,
                    controller: controller,
                    onEverythingDeleted: { phase = .deleted(.everything) },
                    onDeleteFromThisDevice: { phase = .deleted(.thisDeviceOnly) }
                )
            case .safeMode(let store):
                SafeModeView(store: store)
            case .deleted(let kind):
                DeletedScreen(kind: kind)
            case .failedToOpen:
                StoreOpenFailureView(
                    seam: Self.makeSeam(),
                    onTryAgain: { attemptOpen() },
                    onDeleted: { phase = .deleted(.everything) }
                )
            }
        }
        .onAppear { attemptOpen() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
            attemptOpen()
        }
    }

    /// Checks protected data first, before ever constructing a
    /// `RecordStore` (data-and-privacy spec, "File protection": "The app
    /// MUST open the store container only when protected data is
    /// available."). `Record.AppStoreOpening` is the pure decision this
    /// follows; `AppStoreOpeningTests` proves the ordering with fixed
    /// booleans.
    private func attemptOpen() {
        if case .running = phase { return }
        if case .safeMode = phase { return }
        let protectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
        var opened: (store: RecordStore, controller: AppLockController, enterSafeMode: Bool)?
        var openSucceeded = false
        if protectedDataAvailable {
            do {
                opened = try Self.openStoreAndController(metricKitSubscriber: metricKitSubscriber)
                openSucceeded = true
            } catch {
                openSucceeded = false
            }
        }
        switch AppStoreOpening.attempt(protectedDataAvailable: protectedDataAvailable, openSucceeded: openSucceeded) {
        case .waitingForProtectedData:
            phase = .waitingForProtectedData
        case .opened:
            if let opened {
                phase = opened.enterSafeMode ? .safeMode(opened.store) : .running(opened.store, opened.controller)
            }
        case .failed:
            phase = .failedToOpen
        }
    }

    /// Data-and-privacy spec, "Launch safety": writes the marker, opens the
    /// store, adds one to the lifetime failure count when this launch found
    /// an uncleared marker, then either enters safe mode or clears the
    /// marker (this app has no onboarding gate yet, so reaching either
    /// point stands in for "Today appears" — "Marker cleared" names no
    /// difference between safe-mode Today and the ordinary one). "The app
    /// MUST NOT call `fatalError` when the container fails to open" — every
    /// throw here reaches `attemptOpen`'s `catch` instead.
    private static func openStoreAndController(metricKitSubscriber: MetricKitSubscriber) throws -> (store: RecordStore, controller: AppLockController, enterSafeMode: Bool) {
        let applicationSupportDirectory = try StoreLocation.applicationSupportDirectory()
        let launchMarker = LaunchMarker.beginLaunch(applicationSupportDirectory: applicationSupportDirectory)
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: applicationSupportDirectory)
        if launchMarker.markerWasUncleared {
            _ = try? store.incrementLaunchFailureCount()
        }
        LaunchMarker.clearAfterTodayAppears(applicationSupportDirectory: applicationSupportDirectory)
        metricKitSubscriber.onDiagnostics = { [weak store] in
            _ = try? store?.incrementCrashCount()
        }
        return (store, makeController(store: store), launchMarker.launchOutcome.enterSafeMode)
    }

    private static func makeController(store: RecordStore) -> AppLockController {
        let enabledSetting = (try? store.localSettingValue(key: AppLockSettingsKeys.enabled)) ?? nil
        // Requirement: "The app lock is on by default" — no saved row yet
        // means the person has not turned it off, so it is on.
        let appLockEnabled = enabledSetting.map { $0 == "true" } ?? true
        let faceOrTouchOnly = ((try? store.localSettingValue(key: AppLockSettingsKeys.faceOrTouchOnly)) ?? nil) == "true"
        let lockAfterSeconds = ((try? store.localSettingValue(key: AppLockSettingsKeys.lockAfterSeconds)) ?? nil)
            .flatMap { TimeInterval($0) } ?? 0
        return AppLockController(
            state: .launch(appLockEnabled: appLockEnabled, faceOrTouchOnlyEnabled: faceOrTouchOnly, lockAfterSeconds: lockAfterSeconds),
            authenticator: LAContextAuthenticator(),
            deleteAllSeam: Self.makeSeam()
        )
    }

    /// The Privacy group's "Delete everything" (`Record.DeleteAllSeam`) and
    /// the cover's two controls (`AppLock.DeleteAllPerforming`) share one
    /// kind of seam (data-and-privacy spec, "Delete-all", "Delete from this
    /// device"). Needs no open store: `LocalDeletion` works from paths
    /// alone, so "Delete everything" from the store-open-failure page (task
    /// 3.1) can delete a store that never opened.
    private static func makeSeam() -> RealDeleteAllSeam {
        .usingAppFileLocations()
    }
}

/// Data-and-privacy spec, "Delete-all": the Privacy group's own "Delete
/// everything" button is a third route to the same deletion, beside the
/// cover's two controls, and it sits deep under `TodayView`'s navigation
/// stack (`SettingsView`) with no reference back to the root. `SettingsView`
/// reads this through `@EnvironmentObject` (the same mechanism
/// `AppLockController` already uses, mm-t13.9) to tell `AppLockRootView` its
/// own "Delete everything" tap finished, the same way `CoverView`'s two
/// completion callbacks do.
@MainActor
final class DeletionNotifier: ObservableObject {
    var onEverythingDeleted: () -> Void = {}
}

/// Today, the cover and the app's lifecycle events, once the store and the
/// Onboarding, once, before anything else the store and the controller make
/// possible (onboarding spec, "Four screens, once, in order": "The app MUST
/// show onboarding the first time the app opens after install... MUST NOT
/// show onboarding again after the person completes it."). The app lock's
/// own cover only ever sits over Today, so gating here, above
/// `RunningRootView`, keeps the cover from showing before the person has
/// chosen it on screen 4.
@MainActor
private struct OnboardingGatedRootView: View {
    let store: RecordStore
    let controller: AppLockController
    let onEverythingDeleted: () -> Void
    let onDeleteFromThisDevice: () -> Void
    @State private var isOnboardingCompleted: Bool

    init(store: RecordStore, controller: AppLockController, onEverythingDeleted: @escaping () -> Void, onDeleteFromThisDevice: @escaping () -> Void) {
        self.store = store
        self.controller = controller
        self.onEverythingDeleted = onEverythingDeleted
        self.onDeleteFromThisDevice = onDeleteFromThisDevice
        _isOnboardingCompleted = State(initialValue: (try? store.onboardingCompleted()) ?? false)
    }

    var body: some View {
        if isOnboardingCompleted {
            RunningRootView(
                store: store,
                controller: controller,
                onEverythingDeleted: onEverythingDeleted,
                onDeleteFromThisDevice: onDeleteFromThisDevice
            )
        } else {
            OnboardingRootView(store: store) { isOnboardingCompleted = true }
        }
    }
}

/// Today, the cover and the app's lifecycle events, once the store and the
/// controller both exist. Everything `AppLockRootView` showed before this
/// change lived here, unchanged, other than the completion callbacks
/// Delete-all and "Delete from this device" call.
@MainActor
private struct RunningRootView: View {
    let store: RecordStore
    @ObservedObject var controller: AppLockController
    let onEverythingDeleted: () -> Void
    let onDeleteFromThisDevice: () -> Void
    @StateObject private var deletionNotifier = DeletionNotifier()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingWeighInFromReminder = false
    @State private var showingWeeklyReviewFromReminder = false

    var body: some View {
        TodayView(store: store)
            // The one real `AppLockController`, shared with every screen
            // under Today (`SettingsView`'s Privacy section reads it through
            // `@EnvironmentObject`), so the switch there and the cover below
            // can never disagree about the lock state (mm-t13.9).
            .environmentObject(controller)
            .environmentObject(deletionNotifier)
            .overlay {
                CoverView(controller: controller, onEverythingDeleted: onEverythingDeleted, onDeleteFromThisDevice: onDeleteFromThisDevice)
            }
            .onAppear {
                deletionNotifier.onEverythingDeleted = onEverythingDeleted
                checkEnrolmentStateIfNeeded()
                // design.md, "The scheduler is a pure function over a
                // rolling horizon": recomputed on activation.
                ReminderCoordinator.recomputeAndApply(store: store)
            }
            // A pending route always wins over the cover (app-lock spec, "A
            // new entry before authentication"): the notification action
            // "Add" posts `.reminderAddActionTapped`, which requests the
            // route; `AppLifecycleState.coverMode` already reads `.none`
            // while a route is pending, so the cover steps aside on its own.
            .fullScreenCover(isPresented: Binding(
                get: { controller.state.pendingRoute == .newEntry },
                set: { isPresented in if !isPresented { controller.handle(.pendingRouteResolved) } }
            )) {
                NewEntryView(store: store, day: RecordDay.interval(containing: Date(), calendar: .current), initialTime: nil) { _ in
                    controller.handle(.pendingRouteResolved)
                }
            }
            // A tap on the weigh-in day reminder (reminders spec, "The
            // weigh-in day reminder"). No pending-route bypass: unlike
            // "Add", the notification carries no authentication-required
            // option, so the device is already unlocked by the time the app
            // opens.
            .fullScreenCover(isPresented: $showingWeighInFromReminder) {
                NavigationStack { WeighInScreenView(store: store) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .weighInReminderTapped)) { _ in
                showingWeighInFromReminder = true
            }
            // A tap on the weekly review reminder (reminders spec, "The
            // weekly review reminder": "A tap MUST open the weekly
            // review.").
            .fullScreenCover(isPresented: $showingWeeklyReviewFromReminder) {
                NavigationStack { ReviewScreenView(store: store, week: WeeklyReviewModel.load(store: store).dueWeek ?? 1) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .weeklyReviewReminderTapped)) { _ in
                showingWeeklyReviewFromReminder = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .reminderAddActionTapped)) { _ in
                controller.handle(.pendingRouteRequested(.newEntry))
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    controller.handle(.didBecomeActive(now: MachContinuousClock().continuousSeconds()))
                    checkEnrolmentStateIfNeeded()
                    ReminderCoordinator.recomputeAndApply(store: store)
                case .inactive:
                    controller.handle(.didBecomeInactive)
                case .background:
                    controller.handle(.didEnterBackground(now: MachContinuousClock().continuousSeconds()))
                @unknown default:
                    break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
                controller.handle(.protectedDataWillBecomeUnavailable)
            }
    }

    /// Requirement: "Face ID only or Touch ID only" — "compare the
    /// enrolment state with the kept hash before each system authentication
    /// request." Only relevant while the setting is on and the app is
    /// about to ask; the first run has no kept hash, so it only saves one.
    private func checkEnrolmentStateIfNeeded() {
        guard controller.state.faceOrTouchOnlyEnabled, controller.state.isLocked else { return }
        guard let current = EnrolmentHash.current() else { return }
        let kept = (try? store.localSettingValue(key: AppLockSettingsKeys.enrolmentStateHash)) ?? nil
        if kept == nil {
            try? store.setLocalSettingValue(current, key: AppLockSettingsKeys.enrolmentStateHash)
            return
        }
        controller.noteEnrolmentState(current: current, kept: kept)
    }
}
