import XCTest
@testable import Programme

/// Safeguarding spec, "No question about vomiting or laxatives" (mm-t14.18).
/// "Weekly review" needs `weekly-review` (mm-t32), which is not merged in
/// this worktree; `mm-t32` gets a follow-up bead to run this same catalog's
/// check against its own question list.
final class ScreeningQuestionCatalogTests: XCTestCase {
    func testScreeningHasNoCompensationQuestion() {
        XCTAssertTrue(ScreeningQuestionCatalog.hasNoCompensationQuestion())
    }

    func testTheCatalogHasExactlySixQuestionsPlusTheSecondSelfHarmQuestion() {
        XCTAssertEqual(ScreeningQuestionCatalog.questions.count, 6)
    }

    func testDetectorCatchesAPlantedCompensationWord() {
        XCTAssertTrue(ScreeningQuestionCatalog.mentionsCompensation("Have you made yourself sick this week?"))
        XCTAssertFalse(ScreeningQuestionCatalog.mentionsCompensation("Your height"))
    }
}
