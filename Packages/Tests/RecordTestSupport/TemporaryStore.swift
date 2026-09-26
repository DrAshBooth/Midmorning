import Foundation
import XCTest
import Record

/// The one way a test makes a temporary `RecordStore` (mm-t12.38). Each
/// call makes a new directory under the temporary directory, and the test's
/// teardown removes it, so no run leaves a store behind. `RecordTests` and
/// `ExportTests` both use it.
extension XCTestCase {
    /// A new, empty directory that the test's teardown removes. Use it when
    /// a test opens a second store on the same directory, for example after
    /// a restart or a Delete-all.
    public func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(type(of: self))-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory
    }

    /// A new, empty store in a directory that the test's teardown removes.
    @MainActor
    public func makeTemporaryStore() throws -> RecordStore {
        try RecordStore(directory: makeTemporaryDirectory())
    }
}
