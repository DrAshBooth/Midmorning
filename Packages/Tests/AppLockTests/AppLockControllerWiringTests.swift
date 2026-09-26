import XCTest
@testable import AppLock

/// The controller calls the App target makes from the onboarding gate, the
/// cover window and the Privacy group: the onboarding choice (mm-t14.32),
/// a device with no passcode (mm-t15.16) and the saved settings (mm-8jr).
@MainActor
final class AppLockControllerWiringTests: XCTestCase {
    private func makeController(
        state: AppLifecycleState = .launch(appLockEnabled: true),
        authenticationResult: Bool = true,
        settings: AppLockSettingsStoring? = nil
    ) -> (AppLockController, FakeAuthenticator) {
        let authenticator = FakeAuthenticator(result: authenticationResult)
        let controller = AppLockController(
            state: state,
            authenticator: authenticator,
            deleteAllSeam: RecordingDeleteAllSeam(),
            settings: settings
        )
        return (controller, authenticator)
    }

    // MARK: Onboarding "Screen 4: permissions" (mm-t14.32)

    /// Scenario "App lock off": a fresh install has no row, so the
    /// controller the app built before onboarding is locked. "Start" with
    /// the switch off gives an app lock that is off: Today opens with no
    /// cover, and a return from the background does not lock.
    func testOnboardingWithTheLockOffOpensTodayWithNoCover() {
        let (controller, _) = makeController()
        XCTAssertEqual(controller.state.coverMode, .locked)

        controller.applyOnboardingChoice(appLockEnabled: false)

        XCTAssertEqual(controller.state.coverMode, .none)
        XCTAssertFalse(controller.state.appLockEnabled)
        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 3_600))
        XCTAssertEqual(controller.state.coverMode, .none)
    }

    /// Scenario "App lock default": the lock is on. Today opens with no
    /// cover after "Start", and the next return after the grace period
    /// locks.
    func testOnboardingWithTheLockOnOpensTodayAndLocksOnReturn() {
        let (controller, _) = makeController()
        controller.applyOnboardingChoice(appLockEnabled: true)
        XCTAssertEqual(controller.state.coverMode, .none)
        XCTAssertTrue(controller.state.appLockEnabled)

        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 10))
        XCTAssertEqual(controller.state.coverMode, .locked)
    }

    // MARK: No passcode (mm-t15.16)

    /// The person removes the device passcode while the app runs. The app
    /// lock turns off and the cover goes, so the person is not locked out
    /// behind an "Unlock" that cannot succeed.
    func testLosingThePasscodeTurnsTheLockOffAndWritesNothing() {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        controller.noteDeviceBiometry(.none)
        XCTAssertFalse(controller.state.appLockEnabled)
        XCTAssertEqual(controller.state.coverMode, .none)
        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 3_600))
        XCTAssertEqual(controller.state.coverMode, .none)
        XCTAssertTrue(settings.values.isEmpty, "the saved choice stays for a device with a passcode")
    }

    func testADeviceWithAPasscodeChangesNothing() {
        let (controller, _) = makeController()
        for biometry in [Biometry.faceID, .touchID, .passcodeOnly] {
            controller.noteDeviceBiometry(biometry)
            XCTAssertEqual(controller.state.coverMode, .locked, "\(biometry)")
        }
    }

    // MARK: The Privacy group's settings (mm-8jr)

    /// Scenario "Turn off": "the app opens without an authentication
    /// request from then on" — the choice is kept in `Local.store`.
    func testTurningTheSwitchOffAndOnWritesTheEnabledKey() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        await controller.tapTurnOffAppLock()
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enabled], "false")
        controller.turnOnAppLock()
        XCTAssertEqual(settings.values[AppLockSettingsKeys.enabled], "true")
    }

    /// Scenario "Cancel the turn-off": nothing is written.
    func testACancelledTurnOffWritesNothing() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(authenticationResult: false, settings: settings)
        await controller.tapTurnOffAppLock()
        XCTAssertNil(settings.values[AppLockSettingsKeys.enabled])
    }

    func testLockAfterWritesItsKey() {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        controller.setLockAfterSeconds(300)
        XCTAssertEqual(settings.values[AppLockSettingsKeys.lockAfterSeconds], "300")
    }

    func testFaceIDOnlyOnAndOffWritesItsKey() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        controller.confirmTurnOnFaceOrTouchOnly()
        XCTAssertEqual(settings.values[AppLockSettingsKeys.faceOrTouchOnly], "true")
        await controller.tapTurnOffFaceOrTouchOnly()
        XCTAssertEqual(settings.values[AppLockSettingsKeys.faceOrTouchOnly], "false")
    }

    /// The lock and unlock themselves change no saved value.
    func testLockingAndUnlockingWriteNothing() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        await controller.tapUnlock()
        controller.tapLockControl()
        controller.handle(.didEnterBackground(now: 0))
        controller.handle(.didBecomeActive(now: 100))
        XCTAssertTrue(settings.values.isEmpty)
    }

    /// A fresh controller from the same settings starts in the state the
    /// person left.
    func testAFreshControllerStartsWhereThePersonLeftIt() async {
        let settings = InMemoryAppLockSettings()
        let (controller, _) = makeController(settings: settings)
        controller.setLockAfterSeconds(120)
        controller.confirmTurnOnFaceOrTouchOnly()
        await controller.tapTurnOffAppLock()

        let relaunched = AppLockController(
            state: AppLockLaunch.state(settings: settings, biometry: .faceID),
            authenticator: FakeAuthenticator(result: true),
            deleteAllSeam: RecordingDeleteAllSeam(),
            settings: settings
        )
        XCTAssertFalse(relaunched.state.appLockEnabled)
        XCTAssertEqual(relaunched.state.coverMode, .none)
        XCTAssertEqual(relaunched.state.lockAfterSeconds, 120)
        XCTAssertTrue(relaunched.state.faceOrTouchOnlyEnabled)
    }
}
