import XCTest
@testable import Programme

/// weigh-in spec, "The weigh-in day" (mm-t22.2). "The weigh-in day syncs"
/// and "Two devices set the weigh-in day" are `deferred: mm-t41b.11`
/// (`v1-programme/deferred.md`): the first cut reuses onboarding's own
/// synced `Settings` row (`RecordStore.weighInDayChoice`), already proven
/// by `OnboardingStoreTests`, and sync itself is 4.1b's own build.
final class WeighInDayTests: XCTestCase {
    private let calendar = engineTestCalendar

    /// Scenario: No weigh-in day.
    func testNoWeighInDay() {
        let state = WeighInGate.inputState(weighInWeekday: nil, currentDayKey: dayKey(2026, 9, 28), todaysWeighIn: nil, lastWeighInDayKey: nil, now: moment(2026, 9, 28), calendar: calendar)
        XCTAssertEqual(state, .chooseDay)
        XCTAssertFalse(WeighInChartRule.showsChart(weighInWeekday: nil, hasAnyWeighIn: false))
    }

    /// Scenario: Choose a weigh-in day later.
    func testChooseAWeighInDayLater() {
        // Wednesday 30 September; Friday is weekday 6.
        let state = WeighInGate.inputState(weighInWeekday: 6, currentDayKey: dayKey(2026, 10, 2), todaysWeighIn: nil, lastWeighInDayKey: nil, now: moment(2026, 10, 2), calendar: calendar)
        XCTAssertEqual(state, .entry(prefill: nil), "the app accepts a weigh-in on Friday 2 October")
        let candidates = WeighInReminderRule.candidates(weighInWeekday: 6, dayKeys: [dayKey(2026, 10, 2)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates, [ReminderCandidate(kind: .weighInDay, dayKey: dayKey(2026, 10, 2), time: "07:30")])
    }

    /// Scenario: No reminder without a weigh-in day.
    func testNoReminderWithoutAWeighInDay() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: nil, dayKeys: [dayKey(2026, 9, 28)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates, [])
    }

    /// Scenario: Change the weigh-in day.
    func testChangeTheWeighInDay() {
        // Monday to Friday on Wednesday 30 September, no weigh-in in the last six days.
        let state = WeighInGate.inputState(weighInWeekday: 6, currentDayKey: dayKey(2026, 10, 2), todaysWeighIn: nil, lastWeighInDayKey: nil, now: moment(2026, 10, 2), calendar: calendar)
        XCTAssertEqual(state, .entry(prefill: nil))
    }

    /// Scenario: The reminder follows the weigh-in day.
    func testTheReminderFollowsTheWeighInDay() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: 6, dayKeys: [dayKey(2026, 10, 2)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates.first?.time, "07:30")
        XCTAssertEqual(candidates.first?.dayKey, dayKey(2026, 10, 2))
    }

    /// Scenario: Opt out after weigh-ins.
    func testOptOutAfterWeighIns() {
        XCTAssertEqual(WeighInGate.inputState(weighInWeekday: nil, currentDayKey: dayKey(2026, 10, 2), todaysWeighIn: nil, lastWeighInDayKey: dayKey(2026, 9, 28), now: moment(2026, 10, 2), calendar: calendar), .chooseDay)
        XCTAssertFalse(WeighInChartRule.showsChart(weighInWeekday: nil, hasAnyWeighIn: true), "no chart while no weigh-in day exists, even with four kept weigh-ins")
    }

    /// Scenario: A weigh-in day again after an opt-out.
    func testAWeighInDayAgainAfterAnOptOut() {
        // Weigh-in day chosen again as Friday (6) on Wednesday 4 November; last weigh-in Monday 26 October.
        let state = WeighInGate.inputState(weighInWeekday: 6, currentDayKey: dayKey(2026, 11, 4), todaysWeighIn: nil, lastWeighInDayKey: dayKey(2026, 10, 26), now: moment(2026, 11, 4), calendar: calendar)
        guard case .refusal(let nextDayKey) = state else { return XCTFail("expected refusal") }
        XCTAssertEqual(WeighInDayRule.formattedDate(dayKey: nextDayKey, calendar: calendar), "Friday 6 November")
        XCTAssertTrue(WeighInChartRule.showsChart(weighInWeekday: 6, hasAnyWeighIn: true), "the chart shows every kept weigh-in once a weigh-in day is chosen again")
    }
}
