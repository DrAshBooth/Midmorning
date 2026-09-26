import XCTest
@testable import Programme
import Constants

/// reminders spec, "Quiet hours" (mm-t24.15).
final class QuietHoursTests: XCTestCase {
    /// Scenario: A planned meal inside quiet hours.
    func testAPlannedMealInsideQuietHours() {
        let candidate = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 5, time: "22:30")
        let result = Scheduler.pipeline([candidate], switches: [:], remindersPausedAt: nil, quietHoursOn: true, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertTrue(result.isEmpty)
    }

    /// Scenario: The edges of the range.
    func testTheEdgesOfTheRange() {
        XCTAssertTrue(QuietHours.contains(time: "22:00", start: "22:00", end: "07:00"))
        XCTAssertTrue(QuietHours.contains(time: "23:30", start: "22:00", end: "07:00"))
        XCTAssertTrue(QuietHours.contains(time: "06:59", start: "22:00", end: "07:00"))
        XCTAssertFalse(QuietHours.contains(time: "07:00", start: "22:00", end: "07:00"))
        XCTAssertFalse(QuietHours.contains(time: "21:59", start: "22:00", end: "07:00"))
    }

    /// Scenario: A reminder outside quiet hours.
    func testAReminderOutsideQuietHours() {
        let candidate = ReminderCandidate(kind: .morningPlan, dayKey: "2026-09-24", time: "07:30")
        let result = Scheduler.pipeline([candidate], switches: [:], remindersPausedAt: nil, quietHoursOn: true, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.first?.time, "07:30")
    }

    /// Scenario: A close-the-day time inside quiet hours.
    func testACloseTheDayTimeInsideQuietHours() {
        XCTAssertTrue(QuietHours.contains(time: "21:45", start: "21:00", end: "06:00"))
        let candidate = ReminderCandidate(kind: .closeTheDay, dayKey: "2026-09-24", time: "21:45")
        let result = Scheduler.pipeline([candidate], switches: [:], remindersPausedAt: nil, quietHoursOn: true, quietHoursStart: "21:00", quietHoursEnd: "06:00")
        XCTAssertTrue(result.isEmpty)
    }

    /// Scenario: Quiet hours off.
    func testQuietHoursOff() {
        XCTAssertFalse(QuietHours.isOn(start: "07:00", end: "07:00"))
        let candidate = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 5, time: "22:30")
        let result = Scheduler.pipeline([candidate], switches: [:], remindersPausedAt: nil, quietHoursOn: true, quietHoursStart: "07:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.first?.time, "22:30")
    }
}
