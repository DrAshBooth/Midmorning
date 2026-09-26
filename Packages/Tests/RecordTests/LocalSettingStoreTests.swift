import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "Two store configurations in one directory". The
/// app lock's own settings are the first `LocalSetting` rows a test drives
/// through `RecordStore` (app-lock spec, "The app lock is on by default").
@MainActor
final class LocalSettingStoreTests: XCTestCase {
    func testValueForKeyIsNilBeforeAnyWrite() throws {
        let store = try makeTemporaryStore()
        XCTAssertNil(try store.localSettingValue(key: "appLock.enabled"))
    }

    func testSetLocalSettingThenReadsBackTheSameValue() throws {
        let store = try makeTemporaryStore()
        try store.setLocalSettingValue("true", key: "appLock.enabled")
        XCTAssertEqual(try store.localSettingValue(key: "appLock.enabled"), "true")
    }

    /// Scenario: App lock on one device only — writing a key replaces its
    /// one row rather than inserting a second.
    func testSetLocalSettingTwiceReplacesTheRowRatherThanDuplicatingIt() throws {
        let store = try makeTemporaryStore()
        try store.setLocalSettingValue("0", key: "appLock.lockAfterSeconds")
        try store.setLocalSettingValue("30", key: "appLock.lockAfterSeconds")
        XCTAssertEqual(try store.localSettingValue(key: "appLock.lockAfterSeconds"), "30")
    }

    func testValuesSurviveReopeningTheStore() throws {
        let directory = try makeTemporaryDirectory()
        let store = try RecordStore(directory: directory)
        try store.setLocalSettingValue("true", key: "appLock.faceOrTouchOnly")
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.localSettingValue(key: "appLock.faceOrTouchOnly"), "true")
    }
}
