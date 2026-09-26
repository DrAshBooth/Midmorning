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

    public init(state: AppLifecycleState, authenticator: AuthenticationPerforming, deleteAllSeam: DeleteAllPerforming) {
        self.state = state
        self.authenticator = authenticator
        self.deleteAllSeam = deleteAllSeam
    }

    /// Every scene-phase, protected-data and pending-route change goes
    /// through here, so `state` only ever changes by `AppLifecycle.reduce`.
    public func handle(_ event: AppLifecycleEvent) {
        state = AppLifecycle.reduce(state, event: event)
    }

    /// "Unlock" on the cover. Requirement: "The cover" — "'Unlock' MUST
    /// make the system authentication request."
    @discardableResult
    public func tapUnlock() async -> Bool {
        let succeeded = await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
        if succeeded { handle(.authenticationSucceeded) }
        return succeeded
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

    /// Returns whether the deletion succeeded. The cover shows the deleted
    /// screen only on `true` (data-and-privacy spec, "Delete-all": the
    /// screen follows the deletion).
    @discardableResult
    public func confirmDeleteEverything() async -> Bool {
        do {
            try await deleteAllSeam.deleteEverything()
            return true
        } catch {
            return false
        }
    }

    /// "Delete from this device" after an enrolment change makes no
    /// authentication request: the enrolment change is why the cover offers
    /// this control instead of "Unlock" in the first place. Returns whether
    /// the deletion succeeded.
    @discardableResult
    public func confirmDeleteFromThisDevice() async -> Bool {
        do {
            try await deleteAllSeam.deleteFromThisDevice()
            return true
        } catch {
            return false
        }
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
        }
        return succeeded
    }

    public func turnOnAppLock() {
        state.appLockEnabled = true
        state.isLocked = true
    }

    /// The "Face ID only"/"Touch ID only" warning's "Turn on": no
    /// authentication, only the warning the person just read.
    public func confirmTurnOnFaceOrTouchOnly() {
        state.faceOrTouchOnlyEnabled = true
    }

    /// Requirement: "Face ID only or Touch ID only" — "The app MUST make
    /// the system authentication request before it turns the setting off."
    @discardableResult
    public func tapTurnOffFaceOrTouchOnly() async -> Bool {
        let succeeded = await authenticator.authenticate(reason: BiometryLabels.unlockReason, policy: state.authenticationPolicy)
        if succeeded { state.faceOrTouchOnlyEnabled = false }
        return succeeded
    }

    public func setLockAfterSeconds(_ seconds: TimeInterval) {
        state.lockAfterSeconds = seconds
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
