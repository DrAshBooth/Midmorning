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
