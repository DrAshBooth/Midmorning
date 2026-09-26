import Foundation
import XCTest
@testable import Record
@testable import Programme

/// Proves the composition of `Programme`'s pending-card output with
/// `Record`'s `TodayCardSlot`, the seam the App target wires (programme
/// spec, "No opening card after a binge in the same record day", mm-t21.12,
/// and "Two stage 1 cards come to Today"'s own starred-entry scenario,
/// mm-t21.13). `TodayCardSlotTests` already proves the generic barring rule
/// over fixture facts; this proves `Programme`'s own output feeds it
/// correctly.
final class PendingCardsCompositionTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func map(_ card: PendingCard) -> TodayCardFact {
        let kind: TodayCardFact.Kind
        switch card.kind {
        case .opening: kind = .opening
        case .stage1: kind = .stage1
        case .plan: kind = .plan
        }
        return TodayCardFact(kind: kind, becameDueAt: card.becameDueAt)
    }

    /// Scenario: The fifth recorded day ends with a starred entry.
    func testTheFifthRecordedDayEndsWithAStarredEntry() {
        let settings = ProgrammeSettings(startDay: "2026-09-28", dayStart: RecordDay.startHour)
        let unstarredDays = [29, 30].map { at(2026, 9, $0, 9) } + [at(2026, 10, 1, 9), at(2026, 10, 2, 9)]
        let entries = unstarredDays.enumerated().map { i, moment in
            EntryFact(id: "\(i)", dayKey: RecordDay.key(containing: moment, calendar: london), starred: false, savedAt: moment)
        }
        let starredMoment = at(2026, 10, 3, 22, 10)
        let starred = EntryFact(id: "starred", dayKey: RecordDay.key(containing: starredMoment, calendar: london), starred: true, savedAt: starredMoment)
        let facts = ProgrammeFacts(entries: entries + [starred])

        let sameDayNow = at(2026, 10, 3, 22, 15)
        let sameDayKey = RecordDay.key(containing: sameDayNow, calendar: london)
        let state = Programme.state(facts: facts, openings: [], settings: settings, constants: .default, now: sameDayNow, restartAt: nil, currentRecordDay: sameDayKey, calendar: london)
        XCTAssertTrue(state.isOpen(.regularEating), "the stage opens at once")

        let pending = Programme.pendingCards(state: state, facts: facts, cardAnswers: [], stagesWithToolInBuild: [1, 2], hasTemplate: true, currentRecordDay: sameDayKey, settings: settings, calendar: london)
            .map(map)

        let sameDayInterval = RecordDay.interval(containing: sameDayNow, calendar: london)
        XCTAssertNil(TodayCardSlot.next(pending: pending, starredEntryOrOutcomeAt: starredMoment, currentRecordDay: sameDayInterval), "no opening card that record day")

        let nextMorning = at(2026, 10, 4, 9)
        let nextDayInterval = RecordDay.interval(containing: nextMorning, calendar: london)
        XCTAssertEqual(TodayCardSlot.next(pending: pending, starredEntryOrOutcomeAt: nil, currentRecordDay: nextDayInterval), pending.first, "the card appears the first time Today appears after 04:00")
    }

    /// Scenario: A starred entry makes the second recorded day (programme
    /// spec, "Two stage 1 cards come to Today").
    func testAStarredEntryMakesTheSecondRecordedDay() {
        let settings = ProgrammeSettings(startDay: "2026-09-28", dayStart: RecordDay.startHour)
        let first = at(2026, 10, 1, 9)
        let starredMoment = at(2026, 10, 2, 21)
        let entries = [
            EntryFact(id: "1", dayKey: RecordDay.key(containing: first, calendar: london), starred: false, savedAt: first),
            EntryFact(id: "2", dayKey: RecordDay.key(containing: starredMoment, calendar: london), starred: true, savedAt: starredMoment),
        ]
        let facts = ProgrammeFacts(entries: entries)
        let sameDayNow = at(2026, 10, 2, 21, 5)
        let sameDayKey = RecordDay.key(containing: sameDayNow, calendar: london)
        let state = Programme.state(facts: facts, openings: [], settings: settings, constants: .default, now: sameDayNow, restartAt: nil, currentRecordDay: sameDayKey, calendar: london)
        let pending = Programme.pendingCards(state: state, facts: facts, cardAnswers: [], stagesWithToolInBuild: [1, 2], hasTemplate: true, currentRecordDay: sameDayKey, settings: settings, calendar: london).map(map)

        let sameDayInterval = RecordDay.interval(containing: sameDayNow, calendar: london)
        XCTAssertNil(TodayCardSlot.next(pending: pending, starredEntryOrOutcomeAt: starredMoment, currentRecordDay: sameDayInterval), "no card that record day")

        let nextMorning = at(2026, 10, 3, 9)
        let nextDayInterval = RecordDay.interval(containing: nextMorning, calendar: london)
        let winner = TodayCardSlot.next(pending: pending, starredEntryOrOutcomeAt: nil, currentRecordDay: nextDayInterval)
        XCTAssertEqual(winner?.kind, .stage1, "'Why write it down' shows the first time Today appears after 04:00")
    }
}
