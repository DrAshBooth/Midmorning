import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "The window of a planned meal" (mm-t23.9).
final class PlanWindowTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func recordDay(startHour: Int = 4, day: Int = 24) -> DateInterval {
        let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: startHour))!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func windows(_ meals: [PlannedMeal], startHour: Int = 4, before: Int = 60, after: Int = 90) -> [PlannedMealWindow] {
        PlanWindows.windows(for: meals, recordDay: recordDay(startHour: startHour), dayStartHour: startHour, beforeMinutes: before, afterMinutes: after, calendar: calendar)
    }

    /// Scenario: An entry inside the window.
    func testAnEntryInsideTheWindowMatches() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00")])
        let matches = PlanMatching.match(windows: w, entries: [PlanEntryFact(id: UUID(), time: at(13, 10))])
        XCTAssertEqual(matches[2] != nil, true)
    }

    /// Scenario: Two entries inside the window.
    func testTwoEntriesInsideTheWindowTheEarliestMatches() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00")])
        let early = PlanEntryFact(id: UUID(), time: at(12, 30))
        let late = PlanEntryFact(id: UUID(), time: at(13, 40))
        let matches = PlanMatching.match(windows: w, entries: [late, early])
        XCTAssertEqual(matches[2], early.id, "the 12:30 entry matches; 13:40 matches nothing")
        XCTAssertEqual(matches.count, 1)
    }

    /// Scenario: Overlapping windows.
    func testOverlappingWindows() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00"), PlannedMeal(slotIndex: 3, time: "14:30")])
        XCTAssertEqual(w[0].interval, DateInterval(start: at(12, 0), end: at(13, 45)))
        XCTAssertEqual(w[1].interval, DateInterval(start: at(13, 45), end: at(16, 0)))
    }

    /// Scenario: Three planned meals 30 minutes apart.
    func testThreePlannedMealsThirtyMinutesApart() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00"), PlannedMeal(slotIndex: 3, time: "13:30"), PlannedMeal(slotIndex: 4, time: "14:00")])
        XCTAssertEqual(w[0].interval, DateInterval(start: at(12, 0), end: at(13, 15)))
        XCTAssertEqual(w[1].interval, DateInterval(start: at(13, 15), end: at(13, 45)))
        XCTAssertEqual(w[2].interval, DateInterval(start: at(13, 45), end: at(15, 30)))
    }

    /// Scenario: A window clipped to the record day.
    func testAWindowClippedToTheRecordDay() {
        let w = windows([PlannedMeal(slotIndex: 0, time: "04:30"), PlannedMeal(slotIndex: 5, time: "03:00")], startHour: 4)
        let breakfast = w.first { $0.slotIndex == 0 }!
        let eveningSnack = w.first { $0.slotIndex == 5 }!
        XCTAssertEqual(breakfast.interval, DateInterval(start: at(4, 0), end: at(6, 0)), "clipped to the record day's own start")
        XCTAssertEqual(eveningSnack.interval, DateInterval(start: at(2, 0, day: 25), end: at(4, 0, day: 25)), "clipped to the record day's own end")
    }

    /// Scenario: A window clipped to a later day start.
    func testAWindowClippedToALaterDayStart() {
        let w = windows([PlannedMeal(slotIndex: 0, time: "05:30")], startHour: 5)
        XCTAssertEqual(w[0].interval, DateInterval(start: at(5, 0), end: at(7, 0)))
    }

    /// Scenario: An entry at the window's end.
    func testAnEntryAtTheWindowsEndMatchesNothing() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00")])
        let matches = PlanMatching.match(windows: w, entries: [PlanEntryFact(id: UUID(), time: at(14, 30))])
        XCTAssertNil(matches[2], "14:30 is the window's exclusive end")
    }

    /// Scenario: A matched entry deleted.
    func testAMatchedEntryDeletedLeavesTheMealMissed() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00")])
        let matchesBefore = PlanMatching.match(windows: w, entries: [PlanEntryFact(id: UUID(), time: at(13, 10))])
        XCTAssertNotNil(matchesBefore[2])
        let matchesAfterDelete = PlanMatching.match(windows: w, entries: [])
        XCTAssertNil(matchesAfterDelete[2], "no matched entry: Lunch is missed once its window has ended")
    }

    /// Scenario: An entry after "Skipped". The window match still finds the
    /// entry; the Answer row's "Skipped" value is untouched by this package
    /// (data-and-privacy spec: "readers MUST show the entry").
    func testAnEntryAfterSkippedStillMatches() {
        let w = windows([PlannedMeal(slotIndex: 2, time: "13:00")])
        let matches = PlanMatching.match(windows: w, entries: [PlanEntryFact(id: UUID(), time: at(13, 20))])
        XCTAssertNotNil(matches[2], "the entry matches Lunch regardless of the earlier 'Skipped' answer")
    }

    // MARK: mm-t23.16, a record day that disagrees with the day start

    /// A record day built at 04:00 with a day start of 07:00 puts a 06:00
    /// planned meal on the next calendar date, after the record day's end.
    /// The windows function must not trap. The window clips to an empty
    /// interval at the record day's end and matches no entry.
    func testAPlannedMealOutsideTheRecordDayGetsAnEmptyWindow() {
        let breakfast = PlannedMeal(slotIndex: 0, time: "06:00")
        let lunch = PlannedMeal(slotIndex: 2, time: "13:00")
        let w = PlanWindows.windows(for: [breakfast, lunch], recordDay: recordDay(startHour: 4), dayStartHour: 7, beforeMinutes: 60, afterMinutes: 90, calendar: calendar)
        XCTAssertEqual(w.count, 2)
        let breakfastWindow = w.first { $0.slotIndex == 0 }!
        XCTAssertEqual(breakfastWindow.interval.duration, 0, "the window is empty")
        XCTAssertEqual(breakfastWindow.interval.start, recordDay(startHour: 4).end)
        let lunchWindow = w.first { $0.slotIndex == 2 }!
        XCTAssertEqual(lunchWindow.interval, DateInterval(start: at(12, 0), end: at(14, 30)), "a window inside the record day is unchanged")
        let entry = PlanEntryFact(id: UUID(), time: at(3, 59, day: 25))
        XCTAssertNil(PlanMatching.match(windows: w, entries: [entry])[0], "an empty window matches no entry")
    }

    /// The same disagreement in the other direction: a record day built at
    /// 07:00 with a day start of 04:00 and a planned meal at 05:00 puts the
    /// meal before the record day's start. The window clips to an empty
    /// interval at the record day's start.
    func testAPlannedMealBeforeTheRecordDayGetsAnEmptyWindow() {
        let early = PlannedMeal(slotIndex: 0, time: "05:00")
        let w = PlanWindows.windows(for: [early], recordDay: recordDay(startHour: 7), dayStartHour: 4, beforeMinutes: 60, afterMinutes: 90, calendar: calendar)
        XCTAssertEqual(w.first?.interval, DateInterval(start: recordDay(startHour: 7).start, duration: 0))
    }
}
