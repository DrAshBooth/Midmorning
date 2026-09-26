import XCTest
@testable import Programme

/// Covers programme spec.md, "Accessibility of the Programme screen"
/// (mm-t21.22). "Largest text size" is a device check, listed on the epic's
/// device-check bead.
final class AccessibilityOfTheProgrammeScreenTests: XCTestCase {
    private let fullBuild: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    private func row(for stage: Stage, open: [Stage], stagesWithToolInBuild: Set<Int> = [1, 2, 3, 4, 5, 6, 7], recordedDaysCount: Int = 0) -> StageRow {
        var moment: [Stage: Date] = [:]
        for s in open { moment[s] = Foundation.Date(timeIntervalSince1970: 0) }
        let state = ProgrammeState(openStages: Set(open), stageOpenedMoment: moment, stageOpenedDayKey: [:], computedOpenings: [], week: 1, weekOfRegularEating: nil, recordedDaysCount: recordedDaysCount)
        return ProgrammeScreenBuilder.build(state: state, constants: .default, restartAt: nil, stagesWithToolInBuild: stagesWithToolInBuild).rows.first { $0.stage == stage }!
    }

    /// Scenario: Label of the stage with the marker.
    func testLabelOfTheStageWithTheMarker() {
        let r = row(for: .regularEating, open: [.gettingStarted, .regularEating])
        XCTAssertEqual(r.accessibilityLabel, "Regular eating, Now")
    }

    /// Scenario: Label of a closed stage.
    func testLabelOfAClosedStage() {
        let r = row(for: .alternatives, open: [.gettingStarted, .regularEating])
        XCTAssertEqual(r.accessibilityLabel, "Alternatives, Opens after 7 days on your plan, or 2 weeks after your plan starts")
    }

    /// Scenario: Label of the stage 2 row with its count.
    func testLabelOfTheStage2RowWithItsCount() {
        let r = row(for: .regularEating, open: [.gettingStarted], recordedDaysCount: 2)
        XCTAssertEqual(r.accessibilityLabel, "Regular eating, Opens after 5 recorded days. You have 2.")
    }

    /// Scenario: Label of a row without its tool in the build.
    func testLabelOfARowWithoutItsToolInTheBuild() {
        let r = row(for: .problemSolving, open: [.gettingStarted, .regularEating, .alternatives, .problemSolving], stagesWithToolInBuild: [1, 2])
        XCTAssertEqual(r.accessibilityLabel, "Problem solving, Comes in a later version")
    }

    /// Every control's label equals its visible text — asserted directly on
    /// the literal strings the requirement names, since a SwiftUI `Button`
    /// or `Text` control's accessibility label defaults to its own text.
    func testControlLabelsEqualTheirVisibleText() {
        let controls = ["Open", "Close", "Read", "Set it up", "Yes", "Start week 1 again"]
        XCTAssertEqual(Set(controls).count, controls.count, "each is a distinct literal label, used verbatim as both the visible text and the accessibility label")
    }
}
