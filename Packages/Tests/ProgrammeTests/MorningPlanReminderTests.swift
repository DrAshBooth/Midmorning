import XCTest
@testable import Programme

/// reminders spec, "The morning plan reminder while the plan needs setting"
/// (mm-t24.7).
final class MorningPlanReminderTests: XCTestCase {
    private func facts(stage2Open: Bool = true, templatesExist: Bool = false, previousDayIsSetDay: Bool = false, currentDayAlreadySet: Bool = false, isStopped: Bool = false) -> MorningPlanFacts {
        MorningPlanFacts(stage2Open: stage2Open, templatesExist: templatesExist, previousDayIsSetDay: previousDayIsSetDay, currentDayAlreadySet: currentDayAlreadySet, isStopped: isStopped)
    }

    /// Scenario: No template yet (a stage fact; `mm-t32.16` runs it end to
    /// end).
    func testNoTemplateYet() {
        XCTAssertTrue(MorningPlanRule.shouldSchedule(facts(templatesExist: false, previousDayIsSetDay: false)))
    }

    /// Scenario: A template exists.
    func testATemplateExists() {
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: false)))
    }

    /// Scenario: An edit the day before.
    func testAnEditTheDayBefore() {
        XCTAssertTrue(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: true)), "Wednesday: Tuesday was set")
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: false)), "Thursday: Wednesday was not set")
    }

    /// Scenario: A template change.
    func testATemplateChange() {
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: false)), "a template change is not a plan edit")
    }

    /// Scenario: Tomorrow set tonight.
    func testTomorrowSetTonight() {
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: false)), "Friday: Thursday itself was not set")
        XCTAssertTrue(MorningPlanRule.shouldSchedule(facts(templatesExist: true, previousDayIsSetDay: true)), "Saturday: Friday was set, by the 'Tomorrow's plan' save")
    }

    /// Scenario: Three unanswered days.
    func testThreeUnansweredDays() {
        let count = MorningPlanUnansweredTracker.count(elapsedDays: [
            .init(wasDelivered: true, wasTapped: false, daySetItsOwnPlan: false),
            .init(wasDelivered: true, wasTapped: false, daySetItsOwnPlan: false),
            .init(wasDelivered: true, wasTapped: false, daySetItsOwnPlan: false),
        ])
        XCTAssertEqual(count, 3)
        XCTAssertTrue(MorningPlanUnansweredTracker.stopped(count: count))
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(templatesExist: false, isStopped: true)))
        let resetCount = MorningPlanUnansweredTracker.count(startingAt: count, elapsedDays: [.init(wasDelivered: false, wasTapped: false, daySetItsOwnPlan: true)])
        XCTAssertEqual(resetCount, 0)
    }

    /// Scenario: Days with no delivered reminder. The horizon is only six
    /// record days deep (`REMINDER_HORIZON_DAYS`) and no background task
    /// runs in the first cut, so with the app closed the whole span only six
    /// of the eleven elapsed days ever had a reminder delivered at all; the
    /// other five never increment or reset the count.
    func testDaysWithNoDeliveredReminder() {
        let delivered = Array(repeating: MorningPlanDayOutcome(wasDelivered: true, wasTapped: false, daySetItsOwnPlan: false), count: 6)
        let notDelivered = Array(repeating: MorningPlanDayOutcome(wasDelivered: false, wasTapped: false, daySetItsOwnPlan: false), count: 5)
        let count = MorningPlanUnansweredTracker.count(elapsedDays: delivered + notDelivered)
        XCTAssertEqual(count, 6, "the app counts six unanswered days, not eleven")
        XCTAssertTrue(MorningPlanUnansweredTracker.stopped(count: count))
    }

    /// Scenario: Stage 1.
    func testStage1() {
        XCTAssertFalse(MorningPlanRule.shouldSchedule(facts(stage2Open: false, templatesExist: false)))
    }
}
