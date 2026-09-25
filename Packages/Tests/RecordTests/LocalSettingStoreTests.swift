import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Two store configurations in one directory". The
/// app lock's own settings are the first `LocalSetting` rows a test drives
/// through `RecordStore` (app-lock spec, "The app lock is on by default").
@MainActor
final class LocalSettingStoreTests: XCTestCase {
    private func makeStore() throws -> (RecordStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalSettingStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (try RecordStore(directory: directory), directory)
    }

    func testValueForKeyIsNilBeforeAnyWrite() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertNil(try store.localSettingValue(key: "appLock.enabled"))
    }

    func testSetLocalSettingThenReadsBackTheSameValue() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.setLocalSettingValue("true", key: "appLock.enabled")
        XCTAssertEqual(try store.localSettingValue(key: "appLock.enabled"), "true")
    }

    /// Scenario: App lock on one device only — writing a key replaces its
    /// one row rather than inserting a second.
    func testSetLocalSettingTwiceReplacesTheRowRatherThanDuplicatingIt() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.setLocalSettingValue("0", key: "appLock.lockAfterSeconds")
        try store.setLocalSettingValue("30", key: "appLock.lockAfterSeconds")
        XCTAssertEqual(try store.localSettingValue(key: "appLock.lockAfterSeconds"), "30")
    }

    func testValuesSurviveReopeningTheStore() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.setLocalSettingValue("true", key: "appLock.faceOrTouchOnly")
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.localSettingValue(key: "appLock.faceOrTouchOnly"), "true")
    }
}
