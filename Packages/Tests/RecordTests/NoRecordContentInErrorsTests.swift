import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "No record content in the system log or crash
/// reports". `weigh-in` (2.2) has not built its own save path yet, so this
/// proves the general rule `RecordStore` already holds for every save: the
/// one error it throws is a case with no associated value, so no number, no
/// plan and no free text can ever reach an error description through it.
@MainActor
final class NoRecordContentInErrorsTests: XCTestCase {
    /// Scenario: Weigh-in save fails (proved over the one save-failure path
    /// this change can drive today — `update` with no current version;
    /// `weigh-in`'s own save reuses the same `Failure.saveFailed` case, so
    /// this is the same guarantee a weigh-in save failure would carry).
    func testASaveFailureCarriesNoData() throws {
        let directory = try tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try RecordStore(directory: directory)

        do {
            try store.update(entryId: UUID(), time: Date(), what: "72.4", feltLikeABinge: false, whereText: "", context: "", editedAt: Date())
            XCTFail("updating an entry id with no current version must throw")
        } catch RecordStore.Failure.saveFailed {
            // `saveFailed` is a case with no associated value: the type
            // itself carries no number, no plan and no free text, however
            // the description is rendered.
            XCTAssertFalse("\(RecordStore.Failure.saveFailed)".contains("72.4"), "the error's own description never repeats what was saved")
        }
    }

    /// Scenario: Crash while typing (structural: no function in
    /// `RecordStore.swift` writes free text to the system log or to
    /// standard output — a `swift test` cannot induce a real crash to
    /// inspect a crash report, so this reads the one source file's own text
    /// for the calls that would leak it).
    func testRecordStoreSourceNeverLogsOrPrints() throws {
        let recordStoreSource = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // .../Packages/Tests/RecordTests
            .deletingLastPathComponent() // .../Packages/Tests
            .deletingLastPathComponent() // .../Packages
            .appendingPathComponent("Sources/Record/RecordStore.swift")
        let text = try String(contentsOf: recordStoreSource, encoding: .utf8)
        for forbidden in ["print(", "os_log(", "NSLog(", "debugPrint("] {
            XCTAssertFalse(text.contains(forbidden), "RecordStore.swift calls \(forbidden), which could write record content to the system log")
        }
    }

    private func tempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NoRecordContentInErrorsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
