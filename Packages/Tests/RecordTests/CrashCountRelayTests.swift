import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "No record content in the system log or crash
/// reports", Scenario: MetricKit diagnostic; "The Diagnostics counts come
/// from the device" (mm-t41.23). `MetricKitSubscriber` (App target) holds
/// one relay and adds its counts to `RecordStore.incrementCrashCount`.
@MainActor
final class CrashCountRelayTests: XCTestCase {
    /// A delivery of three payloads: one with two crashes, one with only a
    /// hang, one with one crash. The count is three crashes, not three
    /// payloads and not one delivery.
    func testTheCountIsTheNumberOfCrashDiagnosticsNotPayloads() {
        XCTAssertEqual(CrashCountRelay.crashCount(inPayloadCrashCounts: [2, nil, 1]), 3)
        XCTAssertEqual(CrashCountRelay.crashCount(inPayloadCrashCounts: [nil, 0]), 0, "hang, CPU and disk diagnostics add nothing")
    }

    /// A delivery before the store opens waits, and the store gets it when
    /// it opens.
    func testADeliveryBeforeTheStoreOpensIsKeptUntilItOpens() {
        var relay = CrashCountRelay()
        XCTAssertEqual(relay.receive(crashes: 2), 0)
        XCTAssertEqual(relay.waiting, 2)

        XCTAssertEqual(relay.connect(), 2)
        XCTAssertEqual(relay.waiting, 0)
        XCTAssertEqual(relay.receive(crashes: 1), 1)
        XCTAssertEqual(relay.connect(), 0, "nothing waits twice")
    }

    /// The count reaches `Local.store` through the store's own counter,
    /// which the Diagnostics page reads.
    func testTheWaitingCrashesReachTheDiagnosticsCount() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrashCountRelayTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var relay = CrashCountRelay()
        _ = relay.receive(crashes: CrashCountRelay.crashCount(inPayloadCrashCounts: [1, nil]))
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)

        for _ in 0..<relay.connect() { try store.incrementCrashCount() }

        XCTAssertEqual(try store.diagnosticsCounts(contentVersion: 1).crashCount, 1)
    }
}
