import XCTest
@testable import AppLock

/// app-lock spec, "A new entry before authentication": "On Save the app
/// MUST make the system authentication request." Ruling r13-04
/// (mm-t15.19) builds this now for the reminder "Add" route. The App
/// target's pending-route `NewEntryView` calls
/// `authenticateToSaveNewEntry()` before `RecordStore.add`, and saves only
/// on `true`.
@MainActor
final class NewEntrySaveAuthenticationTests: XCTestCase {
    private func lockedControllerWithPendingRoute(
        appLockEnabled: Bool = true,
        faceOrTouchOnly: Bool = false,
        authenticationResult: Bool
    ) -> (AppLockController, FakeAuthenticator) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let controller = AppLockController(
            state: .launch(appLockEnabled: appLockEnabled, faceOrTouchOnlyEnabled: faceOrTouchOnly),
            authenticator: authenticator,
            deleteAllSeam: RecordingDeleteAllSeam()
        )
        // The person taps "Add" on a reminder while the app is locked.
        controller.handle(.pendingRouteRequested(.newEntry))
        return (controller, authenticator)
    }

    /// Save while locked: the request comes first; on success the app is
    /// unlocked and the screen saves.
    func testSaveWhileLockedAsksAndSavesOnSuccess() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(authenticationResult: true)
        XCTAssertEqual(controller.state.coverMode, .none, "the new-entry screen shows with no cover")

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertTrue(canSave)
        XCTAssertFalse(controller.state.isLocked)
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsAndPasscode)])
        // The screen saves and closes: the route resolves, and Today shows
        // with no cover.
        controller.handle(.pendingRouteResolved)
        XCTAssertEqual(controller.state.coverMode, .none)
    }

    /// Cancel the request at Save from a reminder: nothing saves, and the
    /// cover shows over the screen, which keeps its text. After "Unlock"
    /// succeeds, the screen shows again, and Save then saves with no
    /// second request.
    func testCancelTheRequestAtSaveShowsTheCoverAndKeepsTheDraftForUnlock() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(authenticationResult: false)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertFalse(canSave, "nothing saves")
        XCTAssertTrue(controller.state.isLocked)
        XCTAssertEqual(controller.state.coverMode, .locked, "the cover shows \"Unlock\" and \"Delete everything\"")
        XCTAssertEqual(controller.state.pendingRoute, .newEntry, "the new-entry screen stays under the cover, with the draft")
        XCTAssertEqual(controller.state.coverWindowMode, .shownWithFocus)

        await authenticator.setResult(true)
        let unlocked = await controller.tapUnlock()

        XCTAssertTrue(unlocked)
        XCTAssertEqual(controller.state.coverMode, .none, "the new-entry screen shows again")
        XCTAssertEqual(controller.state.pendingRoute, .newEntry)
        let canSaveNow = await controller.authenticateToSaveNewEntry()
        XCTAssertTrue(canSaveNow)
        let requests = await authenticator.requests
        XCTAssertEqual(requests.count, 2, "one request at Save, one at \"Unlock\", none at the second Save")
    }

    /// Failed request at Save from a reminder, with Face ID only: the same
    /// as a cancel.
    func testAFailedRequestAtSaveShowsTheCover() async {
        let (controller, _) = lockedControllerWithPendingRoute(faceOrTouchOnly: true, authenticationResult: false)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertFalse(canSave)
        XCTAssertEqual(controller.state.coverMode, .locked)
        XCTAssertEqual(controller.state.pendingRoute, .newEntry)
    }

    /// A second "Add" while the cover hides a kept draft does not take the
    /// cover off: the draft shows only after "Unlock".
    func testASecondAddKeepsTheCoverOverAKeptDraft() async {
        let (controller, _) = lockedControllerWithPendingRoute(authenticationResult: false)
        _ = await controller.authenticateToSaveNewEntry()

        controller.handle(.pendingRouteRequested(.newEntry))

        XCTAssertEqual(controller.state.coverMode, .locked)
    }

    /// Cancel on the screen: the route resolves while the app is still
    /// locked, so the cover shows.
    func testCancelOnTheScreenShowsTheCover() {
        let (controller, _) = lockedControllerWithPendingRoute(authenticationResult: false)

        controller.handle(.pendingRouteResolved)

        XCTAssertEqual(controller.state.coverMode, .locked)
    }

    /// Face ID only: the request uses the biometrics-only policy.
    func testSaveWithFaceIDOnlyUsesTheBiometricsOnlyPolicy() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(faceOrTouchOnly: true, authenticationResult: true)

        _ = await controller.authenticateToSaveNewEntry()

        let requests = await authenticator.requests
        XCTAssertEqual(requests.map(\.policy), [.biometricsOnly])
    }

    /// After an enrolment change no request can unlock the app: nothing
    /// saves and no request shows.
    func testSaveAfterAnEnrolmentChangeMakesNoRequestAndSavesNothing() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(faceOrTouchOnly: true, authenticationResult: true)
        controller.handle(.enrolmentChanged)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertFalse(canSave)
        XCTAssertTrue(controller.state.isLocked)
        XCTAssertEqual(controller.state.coverMode, .lockedAfterEnrolmentChange)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
    }

    /// With the app lock off, Save saves at once.
    func testSaveWithTheAppLockOffMakesNoRequest() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(appLockEnabled: false, authenticationResult: false)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertTrue(canSave)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
    }

    /// "Add" while the app is already unlocked: Save saves at once.
    func testSaveWhileUnlockedMakesNoRequest() async {
        let (controller, authenticator) = lockedControllerWithPendingRoute(authenticationResult: false)
        controller.handle(.authenticationSucceeded)

        let canSave = await controller.authenticateToSaveNewEntry()

        XCTAssertTrue(canSave)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
    }
}
