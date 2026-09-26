import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "File protection".
final class FileProtectionTests: XCTestCase {
    // MARK: Scenario: Store files

    func testApplyToDatabaseFilesSetsCompleteOnEveryFileInTheDirectory() throws {
        let directory = try tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = ["Record.store", "Record.store-wal", "Record.store-shm", "Local.store"]
        for name in files {
            try "x".write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }

        FileProtection.applyToDatabaseFiles(in: directory)

        for name in files {
            let attributes = try FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)
            XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete, "\(name) carries NSFileProtectionComplete")
        }
    }

    func testDatabaseFileRoleMapsToComplete() {
        XCTAssertEqual(FileProtection.protectionClass(for: .databaseFile), .complete)
    }

    /// data-and-privacy spec, "The app excludes the whole store directory
    /// from backups".
    func testProtectStoreDirectorySetsCompleteProtectionAndBackupExclusion() throws {
        let directory = try tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try FileProtection.protectStoreDirectory(directory)

        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }

    // MARK: Scenario: Side files (built here over fixture facts — neither
    // the action queue nor the widget snapshot exists yet; `mm-t25.15`
    // proves the widget-snapshot half against the real file)

    func testSideFileRoleMapsToCompleteUntilFirstUserAuthentication() {
        XCTAssertEqual(FileProtection.protectionClass(for: .sideFile), .completeUntilFirstUserAuthentication)
    }

    func testAppGroupContentFileURLsAreTheActionQueueAndTheWidgetSnapshot() {
        let directory = URL(fileURLWithPath: "/var/mobile/Containers/Shared/AppGroup/ABCDEF")
        let urls = AppGroupContent.fileURLs(inAppGroupDirectory: directory)
        XCTAssertEqual(Set(urls.map { $0.deletingPathExtension().lastPathComponent }), AppGroupContent.fileStems)
        XCTAssertEqual(Set(urls.map(\.lastPathComponent)), [AppGroupContent.actionQueueFileName, AppGroupContent.snapshotFileName])
    }

    private func tempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FileProtectionTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
