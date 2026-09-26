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
        XCTAssertEqual(ScreeningLimits.weightMessage().english, "Enter a weight of 30 kg or more.")
    }

    func testHeightOutsideTheRange() {
        XCTAssertEqual(ScreeningLimits.validate(heightCm: 90), .tooLow)
        XCTAssertEqual(ScreeningLimits.heightMessage().english, "Enter a height between 100 cm and 250 cm.")
    }

    /// Ruling r13-11: with "ft in" chosen, the message gives the limits in
    /// feet and inches, rounded inward, so the app accepts both values it
    /// shows and refuses the next inch outside them.
    func testTheHeightMessageInFeetAndInchesRoundsInward() {
        XCTAssertEqual(ScreeningLimits.heightMessage(unit: .ftIn).english, "Enter a height between 3 ft 4 in and 8 ft 2 in.")
        XCTAssertEqual(ScreeningLimits.validate(heightCm: BMI.heightCm(feet: 3, inches: 4)), .valid)
        XCTAssertEqual(ScreeningLimits.validate(heightCm: BMI.heightCm(feet: 8, inches: 2)), .valid)
        XCTAssertEqual(ScreeningLimits.validate(heightCm: BMI.heightCm(feet: 3, inches: 3)), .tooLow)
        XCTAssertEqual(ScreeningLimits.validate(heightCm: BMI.heightCm(feet: 8, inches: 3)), .tooHigh)
    }

    /// Ruling r13-11: with "st lb" chosen, the message gives the limit in
    /// stone and pounds, rounded inward.
    func testTheWeightMessageInStoneAndPoundsRoundsInward() {
        XCTAssertEqual(ScreeningLimits.weightMessage(unit: .stLb).english, "Enter a weight of 4 st 11 lb or more.")
        XCTAssertEqual(ScreeningLimits.validate(weightKg: BMI.weightKg(stone: 4, pounds: 11)), .valid)
        XCTAssertEqual(ScreeningLimits.validate(weightKg: BMI.weightKg(stone: 4, pounds: 10)), .tooLow)
    }

    /// The imperial limits come from the cm and kg constants, not from a
    /// second copy of the limits.
    func testTheImperialLimitsFollowTheConstants() {
        var constants = ProgrammeConstants.default
        constants.minHeightCm = 150
        constants.maxHeightCm = 200
        constants.minWeightKg = 40
        XCTAssertEqual(ScreeningLimits.heightMessage(unit: .cm, constants: constants).english, "Enter a height between 150 cm and 200 cm.")
        XCTAssertEqual(ScreeningLimits.heightMessage(unit: .ftIn, constants: constants).english, "Enter a height between 5 ft 0 in and 6 ft 6 in.")
        XCTAssertEqual(ScreeningLimits.weightMessage(unit: .kg, constants: constants).english, "Enter a weight of 40 kg or more.")
        XCTAssertEqual(ScreeningLimits.weightMessage(unit: .stLb, constants: constants).english, "Enter a weight of 6 st 5 lb or more.")
        for constants in [ProgrammeConstants.default, constants] {
            let inches = ScreeningLimits.heightLimitsInInches(constants: constants)
            for total in [inches.lowerBound, inches.upperBound] {
                XCTAssertEqual(ScreeningLimits.validate(heightCm: BMI.heightCm(feet: total / 12, inches: total % 12), constants: constants), .valid)
            }
            let pounds = ScreeningLimits.weightLimitInPounds(constants: constants)
            XCTAssertEqual(ScreeningLimits.validate(weightKg: BMI.weightKg(stone: pounds / 14, pounds: pounds % 14), constants: constants), .valid)
            XCTAssertEqual(ScreeningLimits.validate(weightKg: BMI.weightKg(stone: (pounds - 1) / 14, pounds: (pounds - 1) % 14), constants: constants), .tooLow)
        }
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
