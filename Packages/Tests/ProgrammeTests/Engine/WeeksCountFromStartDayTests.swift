import XCTest
@testable import Programme

/// Covers programme spec.md, "Weeks count from the start day" (mm-t21.3).
final class WeeksCountFromStartDayTests: XCTestCase {
    private let startDay = dayKey(2026, 9, 28) // Monday

    /// Scenario: Last day of week 1.
    func testLastDayOfWeek1() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2026, 10, 4), calendar: engineTestCalendar), 1)
    }

    /// Scenario: After midnight at the end of week 1. The caller has already
    /// resolved "23:00 Sunday 4 October" wall-clock 01:00 Monday 5 October
    /// to the record day Sunday 4 October; the engine only counts weeks from
    /// the record day it is given.
    func testAfterMidnightAtTheEndOfWeek1() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2026, 10, 4), calendar: engineTestCalendar), 1)
    }

    /// Scenario: First day of week 2.
    func testFirstDayOfWeek2() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2026, 10, 5), calendar: engineTestCalendar), 2)
    }

    /// Scenario: Week 13.
    func testWeek13() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2026, 12, 21), calendar: engineTestCalendar), 13)
    }

    /// Scenario: A later day start. The caller resolves "05:30 with a 06:00
    /// day start" to the record day Sunday 4 October before calling `week`.
    func testALaterDayStart() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2026, 10, 4), calendar: engineTestCalendar), 1)
    }

    /// Scenario: Start day is tomorrow.
    func testStartDayIsTomorrow() {
        let tomorrow = dayKey(2026, 9, 29)
        XCTAssertNil(Programme.week(startDay: tomorrow, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar), "today is before week 1")
    }

    /// The engine keeps counting weeks past week 12 (requirement text, not
    /// its own numbered scenario).
    func testKeepsCountingPastWeek12() {
        XCTAssertEqual(Programme.week(startDay: startDay, currentRecordDay: dayKey(2027, 6, 28), calendar: engineTestCalendar), 40)
    }
}
