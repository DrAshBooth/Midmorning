import XCTest
@testable import Programme

/// weigh-in spec, "The one-line explanation" (mm-t22.7).
final class WeighInExplanationTests: XCTestCase {
    /// Scenario: Explanation in kilograms.
    func testExplanationInKilograms() {
        XCTAssertEqual(WeighInExplanation.text(unit: .kg).english, "Weekly swings of a kilo or two are normal and mean nothing on their own.")
    }

    /// Scenario: Explanation in stone and pounds.
    func testExplanationInStoneAndPounds() {
        XCTAssertEqual(WeighInExplanation.text(unit: .stLb).english, "Weekly swings of two or three pounds are normal and mean nothing on their own.")
    }

    /// Scenario: After a save. The function takes only the unit, so a saved
    /// value can never change its output — the screen has no other text
    /// about the change to show.
    func testAfterASaveTheSentenceIsUnchanged() {
        XCTAssertEqual(WeighInExplanation.text(unit: .kg), WeighInExplanation.text(unit: .kg))
    }
}
