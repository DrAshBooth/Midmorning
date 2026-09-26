import Foundation

/// The `LocalSetting` keys the app lock owns in `Local.store`
/// (data-and-privacy spec, "Two store configurations in one directory").
/// The App target, the onboarding screen and the tests all read these, so
/// the keys live here, once.
public enum AppLockSettingsKeys {
    public static let enabled = "appLock.enabled"
    public static let faceOrTouchOnly = "appLock.faceOrTouchOnly"
    public static let lockAfterSeconds = "appLock.lockAfterSeconds"
    public static let enrolmentStateHash = "appLock.enrolmentStateHash"
}

/// Reads and writes the device values the app lock keeps in `Local.store`.
/// The App target adapts `RecordStore` to this; a test uses
/// `InMemoryAppLockSettings`. A write that fails changes nothing on
/// screen: the next launch reads the last value that the store kept.
@MainActor
public protocol AppLockSettingsStoring {
    func appLockSetting(forKey key: String) -> String?
    func setAppLockSetting(_ value: String, forKey key: String)
}

/// A test's settings store: a plain dictionary, with no `Local.store`.
@MainActor
public final class InMemoryAppLockSettings: AppLockSettingsStoring {
    public private(set) var values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }

    public func appLockSetting(forKey key: String) -> String? {
        values[key]
    }

    public func setAppLockSetting(_ value: String, forKey key: String) {
        values[key] = value
    }
}

/// The launch state from the values in `Local.store` and the device's
/// `Biometry` (app-lock spec, "The app lock is on by default", "Lock
/// after", "Face ID only or Touch ID only").
public enum AppLockLaunch {
    /// Requirement "The app lock is on by default": no saved row means the
    /// person has not turned the lock off, so it is on. "When the device has
    /// no passcode, the switch MUST be off": with `.none` the lock is off,
    /// whatever the saved row holds. The saved row stays as it is, so the
    /// person's choice applies again when the device has a passcode.
    public static func isEnabled(saved: String?, biometry: Biometry) -> Bool {
        guard biometry != .none else { return false }
        return saved.map { $0 == "true" } ?? true
    }

    public static func state(
        enabled: String?,
        faceOrTouchOnly: String?,
        lockAfterSeconds: String?,
        biometry: Biometry
    ) -> AppLifecycleState {
        .launch(
            appLockEnabled: isEnabled(saved: enabled, biometry: biometry),
            faceOrTouchOnlyEnabled: faceOrTouchOnly == "true",
            lockAfterSeconds: lockAfterSeconds.flatMap { TimeInterval($0) } ?? 0
        )
    }

    @MainActor
    public static func state(settings: AppLockSettingsStoring, biometry: Biometry) -> AppLifecycleState {
        state(
            enabled: settings.appLockSetting(forKey: AppLockSettingsKeys.enabled),
            faceOrTouchOnly: settings.appLockSetting(forKey: AppLockSettingsKeys.faceOrTouchOnly),
            lockAfterSeconds: settings.appLockSetting(forKey: AppLockSettingsKeys.lockAfterSeconds),
            biometry: biometry
        )
    }
}
