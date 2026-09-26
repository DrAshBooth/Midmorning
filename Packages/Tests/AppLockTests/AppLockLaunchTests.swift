import XCTest
@testable import AppLock

/// `AppLockLaunch`: the launch state from `Local.store` and the device's
/// `Biometry`. The App target builds its controller from it
/// (`AppLockControllerFactory`).
final class AppLockLaunchTests: XCTestCase {
    // MARK: Requirement: The app lock is on by default

    /// Scenario "Default": no saved row means the lock is on.
    func testNoSavedRowIsLockedOnADeviceWithAPasscode() {
        for biometry in [Biometry.faceID, .touchID, .passcodeOnly] {
            let state = AppLockLaunch.state(enabled: nil, faceOrTouchOnly: nil, lockAfterSeconds: nil, biometry: biometry)
            XCTAssertTrue(state.appLockEnabled, "\(biometry)")
            XCTAssertEqual(state.coverMode, .locked, "\(biometry)")
        }
    }

    /// mm-t15.16, scenario "No passcode": with `.none` the switch is off, so
    /// a launch is not locked, whatever the saved row holds. Before, every
    /// launch showed a cover whose "Unlock" could never succeed.
    func testALaunchWithNoPasscodeIsNotLocked() {
        for saved in [nil, "true", "false"] {
            let state = AppLockLaunch.state(enabled: saved, faceOrTouchOnly: nil, lockAfterSeconds: nil, biometry: .none)
            XCTAssertFalse(state.appLockEnabled, "saved \(saved ?? "nil")")
            XCTAssertFalse(state.isLocked, "saved \(saved ?? "nil")")
            XCTAssertEqual(state.coverMode, .none, "saved \(saved ?? "nil")")
        }
    }

    /// With no passcode, a return from the background after the grace
    /// period does not lock either.
    func testNoPasscodeNeverLocksOnReturn() {
        var state = AppLockLaunch.state(enabled: nil, faceOrTouchOnly: nil, lockAfterSeconds: nil, biometry: .none)
        state = AppLifecycle.reduce(state, event: .didEnterBackground(now: 0))
        state = AppLifecycle.reduce(state, event: .didBecomeActive(now: 3_600))
        XCTAssertEqual(state.coverMode, .none)
    }

    /// Scenario "Turn off": the saved "false" keeps the lock off at the
    /// next launch.
    func testSavedFalseIsNotLocked() {
        let state = AppLockLaunch.state(enabled: "false", faceOrTouchOnly: nil, lockAfterSeconds: nil, biometry: .faceID)
        XCTAssertFalse(state.appLockEnabled)
        XCTAssertEqual(state.coverMode, .none)
    }

    // MARK: Requirement: Lock after / Face ID only or Touch ID only

    /// mm-t14.32 and mm-8jr: the other two saved values come back as saved.
    @MainActor
    func testSavedLockAfterAndFaceIDOnlyComeBack() {
        let settings = InMemoryAppLockSettings([
            AppLockSettingsKeys.enabled: "true",
            AppLockSettingsKeys.faceOrTouchOnly: "true",
            AppLockSettingsKeys.lockAfterSeconds: "120",
        ])
        let state = AppLockLaunch.state(settings: settings, biometry: .faceID)
        XCTAssertTrue(state.faceOrTouchOnlyEnabled)
        XCTAssertEqual(state.lockAfterSeconds, 120)
        XCTAssertEqual(state.authenticationPolicy, .biometricsOnly)
    }

    /// Scenario "Default" of "Lock after": no row reads "At once".
    func testNoLockAfterRowIsAtOnce() {
        let state = AppLockLaunch.state(enabled: nil, faceOrTouchOnly: nil, lockAfterSeconds: nil, biometry: .faceID)
        XCTAssertEqual(state.lockAfterSeconds, 0)
        XCTAssertFalse(state.faceOrTouchOnlyEnabled)
    }
}
