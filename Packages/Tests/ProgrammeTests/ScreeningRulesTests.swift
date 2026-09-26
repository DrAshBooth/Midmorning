import XCTest
@testable import Programme

/// Safeguarding spec, "Screening rules for age, pregnancy and treatment" and
/// "Screening rules for BMI".
final class ScreeningRulesTests: XCTestCase {
    // MARK: Age, pregnancy, treatment (mm-t14.15)

    func testUnder18Excludes() {
        XCTAssertTrue(ScreeningRules.ageExcludes(17))
    }

    func testExactly18DoesNotExclude() {
        XCTAssertFalse(ScreeningRules.ageExcludes(18))
    }

    func testTreatmentWithAgreementDoesNotExclude() {
        XCTAssertFalse(ScreeningRules.treatmentExcludes(.yesWithAgreement))
    }

    func testTreatmentYesExcludes() {
        XCTAssertTrue(ScreeningRules.treatmentExcludes(.yes))
    }

    func testPregnancyDoesNotApplyDoesNotExclude() {
        XCTAssertFalse(ScreeningRules.pregnancyExcludes(.doesNotApply))
    }

    func testPregnancyYesExcludes() {
        XCTAssertTrue(ScreeningRules.pregnancyExcludes(.yes))
    }

    func testTwoReasonsPregnancyAndTreatment() {
        let reasons = ScreeningRules.onboardingReasons(age: 30, pregnancy: .yes, treatment: .yes, bmi: 22, selfHarm: .noFollowUp)
        XCTAssertEqual(reasons, [.pregnancy, .treatment])
    }

    func testNoReasonsWhenNothingApplies() {
        let reasons = ScreeningRules.onboardingReasons(age: 30, pregnancy: .no, treatment: .no, bmi: 22, selfHarm: .noFollowUp)
        XCTAssertTrue(reasons.isEmpty)
    }

    /// "No Declared Age Range": the rule's only input is the typed age.
    func testAgeRuleReadsOnlyTheTypedAge() {
        // The function signature itself is the proof: `ageExcludes(_ age:
        // Int)` takes no entitlement or system value, only the typed number.
        XCTAssertTrue(ScreeningRules.ageExcludes(17))
        XCTAssertFalse(ScreeningRules.ageExcludes(19))
    }

    // MARK: BMI (mm-t14.17)

    func testBelow18_5Excludes() {
        let bmi = BMI.value(heightCm: 170, weightKg: 53)
        XCTAssertTrue(ScreeningRules.bmiExcludes(bmi))
    }

    func testCautionBand() {
        let bmi = BMI.value(heightCm: 170, weightKg: 54)
        XCTAssertFalse(ScreeningRules.bmiExcludes(bmi))
        XCTAssertTrue(ScreeningRules.cautionFlag(for: bmi))
    }

    func testAboveCautionBand() {
        let bmi = BMI.value(heightCm: 170, weightKg: 55)
        XCTAssertFalse(ScreeningRules.bmiExcludes(bmi))
        XCTAssertFalse(ScreeningRules.cautionFlag(for: bmi))
    }

    func testExactly18_5IsCautionNotExcluded() {
        XCTAssertFalse(ScreeningRules.bmiExcludes(18.50))
        XCTAssertTrue(ScreeningRules.cautionFlag(for: 18.50))
    }

    // MARK: Onboarding order (mm-t14.19 "Two reasons" / "Self-harm first")

    func testExclusionOrderPutsSelfHarmFirst() {
        let reasons = ScreeningRules.onboardingReasons(age: 30, pregnancy: .no, treatment: .no, bmi: 18.0, selfHarm: .excludes)
        XCTAssertEqual(reasons, [.selfHarm, .weight])
    }

    func testExclusionOrderIsFixedRegardlessOfEvaluationOrder() {
        let reasons = ScreeningRules.onboardingReasons(age: 16, pregnancy: .yes, treatment: .yes, bmi: 15, selfHarm: .excludes)
        XCTAssertEqual(reasons, [.selfHarm, .age, .weight, .pregnancy, .treatment])
    }

    /// Scenario "Exactly 18.5" when `Double` puts the BMI a few units in the
    /// last place low: 160 cm and 47.36 kg, and 180 cm and 59.94 kg.
    func testExactly18_5FromHeightAndWeightIsCautionNotExcluded() {
        for (heightCm, weightKg) in [(160.0, 47.36), (180.0, 59.94)] {
            let bmi = BMI.value(heightCm: heightCm, weightKg: weightKg)
            XCTAssertFalse(ScreeningRules.bmiExcludes(bmi), "\(heightCm) cm, \(weightKg) kg")
            XCTAssertTrue(ScreeningRules.cautionFlag(for: bmi), "\(heightCm) cm, \(weightKg) kg")
        }
        XCTAssertFalse(ScreeningRules.cautionFlag(for: 19.0), "19.0 or more sets no caution flag")
    }
}
