import XCTest
@testable import Programme

/// reminders spec, "The weigh-in day reminder" (mm-t24.11, parented under
/// mm-t22 — the weigh-in capability owns this reminder; `reminders` (2.4)
/// already wired `.weighInDay` into the scheduler's cap, same-minute order
/// and discreet-text title ahead of this bead (`ReminderTypesAndSwitchesTests`,
/// `CapOfTwoOtherRemindersTests`, `TwoRemindersNeverShareAMinuteTests`)).
final class WeighInDayReminderTests: XCTestCase {
    private let calendar = engineTestCalendar
    private let monday = 2

    /// Scenario: The weigh-in day.
    func testTheWeighInDay() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: monday, dayKeys: [dayKey(2026, 9, 28)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates, [ReminderCandidate(kind: .weighInDay, dayKey: dayKey(2026, 9, 28), time: "07:30")])
    }

    /// Scenario: I won't be weighing.
    func testIWontBeWeighing() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: nil, dayKeys: [dayKey(2026, 9, 28), dayKey(2026, 10, 5)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates, [], "no weigh-in day reminder fires on any day")
    }

    /// Scenario: A weigh-in day chosen later.
    func testAWeighInDayChosenLater() {
        // Chosen Thursday 1 October; the horizon reaches Monday 5 October.
        let horizon = (1...5).map { dayKey(2026, 10, $0) }
        let candidates = WeighInReminderRule.candidates(weighInWeekday: monday, dayKeys: horizon, time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates.map(\.dayKey), [dayKey(2026, 10, 5)])
    }

    /// Scenario: A weigh-in before the reminder.
    func testAWeighInBeforeTheReminder() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: monday, dayKeys: [dayKey(2026, 9, 28)], time: "07:30", hasWeighIn: { key in key == dayKey(2026, 9, 28) }, calendar: calendar)
        XCTAssertEqual(candidates, [], "no weigh-in day reminder fires at 07:30 once a weigh-in already exists for the day")
    }

    /// Scenario: Another day.
    func testAnotherDay() {
        let candidates = WeighInReminderRule.candidates(weighInWeekday: monday, dayKeys: [dayKey(2026, 9, 29)], time: "07:30", hasWeighIn: { _ in false }, calendar: calendar)
        XCTAssertEqual(candidates, [])
    }
}
