import Foundation

/// The three phases the reducer cares about, its own copy of SwiftUI's
/// `ScenePhase` so this package imports no UIKit or SwiftUI.
public enum LifecycleScenePhase: Sendable, Equatable {
    case active
    case inactive
    case background
}

/// The one screen an entry point can show before authentication.
/// Requirement: "A new entry before authentication".
public enum PendingRoute: Sendable, Equatable {
    case newEntry
}

/// What the app shows over the real screen right now. A pure function of
/// `AppLifecycleState`, never a stored flag of its own, so the cover and the
/// privacy screen can never disagree with the lock state.
///
/// Requirement: "The cover" — `.privacyOnly` is the "Midmorning"-only
/// screen the app shows while merely inactive, on or off; `.locked` and
/// `.lockedAfterEnrolmentChange` are the cover with "Unlock" (or
/// "Delete from this device") and "Delete everything". Requirement:
/// "A new entry before authentication" — a pending route always wins, so
/// the new-entry screen shows with no cover at all.
public enum CoverMode: Sendable, Equatable {
    case none
    case privacyOnly
    case locked
    case lockedAfterEnrolmentChange
}

/// The app-lock state `AppLifecycle.reduce` carries. Every field a pure
/// value; the App target's `AppLockController` is the only mutable owner.
public struct AppLifecycleState: Sendable, Equatable {
    public var scenePhase: LifecycleScenePhase
    public var appLockEnabled: Bool
    public var faceOrTouchOnlyEnabled: Bool
    public var lockAfterSeconds: TimeInterval
    public var isLocked: Bool
    public var enrolmentChanged: Bool
    public var enteredBackgroundAt: TimeInterval?
    public var pendingRoute: PendingRoute?

    public init(
        scenePhase: LifecycleScenePhase = .active,
        appLockEnabled: Bool,
        faceOrTouchOnlyEnabled: Bool = false,
        lockAfterSeconds: TimeInterval = 0,
        isLocked: Bool,
        enrolmentChanged: Bool = false,
        enteredBackgroundAt: TimeInterval? = nil,
        pendingRoute: PendingRoute? = nil
    ) {
        self.scenePhase = scenePhase
        self.appLockEnabled = appLockEnabled
        self.faceOrTouchOnlyEnabled = faceOrTouchOnlyEnabled
        self.lockAfterSeconds = lockAfterSeconds
        self.isLocked = isLocked
        self.enrolmentChanged = enrolmentChanged
        self.enteredBackgroundAt = enteredBackgroundAt
        self.pendingRoute = pendingRoute
    }

    /// Scenario: "Launch" and "Default" — the app lock, when on, always
    /// starts locked; the person must authenticate before any screen shows.
    public static func launch(appLockEnabled: Bool, faceOrTouchOnlyEnabled: Bool = false, lockAfterSeconds: TimeInterval = 0) -> AppLifecycleState {
        AppLifecycleState(
            appLockEnabled: appLockEnabled,
            faceOrTouchOnlyEnabled: faceOrTouchOnlyEnabled,
            lockAfterSeconds: lockAfterSeconds,
            isLocked: appLockEnabled
        )
    }

    public var authenticationPolicy: AuthenticationPolicy {
        .policy(faceOrTouchOnly: faceOrTouchOnlyEnabled)
    }

    public var coverMode: CoverMode {
        if pendingRoute != nil { return .none }
        if isLocked {
            // Requirement: "The lock control on Today" — "With the app lock
            // off, the lock control MUST still show the cover" as the plain
            // "Midmorning" screen, dismissed by a tap with no
            // authentication request, never the full "Unlock"/"Delete
            // everything" cover.
            guard appLockEnabled else { return .privacyOnly }
            return enrolmentChanged ? .lockedAfterEnrolmentChange : .locked
        }
        if scenePhase != .active {
            // Scenario "App switcher": with the app lock on, the snapshot
            // shows "Midmorning", "Unlock" and "Delete everything", also
            // inside the grace period. Scenario "App lock off": with the
            // app lock off, it shows "Midmorning" only.
            return appLockEnabled ? .locked : .privacyOnly
        }
        return .none
    }
}

/// Every event `AppLifecycle.reduce` handles. The App target raises these
/// from `scenePhase`, `protectedDataWillBecomeUnavailableNotification`, the
/// lock control, a successful system authentication request and an
/// enrolment-state comparison; it never mutates `AppLifecycleState` itself.
public enum AppLifecycleEvent: Sendable, Equatable {
    case didEnterBackground(now: TimeInterval)
    case didBecomeInactive
    case didBecomeActive(now: TimeInterval)
    case protectedDataWillBecomeUnavailable
    case lockControlTapped
    case authenticationSucceeded
    case enrolmentChanged
    case pendingRouteRequested(PendingRoute)
    case pendingRouteResolved
    case privacyCoverDismissed
}

/// The one pure reducer the design names: "`AppLifecycle.reduce(state,
/// event)` handles background and foreground, protected data availability,
/// authentication and the pending route."
public enum AppLifecycle {
    public static func reduce(_ state: AppLifecycleState, event: AppLifecycleEvent) -> AppLifecycleState {
        var state = state
        switch event {
        case .didEnterBackground(let now):
            // Requirement: "When the app asks" — "start the grace timer
            // when it enters the background, not when it becomes inactive."
            state.scenePhase = .background
            state.enteredBackgroundAt = now

        case .didBecomeInactive:
            if state.scenePhase == .active {
                state.scenePhase = .inactive
            }

        case .didBecomeActive(let now):
            // Scenario: "Inactive is not background" — only a real
            // background entry starts the grace timer, so returning from
            // Notification Centre (active -> inactive -> active, with no
            // `didEnterBackground` in between) never asks.
            let wasBackground = state.scenePhase == .background
            state.scenePhase = .active
            if wasBackground, state.appLockEnabled, let enteredAt = state.enteredBackgroundAt {
                if LockPolicy.shouldAsk(enteredBackgroundAt: enteredAt, now: now, grace: state.lockAfterSeconds) {
                    state.isLocked = true
                }
            }
            state.enteredBackgroundAt = nil

        case .protectedDataWillBecomeUnavailable:
            // Scenario: "Device locked within the grace period" — this
            // fires the moment the device locks, inside or outside the
            // grace period, so it never consults the clock.
            if state.appLockEnabled {
                state.isLocked = true
            }

        case .lockControlTapped:
            // Requirement: "The lock control on Today" — locks at once,
            // with no grace period, whether or not the app lock is on.
            state.isLocked = true

        case .authenticationSucceeded:
            state.isLocked = false
            state.enrolmentChanged = false

        case .enrolmentChanged:
            // Requirement: "Face ID only or Touch ID only" — "the app MUST
            // stay locked" with no "Unlock" on the cover.
            state.enrolmentChanged = true
            state.isLocked = true

        case .pendingRouteRequested(let route):
            state.pendingRoute = route

        case .pendingRouteResolved:
            state.pendingRoute = nil

        case .privacyCoverDismissed:
            // Scenario: "Lock control with the app lock off" — a plain tap
            // dismisses the cover with no authentication request; this is
            // never valid while the app lock is on, because that cover only
            // "Unlock" or "Delete from this device" can dismiss.
            if !state.appLockEnabled {
                state.isLocked = false
            }
        }
        return state
    }
}
