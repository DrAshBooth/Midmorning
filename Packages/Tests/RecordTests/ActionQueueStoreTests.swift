import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// widgets-and-intents spec, "The action queue" (mm-t25.9); reminders spec,
/// "Snooze a reminder" (mm-t24.4, "A snooze survives a restart"); reminders
/// spec, "Close the day" (mm-t24.8, the feeling-word row).
@MainActor
final class ActionQueueStoreTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int = 0, day: Int = 6) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: The codec

    /// Scenario: Queue content.
    func testQueueContent() {
        let action = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40))
        let data = ActionQueueCodec.appending(action, to: Data())
        let decoded = ActionQueueCodec.decode(data)
        XCTAssertEqual(decoded, [action])
        // No slot name and no other text: the JSON never carries a label.
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.lowercased().contains("lunch"))
    }

    /// Scenario: Two actions in order.
    func testTwoActionsInOrder() {
        let lunch = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40))
        let midAfternoon = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 3, plannedTime: "16:00", snoozeCount: 0, moment: at(16, 30))
        var data = ActionQueueCodec.appending(lunch, to: Data())
        data = ActionQueueCodec.appending(midAfternoon, to: data)
        XCTAssertEqual(ActionQueueCodec.decode(data), [lunch, midAfternoon])
    }

    /// The app discards a queue file whose format version it does not know.
    func testUnknownFormatVersionDiscards() {
        let unknown = "{\"formatVersion\":99,\"actions\":[]}".data(using: .utf8)!
        XCTAssertEqual(ActionQueueCodec.decode(unknown), [])
    }

    // MARK: The applier (widgets-and-intents spec: "Each time protected data
    // becomes available, the app MUST apply the queue through the store in
    // order... The app MUST drop an action whose date key is earlier than
    // the current record day.")

    /// Scenario: Skipped while the app is closed.
    func testSkippedWhileTheAppIsClosed() throws {
        let store = try makeTemporaryStore()
        let action = QueuedAction(kind: .skipped, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40))
        try store.applyQueuedActions([action], currentRecordDayKey: "2026-10-06")
        XCTAssertEqual(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2), "Skipped")
    }

    /// Scenario: Action from an earlier day.
    func testActionFromAnEarlierDay() throws {
        let store = try makeTemporaryStore()
        let action = QueuedAction(kind: .skipped, dayKey: "2026-10-05", slotIndex: 2, plannedTime: "13:00", snoozeCount: 0, moment: at(13, 40, day: 5))
        let kept = try store.applyQueuedActions([action], currentRecordDayKey: "2026-10-07")
        XCTAssertTrue(kept.isEmpty)
        XCTAssertNil(try store.plannedMealAnswer(dateKey: "2026-10-05", slotIndex: 2))
    }

    /// Scenario: Snooze count applied.
    func testSnoozeCountApplied() throws {
        let store = try makeTemporaryStore()
        let action = QueuedAction(kind: .snooze, dayKey: "2026-10-06", slotIndex: 2, plannedTime: "13:00", snoozeCount: 2, moment: at(13, 30))
        try store.applyQueuedActions([action], currentRecordDayKey: "2026-10-06")
        XCTAssertEqual(try store.snoozeCount(dateKey: "2026-10-06", slotIndex: 2), 2)
        XCTAssertNil(try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2), "Record.store holds no snooze count")
    }

    /// Scenario: A snooze survives a restart.
    func testASnoozeSurvivesARestart() throws {
        let directory = try makeTemporaryDirectory()
        do {
            let store = try RecordStore(directory: directory)
            try store.setSnoozeCount(1, dateKey: "2026-10-06", slotIndex: 2)
        }
        let restarted = try RecordStore(directory: directory)
        XCTAssertEqual(try restarted.snoozeCount(dateKey: "2026-10-06", slotIndex: 2), 1)
    }

    // MARK: Close the day's feeling word (mm-t24.8)

    /// Scenario: One word.
    func testOneWord() throws {
        let store = try makeTemporaryStore()
        try store.setFeelingWord("tired", dateKey: "2026-10-06", changedAt: at(21, 50))
        XCTAssertEqual(try store.feelingWord(dateKey: "2026-10-06"), "tired")
    }

    /// Scenario: A day with no entries — no feeling word saved yet reads as
    /// `nil`, distinct from a saved empty word.
    func testNoFeelingWordYet() throws {
        let store = try makeTemporaryStore()
        XCTAssertNil(try store.feelingWord(dateKey: "2026-10-06"))
    }
}
