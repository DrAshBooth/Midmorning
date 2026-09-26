import XCTest
@testable import Programme

/// weekly-review spec, "The deterioration rule at the review" (mm-t32.7):
/// the same rule `safeguarding` defines (`DeteriorationRuleTests`), read
/// from the review's own trigger.
final class DeteriorationRuleAtTheReviewTests: XCTestCase {
    /// Scenario: Three rising weeks.
    func testThreeRisingWeeks() {
        XCTAssertTrue(DeteriorationRule.fires(lastFrozenStarredCounts: [2, 3, 4, 5]))
    }

    /// Scenario: Rising but small.
    func testRisingButSmall() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [0, 1, 2, 3]))
    }

    /// Scenario: Rising but not doubled.
    func testRisingButNotDoubled() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [4, 5, 6, 7]))
    }
}
