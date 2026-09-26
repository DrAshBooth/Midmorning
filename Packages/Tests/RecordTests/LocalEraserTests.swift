import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "Delete-all", "Delete from this device": both
/// requirements route to `LocalEraser`.
final class LocalEraserTests: XCTestCase {
    /// Scenario: Delete everything (the store-directory half).
    func testEraseAndRecreateDeletesEveryFileAndLeavesTheDirectoryEmpty() throws {
        let directory = try makeTemporaryDirectory()
        try "old data".write(to: directory.appendingPathComponent("Record.store"), atomically: true, encoding: .utf8)
        try "old data".write(to: directory.appendingPathComponent("Local.store"), atomically: true, encoding: .utf8)

        try LocalEraser.eraseAndRecreate(directory: directory)

        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertTrue(contents.isEmpty, "the store directory holds no file after Delete-all")
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path), "the directory itself exists again, empty")
    }

    /// Scenario: covers a device that never had the directory yet (a fresh
    /// install, or an install whose container never opened).
    func testEraseAndRecreateWorksWhenTheDirectoryDidNotExist() throws {
        let parent = try makeTemporaryDirectory()
        let directory = parent.appendingPathComponent("Record", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))

        try LocalEraser.eraseAndRecreate(directory: directory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }

    /// The recreated directory itself carries `NSFileProtectionComplete`
    /// and stays excluded from backup, matching every fresh install
    /// (data-and-privacy spec, "File protection", "The app excludes the
    /// whole store directory from backups": a brand new directory has
    /// neither by default, so Delete-all must set both again).
    func testRecreatedDirectoryCarriesCompleteProtectionAndBackupExclusion() throws {
        let directory = try makeTemporaryDirectory().appendingPathComponent("Record", isDirectory: true)
        try LocalEraser.eraseAndRecreate(directory: directory)
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }
}
