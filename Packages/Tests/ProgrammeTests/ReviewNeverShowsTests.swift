import XCTest
@testable import Programme

/// weekly-review spec, "What the review never shows" (mm-t32.14). The
/// summary builder emits only the fixed templates `ReviewSummary` defines;
/// these tests prove the banned content (a score, a comparison word, praise,
/// a streak or badge, a skipped count) never appears alongside a number.
final class ReviewNeverShowsTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let startDay = dayKey(2026, 9, 28)

    private func weekDays(_ week: Int) -> [String] {
        ReviewDue.weekDayKeys(week: week, startDay: startDay, calendar: calendar)
    }

    private let bannedWords = ["good", "bad", "great", "well done", "score", "grade", "streak", "badge", "thank", "congrat"]

    private func assertNoBannedWords(_ parts: [String], file: StaticString = #filePath, line: UInt = #line) {
        let joined = parts.joined(separator: " ").lowercased()
        for word in bannedWords {
            XCTAssertFalse(joined.contains(word), "found banned word \"\(word)\" in \(parts)", file: file, line: line)
        }
    }

    /// Scenario: Fewer starred entries.
    func testFewerStarredEntries() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(4), previousWeekFrozenStarred: 6)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertTrue(parts.contains("Starred entries: 0 this week, 6 last week."))
        assertNoBannedWords(parts)
    }

    /// Scenario: More starred entries.
    func testMoreStarredEntries() {
        let days = weekDays(4)
        let entries = (0..<8).map { ReviewEntryFact(dayKey: days[$0 % 7], time: moment(2026, 10, 19 + $0 % 7, 9 + $0), starred: true) }
        let facts = ReviewWeekFacts(weekDayKeys: days, entries: entries, previousWeekFrozenStarred: 3)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertTrue(parts.contains("Starred entries: 8 this week, 3 last week."))
        assertNoBannedWords(parts)
    }

    /// Scenario: Every planned meal with an entry.
    func testEveryPlannedMealWithAnEntry() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(4), plannedMealsWithEntryCount: 30)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertTrue(parts.contains("Planned meals with an entry beside them: 30."))
        assertNoBannedWords(parts)
    }

    /// Scenario: No planned meal with an entry.
    func testNoPlannedMealWithAnEntry() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(4), plannedMealsWithEntryCount: 0)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertTrue(parts.contains("Planned meals with an entry beside them: 0."))
        XCTAssertFalse(parts.joined().contains("25"), "no skipped count and no total")
        assertNoBannedWords(parts)
    }

    /// The summary never emits a percentage, an arrow or a colour word.
    func testNoScoreRatingOrPercentage() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(4), plannedMealsWithEntryCount: 12, previousWeekFrozenStarred: 4)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertFalse(parts.joined().contains("%"))
    }
}
