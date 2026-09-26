import Foundation
@testable import Programme

/// A fixed UTC calendar for every engine test: the engine's own arithmetic
/// only ever adds whole days to a record-day key or finds a key's day-start
/// moment, so the zone choice does not change what a scenario proves.
let engineTestCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// Builds a fixed UTC moment from its calendar fields, for a scenario's own
/// "Monday 28 September 2026, 09:00" wording.
func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year; components.month = month; components.day = day
    components.hour = hour; components.minute = minute
    return engineTestCalendar.date(from: components)!
}

/// The record-day key ("2026-09-28") for the same fields. Built from the
/// normalised `moment(...)`, not a raw string, so a day number that
/// overflows its month (a test's own "day 0 plus 30" arithmetic) still
/// yields the correct, lexically-sortable key for the calendar day it rolls
/// into.
func dayKey(_ year: Int, _ month: Int, _ day: Int) -> String {
    DayKeyMath.key(from: moment(year, month, day), calendar: engineTestCalendar)
}

let defaultSettings = ProgrammeSettings(startDay: dayKey(2026, 9, 28), dayStart: 4)
