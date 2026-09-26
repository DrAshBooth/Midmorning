import XCTest
@testable import Programme

/// reminders spec, "A reminder for every planned meal" (mm-t24.2).
final class ReminderForEveryPlannedMealTests: XCTestCase {
    /// Isolated to the planned-meal candidate alone: midday and
    /// close-the-day are given facts that keep their own rule from firing,
    /// since this file is about "A reminder for every planned meal" only.
    private func day(_ meals: [PlannedMealFact]) -> SchedulerDay {
        SchedulerDay(
            dayKey: "2026-09-24", dayStart: Date(), plannedMeals: meals, slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
    }

    private let settings = SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")

    /// Scenario: A planned meal at its time.
    func testAPlannedMealAtItsTime() {
        let result = Scheduler.candidates(for: day([.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)]), settings: settings)
        XCTAssertEqual(result.map(\.time), ["13:00"])
    }

    /// Scenario: The plan changes — the caller (the App layer) recomputes
    /// the whole schedule from the new plan; there is nothing for the
    /// scheduler itself to "cancel", it simply is not asked for the 13:00
    /// candidate again.
    func testThePlanChanges() {
        let moved = Scheduler.candidates(for: day([.init(slotIndex: 2, time: "13:30", matchedBeforeReminderTime: false)]), settings: settings)
        XCTAssertEqual(moved.map(\.time), ["13:30"])
    }

    /// Scenario: An entry before the time.
    func testAnEntryBeforeTheTime() {
        let result = Scheduler.candidates(for: day([.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: true)]), settings: settings)
        XCTAssertTrue(result.isEmpty)
    }

    /// Scenario: An entry after the reminder — removing a delivered
    /// reminder is `DeliveredReminderRemoval`'s job, proved in
    /// `DeliveredRemindersGroupedAndRemovedTests`.
    func testAnEntryAfterTheReminder() {
        let reminder = DeliveredReminder(id: "lunch", kind: .plannedMeal, dayKey: "2026-09-24", windowEndTime: "14:30")
        XCTAssertTrue(DeliveredReminderRemoval.idsToRemove(delivered: [reminder], currentRecordDayKey: "2026-09-24", nowClockTime: "13:20").isEmpty, "not yet at the window's end")
    }

    /// Scenario: A day beyond tomorrow — the caller resolves an
    /// unmaterialised day's planned meals from its template before calling
    /// the scheduler (reminders spec: "For a record day the app has not
    /// materialised, the scheduler MUST use the day's template."); once
    /// resolved, the scheduler treats it exactly as any other day.
    func testADayBeyondTomorrow() {
        let wednesdayFromTemplate = day([.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)])
        XCTAssertEqual(Scheduler.candidates(for: wednesdayFromTemplate, settings: settings).map(\.time), ["13:00"])
    }
}
