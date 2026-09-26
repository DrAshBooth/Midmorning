import XCTest
@testable import Constants

/// The one `ClockTime`, `QuietHours` and `DurationText` every package and the
/// App target read (mm-t24.37). Before, Plan, Programme, Record and the App
/// target each had a copy, and a fix to one copy did not reach the others.
final class ClockHelpersTests: XCTestCase {
    private let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    func testClockTimeTextAndParse() {
        XCTAssertEqual(ClockTime.string(hour: 7, minute: 5), "07:05")
        XCTAssertEqual(ClockTime.parse("22:30")?.hour, 22)
        XCTAssertEqual(ClockTime.parse("22:30")?.minute, 30)
        XCTAssertNil(ClockTime.parse("7"))
        XCTAssertEqual(ClockTime.minutesOfDay("04:00"), 240)
        XCTAssertEqual(ClockTime.minutesOfDay("bad"), 0)
    }

    /// A time picker's `Date` and the "HH:mm" setting value go both ways.
    func testClockTimePickerRoundTrip() {
        let date = ClockTime.date(from: "21:45", calendar: london)
        XCTAssertEqual(ClockTime.string(from: date, calendar: london), "21:45")
        XCTAssertEqual(ClockTime.minutesOfDay(of: date, calendar: london), 21 * 60 + 45)
    }

    /// A clock time before the day start falls on the next calendar date.
    func testClockTimeAfterMidnightInTheRecordDay() throws {
        let dayStart = try XCTUnwrap(london.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 4)))
        let late = try XCTUnwrap(ClockTime.date(atTime: "01:30", on: dayStart, calendar: london))
        XCTAssertEqual(london.component(.day, from: late), 6)
        XCTAssertEqual(ClockTime.minutesSinceDayStart("01:30", dayStartMinute: 240), 21 * 60 + 30)
    }

    /// reminders spec, "Quiet hours": the half-open range wraps past
    /// midnight, and it is off when the start equals the end.
    func testQuietHoursRange() {
        XCTAssertTrue(QuietHours.contains(time: "22:00", start: "22:00", end: "07:00"))
        XCTAssertTrue(QuietHours.contains(time: "06:59", start: "22:00", end: "07:00"))
        XCTAssertFalse(QuietHours.contains(time: "07:00", start: "22:00", end: "07:00"))
        XCTAssertFalse(QuietHours.contains(time: "07:00", start: "07:00", end: "07:00"))
    }

    /// The switch off means no time is in quiet hours, for every caller
    /// that holds a `QuietHours` value (the plan builder and Today's rows).
    func testQuietHoursSwitchOff() {
        XCTAssertTrue(QuietHours(isOn: true, start: "22:00", end: "07:00").contains("23:00"))
        XCTAssertFalse(QuietHours(isOn: false, start: "22:00", end: "07:00").contains("23:00"))
        XCTAssertFalse(QuietHours(isOn: true, start: "22:00", end: "22:00").contains("22:00"))
    }

    /// regular-eating-plan spec, "Place slots in the plan builder", and
    /// weekly-review spec, "The summary built from the record".
    func testDurationText() {
        XCTAssertEqual(DurationText.string(minutes: 150), "2 hours 30 minutes")
        XCTAssertEqual(DurationText.string(minutes: 180), "3 hours")
        XCTAssertEqual(DurationText.string(minutes: 61), "1 hour 1 minute")
        XCTAssertEqual(DurationText.string(minutes: 0), "0 minutes")
        XCTAssertEqual(DurationText.string(seconds: 6 * 3600 + 20 * 60 + 20), "6 hours 20 minutes")
    }
}
