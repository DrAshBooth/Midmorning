import XCTest
@testable import AppLock

/// A reminder route other than "Add" opens only while no cover shows
/// (app-lock spec, "The cover"; mm-t24.29). `ReminderRouteOpening` (App
/// target) reads this before it opens a route on Today.
final class ReminderRouteGateTests: XCTestCase {
    func testARouteWaitsWhileTheCoverShowsAtLaunch() {
        XCTAssertFalse(AppLifecycleState.launch(appLockEnabled: true).opensAReminderRoute)
    }

    func testARouteOpensOnceTheAppIsUnlockedAndActive() {
        var state = AppLifecycleState.launch(appLockEnabled: true)
        state = AppLifecycle.reduce(state, event: .authenticationSucceeded)
        XCTAssertEqual(state.coverMode, CoverMode.none)
        XCTAssertTrue(state.opensAReminderRoute)
    }

    func testARouteOpensAtOnceWithTheAppLockOff() {
        XCTAssertTrue(AppLifecycleState.launch(appLockEnabled: false).opensAReminderRoute)
    }

    func testARouteWaitsWhileTheAppIsInactive() {
        let state = AppLifecycleState(scenePhase: .inactive, appLockEnabled: false, isLocked: false)
        XCTAssertFalse(state.opensAReminderRoute)
    }

    /// The new-entry screen from "Add" shows with no cover; another route
    /// waits until that screen closes.
    func testARouteWaitsWhileThePendingNewEntryScreenShows() {
        let state = AppLifecycleState(appLockEnabled: true, isLocked: true, pendingRoute: .newEntry)
        XCTAssertEqual(state.coverMode, CoverMode.none)
        XCTAssertFalse(state.opensAReminderRoute)
    }
}
