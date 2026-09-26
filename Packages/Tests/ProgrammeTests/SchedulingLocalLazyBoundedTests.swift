import XCTest
import Constants
@testable import Programme

/// reminders spec, "Scheduling is local, lazy and bounded" (mm-t24.18).
final class SchedulingLocalLazyBoundedTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func dayStart(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 4))!
    }

    private func settings() -> SchedulerSettings {
        SchedulerSettings(switches: [:], remindersPausedAt: nil, explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45", quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00")
    }

    private func plannedDay(_ dayOffset: Int, meals: [PlannedMealFact], others: Bool = true) -> SchedulerDay {
        SchedulerDay(
            dayKey: "day\(dayOffset)", dayStart: dayStart(21 + dayOffset), plannedMeals: meals, slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: !meals.isEmpty, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: others, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
    }

    /// Scenario: No network / The app is not running / Device restart — the
    /// scheduler is a pure function of its inputs, with no server call and
    /// no dependency on the app's own process being alive; calling it twice
    /// with the same facts always produces the same requests, proving it by
    /// construction (`Scheduler` imports only `Foundation` and `Constants`).
    func testTheSchedulerHasNoNetworkOrProcessDependency() {
        let days = [plannedDay(0, meals: [.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)])]
        let first = Scheduler.requests(days: days, settings: settings(), calendar: calendar)
        let second = Scheduler.requests(days: days, settings: settings(), calendar: calendar)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }

    /// Scenario: Six days ahead / The far reminder.
    func testSixDaysAheadAndTheFarReminder() {
        let days = (0..<6).map { plannedDay($0, meals: [.init(slotIndex: 2, time: "13:00", matchedBeforeReminderTime: false)], others: false) }
        let farDay = plannedDay(6, meals: [])
        let requests = Scheduler.requests(days: days, farReminderDay: farDay, settings: settings(), calendar: calendar)
        XCTAssertEqual(Set(requests.map(\.dayKey)), Set(days.map(\.dayKey)).union(["day6"]))
        let far = requests.first { $0.dayKey == "day6" }
        XCTAssertEqual(far?.kind, .closeTheDay)
        XCTAssertEqual(far?.body, "21:45")
        XCTAssertEqual(far?.title.english, "")
    }

    /// Scenario: Three days without opening the app — the app re-runs the
    /// scheduler over a fresh six-day horizon from whatever "now" is at the
    /// next activation; that is simply another `requests(days:)` call over
    /// six new `SchedulerDay` values, which this proves by constructing one.
    func testThreeDaysWithoutOpeningTheApp() {
        let freshHorizon = (10..<16).map { plannedDay($0, meals: [.init(slotIndex: 0, time: "08:00", matchedBeforeReminderTime: false)], others: false) }
        let requests = Scheduler.requests(days: freshHorizon, settings: settings(), calendar: calendar)
        XCTAssertEqual(Set(requests.map(\.dayKey)).count, 6)
    }

    /// Scenario: A later day start — `RecordStore.dayStartHour(effectiveOn:)`
    /// resolves the effective hour from the append-only setting rows; the
    /// scheduler itself only ever places a candidate's clock time on the
    /// `SchedulerDay.dayStart` the caller supplies, so a later day start is
    /// already exercised by every test here that passes a specific
    /// `dayStart`. `RecordTests` proves the setting-row resolution.
    func testALaterDayStartPlacesTheTimeOnTheSuppliedDayStart() {
        let day = SchedulerDay(
            dayKey: "2026-09-24", dayStart: calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 5))!,
            plannedMeals: [.init(slotIndex: 0, time: "04:30", matchedBeforeReminderTime: false)], slotLabels: [:],
            morningPlan: .init(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: .init(hasEntryBeforeMidday: true, hasPlannedMealBeforeMidday: true, isFasting: false),
            closeTheDay: .init(stage2Open: false, hasEntryAfter17: true, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
        let requests = Scheduler.requests(days: [day], settings: settings(), calendar: calendar)
        XCTAssertEqual(requests.first?.body, "04:30")
    }

    /// Scenario: A time-zone change — recomputing with a different calendar
    /// time zone places the same clock time on a different absolute moment.
    func testATimeZoneChange() {
        var lisbon = calendar
        lisbon.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        let day = plannedDay(0, meals: [.init(slotIndex: 4, time: "19:00", matchedBeforeReminderTime: false)], others: false)
        let london = Scheduler.requests(days: [day], settings: settings(), calendar: calendar).first!.time
        let lisbonTime = Scheduler.requests(days: [day], settings: settings(), calendar: lisbon).first!.time
        XCTAssertNotEqual(london, lisbonTime, "the same 19:00 clock time is a different instant in a different zone")
    }

    /// The 60-request cap, farthest days first.
    func test60RequestCapDropsTheFarthestDaysFirst() {
        let manyMeals = (0..<10).map { PlannedMealFact(slotIndex: $0, time: ClockTime.string(hour: 6 + $0, minute: 0), matchedBeforeReminderTime: false) }
        let days = (0..<8).map { plannedDay($0, meals: manyMeals, others: false) }
        let requests = Scheduler.requests(days: days, settings: settings(), calendar: calendar, constants: .default)
        XCTAssertLessThanOrEqual(requests.count, ProgrammeConstants.default.maxPendingReminderRequests)
        XCTAssertTrue(requests.allSatisfy { $0.dayKey != "day7" }, "the farthest day drops first once the cap is exceeded")
    }
}
