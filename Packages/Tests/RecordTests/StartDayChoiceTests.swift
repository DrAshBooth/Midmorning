import XCTest
@testable import Record

/// Onboarding spec, "Screen 3: the start day" (mm-t14.6) and "Screen 3: the
/// record in three sentences" (mm-t14.8).
final class StartDayChoiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.hour = hour; components.minute = minute
        return calendar.date(from: components)!
    }

    func testDefault() {
        let now = date(2026, 9, 24, 14, 0) // Thursday 24 September, 14:00
        XCTAssertEqual(StartDayChoice.label(for: .today, now: now, calendar: calendar, schedule: .standard), "Today, Thursday 24 September")
        XCTAssertEqual(StartDayChoice.label(for: .tomorrow, now: now, calendar: calendar, schedule: .standard), "Tomorrow, Friday 25 September")
    }

    func testTomorrowKeepsFridayAsTheStartDay() {
        let now = date(2026, 9, 24, 14, 0)
        XCTAssertEqual(StartDayChoice.dayKey(for: .tomorrow, now: now, calendar: calendar, schedule: .standard), "2026-09-25")
    }

    func testAfterMidnight() {
        let now = date(2026, 9, 25, 1, 0) // Friday 01:00, default day start 04:00
        XCTAssertEqual(StartDayChoice.label(for: .today, now: now, calendar: calendar, schedule: .standard), "Today, Thursday 24 September")
        XCTAssertEqual(StartDayChoice.label(for: .tomorrow, now: now, calendar: calendar, schedule: .standard), "Tomorrow, Friday 25 September")
    }

    func testDayBoundaryLineWithDefaultDayStart() {
        XCTAssertEqual(DayBoundaryLine.text(startHour: 4), "A day runs from 04:00 to 03:59.")
    }

    func testDayBoundaryLineFollowsTheSetting() {
        XCTAssertEqual(DayBoundaryLine.text(startHour: 5), "A day runs from 05:00 to 04:59.")
    }
}
