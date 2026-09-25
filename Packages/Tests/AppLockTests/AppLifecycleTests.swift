import XCTest
@testable import AppLock

/// app-lock spec, "When the app asks", "The cover", "The lock control on
/// Today" and "A new entry before authentication". Every test drives
/// `AppLifecycle.reduce` with fixed numbers and no clock, no UIKit and no
/// device, as the design's "Pure seams" section requires.
final class AppLifecycleTests: XCTestCase {
    // MARK: Requirement: The app lock is on by default / When the app asks

    /// Scenario: Default / Scenario: Launch.
    func testLaunchWithTheAppLockOnStartsLocked() {
        let state = AppLifecycleState.launch(appLockEnabled: true)
        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.coverMode, .locked)
    }

    func testLaunchWithTheAppLockOffStartsUnlocked() {
        let state = AppLifecycleState.launch(appLockEnabled: false)
        XCTAssertFalse(state.isLocked)
        XCTAssertEqual(state.coverMode, .none)
    }

    /// Scenario: Return within the grace period.
    func testReturnWithinTheGracePeriodDoesNotAsk() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 1_000))
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 1_020))
        XCTAssertFalse(state.isLocked)
    }

    /// Scenario: Return after the grace period.
    func testReturnAfterTheGracePeriodAsks() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 1_000))
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 1_045))
        XCTAssertTrue(state.isLocked)
    }

    /// Scenario: Inactive is not background — Notification Centre never
    /// starts the grace timer, so returning from it never asks, however
    /// long it stayed up.
    func testInactiveAloneNeverStartsTheGraceTimer() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 1_045))
        XCTAssertFalse(state.isLocked)
    }

    /// Scenario: Clock change in the background — because the app measures
    /// elapsed time with continuous-clock ticks the caller supplies, not
    /// the calendar, a wall-clock change never changes the answer.
    func testWallClockMovementNeverAffectsTheContinuousReading() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 500))
        // The device clock "moved back an hour" in wall-clock terms, but the
        // continuous reading the app measures with only advanced 10 ticks.
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 510))
        XCTAssertFalse(state.isLocked)
    }

    /// Scenario: Device locked within the grace period — a locked device
    /// posts `protectedDataWillBecomeUnavailable` at once, so it locks even
    /// well inside the grace period.
    func testProtectedDataUnavailableLocksAtOnceInsideTheGracePeriod() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 0))
        state = AppLifecycle.reduce(state, event: .protectedDataWillBecomeUnavailable)
        XCTAssertTrue(state.isLocked)
    }

    func testProtectedDataUnavailableDoesNothingWithTheAppLockOff() {
        var state = AppLifecycleState.launch(appLockEnabled: false)
        state = AppLifecycle.reduce(state, event: .protectedDataWillBecomeUnavailable)
        XCTAssertFalse(state.isLocked)
    }

    /// Scenario: Device asleep for an hour.
    func testDeviceAsleepForAnHourAsksOnReturn() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 0))
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 3_600))
        XCTAssertTrue(state.isLocked)
    }

    // MARK: Requirement: The lock control on Today

    /// Scenario: Lock at once.
    func testLockControlLocksAtOnceRegardlessOfGrace() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 300)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .lockControlTapped)
        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.coverMode, .locked)
    }

    /// Scenario: Lock control with the app lock off.
    func testLockControlWithTheAppLockOffShowsThePlainCoverAndDismissesWithNoAuthentication() {
        var state = AppLifecycleState.launch(appLockEnabled: false)
        state = AppLifecycle.reduce(state, event: .lockControlTapped)
        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.coverMode, .privacyOnly, "the app lock is off, so the full cover never shows")
        state = AppLifecycle.reduce(state, event: .privacyCoverDismissed)
        XCTAssertFalse(state.isLocked)
        XCTAssertEqual(state.coverMode, .none)
    }

    func testPrivacyCoverDismissedDoesNothingWhileTheAppLockIsOn() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .privacyCoverDismissed)
        XCTAssertTrue(state.isLocked, "only 'Unlock' or 'Delete from this device' can dismiss the real cover")
    }

    // MARK: Requirement: The cover

    /// Scenario: App switcher / Scenario: Weigh-in screen — any inactive or
    /// background moment while locked shows the full cover, whatever screen
    /// sat behind it.
    func testTheCoverShowsWhileLockedRegardlessOfScenePhase() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        XCTAssertEqual(state.coverMode, .locked)
    }

    /// Scenario: App lock off — the app switcher snapshot still shows the
    /// plain "Midmorning" screen, never the real content.
    func testTheAppSwitcherShowsThePlainCoverWithTheAppLockOff() {
        var state = AppLifecycleState.launch(appLockEnabled: false)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        XCTAssertEqual(state.coverMode, .privacyOnly)
    }

    func testNoCoverWhileActiveAndUnlocked() {
        let state = AppLifecycleState.launch(appLockEnabled: false)
        XCTAssertEqual(state.coverMode, .none)
    }

    // MARK: Requirement: Face ID only or Touch ID only — the cover after an
    // enrolment change

    func testEnrolmentChangeShowsTheCoverWithNoUnlock() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .enrolmentChanged)
        XCTAssertEqual(state.coverMode, .lockedAfterEnrolmentChange)
    }

    func testAuthenticationSucceedingClearsAnEnrolmentChange() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .enrolmentChanged)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        XCTAssertFalse(state.enrolmentChanged)
        XCTAssertEqual(state.coverMode, .none)
    }

    // MARK: Requirement: A new entry before authentication

    /// Scenario: Widget tap while locked / Scenario: Notification action
    /// while locked — a pending route always wins, so the new-entry screen
    /// never shows behind or beside the cover.
    func testAPendingRouteShowsWithNoCoverEvenWhileLocked() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .pendingRouteRequested(.newEntry))
        XCTAssertEqual(state.coverMode, .none)
        XCTAssertTrue(state.isLocked, "the app is still locked; only the pending route has no cover")
    }

    /// Scenario: Cancel on the screen / Scenario: Cancel the request at
    /// Save — resolving the pending route with the app still locked
    /// restores the cover.
    func testResolvingThePendingRouteWhileStillLockedRestoresTheCover() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .pendingRouteRequested(.newEntry))
        state = AppLifecycle.reduce(state, event: .pendingRouteResolved)
        XCTAssertEqual(state.coverMode, .locked)
    }

    /// Scenario: Save while locked — authentication succeeding while the
    /// pending route is still set both unlocks the app and clears the
    /// route, so Today shows next, per "the app MUST then show Today".
    func testAuthenticationSucceedingAtSaveClearsBothLockAndRoute() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .pendingRouteRequested(.newEntry))
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .pendingRouteResolved)
        XCTAssertFalse(state.isLocked)
        XCTAssertEqual(state.coverMode, .none)
    }
}
