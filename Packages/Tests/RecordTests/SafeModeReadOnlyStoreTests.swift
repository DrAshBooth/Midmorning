import Foundation
import SwiftData
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "Launch safety": "In safe mode the app MUST open
/// the store read-only" (ruling r13-05, mm-t42.23). `AppLockRootView`
/// chooses safe mode from the launch marker before the open, then opens
/// through the same `RecordStore.openInPreparedDirectory(readOnly:)` these
/// tests call.
@MainActor
final class SafeModeReadOnlyStoreTests: XCTestCase {
    private let moment = Date(timeIntervalSince1970: 1_790_000_000) // 2026-09-21

    /// A store that an earlier, ordinary launch wrote: one entry and one
    /// device value.
    private func makeRecordOnDisk() throws -> URL {
        let root = try makeTemporaryDirectory()
        // The pool ends the ordinary store's container here, so SQLite
        // closes both files before the test reads their bytes.
        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
            try store.add(time: moment, what: "Toast and tea", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0, dayStartHour: 5)
            try store.setLocalSettingValue("kept", key: "test.value")
        }
        return root
    }

    /// The bytes of the two store files and their write-ahead logs. The
    /// `-shm` index is left out: SQLite changes it for a read too.
    private func storeBytes(root: URL) -> [String: Data] {
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: root)
        var bytes: [String: Data] = [:]
        for name in ["Record.store", "Record.store-wal", "Local.store", "Local.store-wal"] {
            bytes[name] = try? Data(contentsOf: directory.appendingPathComponent(name))
        }
        return bytes
    }

    /// SQLite copies the write-ahead log into the main file when the last
    /// ordinary connection closes. Core Data can close the ordinary store
    /// after the test's own scope ends, so the test waits for that copy
    /// before it reads the bytes (2 seconds at most).
    private func waitUntilTheWriteAheadLogsAreEmpty(root: URL) {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            let logs = storeBytes(root: root).filter { $0.key.hasSuffix("-wal") }.values
            if logs.allSatisfy(\.isEmpty) { return }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    /// Safe mode reads the record for Export.
    func testASafeModeOpenReadsTheRecord() throws {
        let root = try makeRecordOnDisk()

        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true)

        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
    }

    /// Safe mode writes nothing: every write fails, and neither file
    /// changes.
    func testASafeModeOpenWritesNothing() throws {
        let root = try makeRecordOnDisk()
        waitUntilTheWriteAheadLogsAreEmpty(root: root)
        let before = storeBytes(root: root)

        do {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true)
            XCTAssertThrowsError(try store.add(time: moment, what: "Soup", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0, dayStartHour: 5))
            XCTAssertThrowsError(try store.setLocalSettingValue("changed", key: "test.value"))
            XCTAssertThrowsError(try store.incrementLaunchFailureCount())
        }

        XCTAssertEqual(storeBytes(root: root), before, "a read-only open changes no store file")
        let reopened = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
        XCTAssertEqual(try reopened.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        XCTAssertEqual(try reopened.localSettingValue(key: "test.value"), "kept")
        XCTAssertEqual(try reopened.diagnosticsCounts(contentVersion: 1).launchFailures, 0)
    }

    /// A store at a schema version that the migration plan does not hold.
    /// The `Record.store` here holds only `Item`, so its metadata agrees
    /// with no version in `RecordMigrationPlan`. Safe mode opens a store
    /// only at the version that the store holds (ruling r15-01,
    /// mm-t42.28), so the open throws, no migration step writes to the
    /// store, and neither file changes. The app then shows the
    /// store-failure page. `SafeModeSchemaVersionTests` proves the open of
    /// a store at an earlier version that the plan holds.
    func testASafeModeOpenOfAStoreAtAnUnknownSchemaVersionWritesNothing() throws {
        let root = try makeRecordOnDisk()
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: root)
        for name in ["Record.store", "Record.store-wal", "Record.store-shm"] {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
        try autoreleasepool {
            let smaller = Schema([Item.self])
            let container = try ModelContainer(
                for: smaller,
                configurations: ModelConfiguration("Record", schema: smaller, url: directory.appendingPathComponent("Record.store"), cloudKitDatabase: .none)
            )
            let context = ModelContext(container)
            context.insert(Item(id: UUID()))
            try context.save()
        }
        waitUntilTheWriteAheadLogsAreEmpty(root: root)
        let before = storeBytes(root: root)
        XCTAssertNotNil(before["Record.store"])

        XCTAssertThrowsError(try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true)) { error in
            guard case RecordStore.Failure.noKnownSchemaVersion = error else { return XCTFail("\(error)") }
        }

        XCTAssertEqual(storeBytes(root: root), before, "no migration step writes to the store")
    }

    /// A safe-mode open never makes a store: with no store on the device,
    /// the open fails and the app shows the store-failure page.
    func testASafeModeOpenMakesNoStore() throws {
        let root = try makeTemporaryDirectory()

        XCTAssertThrowsError(try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true))

        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: root)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        XCTAssertFalse(files.contains("Record.store"))
        XCTAssertFalse(files.contains("Local.store"))
    }
}
