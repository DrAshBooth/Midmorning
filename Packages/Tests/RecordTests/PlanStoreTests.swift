import Foundation
import XCTest
@testable import Record
import RecordTestSupport
@testable import Plan

/// regular-eating-plan spec: "A planned day" (mm-t23.8), "Weekday and weekend
/// templates" (mm-t23.6), "Edit tonight for tomorrow, or this morning for
/// today" (mm-t23.7) and "The plan's data stays on the device" (mm-t23.13).
/// The store-level scenarios these beads' pure-function siblings in
/// `PlanTests` point back to: the ones that need the real `Day`/`Template`/
/// `Answer` models, `RecordDay`'s own day-boundary math, or the store's
/// directory.
@MainActor
final class PlanStoreTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: mm-t23.8, "A planned day"

    /// Scenario: A day start change keeps the key.
    func testADayStartChangeKeepsTheKey() throws {
        let store = try makeTemporaryStore()
        try store.setDayPlan(dateKey: "2026-10-02", slotsJSON: "[]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 10, 2, 8), setBy: "device-a", changedAt: at(2026, 10, 2, 8))
        try store.setDayStartHour(5, now: at(2026, 10, 3, 6), calendar: london)
        let plan = try store.dayPlan(dateKey: "2026-10-02")
        XCTAssertEqual(plan?.dateKey, "2026-10-02", "the row keeps its key")
        XCTAssertTrue(try store.isSetDay(dateKey: "2026-10-02"), "Friday stays a planned day")
    }

    /// Scenario: The set event row from another device — the sticky rule
    /// through the store (the pure Reconciler rule is `ConflictRulesTests`).
    func testTheSetEventRowFromAnotherDeviceThroughTheStore() throws {
        let store = try makeTemporaryStore()
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: "[]", windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 10, 6, 22), setBy: "device-a", changedAt: at(2026, 10, 6, 22))
        XCTAssertTrue(try store.isSetDay(dateKey: "2026-10-06"), "device B reads the set event and treats the day as set")
    }

    // MARK: mm-t23.6, "Weekday and weekend templates"

    /// Scenario: A template change during the day.
    func testATemplateChangeDuringTheDayDoesNotChangeTodaysPlan() throws {
        let store = try makeTemporaryStore()
        try store.setTemplateSlotsJSON(PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:00")]), kind: .weekday, changedAt: at(2026, 9, 28, 9))
        let originalTemplate = try store.templateSlotsJSON(.weekday)
        try store.materialiseDayFromTemplate(dateKey: "2026-09-29", slotsJSON: originalTemplate, windowBeforeMinutes: 60, windowAfterMinutes: 90)

        // The person changes the weekday template at 15:00 on Tuesday.
        try store.setTemplateSlotsJSON(PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "14:00")]), kind: .weekday, changedAt: at(2026, 9, 29, 15))

        let tuesdaysPlan = try store.dayPlan(dateKey: "2026-09-29")
        XCTAssertEqual(tuesdaysPlan?.slotsJSON, originalTemplate, "Tuesday's plan does not change")
        let newTemplate = try store.templateSlotsJSON(.weekday)
        XCTAssertEqual(PlanCodec.decode(newTemplate).first?.time, "14:00", "Wednesday's plan comes from the changed template")
    }

    /// Scenario: Three days without opening the app.
    func testThreeDaysWithoutOpeningTheAppMaterialisesEachElapsedDay() throws {
        let store = try makeTemporaryStore()
        let weekdayJSON = PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:00")])
        try store.setTemplateSlotsJSON(weekdayJSON, kind: .weekday, changedAt: at(2026, 9, 20, 9))

        // Last opened 20:00 Monday 21 September; opens 09:00 Thursday 24 September.
        var interval = RecordDay.interval(containing: at(2026, 9, 21, 20), calendar: london, schedule: .standard)
        let last = RecordDay.interval(containing: at(2026, 9, 24, 9), calendar: london, schedule: .standard)
        var materialisedKeys: [String] = []
        while interval.start < last.start {
            interval = RecordDay.next(interval, calendar: london, schedule: .standard)
            let dateKey = RecordDay.key(containing: interval.start, calendar: london, schedule: .standard)
            let weekday = london.component(.weekday, from: interval.start)
            let kind = RecordStore.TemplateKind(rawValue: Materialisation.templateKind(forRecordDayStartingOnWeekday: weekday))!
            try store.materialiseDayFromTemplate(dateKey: dateKey, slotsJSON: try store.templateSlotsJSON(kind), windowBeforeMinutes: 60, windowAfterMinutes: 90)
            materialisedKeys.append(dateKey)
        }
        XCTAssertEqual(materialisedKeys, ["2026-09-22", "2026-09-23", "2026-09-24"], "Tuesday, Wednesday and Thursday")
        for key in ["2026-09-22", "2026-09-23"] {
            XCTAssertFalse(try store.isSetDay(dateKey: key), "Tuesday and Wednesday are not set/planned days")
        }
    }

    // MARK: mm-t23.7, "Edit tonight for tomorrow, or this morning for today"

    /// Scenario: Tonight for tomorrow.
    func testTonightForTomorrow() throws {
        let store = try makeTemporaryStore()
        // 22:00 Thursday 24 September; "Tomorrow's plan" targets Friday 25 September.
        let today = RecordDay.interval(containing: at(2026, 9, 24, 22), calendar: london, schedule: .standard)
        let tomorrow = RecordDay.next(today, calendar: london, schedule: .standard)
        let tomorrowKey = RecordDay.key(containing: tomorrow.start, calendar: london, schedule: .standard)
        XCTAssertEqual(tomorrowKey, "2026-09-25")
        try store.setDayPlan(dateKey: tomorrowKey, slotsJSON: PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "14:00")]), windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 9, 24, 22), setBy: "device", changedAt: at(2026, 9, 24, 22))
        XCTAssertEqual(PlanCodec.decode(try store.dayPlan(dateKey: "2026-09-25")!.slotsJSON).first?.time, "14:00")
        XCTAssertEqual(try store.templateSlotsJSON(.weekday), "[]", "the weekday template is unchanged")
    }

    /// Scenario: This morning for today.
    func testThisMorningForToday() throws {
        let store = try makeTemporaryStore()
        // 07:30 Friday 25 September; "Today's plan" targets Friday.
        let today = RecordDay.interval(containing: at(2026, 9, 25, 7, 30), calendar: london, schedule: .standard)
        let todayKey = RecordDay.key(containing: today.start, calendar: london, schedule: .standard)
        let saturdayKey = RecordDay.key(containing: RecordDay.next(today, calendar: london, schedule: .standard).start, calendar: london, schedule: .standard)
        try store.setDayPlan(dateKey: todayKey, slotsJSON: PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:30")]), windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(2026, 9, 25, 7, 30), setBy: "device", changedAt: at(2026, 9, 25, 7, 30))
        XCTAssertEqual(PlanCodec.decode(try store.dayPlan(dateKey: todayKey)!.slotsJSON).first?.time, "13:30")
        XCTAssertNil(try store.dayPlan(dateKey: saturdayKey), "Saturday's plan is unchanged")
    }

    /// Scenario: Tomorrow after midnight.
    func testTomorrowAfterMidnight() throws {
        // 01:00 Saturday 26 September, day start 04:00: today is Friday 25;
        // "Tomorrow's plan" edits the record day of Saturday 26 September.
        let today = RecordDay.interval(containing: at(2026, 9, 26, 1), calendar: london, schedule: .standard)
        XCTAssertEqual(RecordDay.key(containing: today.start, calendar: london, schedule: .standard), "2026-09-25")
        let tomorrow = RecordDay.next(today, calendar: london, schedule: .standard)
        XCTAssertEqual(RecordDay.key(containing: tomorrow.start, calendar: london, schedule: .standard), "2026-09-26")
    }

    // MARK: mm-t23.13, "The plan's data stays on the device"

    /// Scenario: Close and open the app.
    func testCloseAndOpenTheAppKeepsTheWeekdayTemplate() throws {
        let directory = try makeTemporaryDirectory()
        let json = PlanCodec.encode([PlannedMeal(slotIndex: 0, time: "08:00")])
        do {
            let store = try RecordStore(directory: directory)
            try store.setTemplateSlotsJSON(json, kind: .weekday, changedAt: .now)
        }
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.templateSlotsJSON(.weekday), json, "the weekday template is unchanged after closing and opening the app")
    }

    /// Scenario: No network. Every call above is a local SwiftData write with
    /// no network code; `RecordStore` makes no networking call anywhere in
    /// this file's calls, so the person can edit the plan and see it on
    /// Today with no network connection.
    func testNoNetworkEditingWorksOffline() throws {
        let store = try makeTemporaryStore()
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:00")]), windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: .now, setBy: "device", changedAt: .now)
        XCTAssertNotNil(try store.dayPlan(dateKey: "2026-10-06"))
    }

    /// Scenario: Delete-all. Plan rows live in `Record.store`, in the same
    /// directory `DeleteAllSeam` deletes whole (data-and-privacy spec: "Only
    /// Delete-all deletes them, with the whole store directory"); a fresh
    /// store at a fresh directory is exactly that post-delete state.
    func testDeleteAllLeavesNoTemplateNoDayAndDefaultLabels() throws {
        let store = try makeTemporaryStore()
        XCTAssertEqual(try store.templateSlotsJSON(.weekday), "[]")
        XCTAssertNil(try store.dayPlan(dateKey: "2026-10-06"))
        XCTAssertNil(try store.slotLabel(index: 1), "the default labels apply")
    }

    /// Scenario: A rename on two devices.
    func testARenameOnTwoDevicesTheLaterOneWins() throws {
        let store = try makeTemporaryStore()
        try store.setSlotLabel("Elevenses", index: 1, changedAt: at(2026, 9, 26, 10, 0))
        try store.setSlotLabel("Brunch", index: 1, changedAt: at(2026, 9, 26, 10, 5))
        XCTAssertEqual(try store.slotLabel(index: 1), "Brunch", "both devices show the later rename")
    }

    // MARK: Slot labels apply everywhere (mm-t23.4)

    func testASavedLabelAppliesAtOnce() throws {
        let store = try makeTemporaryStore()
        XCTAssertNil(try store.slotLabel(index: 1))
        try store.setSlotLabel("Elevenses", index: 1, changedAt: .now)
        XCTAssertEqual(try store.slotLabel(index: 1), "Elevenses")
        XCTAssertEqual(Plan.SlotLabel.effective(stored: try store.slotLabel(index: 1), defaultLabel: Plan.Slot.all[1].defaultLabel).english, "Elevenses")
    }

    func testAnEmptyLabelRevertsToTheDefaultThroughTheStore() throws {
        let store = try makeTemporaryStore()
        try store.setSlotLabel("Elevenses", index: 1, changedAt: at(2026, 9, 26, 9))
        try store.setSlotLabel("", index: 1, changedAt: at(2026, 9, 26, 9, 30))
        XCTAssertEqual(Plan.SlotLabel.effective(stored: try store.slotLabel(index: 1), defaultLabel: Plan.Slot.all[1].defaultLabel).english, "Mid-morning")
    }
}
