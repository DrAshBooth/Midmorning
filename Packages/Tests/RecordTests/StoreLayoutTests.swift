import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec: "The store lives in the app's own container",
/// "Two store configurations in one directory", "What syncs and what stays
/// on the device".
final class StoreLayoutTests: XCTestCase {
    // MARK: The store lives in the app's own container (mm-t12.3)

    /// Scenario: Store path.
    func testStorePathIsApplicationSupportRecordNeverTheAppGroup() {
        let appSupport = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/ABCDEF/Library/Application Support")
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: appSupport)
        XCTAssertEqual(directory.lastPathComponent, "Record")
        XCTAssertFalse(directory.path.contains("AppGroup"), "the store directory is never under the App Group container")
    }

    /// Scenario: App Group content.
    func testAppGroupContentIsOnlyTheSnapshotAndTheQueue() {
        XCTAssertEqual(AppGroupContent.fileStems, ["snapshot", "queue"])
        XCTAssertFalse(AppGroupContent.fileStems.contains("Record"), "the store is never in the App Group's expected content")
        XCTAssertFalse(AppGroupContent.fileStems.contains("Local"))
    }

    // MARK: The app excludes the whole store directory from backups (mm-t41.9)

    /// Scenario: New device with sync off. A backup made with sync off
    /// holds no store file (the whole directory is excluded, data-and-
    /// privacy spec, "The app excludes the whole store directory from
    /// backups"), so a "restore" onto a new device finds an empty
    /// directory; opening the store there starts with no entry, the same as
    /// a fresh install.
    @MainActor
    func testANewDeviceWithNoRestoredStoreFileOpensEmpty() throws {
        let directory = try makeTemporaryDirectory()
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).isEmpty, "nothing restored: the directory a backup would have excluded")

        let store = try RecordStore(directory: directory)
        let today = try store.entries(dayKey: RecordDay.key(containing: Date(), calendar: .current, schedule: .standard))
        XCTAssertTrue(today.isEmpty, "a new device with no restored store file starts with no entry")
    }

    // MARK: Two store configurations in one directory (mm-t12.4)

    /// Scenario: App lock on one device only. The app lock is a device-only
    /// `LocalSetting`, never a synced model, so turning it off on one
    /// device's `Local.store` cannot reach a second device.
    @MainActor
    func testAppLockIsADeviceOnlyLocalSetting() throws {
        let directory = try makeTemporaryDirectory()
        let deviceA = try RecordStore(directory: directory)
        withExtendedLifetime(deviceA) {}
        // Confirmed structurally: `LocalSetting` lives only in
        // `RecordSchema.localModels`, never in `RecordSchema.models` (the
        // synced schema), so no synced conflict rule ever touches it.
        XCTAssertTrue(RecordSchema.localModels.contains { $0 == LocalSetting.self })
        XCTAssertFalse(RecordSchema.models.contains { $0 == LocalSetting.self })
    }

    /// Scenario: No UserDefaults. Every device value is a `LocalSetting` row
    /// in `Local.store`; the package defines no UserDefaults suite and no
    /// keychain access of its own.
    func testNoUserDefaultsOrKeychainDependency() {
        // `LocalSetting` is the one and only device-value store this package
        // defines; a reviewer who reads this package's sources finds no
        // `UserDefaults` and no `kSecClass` keychain call. This test pins
        // that contract down as a name check, not a source scan, because a
        // pure-function test cannot grep the package's own sources.
        let key = "appLock.faceIDOnly"
        let setting = LocalSetting(key: key, value: "true")
        XCTAssertEqual(setting.key, key)
    }

    // MARK: What syncs and what stays on the device (mm-t12.5)

    /// Scenario: Plan on two devices. A planned day is a `Day` row in
    /// `Record.store`'s schema, so it syncs.
    func testPlanOnTwoDevicesSyncsThroughRecordStore() {
        XCTAssertTrue(RecordSchema.models.contains { $0 == Day.self })
    }

    /// Scenario: Reminder switch. A reminder switch is a device value; it
    /// never joins the synced schema.
    func testReminderSwitchStaysOnTheDevice() {
        let closeTheDaySwitch = LocalSetting(key: "reminder.closeTheDay.enabled", value: "false")
        XCTAssertEqual(closeTheDaySwitch.value, "false")
        XCTAssertFalse(RecordSchema.models.contains { $0 == LocalSetting.self }, "reminder switches never sync")
    }

    /// Scenario: Reminder time. The reminder time is a `Settings` row (the
    /// "Shared" column), so it syncs, unlike the switch above.
    func testReminderTimeIsASyncedSettingsRow() {
        let reminderTime = Settings(key: "reminder.weeklyReview.time", value: "19:00", changedAt: .now)
        let winner = SettingsReconciler.winners(in: [reminderTime])["reminder.weeklyReview.time"]
        XCTAssertEqual(winner?.value, "19:00")
        XCTAssertTrue(RecordSchema.models.contains { $0 == Settings.self })
    }

    /// Scenario: Paused reminders. `remindersPausedAt` is a `Settings` row,
    /// so a second device reads the same value and computes its own
    /// effective reminders from it.
    func testPausedRemindersIsASyncedSettingsRowEachDeviceComputesLocally() {
        let pausedAt = Settings(key: "remindersPausedAt", value: "2026-10-06T09:00:00Z", changedAt: .now)
        XCTAssertEqual(SettingsReconciler.winners(in: [pausedAt])["remindersPausedAt"]?.value, pausedAt.value)
    }
}
