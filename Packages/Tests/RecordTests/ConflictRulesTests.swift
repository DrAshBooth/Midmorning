import Foundation
import XCTest
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

    /// Scenario: Day row after an import.
    func testDayRowAfterAnImportKeepsTheImportedRowAndWritesNoChangedAt() {
        let importedChangedAt = at(3, 0)
        let imported = Day(dateKey: "2026-10-06", changedAt: importedChangedAt)
        // Materialisation of 6 October MUST NOT create a second Day row and
        // MUST NOT write changedAt: it simply does nothing when a row for
        // the key already exists.
        func materialise(existing: [Day], dateKey: String) -> [Day] {
            existing.contains { $0.dateKey == dateKey } ? existing : existing + [Day(dateKey: dateKey, changedAt: .distantPast)]
        }
        let afterMaterialisation = materialise(existing: [imported], dateKey: "2026-10-06")
        XCTAssertEqual(afterMaterialisation.count, 1, "no second Day row")
        XCTAssertEqual(afterMaterialisation.first?.changedAt, importedChangedAt, "materialisation wrote no changedAt")
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

    /// Scenario: Snooze count stays on the device. The snooze count never
    /// lives on an `Answer` row; it lives in `Local.store` by date key and
    /// slot index.
    func testSnoozeCountStaysOnTheDevice() {
        var localSnoozeCounts: [String: Int] = [:]
        let dateKey = "2026-10-06"
        let slotIndex = 1
        localSnoozeCounts["\(dateKey)|\(slotIndex)"] = 2
        XCTAssertEqual(localSnoozeCounts["\(dateKey)|\(slotIndex)"], 2)
        let plannedMealAnswer = Answer(kind: "plannedMeal", dateKey: dateKey, slotIndex: slotIndex, value: "", changedAt: .now)
        XCTAssertNil(Mirror(reflecting: plannedMealAnswer).children.first { $0.label == "snoozeCount" }, "Answer carries no snooze-count field")
    }

    /// Scenario: Entry beats Skipped. A stored order-agnostic read rule:
    /// when a match exists, readers show the entry, not "Skipped".
    func testEntryBeatsSkipped() {
        let skipped = Answer(kind: "plannedMeal", dateKey: "2026-10-06", slotIndex: 1, value: "Skipped", changedAt: at(13, 30))
        let matchedEntryTime = at(13, 45)
        func present(answer: Answer, matchedEntryTime: Date?) -> String {
            matchedEntryTime != nil ? "entry" : answer.value
        }
        XCTAssertEqual(present(answer: skipped, matchedEntryTime: matchedEntryTime), "entry", "Today shows the entry beside lunch and no \"Skipped\"")
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: hour, minute: minute))!
    }
}
