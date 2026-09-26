import Foundation
import XCTest
@testable import Plan
import Constants

/// The planned meal rows on Today, through `PlanTodayRows.compute`, the one
/// function the app target calls (regular-eating-plan spec, "The
/// next-planned-meal line"; "A missed planned meal gets one prompt").
/// mm-t23.19 and mm-t23.22.
final class PlanTodayRowsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ hour: Int, _ minute: Int = 0, day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private var recordDay: DateInterval { DateInterval(start: at(4), end: at(4, day: 25)) }

    // Breakfast 08:00, Lunch 13:00, Mid-afternoon 16:00, Evening meal 19:00.
    private let plan = [
        PlannedMeal(slotIndex: 0, time: "08:00"),
        PlannedMeal(slotIndex: 2, time: "13:00"),
        PlannedMeal(slotIndex: 3, time: "16:00"),
        PlannedMeal(slotIndex: 4, time: "19:00"),
    ]

    private func rows(entries: [PlanDayEntry] = [], answers: [Int: String] = [:], now: Date, meals: [PlannedMeal]? = nil) -> PlanTodayRows {
        let match = PlanDayMatch(
            meals: meals ?? plan, recordDay: recordDay, dayStartHour: 4, beforeMinutes: 60, afterMinutes: 90,
            entries: entries.map(\.fact), calendar: calendar
        )
        return PlanTodayRows.compute(
            match: match, entries: entries, answers: answers,
            quietHours: QuietHours(isOn: true, start: "22:00", end: "07:00"),
            recordDay: recordDay, now: now, calendar: calendar
        )
    }

    private func slotsWithLine(_ result: PlanTodayRows) -> [Int] {
        result.rows.filter(\.showsNextLine).map(\.slotIndex)
    }

    // MARK: mm-t23.19, "The next-planned-meal line"

    /// A starred entry at 12:30 matches Lunch at 13:00, before Lunch's own
    /// time. The next planned meal after the entry MUST NOT be Lunch, so
    /// the line shows on Mid-afternoon.
    func testAStarredEntryBeforeItsPlannedMealsTimeShowsTheLineOnTheNextPlannedMeal() {
        let starred = PlanDayEntry(id: UUID(), time: at(12, 30), starred: true)
        let result = rows(entries: [starred], now: at(12, 31))
        XCTAssertEqual(result.rows.first { $0.slotIndex == 2 }?.matchedEntryId, starred.id, "the entry matches Lunch")
        XCTAssertEqual(slotsWithLine(result), [3], "Mid-afternoon at 16:00 still happens.")
        XCTAssertFalse(result.showsTrailingNextLine)
    }

    /// Scenario: A starred entry that matches a planned meal.
    func testAStarredEntryThatMatchesAPlannedMeal() {
        let starred = PlanDayEntry(id: UUID(), time: at(13, 10), starred: true)
        let result = rows(entries: [starred], now: at(13, 11))
        XCTAssertEqual(slotsWithLine(result), [3], "the line is on Mid-afternoon, and nothing is on the Lunch row")
    }

    /// Scenario: A starred entry between planned meals.
    func testAStarredEntryBetweenPlannedMeals() {
        let starred = PlanDayEntry(id: UUID(), time: at(14, 45), starred: true)
        let result = rows(entries: [starred], now: at(14, 46))
        XCTAssertEqual(slotsWithLine(result), [3])
    }

    /// Scenario: Skip lunch.
    func testSkipLunch() {
        let result = rows(answers: [2: "Skipped"], now: at(13, 0))
        XCTAssertEqual(slotsWithLine(result), [3])
    }

    /// Scenario: Skip the last planned meal of the day.
    func testSkipTheLastPlannedMealOfTheDayShowsTheTrailingLine() {
        let result = rows(answers: [4: "Skipped"], now: at(19, 5))
        XCTAssertEqual(slotsWithLine(result), [])
        XCTAssertTrue(result.showsTrailingNextLine, "the line points to the next record day's first planned meal")
    }

    /// The trailing line belongs to the current day section only. Once the
    /// record day ends, the day shows no line.
    func testTheTrailingLineHidesOnceTheRecordDayEnds() {
        let result = rows(answers: [4: "Skipped"], now: at(5, 0, day: 25))
        XCTAssertFalse(result.showsTrailingNextLine)
    }

    /// Scenario: The next planned meal arrives.
    func testTheNextPlannedMealArrivesHidesTheLine() {
        let entry = PlanDayEntry(id: UUID(), time: at(16, 5), starred: false)
        let result = rows(entries: [entry], answers: [2: "Skipped"], now: at(16, 6))
        XCTAssertEqual(slotsWithLine(result), [], "the entry matches Mid-afternoon and Today hides the line")
    }

    /// Scenario: The window ends.
    func testTheWindowEndsHidesTheLineAndThePromptApplies() {
        let result = rows(answers: [2: "Skipped"], now: at(17, 30))
        XCTAssertEqual(slotsWithLine(result), [])
        XCTAssertEqual(result.rows.first { $0.slotIndex == 3 }?.prompt, .skippedOrNotRecorded)
    }

    // MARK: mm-t23.22, "A missed planned meal gets one prompt"

    /// Scenario: The window ends with no entry.
    func testTheWindowEndsWithNoEntryShowsSkippedAndAddIt() {
        let result = rows(now: at(14, 30), meals: [PlannedMeal(slotIndex: 2, time: "13:00")])
        XCTAssertEqual(result.rows.first?.prompt, .skippedOrNotRecorded)
    }

    /// The first cut does not build "That was it" (mm-t33.14). With an
    /// unmatched entry after the window, the prompt keeps the "Skipped" and
    /// "Add it" form, so Today shows no control that does nothing.
    func testAnUnmatchedEntryAfterTheWindowKeepsSkippedAndAddIt() {
        let entry = PlanDayEntry(id: UUID(), time: at(14, 45), starred: false)
        let result = rows(entries: [entry], now: at(15, 0))
        XCTAssertEqual(result.rows.first { $0.slotIndex == 2 }?.prompt, .skippedOrNotRecorded)
        XCTAssertEqual(result.rows.filter { $0.prompt != nil }.count, 1, "at most one prompt")
    }

    /// Scenario: A later entry.
    func testALaterEntrySuppressesTheEarlierPrompt() {
        let entry = PlanDayEntry(id: UUID(), time: at(16, 5), starred: false)
        let result = rows(entries: [entry], now: at(20, 0), meals: [PlannedMeal(slotIndex: 2, time: "13:00"), PlannedMeal(slotIndex: 3, time: "16:00")])
        XCTAssertNil(result.rows.first { $0.slotIndex == 2 }?.prompt)
    }
}
