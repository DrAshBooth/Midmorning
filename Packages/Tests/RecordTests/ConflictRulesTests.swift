import Foundation
import SwiftData
import XCTest
import Plan
@testable import Record

/// data-and-privacy spec, "Conflict rules for the plan, weigh-ins and lists".
final class ConflictRulesTests: XCTestCase {
    /// Scenario: Planned day edited on both devices.
    func testPlannedDayEditedOnBothDevicesTheLaterWholeRowWins() {
        let deviceA = Day(dateKey: "2026-10-06", slotsJSON: "[{\"slot\":1,\"time\":\"13:30\"}]", changedAt: at(8, 0))
        let deviceB = Day(dateKey: "2026-10-06", slotsJSON: "[{\"slot\":4,\"time\":\"19:00\"}]", changedAt: at(8, 5))
        let winner = DayReconciler.winners(in: [deviceA, deviceB])["2026-10-06"]!
        XCTAssertEqual(winner.slotsJSON, deviceB.slotsJSON, "device B's whole planned day wins; lunch keeps its previous time, not device A's edit")
    }

    /// Scenario: Skip on one device, plan edit on the other.
    func testSkipOnOneDevicePlanEditOnTheOtherBothSurvive() {
        let skip = Answer(kind: "plannedMeal", dateKey: "2026-10-06", slotIndex: 1, value: "Skipped", changedAt: at(13, 40))
        let planEdit = Day(dateKey: "2026-10-06", changedAt: at(14, 0))
        let answerWinner = AnswerReconciler.winners(in: [skip])["plannedMeal|2026-10-06|1"]
        XCTAssertEqual(answerWinner?.value, "Skipped", "both devices keep the skip")
        XCTAssertEqual(DayReconciler.winners(in: [planEdit])["2026-10-06"]?.dateKey, "2026-10-06", "and show device B's planned day")
    }

    /// Scenario: Two weigh-ins on the weigh-in day.
    func testTwoWeighInsOnTheWeighInDayTheLaterOneWins() {
        let early = Measure(dateKey: "2026-10-11", weightKg: 61.2, changedAt: at(7, 0))
        let later = Measure(dateKey: "2026-10-11", weightKg: 61.0, changedAt: at(7, 30))
        let winners = MeasureReconciler.winners(in: [early, later])
        XCTAssertEqual(winners.count, 1, "the store never keeps two weigh-ins for one weigh-in day")
        XCTAssertEqual(winners["2026-10-11"]?.weightKg, 61.0, "the 07:30 weigh-in only; the store never averages")
    }

    /// Scenario: Alternatives list on two devices.
    func testAlternativesListOnTwoDevicesUnionsByDistinctId() {
        let walk = ListItem(kind: "alternative", text: "Walk round the block", changedAt: at(9, 0))
        let ring = ListItem(kind: "alternative", text: "Ring Sam", changedAt: at(9, 5))
        let merged = ListItemReconciler.merged([walk, ring])
        XCTAssertEqual(Set(merged.map(\.text)), ["Walk round the block", "Ring Sam"], "both items, from two offline devices")
    }

    /// Scenario: Day row after an import. The import writes a Day row
    /// straight into the store; then the real materialisation of the same
    /// key runs.
    @MainActor
    func testDayRowAfterAnImportKeepsTheImportedRowAndWritesNoChangedAt() throws {
        let store = try makeStore()
        let importedChangedAt = at(3, 0)
        let importedSlots = "[{\"slotIndex\":2,\"time\":\"13:30\"}]"
        let importContext = ModelContext(store.container)
        importContext.insert(Day(dateKey: "2026-10-06", slotsJSON: importedSlots, changedAt: importedChangedAt))
        try importContext.save()

        let wrote = try store.materialiseDayFromTemplate(dateKey: "2026-10-06", slotsJSON: "[]", windowBeforeMinutes: 60, windowAfterMinutes: 90)

        XCTAssertFalse(wrote, "materialisation writes nothing for a key the store already holds")
        let rows = try ModelContext(store.container).fetch(FetchDescriptor<Day>())
        XCTAssertEqual(rows.count, 1, "no second Day row")
        XCTAssertEqual(rows.first?.changedAt, importedChangedAt, "materialisation wrote no changedAt")
        XCTAssertEqual(try store.dayPlan(dateKey: "2026-10-06")?.slotsJSON, importedSlots, "the store keeps the imported row")
    }

