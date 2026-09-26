import Foundation
import XCTest
@testable import Record
import AppLock

/// mm-8jr: the Privacy group's three app-lock values survive a relaunch.
/// The App target adapts `RecordStore` to `AppLockSettingsStoring` with
/// `RecordStoreAppLockSettings` (App/Midmorning/AppLock/
/// AppLockControllerFactory.swift). No test runner builds the App target,
/// so this test uses the same two calls over a real store, closes it,
/// opens it again and builds a fresh controller from it, the same way
/// `AppLockControllerFactory.make(store:)` does at launch.
@MainActor
final class AppLockLocalStoreTests: XCTestCase {
    /// The same adapter as the App target's `RecordStoreAppLockSettings`.
    private struct StoreSettings: AppLockSettingsStoring {
        let store: RecordStore

        func appLockSetting(forKey key: String) -> String? {
            (try? store.localSettingValue(key: key)) ?? nil
        }

        func setAppLockSetting(_ value: String, forKey key: String) {
            try? store.setLocalSettingValue(value, key: key)
        }
    }

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLockLocalStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeController(store: RecordStore, biometry: Biometry = .faceID) -> AppLockController {
        let settings = StoreSettings(store: store)
        return AppLockController(
            state: AppLockLaunch.state(settings: settings, biometry: biometry),
            authenticator: FakeAuthenticator(result: true),
            deleteAllSeam: RecordingDeleteAllSeam(),
            settings: settings
        )
    }

    /// Each Privacy group action writes its own key to `Local.store`.
    func testEachSettingsActionWritesItsKey() async throws {
        let store = try RecordStore(directory: directory)
        let controller = makeController(store: store)

        await controller.tapTurnOffAppLock()
        XCTAssertEqual(try store.localSettingValue(key: AppLockSettingsKeys.enabled), "false")
        controller.turnOnAppLock()
        XCTAssertEqual(try store.localSettingValue(key: AppLockSettingsKeys.enabled), "true")

        controller.setLockAfterSeconds(30)
        XCTAssertEqual(try store.localSettingValue(key: AppLockSettingsKeys.lockAfterSeconds), "30")

        controller.confirmTurnOnFaceOrTouchOnly()
        XCTAssertEqual(try store.localSettingValue(key: AppLockSettingsKeys.faceOrTouchOnly), "true")
        await controller.tapTurnOffFaceOrTouchOnly()
        XCTAssertEqual(try store.localSettingValue(key: AppLockSettingsKeys.faceOrTouchOnly), "false")
    }

    /// Scenario "Turn off": "the app lock is off and the app opens without
    /// an authentication request from then on". A fresh controller from
    /// the reopened store starts in the state the person left.
    func testAFreshControllerFromTheReopenedStoreStartsWhereThePersonLeftIt() async throws {
        do {
            let store = try RecordStore(directory: directory)
            let controller = makeController(store: store)
            controller.setLockAfterSeconds(300)
            controller.confirmTurnOnFaceOrTouchOnly()
            await controller.tapTurnOffAppLock()
        }

        let reopened = try RecordStore(directory: directory)
        let relaunched = makeController(store: reopened)
        XCTAssertFalse(relaunched.state.appLockEnabled)
        XCTAssertEqual(relaunched.state.coverMode, .none)
        XCTAssertEqual(relaunched.state.lockAfterSeconds, 300)
        XCTAssertTrue(relaunched.state.faceOrTouchOnlyEnabled)
    }

    /// mm-t14.32: onboarding "Start" writes the choice (Screen 4), and the
    /// controller built before onboarding applies the same row.
    func testTheOnboardingChoiceReachesTheController() throws {
        let store = try RecordStore(directory: directory)
        let controller = makeController(store: store)
        XCTAssertEqual(controller.state.coverMode, .locked, "a fresh install has no row")

        try store.setLocalSettingValue("false", key: AppLockSettingsKeys.enabled)
        let saved = StoreSettings(store: store).appLockSetting(forKey: AppLockSettingsKeys.enabled)
        controller.applyOnboardingChoice(appLockEnabled: AppLockLaunch.isEnabled(saved: saved, biometry: .faceID))

        XCTAssertEqual(controller.state.coverMode, .none)
        XCTAssertFalse(controller.state.appLockEnabled)
    }
}
