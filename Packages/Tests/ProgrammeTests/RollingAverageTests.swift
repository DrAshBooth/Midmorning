import XCTest
@testable import Programme

/// weigh-in spec, "The rolling average" (mm-t22.5).
final class RollingAverageTests: XCTestCase {
    private let calendar = engineTestCalendar

    private func fact(_ year: Int, _ month: Int, _ day: Int, _ kg: Double) -> WeighInFact {
        WeighInFact(dayKey: dayKey(year, month, day), weightKg: kg)
    }

    /// Scenario: Four weeks of weigh-ins.
    func testFourWeeksOfWeighIns() {
        let facts = [fact(2026, 9, 28, 66.8), fact(2026, 10, 5, 66.2), fact(2026, 10, 12, 67.1), fact(2026, 10, 19, 66.4)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertEqual(RollingAverage.display(series.last!.averageKg, unit: .kg), "66.6 kg")
    }

    /// Scenario: The window moves.
    func testTheWindowMoves() {
        let facts = [fact(2026, 9, 28, 66.8), fact(2026, 10, 5, 66.2), fact(2026, 10, 12, 67.1), fact(2026, 10, 19, 66.4), fact(2026, 10, 26, 66.0)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertEqual(RollingAverage.display(series.last!.averageKg, unit: .kg), "66.4 kg")
    }

    /// Scenario: First weigh-in.
    func testFirstWeighIn() {
        let series = RollingAverage.series([fact(2026, 9, 28, 66.8)], calendar: calendar)
        XCTAssertEqual(series.first?.averageKg, 66.8)
    }

    /// Scenario: A missing week.
    func testAMissingWeek() {
        let facts = [fact(2026, 9, 28, 66.8), fact(2026, 10, 5, 66.2), fact(2026, 10, 19, 66.4)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertEqual(RollingAverage.display(series.last!.averageKg, unit: .kg), "66.5 kg", "the mean of three values")
    }

    /// Scenario: A gap of five weeks.
    func testAGapOfFiveWeeks() {
        let facts = [fact(2026, 10, 5, 66.2), fact(2026, 11, 9, 65.9)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertEqual(series.last?.averageKg, 65.9)
    }

    /// The App target never fills a missing week with an estimate, the
    /// previous value or zero: the window's own mean is over only the
    /// weigh-ins that exist, by construction (no fixture week is invented
    /// above).
    func testNoEstimateForAMissingWeek() {
        let facts = [fact(2026, 9, 28, 66.8), fact(2026, 10, 19, 66.4)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertEqual(series.count, 2, "no third point invented for the missing week")
    }

    /// safeguarding spec, "The underweight check": the rolling average at
    /// the latest weigh-in 28 or more days earlier.
    func testAverageAtLeast28DaysEarlier() {
        let facts = [fact(2026, 8, 24, 70.0), fact(2026, 9, 21, 68.0), fact(2026, 9, 28, 66.0)]
        let series = RollingAverage.series(facts, calendar: calendar)
        // 28 September minus 28 days is 31 August; 24 August qualifies, 21 September does not.
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: dayKey(2026, 9, 28), in: series, calendar: calendar)
        XCTAssertEqual(earlier, series.first { $0.dayKey == dayKey(2026, 8, 24) }?.averageKg)
    }

    /// Scenario: No weigh-in, no check (safeguarding spec): with no weigh-in
    /// 28 or more days old, Rule C's own input is `nil`.
    func testNoWeighInOldEnoughReadsNil() {
        let facts = [fact(2026, 9, 21, 68.0), fact(2026, 9, 28, 66.0)]
        let series = RollingAverage.series(facts, calendar: calendar)
        XCTAssertNil(RollingAverage.averageAtLeastDaysEarlier(28, before: dayKey(2026, 9, 28), in: series, calendar: calendar))
    }
}
