import XCTest
@testable import Programme

/// Safeguarding spec, "Screening rules for BMI" and "Screening rules for age,
/// pregnancy and treatment", through the screen 2 decision that
/// `OnboardingRootView` calls (mm-t14.33).
final class OnboardingScreeningTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_758_700_000)

    private func evaluate(age: Int = 34, heightCm: Double = 170, weightKg: Double, selfHarm: SelfHarmOutcome = .noFollowUp) -> OnboardingScreeningOutcome {
        OnboardingScreening.evaluate(age: age, heightCm: heightCm, weightKg: weightKg, pregnancy: .no, treatment: .no, selfHarm: selfHarm, now: now)
    }

    /// Scenario "Below 18.5".
    func testBelow18Point5() {
        XCTAssertEqual(evaluate(weightKg: 53), .excluded([.weight]))
    }

    /// Scenario "Caution band".
    func testCautionBand() {
        guard case .cautionSheet(let kept) = evaluate(weightKg: 54) else { return XCTFail() }
        XCTAssertTrue(kept.cautionFlag)
        XCTAssertEqual(kept.askedAt, now)
    }

    /// Scenario "Above the caution band".
    func testAboveTheCautionBand() {
        guard case .continues(let kept) = evaluate(weightKg: 55) else { return XCTFail() }
        XCTAssertFalse(kept.cautionFlag)
        XCTAssertEqual(BMI.rounded(kept.onboardingBMI), 19.03)
    }

    /// The rules read the unrounded BMI: 174 cm and 56 kg (18.4965)
    /// excludes, and 214 cm and 87 kg (18.997) shows the caution sheet.
    func testUnroundedBoundaries() {
        XCTAssertEqual(evaluate(heightCm: 174, weightKg: 56), .excluded([.weight]))
        guard case .cautionSheet = evaluate(heightCm: 214, weightKg: 87) else { return XCTFail() }
    }

    /// Scenario "Thoughts with a method", with a second reason.
    func testSelfHarmFirstThenAge() {
        XCTAssertEqual(evaluate(age: 17, weightKg: 60, selfHarm: .excludes), .excluded([.selfHarm, .age]))
    }
}
