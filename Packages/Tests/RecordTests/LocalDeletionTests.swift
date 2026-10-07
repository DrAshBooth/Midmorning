import Foundation
import XCTest
@testable import Record
import Export

/// Records every call, in order, with no LocalAuthentication, no
/// notification centre and no widget extension — `RecordingDeleteAllSeam`'s
/// counterpart for the local half of Delete-all (data-and-privacy spec,
/// "Delete-all", "Delete from this device").
final class FakeDeleteAllSideEffects: DeleteAllSideEffects, @unchecked Sendable {
    private(set) var calls: [String] = []

    func cancelEveryNotification() {
        calls.append("cancelEveryNotification")
    }

    func reloadWidgets() {
        calls.append("reloadWidgets")
    }
}

/// data-and-privacy spec, "Delete-all" (mm-t41.1), "Delete from this device"
/// (mm-t41.2).
final class LocalDeletionTests: XCTestCase {
    private func makeDirectories() throws -> (store: URL, appGroup: URL, marker: URL, cleanup: () -> Void) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalDeletionTests-\(UUID().uuidString)", isDirectory: true)
        let store = root.appendingPathComponent("Record", isDirectory: true)
        let appGroup = root.appendingPathComponent("AppGroup", isDirectory: true)
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: appGroup, withIntermediateDirectories: true)
        let marker = root.appendingPathComponent("LaunchMarker")
        return (store, appGroup, marker, { try? FileManager.default.removeItem(at: root) })
    }

    /// Scenario: Delete everything — the store directory holds no file
    /// afterwards.
    func testPerformDeletesEveryFileInTheStoreDirectory() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        try "x".write(to: store.appendingPathComponent("Record.store"), atomically: true, encoding: .utf8)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)

        try deletion.perform(sideEffects: FakeDeleteAllSideEffects())

        let contents = try FileManager.default.contentsOfDirectory(at: store, includingPropertiesForKeys: nil)
        XCTAssertTrue(contents.isEmpty)
    }

    /// Scenario: "Pending requests first". `mm-t42.20` confirmed
    /// empirically that `UNUserNotificationCenter.current()` crashes outside
    /// a real app bundle (`ununnotificationcenter-crashes-under-swift-test`,
    /// `bd memories`): a real notification centre and a real six-request
    /// queue are a device check, not a `swift test` scenario. This call-order
    /// assertion over the fake stays the package-level proof.
    func testPerformCancelsNotificationsBeforeDeletingTheStoreDirectoryAndReloadsWidgetsLast() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        try "x".write(to: store.appendingPathComponent("Record.store"), atomically: true, encoding: .utf8)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)
        let sideEffects = FakeDeleteAllSideEffects()

        try deletion.perform(sideEffects: sideEffects)

        XCTAssertEqual(sideEffects.calls, ["cancelEveryNotification", "reloadWidgets"])
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(at: store, includingPropertiesForKeys: nil).isEmpty, "the store directory is already gone by the time widgets reload")
    }

    /// Scenario: "Side files" — the action queue and the widget snapshot,
    /// and the launch marker, are each deleted when present.
    func testPerformDeletesTheAppGroupSideFilesAndTheLaunchMarkerWhenTheyExist() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        for url in AppGroupContent.fileURLs(inAppGroupDirectory: appGroup) {
            try "x".write(to: url, atomically: true, encoding: .utf8)
        }
        try "1".write(to: marker, atomically: true, encoding: .utf8)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)

        try deletion.perform(sideEffects: FakeDeleteAllSideEffects())

        for url in AppGroupContent.fileURLs(inAppGroupDirectory: appGroup) {
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "\(url.lastPathComponent) is deleted")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path), "the launch marker is deleted")
    }

    /// mm-t41.18: the action queue file the app writes, `queue.json`, by
    /// the same `AppGroupContent` path `StoreLocation.actionQueueURL()` and
    /// `ActionQueueFile` use. A name that differs between the writer and
    /// Delete-all fails here.
    func testPerformDeletesTheActionQueueFileByTheNameTheAppWrites() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let queueURL = AppGroupContent.actionQueueURL(inAppGroupDirectory: appGroup)
        XCTAssertEqual(queueURL.lastPathComponent, "queue.json")
        let action = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: Date(timeIntervalSince1970: 1_760_000_000))
        try ActionQueueCodec.appending(action, to: Data()).write(to: queueURL)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)

        try deletion.perform(sideEffects: FakeDeleteAllSideEffects())

        XCTAssertFalse(FileManager.default.fileExists(atPath: queueURL.path), "queue.json is deleted")
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: appGroup.path).isEmpty, "the App Group container holds no file of ours")
    }

    /// Neither side file nor the marker existing yet (a fresh install, or a
    /// device before `2.4`/`2.5` ever write them) is not an error.
    func testPerformSucceedsWhenNeitherSideFileNorTheMarkerExistYet() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)
        XCTAssertNoThrow(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
    }

    /// mm-t42.24: an export PDF that a process left in `tmp/Export` goes at
    /// Delete-all ("The app MUST leave no file").
    func testPerformDeletesTheExportFolder() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let temporaryDirectory = store.deletingLastPathComponent().appendingPathComponent("tmp", isDirectory: true)
        let pdf = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "Record.pdf", temporaryDirectory: temporaryDirectory)
        let exportFolder = ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker, exportDirectory: exportFolder)

        try deletion.perform(sideEffects: FakeDeleteAllSideEffects())

        XCTAssertFalse(FileManager.default.fileExists(atPath: pdf.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: exportFolder.path))
    }

    /// mm-t45.11: when the person taps Print, iOS writes its own copy of
    /// the PDF to `tmp/<UUID>/`, beside `tmp/Export`. Delete-all and "Delete
    /// from this device" (one engine) remove that copy and each other PDF
    /// in `tmp` ("The app MUST leave no file"), and remove `tmp/Export` as
    /// before. Each item in `tmp` that is not a PDF stays.
    func testPerformDeletesThePrintCopyAndEveryOtherPDFInTmp() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let manager = FileManager.default
        let temporaryDirectory = store.deletingLastPathComponent().appendingPathComponent("tmp", isDirectory: true)
        let exported = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "Record.pdf", temporaryDirectory: temporaryDirectory)
        let printFolder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: printFolder, withIntermediateDirectories: true)
        let printCopy = printFolder.appendingPathComponent("Record 2026-10-07 to 2026-10-07.pdf")
        try Data("%PDF".utf8).write(to: printCopy)
        let topLevel = temporaryDirectory.appendingPathComponent("Record.PDF")
        try Data("%PDF".utf8).write(to: topLevel)
        let notAPDF = printFolder.appendingPathComponent("notes.txt")
        try Data("x".utf8).write(to: notAPDF)
        let exportFolder = ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker,
                                     exportDirectory: exportFolder, temporaryDirectory: temporaryDirectory)

        try deletion.perform(sideEffects: FakeDeleteAllSideEffects())

        for url in [exported, printCopy, topLevel] {
            XCTAssertFalse(manager.fileExists(atPath: url.path), "\(url.lastPathComponent) is deleted")
        }
        XCTAssertEqual(TemporaryPDFFiles.urls(inTemporaryDirectory: temporaryDirectory), [], "tmp holds no PDF")
        XCTAssertFalse(manager.fileExists(atPath: exportFolder.path), "tmp/Export is deleted, as before")
        XCTAssertTrue(manager.fileExists(atPath: notAPDF.path), "a file that is not a PDF stays")
    }

    /// mm-t45.11: a PDF in `tmp` that exists but cannot be deleted makes
    /// the deletion throw, so no caller shows "Everything is deleted"
    /// while a PDF stays (ruling r14-01).
    func testPerformThrowsWhenAPDFInTmpCannotBeDeleted() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        let temporaryDirectory = store.deletingLastPathComponent().appendingPathComponent("tmp", isDirectory: true)
        let printFolder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: printFolder, withIntermediateDirectories: true)
        let printCopy = printFolder.appendingPathComponent("Record.pdf")
        try Data("%PDF".utf8).write(to: printCopy)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: printFolder.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: printFolder.path)
            cleanup()
        }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker, temporaryDirectory: temporaryDirectory)

        XCTAssertThrowsError(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: printCopy.path))
    }

    /// A temporary directory that does not exist holds no PDF: the deletion
    /// succeeds.
    func testPerformSucceedsWhenTheTemporaryDirectoryIsMissing() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let missing = store.deletingLastPathComponent().appendingPathComponent("no-tmp", isDirectory: true)
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker, temporaryDirectory: missing)
        XCTAssertNoThrow(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
    }

    /// A folder in `tmp` that the sweep cannot read does not stop the
    /// deletion: the app and the print copy write only folders that the
    /// app can read, and a folder of another owner must not stop
    /// Delete-all every time. A PDF beside that folder still goes.
    func testPerformSucceedsWhenAFolderInTmpCannotBeRead() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        let temporaryDirectory = store.deletingLastPathComponent().appendingPathComponent("tmp", isDirectory: true)
        let unreadable = temporaryDirectory.appendingPathComponent("NotOurs", isDirectory: true)
        try FileManager.default.createDirectory(at: unreadable, withIntermediateDirectories: true)
        let printFolder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: printFolder, withIntermediateDirectories: true)
        let printCopy = printFolder.appendingPathComponent("Record.pdf")
        try Data("%PDF".utf8).write(to: printCopy)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: unreadable.path)
            cleanup()
        }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker, temporaryDirectory: temporaryDirectory)

        XCTAssertNoThrow(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: printCopy.path), "the PDF beside the folder is deleted")
    }

    /// mm-t41.20: a side file that exists but cannot be deleted makes the
    /// deletion throw, so no caller shows "Everything is deleted".
    func testPerformThrowsWhenAnExistingSideFileCannotBeDeleted() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        let queueURL = AppGroupContent.actionQueueURL(inAppGroupDirectory: appGroup)
        try Data("[]".utf8).write(to: queueURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: appGroup.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: appGroup.path)
            cleanup()
        }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)

        XCTAssertThrowsError(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: queueURL.path))
    }

    /// mm-t41.20: a store directory that cannot be erased makes the
    /// deletion throw.
    func testPerformThrowsWhenTheStoreDirectoryCannotBeErased() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        try "x".write(to: store.appendingPathComponent("Record.store"), atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: store.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: store.path)
            cleanup()
        }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)

        XCTAssertThrowsError(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
    }

    /// A device with no App Group container yet (development signing with
    /// no matching provisioning) still completes the store-directory half.
    func testPerformSucceedsWithNoAppGroupDirectory() throws {
        let (store, _, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: nil, launchMarkerURL: marker)
        XCTAssertNoThrow(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
    }
}
