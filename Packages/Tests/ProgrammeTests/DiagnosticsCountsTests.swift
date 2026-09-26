import XCTest
@testable import Programme

/// settings spec, "The About group" — the two Diagnostics counts 2.4 owns
/// (mm-t24.20).
final class DiagnosticsCountsTests: XCTestCase {
    func testPendingReminderCount() {
        let requests = (0..<3).map { ReminderRequest(id: "r\($0)", kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: $0, time: Date(), title: "", body: "08:00", userInfo: [:], category: "plannedMeal") }
        XCTAssertEqual(ReminderDiagnostics.pendingReminderCount(requests), 3)
        XCTAssertEqual(ReminderDiagnostics.pendingReminderCount([]), 0)
    }

    func testQueueLength() {
        XCTAssertEqual(ReminderDiagnostics.queueLength(4), 4)
        XCTAssertEqual(ReminderDiagnostics.queueLength(0), 0)
    }
}
