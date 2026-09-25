import Foundation
import XCTest
@testable import Record

/// record spec, "The Today stack" (mm-t12.15). "Card after a starred entry"
/// and "Lapse card in the same record day" run over fixture `TodayCardFact`
/// values, since `programme-engine` (2.1) and `staying-on-track` are not
/// built yet.
final class TodayCardSlotTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func recordDay(_ day: Int) -> DateInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return RecordDay.interval(containing: at(12, 0, day: day), calendar: calendar)
    }

    /// Scenario: Card after a starred entry.
    func testCardAfterAStarredEntryWaitsForTheNextRecordDay() {
        let opening = TodayCardFact(kind: .opening, becameDueAt: at(20, 15))
        let starredAt = at(20, 15)

        let onSave = TodayCardSlot.next(pending: [opening], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(24))
        XCTAssertNil(onSave, "no card shows on the load right after the starred entry")

        let nextMorning = TodayCardSlot.next(pending: [opening], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(25))
        XCTAssertEqual(nextMorning, opening, "the card shows from the next record day")
    }

    /// Scenario: Lapse card in the same record day.
    func testLapseCardShowsInTheSameRecordDayEveryOtherCardWaits() {
        let starredAt = at(14, 10)
        let lapse = TodayCardFact(kind: .maintenancePlan, becameDueAt: at(16, 0))
        let opening = TodayCardFact(kind: .opening, becameDueAt: at(10, 0))

        let winner = TodayCardSlot.next(pending: [opening, lapse], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(24))
        XCTAssertEqual(winner, lapse, "the maintenance plan card shows in the same record day as the starred entry")
    }

    /// The oldest pending card shows first, with no bar in force.
    func testOldestPendingCardShowsFirst() {
        let older = TodayCardFact(kind: .opening, becameDueAt: at(9, 0))
        let newer = TodayCardFact(kind: .suggestion, becameDueAt: at(10, 0))
        let winner = TodayCardSlot.next(pending: [newer, older], starredEntryOrOutcomeAt: nil, currentRecordDay: recordDay(24))
        XCTAssertEqual(winner, older)
    }

    /// No pending card, no starred entry: the slot is empty.
    func testNoPendingCardIsAnEmptySlot() {
        XCTAssertNil(TodayCardSlot.next(pending: [], starredEntryOrOutcomeAt: nil, currentRecordDay: recordDay(24)))
    }
}
