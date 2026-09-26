import XCTest
@testable import Programme

/// Covers programme spec.md, "Today is home" (mm-t21.2). "Launch after a
/// stage opened while the app was closed" is `deferred: mm-t32b.3`. "One tap
/// to each screen" and "Before the first weekly review" are `Record`'s own
/// `BottomToolbar.items(reviewsDue:)`, already proved by
/// `RecordTests.TodayStackTests.testReviewsInTheBottomToolbar` and
/// `.testNoReviewsBeforeTheFirstOneIsDue`; `mm-t32.16` runs "One tap to each
/// screen" end to end with a live "review due" fact.
final class TodayIsHomeTests: XCTestCase {
    /// The "Getting started" line shows exactly while stage 2 is closed
    /// (programme spec: "From the end of onboarding until stage 2 opens...
    /// When stage 2 opens, the app MUST take the line off Today.").
    private func showsGettingStartedLine(_ state: ProgrammeState) -> Bool { !state.isOpen(.regularEating) }

    /// Scenario: Launch on day 1.
    func testLaunchOnDay1() {
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 9, 28), restartAt: nil, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar)
        XCTAssertTrue(showsGettingStartedLine(s))
    }

    /// Scenario: Launch in stage 3.
    func testLaunchInStage3() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 1, 9)), StageOpenedRecord(stage: 3, moment: moment(2026, 10, 10, 4))]
        let s = StageEngine.state(facts: ProgrammeFacts(), openings: openings, settings: defaultSettings, constants: .default, now: moment(2026, 10, 20), restartAt: nil, currentRecordDay: dayKey(2026, 10, 20), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.alternatives))
        XCTAssertFalse(showsGettingStartedLine(s), "stage 2 (and so the plan beside the record) is already open")
    }

    /// Scenario: The "Getting started" line in week 3 with stage 2 closed.
    func testTheGettingStartedLineInWeek3WithStage2Closed() {
        let entries = (0..<3).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, 12 + i), starred: false, savedAt: moment(2026, 10, 12 + i, 9)) }
        let s = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 14), restartAt: nil, currentRecordDay: dayKey(2026, 10, 14), calendar: engineTestCalendar)
        XCTAssertEqual(s.week, 3)
        XCTAssertFalse(s.isOpen(.regularEating))
        XCTAssertTrue(showsGettingStartedLine(s))
    }

    /// Scenario: The "Getting started" line when stage 2 opens.
    func testTheGettingStartedLineWhenStage2Opens() {
        let entries = (0..<5).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 9)) }
        let s = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default, now: moment(2026, 10, 3, 10), restartAt: nil, currentRecordDay: dayKey(2026, 10, 3), calendar: engineTestCalendar)
        XCTAssertTrue(s.isOpen(.regularEating))
        XCTAssertFalse(showsGettingStartedLine(s), "from the next Today load, the line is gone")
    }
}
