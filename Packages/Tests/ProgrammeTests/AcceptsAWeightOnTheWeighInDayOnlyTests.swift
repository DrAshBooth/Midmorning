import XCTest
@testable import Programme

/// weigh-in spec, "The app accepts a weight on the weigh-in day only"
/// (mm-t22.3). "The route from Today" (three taps: Programme, Getting
/// started, Weigh-in) is a navigation-structure claim with no pure function
/// to test; it is a device check on the epic's device-check bead.
final class AcceptsAWeightOnTheWeighInDayOnlyTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let monday = 2 // Calendar.weekday: Monday

    /// Scenario: On the weigh-in day.
    func testOnTheWeighInDay() {
        let state = WeighInGate.inputState(weighInWeekday: monday, currentDayKey: dayKey(2026, 9, 28), todaysWeighIn: nil, lastWeighInDayKey: nil, now: moment(2026, 9, 28, 8), calendar: calendar)
        XCTAssertEqual(state, .entry(prefill: nil))
    }

    /// Scenario: On another day.
    func testOnAnotherDay() {
        // Weigh-in day Monday; opens Thursday 24 September, no prior weigh-in.
        let state = WeighInGate.inputState(weighInWeekday: monday, currentDayKey: dayKey(2026, 9, 24), todaysWeighIn: nil, lastWeighInDayKey: nil, now: moment(2026, 9, 24), calendar: calendar)
        guard case .refusal(let nextDayKey) = state else { return XCTFail("expected refusal") }
        let text = WeighInRefusalText.text(dayName: "Monday", nextDate: WeighInDayRule.formattedDate(dayKey: nextDayKey, calendar: calendar))
        XCTAssertEqual(text, "Your weigh-in day is Monday. The app asks once a week, because day-to-day numbers move on their own. Next: Monday 28 September.")
    }

    /// Scenario: Change the number within 10 minutes.
    func testChangeTheNumberWithinTenMinutes() {
        let saved = TodaysWeighInFact(weightKg: 68.6, savedAt: moment(2026, 9, 28, 8))
        let state = WeighInGate.inputState(weighInWeekday: monday, currentDayKey: dayKey(2026, 9, 28), todaysWeighIn: saved, lastWeighInDayKey: dayKey(2026, 9, 28), now: moment(2026, 9, 28, 8, 5), calendar: calendar)
        XCTAssertEqual(state, .entry(prefill: 68.6))
    }

    /// Scenario: The number is fixed after 10 minutes.
    func testTheNumberIsFixedAfterTenMinutes() {
        let saved = TodaysWeighInFact(weightKg: 68.6, savedAt: moment(2026, 9, 28, 8))
        let state = WeighInGate.inputState(weighInWeekday: monday, currentDayKey: dayKey(2026, 9, 28), todaysWeighIn: saved, lastWeighInDayKey: dayKey(2026, 9, 28), now: moment(2026, 9, 28, 8, 15), calendar: calendar)
        XCTAssertEqual(state, .fixedForToday, "the screen shows the chart and no weight input, with no refusal text")
    }

    /// Scenario: The weigh-in day ended.
    func testTheWeighInDayEnded() {
        let state = WeighInGate.inputState(weighInWeekday: monday, currentDayKey: dayKey(2026, 9, 29), todaysWeighIn: nil, lastWeighInDayKey: dayKey(2026, 9, 28), now: moment(2026, 9, 29, 10), calendar: calendar)
        guard case .refusal(let nextDayKey) = state else { return XCTFail("expected refusal") }
        XCTAssertEqual(WeighInDayRule.formattedDate(dayKey: nextDayKey, calendar: calendar), "Monday 5 October")
    }

    /// Scenario: Weigh-in day changed within six days of the last weigh-in.
    func testWeighInDayChangedWithinSixDaysOfTheLastWeighIn() {
        let friday = 6
        // Last weigh-in Monday 28 September; day changed to Friday; opens Friday 2 October (4 days later).
        let state = WeighInGate.inputState(weighInWeekday: friday, currentDayKey: dayKey(2026, 10, 2), todaysWeighIn: nil, lastWeighInDayKey: dayKey(2026, 9, 28), now: moment(2026, 10, 2), calendar: calendar)
        guard case .refusal(let nextDayKey) = state else { return XCTFail("expected refusal, the six-day gate still blocks Friday 2 October") }
        XCTAssertEqual(WeighInDayRule.formattedDate(dayKey: nextDayKey, calendar: calendar), "Friday 9 October")
    }
}