    /// Scenario: Set event.
    func testSetEventIsStickyAcrossALaterPlanEdit() {
        let setOnDeviceA = Day(dateKey: "2026-10-06", changedAt: at(9, 0), setAt: at(9, 0), setBy: "device-a")
        let laterEditOnDeviceB = Day(dateKey: "2026-10-06", slotsJSON: "[{\"slot\":2}]", changedAt: at(9, 5))
        let winner = DayReconciler.winners(in: [setOnDeviceA, laterEditOnDeviceB])["2026-10-06"]!
        XCTAssertEqual(winner.setAt, at(9, 0))
        XCTAssertEqual(winner.setBy, "device-a")
        XCTAssertEqual(winner.slotsJSON, laterEditOnDeviceB.slotsJSON, "device B reads the set event and the later plan payload together")
    }

    /// Scenario: Snooze count stays on the device. The real snooze counter
    /// writes to `Local.store`; the synced store gains no `Answer` row, and
    /// the frozen `Answer` record type has no count field.
    @MainActor
    func testSnoozeCountStaysOnTheDevice() throws {
        let store = try makeStore()
        try store.setSnoozeCount(1, dateKey: "2026-10-06", slotIndex: 2)
        try store.setSnoozeCount(2, dateKey: "2026-10-06", slotIndex: 2)

        XCTAssertEqual(try store.snoozeCount(dateKey: "2026-10-06", slotIndex: 2), 2, "device A holds 2 for that date key and slot index")
        XCTAssertEqual(try store.snoozeCount(dateKey: "2026-10-06", slotIndex: 4), 0, "the count is per slot")
        XCTAssertTrue(try ModelContext(store.container).fetch(FetchDescriptor<Answer>()).isEmpty, "no Answer row carries a count")
        XCTAssertTrue(try store.plannedMealAnswers(dateKey: "2026-10-06").isEmpty)
        XCTAssertFalse(FrozenSchema.currentFields()["Answer"]!.keys.contains { $0.lowercased().contains("snooze") }, "Answer carries no snooze-count field")
    }

    /// Scenario: Entry beats Skipped. The same composition as Today's plan
    /// rows (`PlanToday.load`): the real store's "Skipped" answer and entry,
    /// the real window match and the real `PlannedMealDisplay` decision.
    @MainActor
    func testEntryBeatsSkipped() throws {
        let store = try makeStore()
        let london = TimeZone(identifier: "Europe/London")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = london
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:30")]), windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: at(8, 0), setBy: "device-a", changedAt: at(8, 0))
        try store.setPlannedMealAnswer("Skipped", dateKey: "2026-10-06", slotIndex: 2, changedAt: at(13, 30))
        try store.add(time: at(13, 45), what: "Soup", feltLikeABinge: false, createdAt: at(13, 50), utcOffsetSeconds: london.secondsFromGMT(for: at(13, 45)))

        let plan = try XCTUnwrap(store.dayPlan(dateKey: "2026-10-06"))
        let recordDay = RecordDay.interval(containing: at(12, 0), calendar: calendar, startHour: RecordDay.startHour)
        let windows = PlanWindows.windows(for: PlanCodec.decode(plan.slotsJSON), recordDay: recordDay, dayStartHour: 4, beforeMinutes: plan.windowBeforeMinutes, afterMinutes: plan.windowAfterMinutes, calendar: calendar)
        let entries = try store.entries(dayKey: "2026-10-06")
        let matches = PlanMatching.match(windows: windows, entries: entries.map { PlanEntryFact(id: $0.id, time: $0.time) })
        let matched = matches[2].flatMap { id in entries.first { $0.id == id } }
        let isSkipped = try store.plannedMealAnswer(dateKey: "2026-10-06", slotIndex: 2) == "Skipped"

        XCTAssertTrue(isSkipped, "the store keeps the skip")
        XCTAssertEqual(PlannedMealDisplay.content(matchedEntry: matched.map { ($0.clockTime, $0.what) }, isSkipped: isSkipped), .matched(entryTime: "13:45", what: "Soup"), "Today shows the entry beside lunch and no \"Skipped\"")
    }

    @MainActor
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: hour, minute: minute))!
    }
}
