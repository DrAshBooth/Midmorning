import Foundation
import XCTest
import Constants
@testable import Record

/// programme spec, "The constants live in one value": "Every capability
/// that uses the record day MUST read the day start from the setting, not
/// from the constant."
@MainActor
final class DayStartSettingTests: XCTestCase {
    /// Scenario: A capability reads the day start from the setting. "Day
    /// starts at" is 05:00 from 10 October. At 04:30 on 10 October the app
    /// computes the current record day the way the app target does (the
    /// store's `dayStartHour(effectiveOn:)`, then `RecordDay.key`), and a
    /// save at that moment keys to the same day.
    func testTheAppUsesTheSettingAndTheConstantStaysFour() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try RecordStore(directory: directory)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            utc.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
        }

        try store.setDayStartHour(5, now: at(9, 12), calendar: utc, changedAt: at(9, 12))

        let now = at(10, 4, 30)
        let dayStart = try store.dayStartHour(effectiveOn: RecordDay.key(containing: now, calendar: utc))
        XCTAssertEqual(dayStart, 5, "the app uses 05:00 as the day start")
        XCTAssertEqual(RecordDay.key(containing: now, calendar: utc, startHour: dayStart), "2026-10-09", "04:30 is still the record day of 9 October")
        let row = try store.add(time: now, what: "Toast", feltLikeABinge: false, createdAt: now, utcOffsetSeconds: 0, dayStartHour: dayStart)
        XCTAssertEqual(row.dayKey, "2026-10-09")
        XCTAssertEqual(ProgrammeConstants.default.defaultDayStartHour, 4, "DEFAULT_DAY_START_HOUR still holds 4")
        XCTAssertNotEqual(dayStart, ProgrammeConstants.default.defaultDayStartHour, "the constant does not stand in for the setting")
    }
}
