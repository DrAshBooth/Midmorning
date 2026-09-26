import XCTest
@testable import Programme

/// weigh-in spec, "A missed weigh-in day" (mm-t22.9). "One skipped week" and
/// "Two skipped weeks" (the app shows nothing, and the following weigh-in
/// day shows the input as usual) are covered by construction: no code path
/// in this change reads a missed week's status to change the weigh-in
/// screen (`WeighInGate` never takes it as an input), and
/// `AcceptsAWeightOnTheWeighInDayOnlyTests.testOnTheWeighInDay` already
/// proves the next weigh-in day shows the input regardless of an earlier
/// miss.
final class MissedWeighInTests: XCTestCase {
    /// Scenario: The weekly review reads the status.
    func testTheWeeklyReviewReadsTheStatus() {
        let status = MissedWeighIn.status(weighInWeekday: 2, weekDayKey: "2026-10-05", hasWeighIn: { _ in false })
        XCTAssertEqual(status, .notDone)
    }

    /// Scenario: The weekly review with no weigh-in day.
    func testTheWeeklyReviewWithNoWeighInDay() {
        let status = MissedWeighIn.status(weighInWeekday: nil, weekDayKey: "2026-10-05", hasWeighIn: { _ in false })
        XCTAssertEqual(status, .noWeighInDay)
    }

    func testDoneWhenTheWeekHasAWeighIn() {
        let status = MissedWeighIn.status(weighInWeekday: 2, weekDayKey: "2026-10-05", hasWeighIn: { $0 == "2026-10-05" })
        XCTAssertEqual(status, .done)
    }
}
