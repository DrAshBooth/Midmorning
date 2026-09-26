import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Today shows the plan beside the record"
/// (mm-t23.10).
final class TodayRowsTests: XCTestCase {
    /// Scenario: A matched planned meal.
    func testAMatchedPlannedMealShowsTheEntryBesideTheSlot() {
        let content = PlannedMealDisplay.content(matchedEntry: MatchedEntryText(time: "13:10", what: "Toast and tea"), isSkipped: false)
        XCTAssertEqual(content, .matched(MatchedEntryText(time: "13:10", what: "Toast and tea")))
    }

    /// Scenario: A planned meal still to come.
    func testAPlannedMealStillToComeShowsTheSlotAndTimeOnly() {
        let content = PlannedMealDisplay.content(matchedEntry: nil, isSkipped: false)
        XCTAssertEqual(content, .pending)
    }

    /// Scenario: A skipped planned meal.
    func testASkippedPlannedMealShowsSkipped() {
        let content = PlannedMealDisplay.content(matchedEntry: nil, isSkipped: true)
        XCTAssertEqual(content, .skipped)
    }

    /// Scenario: Skipped, then an entry matches.
    func testSkippedThenAnEntryMatchesShowsTheEntryNotSkipped() {
        let content = PlannedMealDisplay.content(matchedEntry: MatchedEntryText(time: "13:20", what: "Soup"), isSkipped: true)
        XCTAssertEqual(content, .matched(MatchedEntryText(time: "13:20", what: "Soup")), "the entry always wins over an earlier 'Skipped' answer")
    }

    /// record spec, "Today shows Where and Context", scenario "Entry with
    /// Where and Context", on a planned meal row (mm-t23.20). The row shows
    /// the matched entry's Where, Context and star, as an entry row does.
    func testAMatchedPlannedMealShowsTheEntrysWhereContextAndStar() {
        let entry = MatchedEntryText(time: "13:05", what: "Toast and tea", whereText: "Home", context: "Row with my sister", starred: true)
        guard case .matched(let shown) = PlannedMealDisplay.content(matchedEntry: entry, isSkipped: false) else {
            return XCTFail("a matched entry shows on the row")
        }
        XCTAssertEqual(shown.time, "13:05")
        XCTAssertEqual(shown.what, "Toast and tea")
        XCTAssertEqual(shown.whereText, "Home")
        XCTAssertEqual(shown.context, "Row with my sister")
        XCTAssertTrue(shown.starred)
    }

    /// Scenario: An entry outside every window. No planned meal claims it,
    /// so no slot index appears in the match map — the app target's existing
    /// entry-row rendering shows it as a plain entry, unchanged by this
    /// package.
    func testAnEntryOutsideEveryWindowMatchesNoSlot() {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 4))!
        let recordDay = DateInterval(start: day, end: calendar.date(byAdding: .day, value: 1, to: day)!)
        let lunch = PlannedMeal(slotIndex: 2, time: "13:00")
        let windows = PlanWindows.windows(for: [lunch], recordDay: recordDay, dayStartHour: 4, beforeMinutes: 60, afterMinutes: 90, calendar: calendar)
        let outsideEntry = PlanEntryFact(id: UUID(), time: calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 14, minute: 45))!)
        let matches = PlanMatching.match(windows: windows, entries: [outsideEntry])
        XCTAssertTrue(matches.isEmpty)
    }
}
