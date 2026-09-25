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

/// Wraps Today with the app-lock cover, so every screen in the window sits
/// behind it (requirement: "The cover"). Reads the app lock's own settings
/// from `Local.store` at launch; `PrivacyAppLockControls` (this change's
/// fixture-only Privacy section) writes them back once a settings screen
/// embeds it (mm-t13's wiring bead).
@MainActor
struct AppLockRootView: View {
    let store: RecordStore
    @StateObject private var controller: AppLockController
    @Environment(\.scenePhase) private var scenePhase

    init(store: RecordStore) {
        self.store = store
        let enabledSetting = (try? store.localSettingValue(key: AppLockSettingsKeys.enabled)) ?? nil
        // Requirement: "The app lock is on by default" — no saved row yet
        // means the person has not turned it off, so it is on.
        let appLockEnabled = enabledSetting.map { $0 == "true" } ?? true
        let faceOrTouchOnly = ((try? store.localSettingValue(key: AppLockSettingsKeys.faceOrTouchOnly)) ?? nil) == "true"
        let lockAfterSeconds = ((try? store.localSettingValue(key: AppLockSettingsKeys.lockAfterSeconds)) ?? nil)
            .flatMap { TimeInterval($0) } ?? 0
        _controller = StateObject(wrappedValue: AppLockController(
            state: .launch(appLockEnabled: appLockEnabled, faceOrTouchOnlyEnabled: faceOrTouchOnly, lockAfterSeconds: lockAfterSeconds),
            authenticator: LAContextAuthenticator(),
            // 4.1 (`local-delete-all`) is not merged yet; the change README
            // names this stub. It records each call and deletes nothing.
            deleteAllSeam: RecordingDeleteAllSeam()
        ))
    }

    var body: some View {
        TodayView(store: store)
            .overlay {
                CoverView(controller: controller, onEverythingDeleted: {})
            }
            .onAppear { checkEnrolmentStateIfNeeded() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    controller.handle(.didBecomeActive(now: MachContinuousClock().continuousSeconds()))
                    checkEnrolmentStateIfNeeded()
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
