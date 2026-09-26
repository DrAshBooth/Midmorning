import Foundation
import XCTest
import Record
import RecordTestSupport

/// mm-t12.38: the shared test helper removes the store's directory when the
/// test ends, so no run leaves a store in the temporary directory.
final class TemporaryStoreTests: XCTestCase {
    /// Runs a one-test probe case to its end, teardown included, and then
    /// looks for the directory that the probe's store used.
    func testTheTeardownRemovesTheStoreDirectory() throws {
        let probe = TemporaryStoreProbe(selector: #selector(TemporaryStoreProbe.testOpenAStore))
        probe.run()
        let directory = try XCTUnwrap(probe.directory, "the probe opened a store")
        XCTAssertEqual(probe.testRun?.hasSucceeded, true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path), "the teardown removed the directory")
    }
}

/// The probe that `TemporaryStoreTests` runs. It also runs alone as an
/// ordinary test, and passes.
final class TemporaryStoreProbe: XCTestCase {
    nonisolated(unsafe) private(set) var directory: URL?

    @MainActor
    @objc func testOpenAStore() throws {
        let directory = try makeTemporaryDirectory()
        let store = try RecordStore(directory: directory)
        try store.setLocalSettingValue("true", key: "probe")
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("Local.store").path))
        self.directory = directory
    }
}
