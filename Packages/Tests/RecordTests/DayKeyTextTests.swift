import Foundation
import XCTest
@testable import Record

/// record spec, "Earlier record days": "Each row in the list MUST show the
/// weekday and date only". product-rules spec, "Dates and times in
/// strings". A day key shows its own date and weekday in every zone; before
/// mm-t12b.11 the App target read a key at midnight GMT and showed it in the
/// device zone, so west of GMT every date was one day early.
final class DayKeyTextTests: XCTestCase {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private let zones = ["Europe/London", "America/New_York", "Pacific/Pago_Pago", "Pacific/Kiritimati", "Asia/Kathmandu"]

    func testKeyShowsItsOwnDateInEveryZone() {
        for zone in zones {
            XCTAssertEqual(DayKeyText.weekdayAndDate(forKey: "2026-09-24", calendar: calendar(zone)), "Thursday 24 September", zone)
            XCTAssertEqual(DayKeyText.weekdayAndDate(forKey: "2026-09-21", calendar: calendar(zone)), "Monday 21 September", zone)
        }
    }

    /// The plan builder reads the template kind from the weekday of the key.
    func testKeyWeekdayIsItsOwnInEveryZone() throws {
        for zone in zones {
            let cal = calendar(zone)
            let saturday = try XCTUnwrap(RecordDay.noon(ofKey: "2026-09-26", calendar: cal))
            XCTAssertEqual(cal.component(.weekday, from: saturday), 7, zone)
            XCTAssertEqual(cal.component(.day, from: saturday), 26, zone)
        }
    }

    /// The earlier day's interval comes from its own key, so the day moves
    /// by one record day in any zone.
    func testEarlierDayIntervalInNewYork() throws {
        let newYork = calendar("America/New_York")
        let interval = try XCTUnwrap(RecordDay.interval(forKey: "2026-09-24", calendar: newYork, schedule: .standard))
        XCTAssertEqual(DayKeyText.weekdayAndDate(interval.start, calendar: newYork), "Thursday 24 September")
        XCTAssertEqual(newYork.component(.hour, from: interval.start), 4)
        let next = RecordDay.next(interval, calendar: newYork, schedule: .standard)
        XCTAssertEqual(RecordDay.key(containing: next.start, calendar: newYork, schedule: .standard), "2026-09-25")
    }

    func testMalformedKeyShowsTheKey() {
        XCTAssertEqual(DayKeyText.weekdayAndDate(forKey: "later", calendar: calendar("Europe/London")), "later")
    }
}
