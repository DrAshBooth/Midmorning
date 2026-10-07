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

    /// Scenario: Turn on. Ruling r15-03 (mm-t15.21): "Turn on" makes a
    /// biometrics-only system authentication request before the app saves
    /// the setting and the enrolment state hash. The request never offers
    /// the device passcode, also while the setting is still off.
    func testTurnOnMakesABiometricsOnlyRequestBeforeTheSave() async {
        let settings = InMemoryAppLockSettings()
        let (controller, authenticator) = makeController(settings: settings, authenticationResult: true)
        XCTAssertEqual(controller.state.authenticationPolicy, .biometricsAndPasscode)

        let turnedOn = await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")

        XCTAssertTrue(turnedOn)
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsOnly)])
        XCTAssertTrue(controller.state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(controller.state.authenticationPolicy, .biometricsOnly)
        XCTAssertEqual(settings.values[AppLockSettingsKeys.faceOrTouchOnly], "true")
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H1")
    }

    /// Ruling r15-03 (mm-t15.21): on a cancel or a failure of the request at
    /// "Turn on", the setting stays off and the app saves no hash. The app
    /// does not read the enrolment state hash. A biometry lockout fails the
    /// request in the same way, so the old kept hash does not come back
    /// into use.
    func testACancelledOrFailedRequestAtTurnOnKeepsTheSettingOffAndSavesNoHash() async {
        let settings = InMemoryAppLockSettings([AppLockSettingsKeys.enrolmentStateHash: "H0"])
        let (controller, authenticator) = makeController(settings: settings, authenticationResult: false)
        var hashReads = 0
        func readHash() -> String? {
            hashReads += 1
            return "H1"
        }

        let turnedOn = await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: readHash())

        XCTAssertFalse(turnedOn)
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsOnly)])
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(controller.state.authenticationPolicy, .biometricsAndPasscode)
        XCTAssertNil(settings.values[AppLockSettingsKeys.faceOrTouchOnly])
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H0", "the app saves no hash")
        XCTAssertEqual(hashReads, 0, "the app reads the hash only after the request succeeds")
    }

    /// A second "Turn on" after a cancel makes a new request, and turns the
    /// setting on when that request succeeds.
    func testTurnOnAfterACancelledRequestCanSucceedNextTime() async {
        let settings = InMemoryAppLockSettings()
        let (controller, authenticator) = makeController(settings: settings, authenticationResult: false)
        await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)

        await authenticator.setResult(true)
        let turnedOn = await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")

        XCTAssertTrue(turnedOn)
        XCTAssertTrue(controller.state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H1")
        let requests = await authenticator.requests
        XCTAssertEqual(requests.count, 2)
    }

    /// Scenario: Cancel the turn-on.
    func testFaceOrTouchOnlyStaysOffWithNoConfirmation() {
        let (controller, _, _) = makeController()
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
    }

    func testTurningFaceOrTouchOnlyOffNeedsAuthentication() async {
        let (controller, _, _) = makeController()
        await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")
        XCTAssertTrue(controller.state.faceOrTouchOnlyEnabled)
        let succeeded = await controller.tapTurnOffFaceOrTouchOnly()
        XCTAssertTrue(succeeded)
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
    }

    private func makeController(
        settings: InMemoryAppLockSettings,
        authenticationResult: Bool = true
    ) -> (AppLockController, FakeAuthenticator) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let controller = AppLockController(
            state: .launch(appLockEnabled: true),
            authenticator: authenticator,
            deleteAllSeam: RecordingDeleteAllSeam(),
            settings: settings
        )
        controller.handle(.authenticationSucceeded)
        return (controller, authenticator)
    }

    /// Ruling r13-06 (mm-t15.20): the person turns "Face ID only" on,
    /// turns it off, adds a face in the iOS Settings app and turns it on
    /// again. The second turn-on saves the new hash, so the next lock
    /// still shows "Unlock".
    func testTurningOnAgainAfterAnEnrolmentChangeSavesTheNewHash() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)

        await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H1")
        await controller.tapTurnOffFaceOrTouchOnly()
        // The person adds a face in the iOS Settings app: the hash is H2.
        await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H2")
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H2")

        controller.tapLockControl()
        controller.noteEnrolmentState(current: "H2", kept: settings.values[AppLockSettingsKeys.enrolmentStateHash])

        XCTAssertEqual(controller.state.coverMode, .locked, "the cover shows \"Unlock\"")
    }

    /// The kept hash compares as before: an enrolment change while the
    /// setting is on still takes "Unlock" off the cover.
    func testAnEnrolmentChangeWhileTheSettingIsOnStillTakesUnlockOff() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: "H1")

        controller.tapLockControl()
        controller.noteEnrolmentState(current: "H2", kept: settings.values[AppLockSettingsKeys.enrolmentStateHash])

        XCTAssertEqual(controller.state.coverMode, .lockedAfterEnrolmentChange)
    }

    /// Ruling r15-03 (mm-t15.21): when the device gives no enrolment state
    /// hash after the request succeeds, the setting stays off, the app
    /// saves no value and the kept hash does not change. Thus the old kept
    /// hash does not come back into use.
    func testATurnOnWithNoHashKeepsTheSettingOffAndTheKeptHash() async {
        let settings = InMemoryAppLockSettings([AppLockSettingsKeys.enrolmentStateHash: "H1"])
        let (controller, authenticator) = makeController(settings: settings, authenticationResult: true)

        let turnedOn = await controller.confirmTurnOnFaceOrTouchOnly(currentEnrolmentHash: nil)

        XCTAssertFalse(turnedOn)
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsOnly)])
        XCTAssertFalse(controller.state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(controller.state.authenticationPolicy, .biometricsAndPasscode)
        XCTAssertNil(settings.values[AppLockSettingsKeys.faceOrTouchOnly])
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enrolmentStateHash], "H1")
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
