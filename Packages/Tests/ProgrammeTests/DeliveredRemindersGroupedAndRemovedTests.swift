import XCTest
@testable import Programme

/// reminders spec, "Delivered reminders are grouped and removed" (mm-t24.6).
final class DeliveredRemindersGroupedAndRemovedTests: XCTestCase {
    /// Scenario: One thread — every request this capability builds shares
    /// the one thread identifier.
    func testOneThread() {
        let breakfast = ReminderRequest(id: "a", kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 0, time: Date(), title: "", body: "08:00", userInfo: [:], category: "plannedMeal")
        let lunch = ReminderRequest(id: "b", kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 2, time: Date(), title: "", body: "13:00", userInfo: [:], category: "plannedMeal")
        XCTAssertEqual(breakfast.threadIdentifier, lunch.threadIdentifier)
    }

    /// Scenario: The window ends.
    func testTheWindowEnds() {
        let lunch = DeliveredReminder(id: "lunch", kind: .plannedMeal, dayKey: "2026-09-24", windowEndTime: "14:30")
        let ids = DeliveredReminderRemoval.idsToRemove(delivered: [lunch], currentRecordDayKey: "2026-09-24", nowClockTime: "14:30")
        XCTAssertEqual(ids, ["lunch"])
        XCTAssertTrue(DeliveredReminderRemoval.idsToRemove(delivered: [lunch], currentRecordDayKey: "2026-09-24", nowClockTime: "14:00").isEmpty)
    }

    /// Scenario: The end of the record day.
    func testTheEndOfTheRecordDay() {
        let closeTheDay = DeliveredReminder(id: "close", kind: .closeTheDay, dayKey: "2026-09-24")
        let ids = DeliveredReminderRemoval.idsToRemove(delivered: [closeTheDay], currentRecordDayKey: "2026-09-25", nowClockTime: "04:00")
        XCTAssertEqual(ids, ["close"])
    }

    /// Scenario: A later day start.
    func testALaterDayStart() {
        let closeTheDay = DeliveredReminder(id: "close", kind: .closeTheDay, dayKey: "2026-09-24")
        // Still 24 September's own record day at 04:30 with a 05:00 day
        // start: not removed yet.
        XCTAssertTrue(DeliveredReminderRemoval.idsToRemove(delivered: [closeTheDay], currentRecordDayKey: "2026-09-24", nowClockTime: "04:30").isEmpty)
        XCTAssertEqual(DeliveredReminderRemoval.idsToRemove(delivered: [closeTheDay], currentRecordDayKey: "2026-09-25", nowClockTime: "05:00"), ["close"])
    }

    /// Scenario: Launch — every delivered reminder is read, then removed;
    /// the read-then-clear order is the App layer's own sequencing
    /// (`NotificationScheduling`), not a pure-function fact.
    func testLaunchRemovesEveryDeliveredReminder() {
        let reminders = (0..<3).map { DeliveredReminder(id: "r\($0)", kind: .plannedMeal, dayKey: "2026-09-23") }
        let ids = DeliveredReminderRemoval.idsToRemove(delivered: reminders, currentRecordDayKey: "2026-09-24", nowClockTime: "09:00")
        XCTAssertEqual(ids.count, 3)
    }
}
