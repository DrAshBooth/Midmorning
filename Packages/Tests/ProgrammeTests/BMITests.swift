import XCTest
import Constants
@testable import Programme

/// Onboarding spec, "The one-time BMI" (mm-t14.5).
final class BMITests: XCTestCase {
    func testMetricInput() {
        let bmi = BMI.value(heightCm: 170, weightKg: 60)
        XCTAssertEqual(BMI.rounded(bmi), 20.76)
    }

    func testImperialInput() {
        let heightCm = BMI.heightCm(feet: 5, inches: 7)
        let weightKg = BMI.weightKg(stone: 8, pounds: 7)
        XCTAssertEqual(BMI.rounded(heightCm), 170.18)
        XCTAssertEqual(BMI.rounded(weightKg), 53.98)
        XCTAssertEqual(BMI.rounded(BMI.value(heightCm: heightCm, weightKg: weightKg)), 18.64)
    }

    func testWeightBelowTheRange() {
        XCTAssertEqual(ScreeningLimits.validate(weightKg: 20), .tooLow)
        XCTAssertEqual(ScreeningLimits.weightMessage(), "Enter a weight of 30 kg or more.")
    }

    func testHeightOutsideTheRange() {
        XCTAssertEqual(ScreeningLimits.validate(heightCm: 90), .tooLow)
        XCTAssertEqual(ScreeningLimits.heightMessage(), "Enter a height between 100 and 250 cm.")
    }

    func testHeightAboveTheRange() {
        XCTAssertEqual(ScreeningLimits.validate(heightCm: 300), .tooHigh)
    }

    func testNoUpperWeightBound() {
        XCTAssertEqual(ScreeningLimits.validate(weightKg: 320), .valid)
        let bmi = BMI.value(heightCm: 170, weightKg: 320)
        XCTAssertEqual(BMI.rounded(bmi), 110.73)
    }

    /// "BMI on no screen": the type this module exposes never formats a BMI
    /// for display; the app only ever passes the raw value to `ScreeningRules`.
    func testConstantsSuppliesTheLimits() {
        let constants = ProgrammeConstants.default
        XCTAssertEqual(constants.minHeightCm, 100)
        XCTAssertEqual(constants.maxHeightCm, 250)
        XCTAssertEqual(constants.minWeightKg, 30)
    }
}
