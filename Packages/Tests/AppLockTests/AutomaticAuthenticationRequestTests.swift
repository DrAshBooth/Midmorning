import XCTest
@testable import AppLock

/// mm-t15.17, requirement "When the app asks": "With the app lock on, the
/// app MUST make the system authentication request at every launch. The
/// app MUST ask again when it returns from the background after the grace
/// period." The App target's cover modifier calls
/// `requestAuthenticationIfDue()` each time the scene becomes active; these
/// tests drive the same calls with `FakeAuthenticator` and count the
/// requests.
@MainActor
final class AutomaticAuthenticationRequestTests: XCTestCase {
    private func makeController(
        state: AppLifecycleState = .launch(appLockEnabled: true),
        authenticationResult: Bool = true
    ) -> (AppLockController, FakeAuthenticator) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let controller = AppLockController(
            state: state,
            authenticator: authenticator,
            deleteAllSeam: RecordingDeleteAllSeam()
        )
        return (controller, authenticator)
    }

    /// Scenario "Launch": the cover and the system authentication request,
    /// with no tap. The scene becomes active more than once at launch; the
    /// app asks once.
    func testALockedLaunchAsksOnce() async {
        let (controller, authenticator) = makeController(authenticationResult: false)
        await controller.requestAuthenticationIfDue()
        await controller.requestAuthenticationIfDue()
        let requests = await authenticator.requests
        XCTAssertEqual(requests, [.init(reason: BiometryLabels.unlockReason, policy: .biometricsAndPasscode)])
        XCTAssertEqual(controller.state.coverMode, .locked, "a cancel leaves the cover and its 'Unlock'")
    }

    func testASuccessfulAutomaticRequestUnlocks() async {
        let (controller, _) = makeController()
        let succeeded = await controller.requestAuthenticationIfDue()
        XCTAssertTrue(succeeded)
        XCTAssertEqual(controller.state.coverMode, .none)
    }

    /// Scenario "Unlock control": after a cancel, only "Unlock" asks again.
    /// The system request makes the app inactive, and its close makes the
    /// app active again; that return does not start a second request.
    func testACancelThenTheReturnFromTheSystemRequestDoesNotAskAgain() async {
        let (controller, authenticator) = makeController(authenticationResult: false)
        await controller.requestAuthenticationIfDue()
        controller.handle(.didBecomeInactive)
        controller.handle(.didBecomeActive(now: 10))
        await controller.requestAuthenticationIfDue()
        var count = await authenticator.requests.count
        XCTAssertEqual(count, 1)

        await controller.tapUnlock()
        count = await authenticator.requests.count
        XCTAssertEqual(count, 2)
    }

    /// Scenario "Return after the grace period": the cover and the request.
    func testAReturnAfterTheGracePeriodAsksOnce() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: true, lockAfterSeconds: 30))
        await controller.requestAuthenticationIfDue()
        XCTAssertEqual(controller.state.coverMode, .none)

        controller.handle(.didBecomeInactive)
        controller.handle(.didEnterBackground(now: 1_000))
        controller.handle(.didBecomeActive(now: 1_045))
        XCTAssertEqual(controller.state.coverMode, .locked)
        await controller.requestAuthenticationIfDue()
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 2, "one at launch, one at the return")
        XCTAssertEqual(controller.state.coverMode, .none)
    }

    /// The full cover of an inactive app that is not locked (scenario "App
    /// switcher") makes no request.
    func testTheInactiveCoverOfAnUnlockedAppDoesNotAsk() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: true, lockAfterSeconds: 30))
        await controller.requestAuthenticationIfDue()
        controller.handle(.didBecomeInactive)
        XCTAssertEqual(controller.state.coverMode, .locked)
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 1, "the launch request only")
    }

    /// Scenario "Return within the grace period": no request.
    func testAReturnWithinTheGracePeriodDoesNotAsk() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: true, lockAfterSeconds: 30))
        await controller.requestAuthenticationIfDue()
        controller.handle(.didEnterBackground(now: 1_000))
        controller.handle(.didBecomeActive(now: 1_020))
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 1, "the launch request only")
    }

    /// Scenario "Device locked within the grace period": the lock came in
    /// the background, and the return asks.
    func testADeviceLockInTheBackgroundAsksOnReturn() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: true, lockAfterSeconds: 30))
        await controller.requestAuthenticationIfDue()
        controller.handle(.didEnterBackground(now: 1_000))
        controller.handle(.protectedDataWillBecomeUnavailable)
        controller.handle(.didBecomeActive(now: 1_010))
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 2)
    }

    /// Scenario "Lock at once": after the lock control, only the next
    /// "Unlock" asks. An automatic request would unlock at once for the
    /// face in front of the device.
    func testTheLockControlDoesNotAskByItself() async {
        let (controller, authenticator) = makeController()
        await controller.requestAuthenticationIfDue()
        controller.tapLockControl()
        controller.handle(.didBecomeInactive)
        controller.handle(.didBecomeActive(now: 5))
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 1, "the launch request only")
        XCTAssertEqual(controller.state.coverMode, .locked)
    }

    /// With a pending route, the new-entry screen shows with no cover, so
    /// the app does not ask.
    func testAPendingRouteSkipsTheRequest() async {
        let (controller, authenticator) = makeController()
        controller.handle(.pendingRouteRequested(.newEntry))
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 0)
    }

    /// Scenario "Enrolment changed": the cover "makes no authentication
    /// request".
    func testAnEnrolmentChangeSkipsTheRequest() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: true, faceOrTouchOnlyEnabled: true))
        controller.noteEnrolmentState(current: "new", kept: "old")
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 0)
        XCTAssertEqual(controller.state.coverMode, .lockedAfterEnrolmentChange)
    }

    func testTheAppLockOffNeverAsks() async {
        let (controller, authenticator) = makeController(state: .launch(appLockEnabled: false))
        await controller.requestAuthenticationIfDue()
        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 3_600))
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 0)
    }

    /// mm-t14.32 with mm-t15.17: after "Start" the app does not ask at
    /// once; with the lock on, the next return after the grace period does.
    func testNoRequestRightAfterOnboardingThenOneOnReturn() async {
        let (controller, authenticator) = makeController()
        controller.applyOnboardingChoice(appLockEnabled: true)
        await controller.requestAuthenticationIfDue()
        var count = await authenticator.requests.count
        XCTAssertEqual(count, 0)

        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 10))
        await controller.requestAuthenticationIfDue()
        count = await authenticator.requests.count
        XCTAssertEqual(count, 1)
    }

    /// mm-t15.16 with mm-t15.17: with no device passcode the app does not
    /// ask, because the request cannot succeed.
    func testNoRequestOnADeviceWithNoPasscode() async {
        let (controller, authenticator) = makeController()
        controller.noteDeviceBiometry(.none)
        await controller.requestAuthenticationIfDue()
        let count = await authenticator.requests.count
        XCTAssertEqual(count, 0)
    }
}
