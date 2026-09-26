import XCTest
import Constants
@testable import Programme

/// programme spec, "The constants live in one value": "Every threshold test
/// MUST construct a modified ProgrammeConstants value. A test MUST NOT edit
/// `.default`."
final class ConstantsThresholdTests: XCTestCase {
    /// Scenario: A threshold test. Three recorded days, and the real stage
    /// engine with RECORDED_DAYS_FOR_STAGE_2 = 3.
    func testStage2OpensAfterThreeRecordedDaysWithAModifiedValue() {
        var modified = ProgrammeConstants.default
        modified.recordedDaysForStage2 = 3
        let entries = (0..<3).map { i in
            EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 28 + i), starred: false, savedAt: moment(2026, 9, 28 + i, 9))
        }

        func state(_ constants: ProgrammeConstants) -> ProgrammeState {
            StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: [], settings: defaultSettings, constants: constants, now: moment(2026, 9, 30, 10), restartAt: nil, currentRecordDay: dayKey(2026, 9, 30), calendar: engineTestCalendar)
        }

        XCTAssertTrue(state(modified).isOpen(.regularEating), "stage 2 opens after 3 recorded days")
        XCTAssertFalse(state(.default).isOpen(.regularEating), "the shipped gate is still 5")
        XCTAssertEqual(ProgrammeConstants.default.recordedDaysForStage2, 5, ".default still holds 5")
    }
}
