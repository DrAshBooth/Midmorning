import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "The app excludes the whole store directory from
/// backups" and "File protection" (mm-t41.16). `AppLockRootView` opens the
/// store only through `RecordStore.openInPreparedDirectory`, so these tests
/// call the same function the app calls at every launch.
@MainActor
final class StoreBackupExclusionTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("StoreBackupExclusionTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// An ordinary install: no store directory exists before the first
    /// open, and no Delete-all ever ran.
    func testTheFirstOpenCreatesTheStoreDirectoryExcludedFromBackup() throws {
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: root)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))

        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
        withExtendedLifetime(store) {}

        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("Record.store").path), "the store files are inside the excluded directory")
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("Local.store").path))
    }

    /// A device that an earlier build left with a store directory that is
    /// not excluded gets the exclusion at the next open.
    func testAnOpenExcludesADirectoryThatAnEarlierBuildLeftInTheBackup() throws {
        var directory = StoreLayout.storeDirectory(applicationSupportDirectory: root)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        try directory.setResourceValues(values)
        directory.removeAllCachedResourceValues()
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, false)

        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
        withExtendedLifetime(store) {}

        directory.removeAllCachedResourceValues()
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    /// Scenario: Side files — the action queue carries the side-file class,
    /// and the app excludes it from backup ("The app MUST exclude every file
    /// it writes in the App Group container").
    func testTheActionQueueFileIsExcludedFromBackupWithTheSideFileClass() throws {
        let url = AppGroupContent.actionQueueURL(inAppGroupDirectory: root)
        let action = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: Date(timeIntervalSince1970: 1_760_000_000))
        try ActionQueueCodec.encode([action]).write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)

        try FileProtection.protectSideFile(url)

        XCTAssertEqual(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .completeUntilFirstUserAuthentication)
    }
}
