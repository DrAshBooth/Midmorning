import XCTest
import Constants
@testable import Programme

/// Covers programme spec.md, "Reading ahead is never blocked" (mm-t21.8).
/// "Stage 4 cards on day 1" is `deferred: mm-t33.16`.
final class ReadingAheadTests: XCTestCase {
    private func state(entries: [EntryFact], now: Date = moment(2026, 10, 1)) -> ProgrammeState {
        StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: .default, now: now, restartAt: nil, currentRecordDay: dayKey(2026, 10, 1), calendar: engineTestCalendar)
    }

    /// Scenario: A closed stage's row.
    func testAClosedStagesRow() {
        let entries = (0..<2).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 28 + i), starred: false, savedAt: moment(2026, 9, 28 + i, 9)) }
        let s = state(entries: entries, now: moment(2026, 9, 30))
        XCTAssertEqual(StageRuleText.string(for: .regularEating, constants: .default, recordedDaysCount: s.recordedDaysCount), "Opens after 5 recorded days. You have 2.")
    }

    /// Scenario: The count before any entry.
    func testTheCountBeforeAnyEntry() {
        let s = state(entries: [])
        XCTAssertEqual(StageRuleText.string(for: .regularEating, constants: .default, recordedDaysCount: s.recordedDaysCount), "Opens after 5 recorded days. You have 0.")
    }

    /// Scenario: A gate changes.
    func testAGateChanges() {
        var constants = ProgrammeConstants.default
        constants.recordedDaysForStage2 = 3
        let entries = [EntryFact(id: "1", dayKey: dayKey(2026, 9, 28), starred: false, savedAt: moment(2026, 9, 28, 9))]
        let s = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: constants, now: moment(2026, 9, 29), restartAt: nil, currentRecordDay: dayKey(2026, 9, 29), calendar: engineTestCalendar)
        XCTAssertFalse(s.isOpen(.regularEating))
        XCTAssertEqual(StageRuleText.string(for: .regularEating, constants: constants, recordedDaysCount: s.recordedDaysCount), "Opens after 3 recorded days. You have 1.")
    }

    /// The stage 3 rule string, checked directly against
    /// `RECORD_DAYS_FOR_STAGE_3_FALLBACK`'s default (also asserted as a
    /// multiple of 7 in `ProgrammeConstantsTests`).
    func testTheStage3RuleString() {
        XCTAssertEqual(StageRuleText.stage3(constants: .default), "Opens after 7 days on your plan, or 2 weeks after your plan starts")
    }
}
