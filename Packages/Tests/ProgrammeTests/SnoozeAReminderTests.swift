import XCTest
import Constants
@testable import Programme

/// reminders spec, "Snooze a reminder" (mm-t24.4).
final class SnoozeAReminderTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: hour, minute: minute))!
    }

    private func userInfo(snoozeCount: Int, next: String? = "16:00", minutes: Int = 15) -> ReminderUserInfo {
        ReminderUserInfo(dayKey: "2026-09-24", slotIndex: 2, plannedTime: "13:00", nextPlannedTime: next, snoozeCount: snoozeCount, quietHoursStart: "22:00", quietHoursEnd: "07:00", snoozeMinutes: minutes)
    }

    /// Scenario: Remind me in 15 minutes.
    func testRemindMeIn15Minutes() {
        let outcome = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0), now: date(hour: 13, minute: 0), calendar: calendar)
        guard case .scheduleAt(let when) = outcome else { return XCTFail() }
        XCTAssertEqual(ClockTime.string(from: when, calendar: calendar), "13:15")
    }

    /// Scenario: The thirty-minute title (the 30-minute length applies the
    /// same way; the title text itself is `DiscreetText`'s job).
    func testTheThirtyMinuteLength() {
        let outcome = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0, minutes: 30), now: date(hour: 13, minute: 0), calendar: calendar)
        guard case .scheduleAt(let when) = outcome else { return XCTFail() }
        XCTAssertEqual(ClockTime.string(from: when, calendar: calendar), "13:30")
    }

    /// Scenario: A third snooze.
    func testAThirdSnooze() {
        let outcome = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 2), now: date(hour: 13, minute: 30), calendar: calendar)
        XCTAssertEqual(outcome, .drop)
    }

    /// Scenario: A snooze past the next planned meal.
    func testASnoozePastTheNextPlannedMeal() {
        let outcome = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0, next: "16:00"), now: date(hour: 15, minute: 50), calendar: calendar)
        XCTAssertEqual(outcome, .drop)
    }

    /// Scenario: A snooze into quiet hours.
    func testASnoozeIntoQuietHours() {
        let outcome = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0, next: nil), now: date(hour: 21, minute: 50), calendar: calendar)
        XCTAssertEqual(outcome, .drop)
    }

    /// Scenario: The pure function.
    func testThePureFunction() {
        let info = userInfo(snoozeCount: 1, next: "16:00")
        let outcome = SnoozeDecision.decide(userInfo: info, now: date(hour: 13, minute: 15), calendar: calendar)
        guard case .scheduleAt(let when) = outcome else { return XCTFail() }
        XCTAssertEqual(ClockTime.string(from: when, calendar: calendar), "13:30")

        let dropped = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 2, next: "16:00"), now: date(hour: 13, minute: 15), calendar: calendar)
        XCTAssertEqual(dropped, .drop)
    }

    /// Scenario: A snooze survives a restart — pure part: the decision
    /// itself does not depend on process lifetime, only on `userInfo` and
    /// `now`; the store-level half is `RecordTests.ActionQueueStoreTests`.
    func testDecisionHasNoHiddenProcessState() {
        let first = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0), now: date(hour: 13, minute: 0), calendar: calendar)
        let second = SnoozeDecision.decide(userInfo: userInfo(snoozeCount: 0), now: date(hour: 13, minute: 0), calendar: calendar)
        XCTAssertEqual(first, second)
    }
}
