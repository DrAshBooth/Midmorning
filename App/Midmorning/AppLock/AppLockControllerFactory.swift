import SwiftUI
import UIKit
import Record
import AppLock

/// `RecordStore` as the app lock's settings store: the three values the
/// Privacy group changes, and the enrolment hash, are `LocalSetting` rows
/// in `Local.store` (data-and-privacy spec, "Two store configurations in
/// one directory"). `AppLockLocalStoreTests` (`RecordTests`) runs the same
/// two calls over a real store.
struct RecordStoreAppLockSettings: AppLockSettingsStoring {
    let store: RecordStore

    func appLockSetting(forKey key: String) -> String? {
        (try? store.localSettingValue(key: key)) ?? nil
    }

    func setAppLockSetting(_ value: String, forKey key: String) {
        try? store.setLocalSettingValue(value, key: key)
    }
}

/// Builds the one `AppLockController` a phase of `AppLockRootView` uses,
/// from `Local.store` and the device's `Biometry` (app-lock spec, "The app
/// lock is on by default").
@MainActor
enum AppLockControllerFactory {
    static func make(store: RecordStore) -> AppLockController {
        let settings = RecordStoreAppLockSettings(store: store)
        return AppLockController(
            state: AppLockLaunch.state(settings: settings, biometry: BiometryDetector.current()),
            authenticator: LAContextAuthenticator(),
            deleteAllSeam: RealDeleteAllSeam.usingAppFileLocations(),
            settings: settings
        )
    }

    /// Onboarding spec, "Screen 4: permissions": "Start" wrote the choice
    /// to `Local.store`; this gives the same choice to the controller that
    /// the app built before onboarding (mm-t14.32).
    static func applyOnboardingChoice(to controller: AppLockController, store: RecordStore) {
        let saved = RecordStoreAppLockSettings(store: store).appLockSetting(forKey: AppLockSettingsKeys.enabled)
        controller.applyOnboardingChoice(appLockEnabled: AppLockLaunch.isEnabled(saved: saved, biometry: BiometryDetector.current()))
    }
}

/// Requirement "Face ID only or Touch ID only": "compare the enrolment
/// state with the kept hash before each system authentication request."
/// This applies only while the setting is on and the app is locked. The
/// first run has no kept hash, so it only saves one. Moved here from
/// `RunningRootView`, unchanged, so that more than one phase can run it.
@MainActor
enum AppLockEnrolmentCheck {
    static func run(controller: AppLockController, store: RecordStore) {
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
