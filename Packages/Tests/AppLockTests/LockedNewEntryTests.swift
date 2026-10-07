import XCTest
@testable import AppLock

/// App-lock spec, "A new entry before authentication" (ruling r17-01,
/// mm-t15.22). While the app is locked, the new-entry screen that a
/// reminder "Add" opens shows only the four fixed Where chips and the
/// places the person adds on that screen. After "Unlock", or after the
/// request at Save succeeds, the screen shows the custom chips too. The
/// App target's pending-route `NewEntryView` reads
/// `newEntryShowsSavedPlaces` from the same controller state.
@MainActor
final class LockedNewEntryTests: XCTestCase {
    private func controllerWithPendingRoute(
        appLockEnabled: Bool = true,
        authenticationResult: Bool
    ) -> (AppLockController, FakeAuthenticator) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let controller = AppLockController(
            state: .launch(appLockEnabled: appLockEnabled),
            authenticator: authenticator,
            deleteAllSeam: RecordingDeleteAllSeam()
        )
        // The person taps "Add" on a reminder while the app is locked.
        controller.handle(.pendingRouteRequested(.newEntry))
        return (controller, authenticator)
    }

    func testTheLockedAddScreenShowsNoCustomPlace() {
        let (controller, _) = controllerWithPendingRoute(authenticationResult: true)

        XCTAssertEqual(controller.state.coverMode, .none, "the new-entry screen shows with no cover")
        XCTAssertFalse(controller.state.newEntryShowsSavedPlaces)
    }

    func testTheCustomPlacesShowAfterTheRequestAtSaveSucceeds() async {
        let (controller, _) = controllerWithPendingRoute(authenticationResult: true)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertTrue(canSave)
        XCTAssertTrue(controller.state.newEntryShowsSavedPlaces)
    }

    /// A cancel at Save keeps the screen under the cover, with no custom
    /// place. After "Unlock" succeeds, the screen shows again with the
    /// custom places.
    func testTheCustomPlacesShowOnlyAfterUnlockWhenTheRequestAtSaveIsCancelled() async {
        let (controller, authenticator) = controllerWithPendingRoute(authenticationResult: false)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertFalse(canSave)
        XCTAssertFalse(controller.state.newEntryShowsSavedPlaces)

        await authenticator.setResult(true)
        await controller.tapUnlock()

        XCTAssertEqual(controller.state.pendingRoute, .newEntry, "the same screen shows again")
        XCTAssertTrue(controller.state.newEntryShowsSavedPlaces)
    }

    /// After an enrolment change no authentication can unlock the app, so
    /// the screen never shows the custom places.
    func testNoCustomPlaceShowsAfterAnEnrolmentChange() async {
        let (controller, _) = controllerWithPendingRoute(authenticationResult: true)
        controller.handle(.enrolmentChanged)

        await controller.authenticateToSaveNewEntry()

        XCTAssertFalse(controller.state.newEntryShowsSavedPlaces)
    }

    /// With the app lock off, no authentication protects the record: the
    /// screen shows the custom places at once. The plain cover of the lock
    /// control does not change this.
    func testTheCustomPlacesShowWithTheAppLockOff() {
        let (controller, _) = controllerWithPendingRoute(appLockEnabled: false, authenticationResult: true)
        XCTAssertTrue(controller.state.newEntryShowsSavedPlaces)

        controller.tapLockControl()

        XCTAssertTrue(controller.state.isLocked)
        XCTAssertTrue(controller.state.newEntryShowsSavedPlaces)
    }

    /// "Add" on a reminder while the app is not locked shows the custom
    /// places at once.
    func testTheCustomPlacesShowWhenTheAppIsNotLocked() {
        let controller = AppLockController(
            state: .launch(appLockEnabled: true),
            authenticator: FakeAuthenticator(result: true),
            deleteAllSeam: RecordingDeleteAllSeam()
        )
        controller.handle(.authenticationSucceeded)

        controller.handle(.pendingRouteRequested(.newEntry))

        XCTAssertTrue(controller.state.newEntryShowsSavedPlaces)
    }

    /// The app locks again while the screen shows (the device locks):
    /// the custom places go from the screen.
    func testTheCustomPlacesGoWhenTheAppLocksAgain() {
        let controller = AppLockController(
            state: .launch(appLockEnabled: true),
            authenticator: FakeAuthenticator(result: true),
            deleteAllSeam: RecordingDeleteAllSeam()
        )
        controller.handle(.authenticationSucceeded)
        controller.handle(.pendingRouteRequested(.newEntry))

        controller.handle(.protectedDataWillBecomeUnavailable)

        XCTAssertFalse(controller.state.newEntryShowsSavedPlaces)
    }
}
