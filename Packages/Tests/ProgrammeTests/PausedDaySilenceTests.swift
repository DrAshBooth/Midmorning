import XCTest
@testable import Programme

/// reminders spec, "A paused day and a reminder pause silence everything"
/// (mm-t24.16).
final class PausedDaySilenceTests: XCTestCase {
    private func day(paused: Bool, plannedMeals: [PlannedMealFact] = []) -> SchedulerDay {
        SchedulerDay(
            dayKey: "2026-09-24", dayStart: Date(), plannedMeals: plannedMeals, slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: paused
        )
    }

    private func settings(pausedAt: Date? = nil) -> SchedulerSettings {
        SchedulerSettings(switches: [:], remindersPausedAt: pausedAt, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
    }

    /// Scenario: Pause at 14:00 — a paused day contributes no candidate at
    /// all, snoozed or not, for the rest of that record day.
    func testPauseAt1400() {
        let meals = [
            PlannedMealFact(slotIndex: 3, time: "16:00", matchedBeforeReminderTime: false),
            PlannedMealFact(slotIndex: 4, time: "19:00", matchedBeforeReminderTime: false),
        ]
        XCTAssertEqual(Scheduler.candidates(for: day(paused: true, plannedMeals: meals), settings: settings()), [])
        let closeTheDay = day(paused: true)
        XCTAssertTrue(Scheduler.candidates(for: closeTheDay, settings: settings()).isEmpty)
    }

    /// Scenario: The day after a pause.
    func testTheDayAfterAPause() {
        let friday = day(paused: false, plannedMeals: [PlannedMealFact(slotIndex: 0, time: "08:00", matchedBeforeReminderTime: false)])
        XCTAssertEqual(Scheduler.candidates(for: friday, settings: settings()).map(\.time), ["08:00"])
    }

    /// Scenario: A reminder pause.
    func testAReminderPause() {
        let lunch = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 2, time: "13:00")
        let result = Scheduler.pipeline([lunch], switches: [:], remindersPausedAt: Date(timeIntervalSince1970: 0), quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertTrue(result.isEmpty)
    }

    /// Scenario: Resume.
    func testResume() {
        let lunch = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-28", slotIndex: 2, time: "13:00")
        let result = Scheduler.pipeline([lunch], switches: [:], remindersPausedAt: nil, quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.map(\.time), ["13:00"])
    }

    /// Scenario: The self-harm reason — the not-right-now page pauses
    /// reminders only when it shows a weight reason (`safeguarding` sets
    /// `remindersPausedAt`); with the self-harm reason and no weight reason
    /// it MUST NOT pause reminders, so an unrelated Lunch reminder is
    /// unaffected.
    func testTheSelfHarmReason() {
        let lunch = ReminderCandidate(kind: .plannedMeal, dayKey: "2026-09-24", slotIndex: 2, time: "13:00")
        let result = Scheduler.pipeline([lunch], switches: [:], remindersPausedAt: nil, quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        XCTAssertEqual(result.map(\.time), ["13:00"])
    }
}
