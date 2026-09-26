import Foundation
import XCTest
@testable import Record

/// settings spec, "The Record group": "Day starts at" is a time from 00:00 to
/// 12:00, and a change applies from the next day start. data-and-privacy
/// spec, "Slot labels and the day start are Settings rows". The Settings
/// row reads `dayStartHourFromNextRecordDay` and writes only from its own
/// setter (mm-t13.13).
@MainActor
final class DayStartSettingRowTests: XCTestCase {
    private let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int) -> Date {
        london.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DayStartSettingRowTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    func testRowOffersWholeHoursFromMidnightToNoon() {
        XCTAssertEqual(Array(RecordDay.startHourChoices), Array(0...12))
    }

    /// Before any change the row shows 04:00.
    func testRowShowsTheDefault() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.dayStartHourFromNextRecordDay(after: at(24, 13), calendar: london), 4)
    }

    /// After a change the row shows the new hour at once, although today
    /// keeps the old one; before the fix it showed today's hour, which
    /// invited the person to set it again.
    func testRowShowsTheNewHourRightAfterAChange() throws {
        let store = try makeStore()
        try store.setDayStartHour(6, now: at(24, 13), calendar: london)
        XCTAssertEqual(try store.dayStartHourFromNextRecordDay(after: at(24, 13), calendar: london), 6)
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-24"), 4, "today keeps the old hour")
    }

    /// The row keeps showing the hour on the next day, when it is in force.
    func testRowShowsTheHourInForceNextDay() throws {
        let store = try makeStore()
        try store.setDayStartHour(6, now: at(24, 13), calendar: london)
        XCTAssertEqual(try store.dayStartHourFromNextRecordDay(after: at(25, 13), calendar: london), 6)
    }

    /// An hour outside 00:00 to 12:00 is stored as the nearest end.
    func testStoreKeepsTheHourInsideTheRange() throws {
        let store = try makeStore()
        try store.setDayStartHour(23, now: at(24, 13), calendar: london)
        XCTAssertEqual(try store.dayStartHour(effectiveOn: "2026-09-25"), 12)
    }

    /// Reading the row writes nothing.
    func testReadingTheRowWritesNoRow() throws {
        let store = try makeStore()
        _ = try store.dayStartHourFromNextRecordDay(after: at(24, 13), calendar: london)
        XCTAssertEqual(try store.dayStartSchedule(), .standard)
    }
}
