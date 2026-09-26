import Foundation
import XCTest
@testable import Record

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

    /// Scenario: "Pending requests first" (built here over fixture facts,
    /// with no live dependency — `mm-t42.20` runs it against a real
    /// notification centre and a real six-request queue).
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

    /// Neither side file nor the marker existing yet (a fresh install, or a
    /// device before `2.4`/`2.5` ever write them) is not an error.
    func testPerformSucceedsWhenNeitherSideFileNorTheMarkerExistYet() throws {
        let (store, appGroup, marker, cleanup) = try makeDirectories()
        defer { cleanup() }
        let deletion = LocalDeletion(directory: store, appGroupDirectory: appGroup, launchMarkerURL: marker)
        XCTAssertNoThrow(try deletion.perform(sideEffects: FakeDeleteAllSideEffects()))
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
