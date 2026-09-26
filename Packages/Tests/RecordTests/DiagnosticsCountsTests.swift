import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "The Diagnostics counts come from the device";
/// settings spec, "The About group".
@MainActor
final class DiagnosticsCountsTests: XCTestCase {
    private func makeStore() throws -> (RecordStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiagnosticsCountsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (try RecordStore(directory: directory), directory)
    }

    /// Scenario: Sync off. Built here: every count this change can compute
    /// with no sync — "last successful sync day" is the one count `4.1b`
    /// (`mm-t41b.11`) writes for real.
    func testSyncOffReadsNeverForTheLastSuccessfulSyncDay() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let counts = try store.diagnosticsCounts(contentVersion: 2)
        XCTAssertEqual(counts.lastSuccessfulSyncDay, "Never")
    }

    /// Scenario: Managed device — no code path reads or reacts to MDM, so
    /// the counts are the same on any device; this is that same computation.
    func testManagedDeviceComputesTheSameCounts() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let counts = try store.diagnosticsCounts(contentVersion: 2)
        XCTAssertEqual(counts.schemaVersion, "\(RecordSchemaV1.versionIdentifier)")
        XCTAssertEqual(counts.contentVersion, 2)
    }

    /// Scenario: Diagnostics content (built here for six of the eight
    /// counts; the sync-on half is `deferred: mm-t41b.11`).
    func testDiagnosticsCountsReflectEveryStoredCounter() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.incrementLaunchFailureCount()
        try store.incrementLaunchFailureCount()
        try store.incrementCrashCount()
        try store.recordReconcileOutcome(winners: 4, losers: 1)

        let counts = try store.diagnosticsCounts(contentVersion: 3)

        XCTAssertEqual(counts.launchFailures, 2)
        XCTAssertEqual(counts.crashCount, 1)
        XCTAssertEqual(counts.lastReconcileOutcome, .init(winners: 4, losers: 1))
        XCTAssertEqual(counts.pendingReminders, 0, "2.4 (mm-t24.20) supplies the real value")
        XCTAssertEqual(counts.queueLength, 0, "2.4 (mm-t24.20) supplies the real value")
    }

    func testIncrementLaunchFailureCountReturnsTheNewCount() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertEqual(try store.incrementLaunchFailureCount(), 1)
        XCTAssertEqual(try store.incrementLaunchFailureCount(), 2)
    }

    /// data-and-privacy spec, "No record content in the system log or
    /// crash reports": "MetricKit diagnostic".
    func testIncrementCrashCountKeepsOnlyTheCountAndSurvivesReopening() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.incrementCrashCount()
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.diagnosticsCounts(contentVersion: 1).crashCount, 1)
    }

    func testZeroDiagnosticsSourceCountsAreBothZero() {
        let source = ZeroDiagnosticsSourceCounts()
        XCTAssertEqual(source.pendingReminders, 0)
        XCTAssertEqual(source.queueLength, 0)
    }
}
