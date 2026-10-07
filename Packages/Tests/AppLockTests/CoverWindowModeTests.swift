import XCTest
@testable import AppLock

/// mm-t15.15 and mm-t15.18: the cover lives in a window of its own, above
/// every sheet and full-screen cover. `AppLifecycleState.coverWindowMode`
/// is the rule the App target's `AppLockCoverWindow` follows; the device
/// check in mm-t15.14 confirms the window itself.
final class CoverWindowModeTests: XCTestCase {
    /// Requirement "The cover": the locked cover takes the keyboard and
    /// VoiceOver, over whatever the app's own window presents.
    func testTheLockedCoverShowsWithFocus() {
        let state = AppLifecycleState.launch(appLockEnabled: true)
        XCTAssertEqual(state.coverMode, .locked)
        XCTAssertEqual(state.coverWindowMode, .shownWithFocus)
    }

    /// Scenario "Enrolment changed": the cover with no "Unlock" is the same
    /// window.
    func testTheCoverAfterAnEnrolmentChangeShowsWithFocus() {
        var state = AppLifecycleState.launch(appLockEnabled: true, faceOrTouchOnlyEnabled: true)
        state = AppLifecycle.reduce(state, event: .enrolmentChanged)
        XCTAssertEqual(state.coverWindowMode, .shownWithFocus)
    }

    /// Scenario "App lock off": the "Midmorning"-only cover of the inactive
    /// app shows, but does not take the keyboard of a sheet.
    func testTheInactiveCoverShowsWithoutFocus() {
        var state = AppLifecycleState.launch(appLockEnabled: false)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        XCTAssertEqual(state.coverMode, .privacyOnly)
        XCTAssertEqual(state.coverWindowMode, .shown)
    }

    /// Scenario "App switcher": with the app lock on, the snapshot shows
    /// "Midmorning", "Unlock" and "Delete everything", also inside the
    /// grace period. The app is not locked, so the window does not take the
    /// keyboard, and a return within the grace period shows the screen the
    /// person left.
    func testTheAppSwitcherShowsTheFullCoverWithTheAppLockOn() {
        var state = AppLifecycleState.launch(appLockEnabled: true, lockAfterSeconds: 30)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        XCTAssertEqual(state.coverMode, .locked)
        XCTAssertEqual(state.coverWindowMode, .shown)

        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 1_000))
        XCTAssertEqual(state.coverMode, .locked)
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 1_020))
        XCTAssertEqual(state.coverMode, .none)
        XCTAssertEqual(state.coverWindowMode, .hidden)
    }

    func testTheUnlockedActiveAppHidesTheWindow() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        XCTAssertEqual(state.coverWindowMode, .hidden)
    }

    /// mm-t15.18: while a route waits, the window shows, so the new-entry
    /// screen always has a presenter, with or without a sheet in the app's
    /// own window. Before, the route stayed set when the screen could not
    /// present, and `coverMode` stayed `.none` for the rest of the session.
    func testAPendingRouteShowsTheWindowWhetherLockedOrNot() {
        var locked = AppLifecycleState.launch(appLockEnabled: true)
        locked = AppLifecycle.reduce(locked, event: .pendingRouteRequested(.newEntry))
        XCTAssertEqual(locked.coverMode, .none, "the route's screen shows with no cover")
        XCTAssertEqual(locked.coverWindowMode, .shownWithFocus)

        var unlocked = AppLifecycleState.launch(appLockEnabled: false)
        unlocked = AppLifecycle.reduce(unlocked, event: .pendingRouteRequested(.newEntry))
        XCTAssertEqual(unlocked.coverWindowMode, .shownWithFocus)
    }

    /// Ruling r16-02 (mm-t12b.27): the screens have no redaction of their
    /// own, so the cover hides the new-entry screen of a pending route
    /// while the app is not active, as it hides every other screen
    /// ("The App Switcher MUST show the cover and nothing else"). With the
    /// app lock on, the cover with "Unlock" and "Delete everything" shows;
    /// with the app lock off, "Midmorning" only. When the app is active
    /// again, the screen shows with no cover, and its text stays.
    func testThePendingRouteScreenHasTheCoverWhileTheAppIsNotActive() {
        var locked = AppLifecycleState.launch(appLockEnabled: true)
        locked = AppLifecycle.reduce(locked, event: .pendingRouteRequested(.newEntry))
        locked = AppLifecycle.reduce(locked, event: .didBecomeInactive)
        XCTAssertEqual(locked.coverMode, .locked)
        XCTAssertEqual(locked.coverWindowMode, .shownWithFocus, "the window that holds the screen still shows")
        locked = AppLifecycle.reduce(locked, event: .didEnterBackground(now: 1_000))
        XCTAssertEqual(locked.coverMode, .locked)
        locked = AppLifecycle.reduce(locked, event: .didBecomeActive(now: 1_005))
        XCTAssertEqual(locked.coverMode, .none, "the screen shows again with no cover")
        XCTAssertEqual(locked.pendingRoute, .newEntry, "the screen and its text stay")

        var unlocked = AppLifecycleState.launch(appLockEnabled: false)
        unlocked = AppLifecycle.reduce(unlocked, event: .pendingRouteRequested(.newEntry))
        unlocked = AppLifecycle.reduce(unlocked, event: .didBecomeInactive)
        XCTAssertEqual(unlocked.coverMode, .privacyOnly)
        unlocked = AppLifecycle.reduce(unlocked, event: .didBecomeActive(now: 5))
        XCTAssertEqual(unlocked.coverMode, .none)
    }

    /// A kept draft that waits for "Unlock" keeps the locked cover, active
    /// or not.
    func testAKeptDraftKeepsTheCoverInEveryPhase() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .pendingRouteRequested(.newEntry))
        state = AppLifecycle.reduce(state, event: .pendingRouteSaveNotAuthenticated)
        XCTAssertEqual(state.coverMode, .locked)
        state = AppLifecycle.reduce(state, event: .didBecomeInactive)
        XCTAssertEqual(state.coverMode, .locked)
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 5))
        XCTAssertEqual(state.coverMode, .locked)
    }

    /// When the route resolves, the locked cover is back in the same
    /// window, and the app's own window is still under it.
    func testTheCoverReturnsWhenTheRouteResolves() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .pendingRouteRequested(.newEntry))
        state = AppLifecycle.reduce(state, event: .pendingRouteResolved)
        XCTAssertEqual(state.coverMode, .locked)
        XCTAssertEqual(state.coverWindowMode, .shownWithFocus)
    }
}
