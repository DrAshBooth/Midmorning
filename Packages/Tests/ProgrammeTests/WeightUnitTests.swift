import XCTest
@testable import Programme

/// weigh-in spec, "The number and its unit" (mm-t22.4).
final class WeightUnitTests: XCTestCase {
    /// Scenario: Kilograms.
    func testKilograms() {
        XCTAssertEqual(WeighInWeight.storedKg(66.8), 66.80)
    }

    /// Scenario: Stone and pounds.
    func testStoneAndPounds() {
        let kg = WeighInWeight.kg(stone: 10, pounds: 7)
        XCTAssertEqual(WeighInWeight.storedKg(kg), 66.68)
    }

    /// Scenario: Below the range.
    func testBelowTheRange() {
        XCTAssertEqual(WeighInWeight.validate(kg: 6.8), .belowRange)
        XCTAssertEqual(WeighInWeight.belowRangeMessage.english, "That number is outside the range the app accepts. Check it and try again.")
    }

    /// Scenario: No upper bound.
    func testNoUpperBound() {
        XCTAssertEqual(WeighInWeight.validate(kg: 312.4), .valid(kg: 312.4))
        XCTAssertEqual(WeighInWeight.storedKg(312.4), 312.40)
    }

    /// Scenario: Unit change after weigh-ins.
    func testUnitChangeAfterWeighIns() {
        XCTAssertEqual(WeighInWeight.display(kg: 66.80, unit: .stLb), "10 st 7 lb")
    }

    /// Scenario: Whole pounds on display.
    func testWholePoundsOnDisplay() {
        XCTAssertEqual(WeighInWeight.display(kg: 66.40, unit: .stLb), "10 st 6 lb")
    }

    func testDisplayInKilograms() {
        XCTAssertEqual(WeighInWeight.display(kg: 66.8, unit: .kg), "66.8 kg")
    }

    /// The 30 kg floor is `ProgrammeConstants.minWeightKg`, not a repeated
    /// literal (`onboarding`'s own `ScreeningLimits` reads the same field).
    func testFloorIsThirtyKilograms() {
        XCTAssertEqual(WeighInWeight.validate(kg: 30), .valid(kg: 30))
        XCTAssertEqual(WeighInWeight.validate(kg: 29.9), .belowRange)
    }
}
