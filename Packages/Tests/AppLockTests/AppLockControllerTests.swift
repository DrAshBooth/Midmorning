import XCTest
@testable import AppLock

/// Drives `AppLockController` with `FakeAuthenticator` and
/// `RecordingDeleteAllSeam`, so every request-response flow the app-lock
/// spec states is a test with no LocalAuthentication and no device.
@MainActor
final class AppLockControllerTests: XCTestCase {
    private func makeController(
        appLockEnabled: Bool = true,
        authenticationResult: Bool = true
    ) -> (AppLockController, FakeAuthenticator, RecordingDeleteAllSeam) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let seam = RecordingDeleteAllSeam()
        let controller = AppLockController(
            state: .launch(appLockEnabled: appLockEnabled),
            authenticator: authenticator,
            deleteAllSeam: seam
        )
        return (controller, authenticator, seam)
    }

    // MARK: Requirement: The app lock is on by default

    /// Scenario: Turn off.
    func testTurnOffSucceedsAfterAuthentication() async {
        let (controller, authenticator, _) = makeController()
        controller.handle(.authenticationSucceeded)
        let succeeded = await controller.tapTurnOffAppLock()
        XCTAssertTrue(succeeded)
        XCTAssertFalse(controller.state.appLockEnabled)
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsAndPasscode)])
    }

    /// Scenario: Cancel the turn-off.
    func testCancelTheTurnOffLeavesTheAppLockOn() async {
        let (controller, _, _) = makeController(authenticationResult: false)
        controller.handle(.authenticationSucceeded)
        let succeeded = await controller.tapTurnOffAppLock()
        XCTAssertFalse(succeeded)
        XCTAssertTrue(controller.state.appLockEnabled)
    }

    // MARK: Requirement: Delete everything from the cover

    /// Scenario: Delete from the cover / Scenario: Two taps.
    func testDeleteEverythingCallsTheSeamOnlyAfterBothTaps() async {
        let (controller, _, seam) = makeController()
        let authenticated = await controller.tapDeleteEverything()
        XCTAssertTrue(authenticated)
        var count = await seam.deleteEverythingCallCount
        XCTAssertEqual(count, 0, "authenticating alone must not delete anything")
        await controller.confirmDeleteEverything()
        count = await seam.deleteEverythingCallCount
        XCTAssertEqual(count, 1)
    }

    /// Scenario: Cancel the authentication.
    func testCancelDeleteEverythingsAuthenticationDeletesNothing() async {
        let (controller, _, seam) = makeController(authenticationResult: false)
        let authenticated = await controller.tapDeleteEverything()
        XCTAssertFalse(authenticated)
        let count = await seam.deleteEverythingCallCount
        XCTAssertEqual(count, 0)
    }

    /// Scenario: Delete everything after an enrolment change — no
    /// authentication request, the same as "Delete from this device".
    func testDeleteEverythingAfterAnEnrolmentChangeMakesNoAuthenticationRequest() async {
        let (controller, authenticator, seam) = makeController()
        controller.handle(.enrolmentChanged)
        let authenticated = await controller.tapDeleteEverything()
        XCTAssertTrue(authenticated)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
        await controller.confirmDeleteEverything()
        let count = await seam.deleteEverythingCallCount
        XCTAssertEqual(count, 1)
    }

    // MARK: Requirement: Delete from this device after an enrolment change

    /// Scenario: Delete from this device — no authentication request.
    func testDeleteFromThisDeviceMakesNoAuthenticationRequest() async {
        let (controller, authenticator, seam) = makeController()
        controller.handle(.enrolmentChanged)
        await controller.confirmDeleteFromThisDevice()
        let count = await seam.deleteFromThisDeviceCallCount
        XCTAssertEqual(count, 1)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: Requirement: Face ID only or Touch ID only

    /// Scenario: Turn on.
    func testConfirmTurnOnFaceOrTouchOnlyNeedsNoAuthentication() async {
        let (controller, authenticator, _) = makeController()
        controller.confirmTurnOnFaceOrTouchOnly()
        XCTAssertTrue(controller.state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(controller.state.authenticationPolicy, .biometricsOnly)
        let requests = await authenticator.requests
        XCTAssertTrue(requests.isEmpty)
    }

    /// Scenario: Cancel the turn-on.
    func testFaceOrTouchOnlyStaysOffWithNoConfirmation() {
        let (controller, _, _) = makeController()
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
    }

    func testTurningFaceOrTouchOnlyOffNeedsAuthentication() async {
        let (controller, _, _) = makeController()
        controller.confirmTurnOnFaceOrTouchOnly()
        let succeeded = await controller.tapTurnOffFaceOrTouchOnly()
        XCTAssertTrue(succeeded)
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
    }

    // MARK: Requirement: The cover

    /// Scenario: Unlock control.
    func testUnlockAfterACancelledRequestCanSucceedNextTime() async {
        let (controller, authenticator, _) = makeController()
        await authenticator.setResult(false)
        let firstAttempt = await controller.tapUnlock()
        XCTAssertFalse(firstAttempt)
        XCTAssertTrue(controller.state.isLocked)
        await authenticator.setResult(true)
        let secondAttempt = await controller.tapUnlock()
        XCTAssertTrue(secondAttempt)
        XCTAssertFalse(controller.state.isLocked)
    }
}
