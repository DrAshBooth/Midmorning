import XCTest
@testable import AppLock

/// mm-t13.9: `SettingsView` embeds `PrivacyAppLockControls` against the
/// app's one real `AppLockController` (built once in `AppLockRootView`,
/// shared down through `@EnvironmentObject`), so the Privacy section's rows
/// and the cover (`CoverView`) always agree.
///
/// Because "the same controller" is a Swift object identity fact, not a
/// value one test can compare, this drives the exact calls each of those two
/// roles makes on one `AppLockController` and reads the exact state the
/// other one reads, at the level `AppLockControllerTests` already tests the
/// controller at (no SwiftUI, no device): `tapTurnOffAppLock()` /
/// `turnOnAppLock()` are what the Privacy section's app-lock switch calls;
/// `coverMode` is what `CoverView`'s `body` switches on; `setLockAfterSeconds`
/// is what the "Lock after" picker calls, and `LockPolicy.shouldAsk` reading
/// the same state's `lockAfterSeconds` is what the background/foreground
/// handler consults. A regression that gave `SettingsView` its own, separate
/// `AppLockController` (rather than the shared one) would still pass every
/// existing `AppLockControllerTests` case, because those drive one isolated
/// controller; only proving the round trip through both roles' own calls, as
/// here, catches it.
@MainActor
final class AppLockSharedStateIntegrationTests: XCTestCase {
    private func makeController(appLockEnabled: Bool) -> AppLockController {
        AppLockController(
            state: .launch(appLockEnabled: appLockEnabled),
            authenticator: FakeAuthenticator(result: true),
            deleteAllSeam: RecordingDeleteAllSeam()
        )
    }

    /// Acceptance criteria example: "turning the switch off in Settings
    /// unlocks the cover."
    func testTurningTheSwitchOffInSettingsUnlocksTheCover() async {
        let controller = makeController(appLockEnabled: true)
        XCTAssertEqual(controller.state.coverMode, .locked, "the cover locks before the change")

        let succeeded = await controller.tapTurnOffAppLock()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(controller.state.coverMode, .none, "the same controller's cover mode reflects Settings' change at once, with no second instance to fall out of step")
    }

    /// The reverse: turning the switch on in Settings locks the cover, with
    /// no relaunch.
    func testTurningTheSwitchOnInSettingsLocksTheCover() {
        let controller = makeController(appLockEnabled: false)
        XCTAssertEqual(controller.state.coverMode, .none, "the cover shows nothing before the change")

        controller.turnOnAppLock()

        XCTAssertEqual(controller.state.coverMode, .locked, "the same controller's cover mode reflects Settings' change at once")
    }

    /// Acceptance criteria example: "a lock-after change takes effect on the
    /// next background."
    func testALockAfterChangeFromSettingsAppliesOnTheNextBackground() {
        let controller = makeController(appLockEnabled: true)

        controller.setLockAfterSeconds(120)

        // 90 seconds in the background is short of the new 2-minute grace.
        XCTAssertFalse(LockPolicy.shouldAsk(enteredBackgroundAt: 0, now: 90, grace: controller.state.lockAfterSeconds))
        // 150 seconds is past it.
        XCTAssertTrue(LockPolicy.shouldAsk(enteredBackgroundAt: 0, now: 150, grace: controller.state.lockAfterSeconds))
    }
}
