import XCTest
@testable import Programme

/// weekly-review spec, "The summary built from the record" (mm-t32.5). The
/// check-in variant ("A check-in", "A check-in with no entries", and the
/// check-in half of "I won't be weighing") is `staying-on-track`'s own
/// (mm-t36.21 builds it).
final class ReviewSummaryTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let startDay = dayKey(2026, 9, 28) // Monday

    private func weekDays(_ week: Int) -> [String] {
        ReviewDue.weekDayKeys(week: week, startDay: startDay, calendar: calendar)
    }

    /// Scenario: A full week.
    func testAFullWeek() {
        let days = weekDays(3) // 12–18 October
        let mon = days[0], tue = days[1], wed = days[2], thu = days[3], fri = days[4], sat = days[5]
        let entries = [
            ReviewEntryFact(dayKey: mon, time: moment(2026, 10, 12, 9), starred: true),
            ReviewEntryFact(dayKey: tue, time: moment(2026, 10, 13, 12, 40), starred: true),
            ReviewEntryFact(dayKey: tue, time: moment(2026, 10, 13, 19, 0), starred: false),
            ReviewEntryFact(dayKey: wed, time: moment(2026, 10, 14, 10), starred: false),
            ReviewEntryFact(dayKey: thu, time: moment(2026, 10, 15, 11), starred: true),
            ReviewEntryFact(dayKey: fri, time: moment(2026, 10, 16, 8), starred: true),
            ReviewEntryFact(dayKey: sat, time: moment(2026, 10, 17, 8), starred: false),
        ]
        let facts = ReviewWeekFacts(
            weekDayKeys: days,
            entries: entries,
            pausedDayKeys: [thu],
            plannedMealsWithEntryCount: 26,
            urgesCount: 3,
            urgesPassedCount: 2,
            weighInDoneDayKey: wed,
            closeTheDayWordsByDayKey: [mon: "tired", wed: "ok", fri: "flat"],
            previousWeekFrozenStarred: 6
        )
        XCTAssertEqual(ReviewSummary.parts(facts, calendar: calendar), [
            "Days with an entry: 6.",
            "Starred entries: 4 this week, 6 last week.",
            "Planned meals with an entry beside them: 26.",
            "Paused days: 1.",
            "Longest gap between entries: 6 hours 20 minutes, on Tuesday, from 12:40 to 19:00.",
            "Urges: 3. Passed: 2.",
            "Weigh-in: done on Wednesday.",
            "Your words this week: tired, ok, flat.",
        ])
    }

    /// Scenario: The first review.
    func testTheFirstReview() {
        let days = weekDays(1)
        let entries = [
            ReviewEntryFact(dayKey: days[0], time: moment(2026, 9, 28, 8), starred: true),
            // Two starred entries the same day, marked exempt from the gap
            // calculation so this scenario's own "no gap part" holds.
            ReviewEntryFact(dayKey: days[1], time: moment(2026, 9, 29, 8), starred: true),
            ReviewEntryFact(dayKey: days[1], time: moment(2026, 9, 29, 20), starred: true),
            ReviewEntryFact(dayKey: days[2], time: moment(2026, 9, 30, 8), starred: true),
            ReviewEntryFact(dayKey: days[3], time: moment(2026, 10, 1, 8), starred: true),
        ]
        let facts = ReviewWeekFacts(weekDayKeys: days, entries: entries, exemptDayKeys: [days[1]])
        XCTAssertEqual(ReviewSummary.parts(facts, calendar: calendar), [
            "Days with an entry: 4.",
            "Starred entries: 5 this week.",
        ])
    }

    /// Scenario: A skipped planned meal.
    func testASkippedPlannedMeal() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(3), plannedMealsWithEntryCount: 27)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertTrue(parts.contains("Planned meals with an entry beside them: 27."))
        XCTAssertFalse(parts.joined().contains("30"), "no total and no skipped count")
    }

    /// Scenario: Words in the person's order.
    func testWordsInThePersonsOrder() {
        let days = weekDays(2)
        let facts = ReviewWeekFacts(weekDayKeys: days, closeTheDayWordsByDayKey: [days[0]: "flat", days[6]: "Better"])
        XCTAssertTrue(ReviewSummary.parts(facts, calendar: calendar).contains("Your words this week: flat, Better."))
    }

    /// Scenario: An entry after midnight.
    func testAnEntryAfterMidnight() {
        let sundayOfWeek1 = weekDays(1).last!
        XCTAssertEqual(sundayOfWeek1, dayKey(2026, 10, 4))
        let entry = ReviewEntryFact(dayKey: sundayOfWeek1, time: moment(2026, 10, 5, 1, 30), starred: false)
        let week1Facts = ReviewWeekFacts(weekDayKeys: weekDays(1), entries: [entry])
        let week2Facts = ReviewWeekFacts(weekDayKeys: weekDays(2), entries: [entry])
        XCTAssertTrue(ReviewSummary.parts(week1Facts, calendar: calendar).contains("Days with an entry: 1."))
        XCTAssertTrue(ReviewSummary.parts(week2Facts, calendar: calendar).contains("Days with an entry: 0."), "the review of week 2 does not count it")
    }

    /// Scenario: A "didn't record" day.
    func testADidntRecordDay() {
        let thursday = weekDays(3)[3]
        let facts = ReviewWeekFacts(
            weekDayKeys: weekDays(3),
            entries: [
                ReviewEntryFact(dayKey: thursday, time: moment(2026, 10, 15, 8), starred: false),
                ReviewEntryFact(dayKey: thursday, time: moment(2026, 10, 15, 20), starred: false),
            ],
            exemptDayKeys: [thursday]
        )
        XCTAssertFalse(ReviewSummary.parts(facts, calendar: calendar).contains { $0.hasPrefix("Longest gap") }, "Thursday's own gap never counts")
    }

    /// Scenario: A fasting day.
    func testAFastingDay() {
        let wednesday = weekDays(3)[2]
        let facts = ReviewWeekFacts(
            weekDayKeys: weekDays(3),
            entries: [
                ReviewEntryFact(dayKey: wednesday, time: moment(2026, 10, 14, 8), starred: false),
                ReviewEntryFact(dayKey: wednesday, time: moment(2026, 10, 14, 20), starred: false),
            ],
            exemptDayKeys: [wednesday]
        )
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertFalse(parts.contains { $0.hasPrefix("Longest gap") })
        XCTAssertFalse(parts.joined().lowercased().contains("fast"), "no text about the fasting day")
    }

    /// Scenario: I won't be weighing (the review half; `staying-on-track`
    /// builds the check-in half).
    func testIWontBeWeighing() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(2), weighInDoneDayKey: nil)
        let parts = ReviewSummary.parts(facts, calendar: calendar)
        XCTAssertFalse(parts.contains { $0.hasPrefix("Weigh-in") })
    }

    /// Scenario: Zero starred entries.
    func testZeroStarredEntries() {
        let facts = ReviewWeekFacts(weekDayKeys: weekDays(4), previousWeekFrozenStarred: 2)
        XCTAssertTrue(ReviewSummary.parts(facts, calendar: calendar).contains("Starred entries: 0 this week, 2 last week."))
    }
}
