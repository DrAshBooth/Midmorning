import XCTest
import Constants
@testable import Programme

/// reminders spec: what a tap on each reminder opens (mm-t24.29, mm-t22.22).
/// `NotificationActionHandling` (App target) passes each response to
/// `ReminderTapRoute.forResponse`; `ReminderRouteOpening` opens the route on
/// Today.
final class ReminderTapRouteTests: XCTestCase {
    private let plainTap = "com.apple.UNNotificationDefaultActionIdentifier"

    private func route(_ kind: ReminderKind, identifier: String = "x", dayKey: String? = "2026-10-06") -> ReminderTapRoute? {
        ReminderTapRoute.forResponse(actionIdentifier: plainTap, requestIdentifier: identifier, kind: kind.rawValue, dayKey: dayKey)
    }

    /// "The morning plan reminder while the plan needs setting": "A tap on
    /// the reminder MUST open 'Today's plan'."
    func testATapOnTheMorningPlanReminderOpensTodaysPlan() {
        XCTAssertEqual(route(.morningPlan), .todaysPlan)
    }

    /// "The midday reminder": "A tap on the reminder MUST open the new-entry
    /// screen." This is a plain tap, not "Add", so it does not use the
    /// pending-route rule.
    func testATapOnTheMiddayReminderOpensTheNewEntryScreen() {
        XCTAssertEqual(route(.midday), .newEntry)
    }

    /// "Close the day": "A tap on the reminder MUST open the close-the-day
    /// screen." The route names the reminder's own record day.
    func testATapOnTheCloseTheDayReminderOpensTheCloseTheDayScreen() {
        XCTAssertEqual(route(.closeTheDay, dayKey: "2026-10-06"), .closeTheDay(dayKey: "2026-10-06"))
    }

    /// "The weigh-in day reminder": "A tap MUST open the weigh-in screen."
    func testATapOnTheWeighInDayReminderOpensTheWeighInScreen() {
        XCTAssertEqual(route(.weighInDay), .weighIn)
    }

    /// "The weekly review reminder": "A tap MUST open the weekly review."
    func testATapOnTheWeeklyReviewReminderOpensTheWeeklyReview() {
        XCTAssertEqual(route(.weeklyReview), .weeklyReview)
    }

    /// "Actions on a planned meal reminder": "A tap on the reminder itself
    /// MUST open Today." A planned meal reminder's `userInfo` has no kind.
    func testATapOnAPlannedMealReminderOpensToday() {
        XCTAssertEqual(ReminderTapRoute.forResponse(actionIdentifier: plainTap, requestIdentifier: "plannedMeal.2026-10-06.2", kind: nil, dayKey: "2026-10-06"), .today)
    }

    /// "Add" uses the pending-route rule; "Skipped" and the snooze action
    /// open no screen.
    func testTheThreePlannedMealActions() {
        XCTAssertEqual(ReminderTapRoute.forResponse(actionIdentifier: PlannedMealReminderAction.add.identifier, requestIdentifier: "x", kind: nil, dayKey: nil), .addAction)
        XCTAssertNil(ReminderTapRoute.forResponse(actionIdentifier: PlannedMealReminderAction.skipped.identifier, requestIdentifier: "x", kind: nil, dayKey: nil))
        XCTAssertNil(ReminderTapRoute.forResponse(actionIdentifier: PlannedMealReminderAction.snooze.identifier, requestIdentifier: "x", kind: nil, dayKey: nil))
    }

    // MARK: Over the real scheduler's requests

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func day(_ offset: Int) -> SchedulerDay {
        SchedulerDay(
            dayKey: "day\(offset)", dayStart: calendar.date(from: DateComponents(year: 2026, month: 9, day: 21 + offset, hour: 4))!,
            plannedMeals: [], slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: false, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
    }

    /// Each request `Scheduler.requests` builds gives the route of its own
    /// kind, and the far reminder, which carries the close-the-day kind,
    /// opens Today ("Scheduling is local, lazy and bounded": "A tap on it
    /// MUST open Today.").
    func testEachRealRequestRoutesByItsOwnUserInfoAndTheFarReminderOpensToday() {
        let settings = SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
        let requests = Scheduler.requests(days: (0..<6).map(day), farReminderDay: day(6), settings: settings, calendar: calendar)
        func tap(_ request: ReminderRequest) -> ReminderTapRoute? {
            ReminderTapRoute.forResponse(actionIdentifier: plainTap, requestIdentifier: request.id, kind: request.userInfo["kind"], dayKey: request.userInfo["dayKey"])
        }

        let far = requests.first { $0.dayKey == "day6" }
        XCTAssertEqual(far?.kind, .closeTheDay)
        XCTAssertEqual(far.flatMap(tap), .today)

        let closeTheDay = requests.first { $0.dayKey == "day0" && $0.kind == .closeTheDay }
        XCTAssertEqual(closeTheDay.flatMap(tap), .closeTheDay(dayKey: "day0"))

        let midday = requests.first { $0.dayKey == "day0" && $0.kind == .midday }
        XCTAssertEqual(midday.flatMap(tap), .newEntry)
    }
}
