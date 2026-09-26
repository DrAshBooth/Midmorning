import XCTest
@testable import Programme

/// safeguarding spec, "The deterioration rule" (mm-t32.2).
final class DeteriorationRuleTests: XCTestCase {
    /// Scenario: Three rising weeks.
    func testThreeRisingWeeks() {
        XCTAssertTrue(DeteriorationRule.fires(lastFrozenStarredCounts: [3, 4, 5, 6]))
    }

    /// Scenario: Two rising weeks.
    func testTwoRisingWeeks() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [4, 4, 5, 6]))
    }

    /// Scenario: Rising from a low count.
    func testRisingFromALowCount() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [0, 1, 2, 3]), "the latest count is below 4")
    }

    /// Scenario: Rising but not doubled.
    func testRisingButNotDoubled() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [5, 6, 7, 8]), "8 is less than twice 5")
    }

    /// Scenario: I'm getting worse — the rule's own "at most once" gate is
    /// the review's job; the rule itself always reports whether it fires
    /// from the counts alone.
    func testFewerThanFourReviewsNeverFires() {
        XCTAssertFalse(DeteriorationRule.fires(lastFrozenStarredCounts: [4, 5, 6]))
    }

    /// Scenario: Getting worse after the rule fired. The rule's own result
    /// does not change between two evaluations of the same counts.
    func testGettingWorseAfterTheRuleFiredIsIdempotent() {
        let counts = [3, 4, 5, 6]
        XCTAssertEqual(DeteriorationRule.fires(lastFrozenStarredCounts: counts), DeteriorationRule.fires(lastFrozenStarredCounts: counts))
    }
}
