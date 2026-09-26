import Foundation
#if canImport(Combine)
import Combine
#endif

/// Brings the reducer, the label function and the two seams together for a
/// screen to drive. Every method that needs the system authentication
/// request is `async` and returns whether it succeeded; the caller (the
/// cover, the Privacy section) decides what to show next. A test builds one
/// with `FakeAuthenticator` and `RecordingDeleteAllSeam` and drives it with
/// no LocalAuthentication and no device (app-lock spec, throughout).
@MainActor
public final class AppLockController: ObservableObject {
    @Published public private(set) var state: AppLifecycleState

    private let authenticator: AuthenticationPerforming
    private let deleteAllSeam: DeleteAllPerforming
    /// Where the three values the Privacy group changes are kept (mm-8jr).
    /// `nil` in a test that does not check persistence.
    private let settings: AppLockSettingsStoring?

    /// Requirement "When the app asks": true after a locked launch, and
    /// after each return from the background that leaves the app locked,
    /// until `requestAuthenticationIfDue()` uses it. The lock control does
    /// not set it: after that tap, only "Unlock" asks.
    public private(set) var authenticationRequestDue: Bool

    public init(
        state: AppLifecycleState,
        authenticator: AuthenticationPerforming,
        deleteAllSeam: DeleteAllPerforming,
        settings: AppLockSettingsStoring? = nil
    ) {
        self.state = state
        self.authenticator = authenticator
        self.deleteAllSeam = deleteAllSeam
        self.settings = settings
        self.authenticationRequestDue = state.isLocked && state.appLockEnabled
    }

    /// Every scene-phase, protected-data and pending-route change goes
    /// through here, so `state` only ever changes by `AppLifecycle.reduce`.
    public func handle(_ event: AppLifecycleEvent) {
        let wasBackground = state.scenePhase == .background
        state = AppLifecycle.reduce(state, event: event)
        switch event {
        case .didBecomeActive:
            // Scenarios "Return after the grace period" and "Device locked
            // within the grace period": the cover and the request. A return
            // from the inactive state (Notification Centre, or the system
            // authentication request itself) does not set it, so a cancel
            // does not start a second request.
            if wasBackground, state.isLocked, state.appLockEnabled {
                authenticationRequestDue = true
            }
        case .authenticationSucceeded:
            authenticationRequestDue = false
        default:
            break
        }
    }

    /// Requirement "When the app asks": "With the app lock on, the app MUST
    /// make the system authentication request at every launch. The app
    /// MUST ask again when it returns from the background after the grace
    /// period." The App target calls this each time the scene becomes
    /// active. It makes one request at most for each launch or return. With
    /// a pending route, or after an enrolment change, the cover shows no
    /// "Unlock", so this makes no request.
    @discardableResult
    public func requestAuthenticationIfDue() async -> Bool {
        guard authenticationRequestDue else { return false }
        authenticationRequestDue = false
        guard state.isLocked, state.coverMode == .locked else { return false }
        return await tapUnlock()
    }

    /// "Unlock" on the cover. Requirement: "The cover" — "'Unlock' MUST
    /// make the system authentication request."
    @discardableResult
    public func tapUnlock() async -> Bool {
        let succeeded = await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
        if succeeded { handle(.authenticationSucceeded) }
        return succeeded
    }

    /// Onboarding spec, "Screen 4: permissions", scenarios "App lock
    /// default" and "App lock off": "Start" applies the person's choice to
    /// this controller, which the app built before onboarding. The person
    /// made the choice a moment ago, so Today opens with no cover. Screen 4
    /// writes the row to `Local.store` itself.
    public func applyOnboardingChoice(appLockEnabled: Bool) {
        state.appLockEnabled = appLockEnabled
        state.isLocked = false
        state.enrolmentChanged = false
        authenticationRequestDue = false
    }

