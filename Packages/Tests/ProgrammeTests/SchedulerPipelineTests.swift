import XCTest
import Constants
@testable import Programme

/// reminders spec, "The scheduler pipeline" (mm-t24.17).
final class SchedulerPipelineTests: XCTestCase {
    private func c(_ kind: ReminderKind, _ time: String, day: String = "2026-09-24", slot: Int? = nil) -> ReminderCandidate {
        ReminderCandidate(kind: kind, dayKey: day, slotIndex: slot, time: time)
    }

    private func run(_ candidates: [ReminderCandidate], switches: [ReminderKind: Bool] = [:], remindersPausedAt: Date? = nil, quietHoursStart: String = "22:00", quietHoursEnd: String = "07:00") -> [ReminderCandidate] {
        Scheduler.pipeline(candidates, switches: switches, remindersPausedAt: remindersPausedAt, quietHoursOn: true, quietHoursStart: quietHoursStart, quietHoursEnd: quietHoursEnd)
    }

    /// Scenario: A switch outranks the end of a pause.
    func testASwitchOutranksTheEndOfAPause() {
        let result = run([c(.plannedMeal, "13:00", slot: 2), c(.closeTheDay, "21:45")], switches: [.plannedMeal: false], remindersPausedAt: nil)
        XCTAssertEqual(Set(result.map(\.kind)), [.closeTheDay])
    }

    /// Scenario: A paused day outlasts the end of a pause. (`isPaused` on
    /// `SchedulerDay` means the day contributes no candidates in the first
    /// place; `Scheduler.candidates(for:settings:)` proves that below.)
    func testAPausedDayOutlastsTheEndOfAPause() {
        let today = SchedulerDay(
            dayKey: "2026-09-24", dayStart: Date(), plannedMeals: [PlannedMealFact(slotIndex: 0, time: "08:00", matchedBeforeReminderTime: false)],
            slotLabels: [:], morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: true
        )
        XCTAssertEqual(Scheduler.candidates(for: today, settings: settings()), [])
        var tomorrow = today
        tomorrow.isPaused = false
        XCTAssertEqual(Scheduler.candidates(for: tomorrow, settings: settings()).map(\.kind), [.plannedMeal])
    }

    private func settings() -> SchedulerSettings {
        SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: true, quietHoursStart: "22:00", quietHoursEnd: "07:00")
    }

    /// Scenario: A dropped reminder takes no part in the shift.
    func testADroppedReminderTakesNoPartInTheShift() {
        let result = run([c(.morningPlan, "07:30"), c(.weighInDay, "07:30"), c(.midday, "12:00"), c(.closeTheDay, "21:45")])
        XCTAssertEqual(Set(result.map(\.kind)), [.weighInDay, .closeTheDay])
        XCTAssertEqual(result.first { $0.kind == .weighInDay }?.time, "07:30")
    }

    /// Scenario: A shifted reminder lands in quiet hours.
    func testAShiftedReminderLandsInQuietHours() {
        let result = run([c(.plannedMeal, "21:45", slot: 5), c(.closeTheDay, "21:45")], quietHoursStart: "21:50", quietHoursEnd: "07:00")
        XCTAssertEqual(result.map(\.kind), [.plannedMeal])
        XCTAssertEqual(result.first?.time, "21:45")
    }

    /// Scenario: A quiet-hours drop still counts toward the cap.
    func testAQuietHoursDropStillCountsTowardTheCap() {
        let result = run([c(.morningPlan, "07:30"), c(.midday, "12:00"), c(.closeTheDay, "21:45")], quietHoursStart: "21:00", quietHoursEnd: "06:00")
        XCTAssertEqual(result.map(\.kind), [.morningPlan])
    }
}
