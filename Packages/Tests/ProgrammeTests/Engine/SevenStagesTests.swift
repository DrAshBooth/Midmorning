import XCTest
import Constants
@testable import Programme

/// Covers programme spec.md, "The seven stages and their tools" (mm-t21.1).
/// "Earlier tools stay open" is `deferred: mm-t31.15` (it needs the
/// alternatives-list tool this build does not have).
final class SevenStagesTests: XCTestCase {
    /// Scenario: Order on the Programme screen.
    func testOrderOnPagesTheProgrammeScreen() {
        XCTAssertEqual(Stage.orderedByStage.map(\.title), [
            "Getting started", "Regular eating", "Alternatives", "Problem solving",
            "Taking stock", "Modules", "Staying on track",
        ])
    }

    /// Scenario: A tool before its stage.
    func testATooBeforeItsStage() {
        let state = Programme.state(
            facts: ProgrammeFacts(), openings: [], settings: defaultSettings, constants: .default,
            now: moment(2026, 9, 28), restartAt: nil, currentRecordDay: dayKey(2026, 9, 28), calendar: engineTestCalendar
        )
        XCTAssertFalse(state.isOpen(.alternatives))
        let screen = ProgrammeScreenBuilder.build(state: state, constants: .default, restartAt: nil, stagesWithToolInBuild: [1, 2])
        let row = screen.rows.first { $0.stage == .alternatives }!
        XCTAssertTrue(row.toolNames.isEmpty, "no Urge button and no alternatives list while stage 3 is closed")
    }
}