    /// Requirement "The app lock is on by default": "When the device has no
    /// passcode, the switch MUST be off". Requirement "Fallback to the
    /// device passcode": "The app MUST NOT ... lock the person out." The
    /// App target calls this each time the scene becomes active, because
    /// the person can remove the device passcode while the app runs. It
    /// writes nothing, so the saved choice applies again at the next launch
    /// on a device with a passcode.
    public func noteDeviceBiometry(_ biometry: Biometry) {
        guard biometry == .none, state.appLockEnabled else { return }
        state.appLockEnabled = false
        state.isLocked = false
        state.enrolmentChanged = false
        authenticationRequestDue = false
    }

    /// "Delete everything" on the cover authenticates only; the caller
    /// shows "Delete everything?" on success and calls
    /// `confirmDeleteEverything()` from that confirmation (the "Two taps"
    /// scenario's second tap). A cancelled or failed request leaves the
    /// cover up and deletes nothing.
    ///
    /// After an enrolment change the cover shows no "Unlock" at all, so
    /// "Delete everything" makes no authentication request either (the same
    /// biometric state that made the app stop trusting "Unlock"); the
    /// person reaches the confirmation on that one tap, as "Delete
    /// everything after an enrolment change" states.
    @discardableResult
    public func tapDeleteEverything() async -> Bool {
        guard !state.enrolmentChanged else { return true }
        return await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
    }

    public func confirmDeleteEverything() async {
        await deleteAllSeam.deleteEverything()
    }

    /// "Delete from this device" after an enrolment change makes no
    /// authentication request: the enrolment change is why the cover offers
    /// this control instead of "Unlock" in the first place.
    public func confirmDeleteFromThisDevice() async {
        await deleteAllSeam.deleteFromThisDevice()
    }

    /// The lock control on Today: locks at once, with no grace period,
    /// whether or not the app lock is on.
    public func tapLockControl() {
        handle(.lockControlTapped)
    }

    /// A tap on the cover while the app lock is off: takes the cover off
    /// the screen with no authentication request. A no-op while the app
    /// lock is on, where only "Unlock" or "Delete from this device" can
    /// dismiss the cover.
    public func tapCoverToDismiss() {
        handle(.privacyCoverDismissed)
    }

    /// Requirement: "The app lock is on by default" — "the app MUST make
    /// the system authentication request first" before it turns the switch
    /// off; a cancelled or failed request leaves it on.
    @discardableResult
    public func tapTurnOffAppLock() async -> Bool {
        let succeeded = await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
        if succeeded {
            state.appLockEnabled = false
            state.isLocked = false
            settings?.setAppLockSetting("false", forKey: AppLockSettingsKeys.enabled)
        }
        return succeeded
    }

    public func turnOnAppLock() {
        state.appLockEnabled = true
        state.isLocked = true
        settings?.setAppLockSetting("true", forKey: AppLockSettingsKeys.enabled)
    }

    /// The "Face ID only"/"Touch ID only" warning's "Turn on": no
    /// authentication, only the warning the person just read.
    public func confirmTurnOnFaceOrTouchOnly() {
        state.faceOrTouchOnlyEnabled = true
        settings?.setAppLockSetting("true", forKey: AppLockSettingsKeys.faceOrTouchOnly)
    }

    /// Requirement: "Face ID only or Touch ID only" — "The app MUST make
    /// the system authentication request before it turns the setting off."
    @discardableResult
    public func tapTurnOffFaceOrTouchOnly() async -> Bool {
        let succeeded = await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
        if succeeded {
            state.faceOrTouchOnlyEnabled = false
            settings?.setAppLockSetting("false", forKey: AppLockSettingsKeys.faceOrTouchOnly)
        }
        return succeeded
    }

    /// Requirement "Lock after": "The choice is a device value in
    /// `Local.store`."
    public func setLockAfterSeconds(_ seconds: TimeInterval) {
        state.lockAfterSeconds = seconds
        settings?.setAppLockSetting(String(Int(seconds)), forKey: AppLockSettingsKeys.lockAfterSeconds)
    }

    /// Compares the enrolment state the "Face ID only or Touch ID only"
    /// requirement keeps, before a system authentication request. The App
    /// target computes both hashes; this only decides whether they differ.
    public func noteEnrolmentState(current: String, kept: String?) {
        if EnrolmentState.hasChanged(current: current, kept: kept) {
            handle(.enrolmentChanged)
        }
    }
}
