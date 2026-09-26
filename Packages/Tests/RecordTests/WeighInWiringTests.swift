import Foundation
import XCTest
@testable import Record
@testable import Programme

/// mm-t22.15, the wiring bead: the four scenarios that need the weigh-in
/// screen, Rule A and the real scheduler together, run over the real
/// `RecordStore` and `Programme.Scheduler` rather than the fixture inputs
/// their own source beads used. `WeighInScreenView.afterSave`
/// (App target, untested by `swift test`) performs the same composition
/// this file drives directly.
@MainActor
final class WeighInWiringTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func dayKey(_ year: Int, _ month: Int, _ day: Int) -> String {
        RecordDay.key(containing: at(year, month, day), calendar: utc)
    }

    /// Scenario: Weight reason (safeguarding spec, "The not-right-now
    /// page"), reached from a real Rule A over a real saved weigh-in.
    func testWeightReason() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, askedAt: at(2026, 1, 1))
        try store.saveWeighIn(dateKey: dayKey(2026, 9, 28), weightKg: 53.0, unit: "kg", at: at(2026, 9, 28))

        let profile = try store.profile()!
        let series = RollingAverage.series(try store.weighIns().map { WeighInFact(dayKey: $0.dateKey, weightKg: $0.weightKg) }, calendar: utc)
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: series.last!.dayKey, in: series, calendar: utc)
        let input = UnderweightCheckInput(heightCm: profile.heightCm, onboardingBMI: profile.onboardingBMI, cautionFlag: profile.cautionFlag, currentAverageKg: series.last!.averageKg, averageAtLeast28DaysEarlierKg: earlier)
        let reasons = UnderweightCheck.notRightNowReasons(UnderweightCheck.rulesThatApply(input))

        XCTAssertEqual(reasons, [.weight])
        XCTAssertEqual(NotRightNowPage.paragraph(for: .weight), "Your weight has fallen to a point where this programme isn't the right tool for you. This is not a judgement about you. This is not a diagnosis. Your GP can look at this with you.")
        XCTAssertEqual(NotRightNowPage.remindersLine(for: reasons), NotRightNowPage.remindersPausedLine)
    }

    /// Scenario: Reminders paused by the weight reason.
    func testRemindersPausedByTheWeightReason() throws {
        let store = try makeStore()
        try store.pauseReminders(at: at(2026, 9, 28, 12, 0))

        let settings = SchedulerSettings(
            switches: [.plannedMeal: true], remindersPausedAt: try store.remindersPausedAt(),
            explicitWordingOn: false, morningPlanTime: "07:30", closeTheDayTime: "21:45",
            quietHoursOn: false, quietHoursStart: "22:00", quietHoursEnd: "07:00"
        )
        let day = SchedulerDay(
            dayKey: dayKey(2026, 9, 28), dayStart: at(2026, 9, 28, 4),
            plannedMeals: [PlannedMealFact(slotIndex: 0, time: "13:00", matchedBeforeReminderTime: false)],
            slotLabels: [:], morningPlan: MorningPlanFacts(stage2Open: false, templatesExist: false, previousDayIsSetDay: false, currentDayAlreadySet: false, isStopped: false),
            midday: MiddayFacts(hasEntryBeforeMidday: false, hasPlannedMealBeforeMidday: false, isFasting: false),
            closeTheDay: CloseTheDayFacts(stage2Open: false, hasEntryAfter17: false, lastPlannedMealTime: nil, lastPlannedMealMatched: false, hasEntryAtOrAfterLastPlannedMealTime: false),
            isPaused: false
        )
        let requests = Scheduler.requests(days: [day], settings: settings, calendar: utc)
        XCTAssertTrue(requests.isEmpty, "the scheduler delivers no reminder at 13:00 while remindersPausedAt is set")
    }

    /// Scenario: From the weigh-in (safeguarding spec, "The GP suggestion
    /// page"), reached from a real Rule C over two real saved weigh-ins.
    func testFromTheWeighIn() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, askedAt: at(2026, 1, 1))
        try store.saveWeighIn(dateKey: dayKey(2026, 8, 24), weightKg: 70.0, unit: "kg", at: at(2026, 8, 24))
        try store.saveWeighIn(dateKey: dayKey(2026, 9, 28), weightKg: 66.0, unit: "kg", at: at(2026, 9, 28))

        let profile = try store.profile()!
        let series = RollingAverage.series(try store.weighIns().map { WeighInFact(dayKey: $0.dateKey, weightKg: $0.weightKg) }, calendar: utc)
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: series.last!.dayKey, in: series, calendar: utc)
        let input = UnderweightCheckInput(heightCm: profile.heightCm, onboardingBMI: profile.onboardingBMI, cautionFlag: profile.cautionFlag, currentAverageKg: series.last!.averageKg, averageAtLeast28DaysEarlierKg: earlier)
        let rules = UnderweightCheck.rulesThatApply(input)
        let reasons = UnderweightCheck.gpSuggestionReasons(rules)

        XCTAssertEqual(reasons, [.quickChange])
        XCTAssertEqual(GPSuggestionPage.heading, "It might help to see your GP")
        XCTAssertEqual(GPSuggestionPage.line(for: .quickChange), "Your weight has changed quickly over the last four weeks.")
        XCTAssertEqual(GPSuggestionPage.diagnosisLine, "This is not a diagnosis, and nothing here is closed to you.")
        // "The app MUST NOT pause a reminder ... because of this page."
        XCTAssertNil(try store.remindersPausedAt())
    }

    /// Scenario: I won't be weighing (onboarding spec, "Screen 3: weigh-in
    /// day and quiet hours"), over the real onboarding store row.
    func testIWontBeWeighing() throws {
        let store = try makeStore()
        try store.setWeighInDayChoice(.wontBeWeighing)

        let weighInWeekday: Int?
        switch try store.weighInDayChoice() {
        case .weekday(let weekday): weighInWeekday = weekday
        case .wontBeWeighing, nil: weighInWeekday = nil
        }
        XCTAssertNil(weighInWeekday)

        let candidates = WeighInReminderRule.candidates(weighInWeekday: weighInWeekday, dayKeys: [dayKey(2026, 9, 28)], time: "07:30", hasWeighIn: { _ in false }, calendar: utc)
        XCTAssertTrue(candidates.isEmpty, "the scheduler holds no weigh-in day reminder")

        let state = WeighInGate.inputState(weighInWeekday: weighInWeekday, currentDayKey: dayKey(2026, 9, 28), todaysWeighIn: nil, lastWeighInDayKey: nil, now: at(2026, 9, 28), calendar: utc)
        XCTAssertEqual(state, .chooseDay, "the weigh-in screen shows \"Choose a weigh-in day\"")
    }
}
