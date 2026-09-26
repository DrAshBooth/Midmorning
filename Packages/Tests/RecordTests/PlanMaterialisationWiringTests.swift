import Foundation
import XCTest
@testable import Record
import RecordTestSupport
@testable import Plan

/// regular-eating-plan spec, "Weekday and weekend templates", through the
/// two store calls the app target makes (mm-t23.21):
/// `materialiseElapsedRecordDays` on every activation (`AppLockRootView`,
/// before the reminder recompute) and `changeTemplate` from the plan
/// builder's "Save" and "Copy to weekend plan". `resolvedPlan` is the one
/// read that Today, the plan builder and the scheduler use (mm-t23.23).
@MainActor
final class PlanMaterialisationWiringTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private let lunchAt13 = PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:00")])
    private let lunchAt14 = PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "14:00")])

    /// Scenario: Three days without opening the app.
    func testThreeDaysWithoutOpeningTheApp() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 20, 9))

        // Activation at 20:00 on Monday 21 September.
        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 21, 20), calendar: london), ["2026-09-21"])
        // Activation at 09:00 on Thursday 24 September.
        let written = try store.materialiseElapsedRecordDays(now: at(2026, 9, 24, 9), calendar: london)

        XCTAssertEqual(written, ["2026-09-22", "2026-09-23", "2026-09-24"], "the app copies the templates onto Tuesday, Wednesday and Thursday")
        for key in written {
            let plan = try store.resolvedPlan(dateKey: key)
            XCTAssertTrue(plan.hasDayRow)
            XCTAssertEqual(plan.meals, [PlannedMeal(slotIndex: 2, time: "13:00")])
            XCTAssertEqual(plan.windowBeforeMinutes, 60)
            XCTAssertEqual(plan.windowAfterMinutes, 90)
        }
        XCTAssertFalse(try store.isSetDay(dateKey: "2026-09-22"), "Tuesday is not a planned day")
        XCTAssertFalse(try store.isSetDay(dateKey: "2026-09-23"), "Wednesday is not a planned day")
        XCTAssertFalse(try store.plannedDayKeys().contains("2026-09-22"))
    }

    /// Scenario: A template change during the day.
    func testATemplateChangeDuringTheDay() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 28, 9))
        // Activation at 08:00 on Tuesday 29 September.
        try store.materialiseElapsedRecordDays(now: at(2026, 9, 29, 8), calendar: london)

        // The person changes the weekday template at 15:00 on Tuesday.
        try store.changeTemplate(lunchAt14, kind: .weekday, now: at(2026, 9, 29, 15), calendar: london)

        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-29").meals.first?.time, "13:00", "Tuesday's plan does not change")
        let wednesday = try store.resolvedPlan(dateKey: "2026-09-30")
        XCTAssertFalse(wednesday.hasDayRow)
        XCTAssertEqual(wednesday.meals.first?.time, "14:00", "Wednesday's plan comes from the changed template")
    }

    /// The app stays open over the day start, so no activation copies the
    /// template onto Tuesday. A template change at 15:00 on Tuesday still
    /// leaves Tuesday's plan as it was, because `changeTemplate` copies
    /// first.
    func testATemplateChangeWithNoActivationSinceTheDayStart() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 28, 9))
        try store.materialiseElapsedRecordDays(now: at(2026, 9, 28, 20), calendar: london)

        try store.changeTemplate(lunchAt14, kind: .weekday, now: at(2026, 9, 29, 15), calendar: london)

        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-28").meals.first?.time, "13:00", "Monday keeps its plan")
        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-29").meals.first?.time, "13:00", "Tuesday's plan does not change")
        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-30").meals.first?.time, "14:00")
    }

    /// "Copy to weekend plan" on a Saturday is also a template change. It
    /// leaves Saturday's plan as it was.
    func testCopyToTheWeekendOnASaturdayKeepsSaturdaysPlan() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekend, changedAt: at(2026, 9, 20, 9))
        try store.changeTemplate(lunchAt14, kind: .weekend, now: at(2026, 9, 26, 10), calendar: london)

        let saturday = try store.resolvedPlan(dateKey: "2026-09-26")
        XCTAssertTrue(saturday.hasDayRow)
        XCTAssertEqual(saturday.meals.first?.time, "13:00")
        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-27").meals.first?.time, "14:00", "Sunday takes the copied plan")
    }

    /// Scenario: A weekend record day. At 01:00 on Sunday 27 September the
    /// current record day is Saturday 26 September, and its copy comes from
    /// the weekend template.
    func testAWeekendRecordDayGetsTheWeekendTemplate() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 20, 9))
        try store.setTemplateSlotsJSON(lunchAt14, kind: .weekend, changedAt: at(2026, 9, 20, 9))

        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 27, 1), calendar: london), ["2026-09-26"])
        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-26").meals.first?.time, "14:00")
    }

    /// Materialisation never replaces a `Day` row, writes no set event, and
    /// a second activation on the same day writes nothing.
    func testMaterialisationKeepsASetDayAndRunsOncePerDay() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 20, 9))
        try store.setDayPlan(dateKey: "2026-09-29", slotsJSON: lunchAt14, windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 9, 28, 22), setBy: "device", changedAt: at(2026, 9, 28, 22))
        try store.materialiseElapsedRecordDays(now: at(2026, 9, 28, 8), calendar: london)

        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 29, 8), calendar: london), [], "Tuesday already has its own row")
        XCTAssertEqual(try store.resolvedPlan(dateKey: "2026-09-29").meals.first?.time, "14:00")
        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 29, 9), calendar: london), [])
        XCTAssertFalse(try store.isSetDay(dateKey: "2026-09-28"), "materialisation writes no set event")
    }

    /// A day that an earlier walk missed gets its copy on the next
    /// activation.
    func testAMissedDayBetweenTwoCopiesGetsItsCopy() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(lunchAt13, kind: .weekday, changedAt: at(2026, 9, 20, 9))
        try store.materialiseElapsedRecordDays(now: at(2026, 9, 21, 8), calendar: london)
        try store.setDayPlan(dateKey: "2026-09-23", slotsJSON: lunchAt14, windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 9, 23, 8), setBy: "device", changedAt: at(2026, 9, 23, 8))

        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 24, 8), calendar: london), ["2026-09-22", "2026-09-24"])
    }

    /// The walk uses the "Day starts at" hour in force. With a day start of
    /// 07:00, 05:00 on Tuesday is still in Monday's record day.
    func testTheWalkUsesTheDayStartInForce() throws {
        let store = try makeTemporaryStore()
        try store.setDayStartHour(7, now: at(2026, 9, 20, 12), calendar: london)
        try store.materialiseElapsedRecordDays(now: at(2026, 9, 28, 12), calendar: london)

        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 29, 5), calendar: london), [], "05:00 on Tuesday is in Monday's record day")
        XCTAssertEqual(try store.materialiseElapsedRecordDays(now: at(2026, 9, 29, 7), calendar: london), ["2026-09-29"])
        let tuesday = try store.resolvedPlan(dateKey: "2026-09-29")
        XCTAssertEqual(tuesday.recordDay(calendar: london), DateInterval(start: at(2026, 9, 29, 7), end: at(2026, 9, 30, 7)))
    }
}
