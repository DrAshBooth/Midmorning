import SwiftUI
import UIKit
import Record
import AppLock

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
        /// launch with an uncleared marker. Skips onboarding gating and the
        /// reminder scheduler; shows only Export and Get support
        /// (`mm-t42.13`, proved end to end by `mm-t42.20`), under the app
        /// lock cover (`SafeModeRootView`, mm-t42.21).
        case safeMode(RecordStore)
        case deleted(DeletedScreen.Kind)
        case failedToOpen

        var openPhase: StoreOpenPhase {
            switch self {
            case .waitingForProtectedData: return .waitingForProtectedData
            case .running: return .running
            case .safeMode: return .safeMode
            case .deleted: return .deleted
            case .failedToOpen: return .failedToOpen
            }
        }
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
                SafeModeRootView(
                    store: store,
                    onEverythingDeleted: { phase = .deleted(.everything) },
                    onDeleteFromThisDevice: { phase = .deleted(.thisDeviceOnly) }
                )
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
    /// booleans. Tries only from the waiting and failure phases
    /// (`AppStoreOpening.triesToOpen`): the deleted screen stays until the
    /// next launch, whatever protected data does.
    private func attemptOpen() {
        guard AppStoreOpening.triesToOpen(from: phase.openPhase) else { return }
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

    /// Data-and-privacy spec, "Launch safety": writes the marker (once per
    /// launch), opens the store, and adds one to the lifetime failure count
    /// when this launch found an uncleared marker (once per launch). The
    /// marker stays until Today or safe mode's Today appears
    /// (`LaunchMarker.clearAfterTodayAppears`). "The app MUST NOT call
    /// `fatalError` when the container fails to open" — every throw here
    /// reaches `attemptOpen`'s `catch` instead.
    private static func openStoreAndController(metricKitSubscriber: MetricKitSubscriber) throws -> (store: RecordStore, controller: AppLockController, enterSafeMode: Bool) {
        let applicationSupportDirectory = try StoreLocation.applicationSupportDirectory()
        let launch = LaunchMarker.session(applicationSupportDirectory: applicationSupportDirectory)
        let launchMarker = launch.begin()
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: applicationSupportDirectory)
        launch.countLaunchFailureIfNeeded(in: store)
        metricKitSubscriber.connect { [weak store] crashes in
            for _ in 0..<crashes { _ = try? store?.incrementCrashCount() }
        }
        return (store, makeController(store: store), launchMarker.launchOutcome.enterSafeMode)
    }

    private static func makeController(store: RecordStore) -> AppLockController {
        AppLockControllerFactory.make(store: store)
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
            OnboardingRootView(store: store) {
                AppLockControllerFactory.applyOnboardingChoice(to: controller, store: store)
                isOnboardingCompleted = true
            }
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

    var body: some View {
        TodayView(store: store)
            // The one real `AppLockController`, shared with every screen
            // under Today (`SettingsView`'s Privacy section reads it through
            // `@EnvironmentObject`), so the switch there and the cover below
            // can never disagree about the lock state (mm-t13.9).
            .environmentObject(controller)
            .environmentObject(deletionNotifier)
            // The cover, in a window of its own over every sheet and
            // full-screen cover (app-lock spec, "The cover"). It also shows
            // the new-entry screen of a pending route ("A new entry before
            // authentication"): the notification action "Add" requests the
            // route through `ReminderRouteInbox` (`ReminderRouteOpening`, on
            // Today), and `AppLifecycleState.coverMode` reads `.none` while
            // it waits.
            .appLockCover(controller: controller, store: store, onEverythingDeleted: onEverythingDeleted, onDeleteFromThisDevice: onDeleteFromThisDevice)
            .onAppear {
                deletionNotifier.onEverythingDeleted = onEverythingDeleted
                checkEnrolmentStateIfNeeded()
                // design.md, "The scheduler is a pure function over a
                // rolling horizon": recomputed on activation.
                // Materialise every elapsed record day first (mm-t23.21).
                _ = try? store.materialiseElapsedRecordDays(now: Date(), calendar: .current)
                ReminderCoordinator.recomputeAndApply(store: store)
                // data-and-privacy spec, "Launch safety": Today appeared.
                LaunchMarker.clearAfterTodayAppears()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    controller.handle(.didBecomeActive(now: MachContinuousClock().continuousSeconds()))
                    checkEnrolmentStateIfNeeded()
                    _ = try? store.materialiseElapsedRecordDays(now: Date(), calendar: .current)
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
    /// request." `AppLockEnrolmentCheck` holds the check.
    private func checkEnrolmentStateIfNeeded() {
        AppLockEnrolmentCheck.run(controller: controller, store: store)
    }
}
