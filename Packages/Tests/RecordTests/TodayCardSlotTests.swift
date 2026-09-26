import Foundation
import XCTest
@testable import Record
@testable import Programme

/// record spec, "The Today stack" (mm-t12.15). `TodayCardSlot` lives in
/// `Programme` and picks from `PendingCard`. No card of this build is the
/// stage 7 lapse card, so "Lapse card in the same record day" runs over a
/// fixture card until `staying-on-track` makes the real one.
final class TodayCardSlotTests: XCTestCase {
    /// A fixture card: `lapse` is the stage 7 maintenance plan card.
    private struct FixtureCard: TodayCardCandidate, Equatable {
        let name: String
        let becameDueAt: Date
        var lapse = false
        var showsInABarredRecordDay: Bool { lapse }
    }

    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func recordDay(_ day: Int) -> DateInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return RecordDay.interval(containing: at(12, 0, day: day), calendar: calendar, schedule: .standard)
    }

    /// Scenario: Card after a starred entry.
    func testCardAfterAStarredEntryWaitsForTheNextRecordDay() {
        let opening = PendingCard(id: "opening.2", kind: .opening, becameDueAt: at(20, 15))
        let starredAt = at(20, 15)

        let onSave = TodayCardSlot.next(pending: [opening], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(24))
        XCTAssertNil(onSave, "no card shows on the load right after the starred entry")

        let nextMorning = TodayCardSlot.next(pending: [opening], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(25))
        XCTAssertEqual(nextMorning, opening, "the card shows from the next record day")
    }

    /// Scenario: Lapse card in the same record day.
    func testLapseCardShowsInTheSameRecordDayEveryOtherCardWaits() {
        let starredAt = at(14, 10)
        let lapse = FixtureCard(name: "maintenancePlan", becameDueAt: at(16, 0), lapse: true)
        let opening = FixtureCard(name: "opening", becameDueAt: at(10, 0))

        let winner = TodayCardSlot.next(pending: [opening, lapse], starredEntryOrOutcomeAt: starredAt, currentRecordDay: recordDay(24))
        XCTAssertEqual(winner, lapse, "the maintenance plan card shows in the same record day as the starred entry")
    }

    /// No card that this build makes shows in a barred record day.
    func testNoPendingCardOfThisBuildIsTheLapseCard() {
        for kind in [PendingCard.Kind.opening, .stage1, .plan] {
            XCTAssertFalse(PendingCard(id: "x", kind: kind, becameDueAt: at(9, 0)).showsInABarredRecordDay)
        }
    }

    /// The oldest pending card shows first, with no bar in force.
    func testOldestPendingCardShowsFirst() {
        let older = PendingCard(id: "opening.2", kind: .opening, becameDueAt: at(9, 0))
        let newer = PendingCard(id: "plan", kind: .plan, becameDueAt: at(10, 0))
        let winner = TodayCardSlot.next(pending: [newer, older], starredEntryOrOutcomeAt: nil, currentRecordDay: recordDay(24))
        XCTAssertEqual(winner, older)
    }

    /// No pending card, no starred entry: the slot is empty.
    func testNoPendingCardIsAnEmptySlot() {
        XCTAssertNil(TodayCardSlot.next(pending: [PendingCard](), starredEntryOrOutcomeAt: nil, currentRecordDay: recordDay(24)))
    }
}
