import XCTest
@testable import Programme

/// The engine's day-start moment on the two clock-change dates in
/// Europe/London (code review of 26 September 2026, mm-t21.33; programme
/// spec, "A pure stage engine with stored openings as input": "For a week or
/// day gate, that moment MUST be the day start that ended the gate."). The
/// record day starts at the wall-clock day start on every date, as `Record`'s
/// `RecordDay` computes it.
final class ClockChangeDayStartTests: XCTestCase {
    private let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func wallClock(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> DateComponents {
        DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    }

    /// The clocks go back on Sunday 25 October 2026: the day start is 04:00
    /// GMT, not 03:00.
    func testTheDayStartWhenTheClocksGoBack() {
        let start = DayKeyMath.dayStartMoment(for: "2026-10-25", dayStart: 4, calendar: london)
        XCTAssertEqual(london.dateComponents([.hour, .minute], from: start), DateComponents(hour: 4, minute: 0))
        let at0330 = london.date(from: wallClock(2026, 10, 25, 3, 30))!
        XCTAssertEqual(DayKeyMath.recordDayKey(containing: at0330, dayStart: 4, calendar: london), "2026-10-24", "03:30 is still the previous record day")
    }

    /// The clocks go forward on Sunday 28 March 2027: the day start is 04:00
    /// BST, not 05:00.
    func testTheDayStartWhenTheClocksGoForward() {
        let start = DayKeyMath.dayStartMoment(for: "2027-03-28", dayStart: 4, calendar: london)
        XCTAssertEqual(london.dateComponents([.hour, .minute], from: start), DateComponents(hour: 4, minute: 0))
        let at0430 = london.date(from: wallClock(2027, 3, 28, 4, 30))!
        XCTAssertEqual(DayKeyMath.recordDayKey(containing: at0430, dayStart: 4, calendar: london), "2027-03-28", "04:30 is in the new record day")
    }

    /// A week gate that ends on a clock-change date opens at 04:00 wall
    /// clock: stage 2 opened on Sunday 20 September 2026, so week 6 of
    /// regular eating starts on Sunday 25 October.
    func testAWeekGateOnAClockChangeDate() {
        let settings = ProgrammeSettings(startDay: "2026-09-14", dayStart: 4)
        let stage2 = StageOpenedRecord(stage: 2, moment: london.date(from: wallClock(2026, 9, 20, 13))!)
        let now = london.date(from: wallClock(2026, 10, 25, 9))!
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [stage2], settings: settings, constants: .default, now: now, restartAt: nil, currentRecordDay: "2026-10-25", calendar: london)
        let opened = s.stageOpenedMoment[.takingStock]
        XCTAssertNotNil(opened)
        XCTAssertEqual(opened.map { london.dateComponents([.year, .month, .day, .hour], from: $0) }, DateComponents(year: 2026, month: 10, day: 25, hour: 4))
    }

    /// The weekly review due moment on a clock-change date is the day start
    /// by the wall clock too (`ReviewDue.dueMoment` uses the same function).
    func testAReviewDueOnAClockChangeDate() {
        let due = ReviewDue.dueMoment(week: 1, startDay: "2027-03-21", dayStart: 4, calendar: london)
        XCTAssertEqual(london.dateComponents([.year, .month, .day, .hour], from: due), DateComponents(year: 2027, month: 3, day: 28, hour: 4))
    }
}
