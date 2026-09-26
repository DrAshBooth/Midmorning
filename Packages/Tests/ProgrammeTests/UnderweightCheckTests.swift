import XCTest
@testable import Programme

/// safeguarding spec, "The underweight check" (mm-t22.1). "No weigh-in" is
/// an orchestration rule (the App target calls this check only after a
/// saved weigh-in exists); `weigh-in`'s own "No weigh-in, no check" scenario
/// (`RollingAverageTests.testNoWeighInOldEnoughReadsNil`) and mm-t22.15's
/// wiring test cover the store-level half of it.
final class UnderweightCheckTests: XCTestCase {
    /// Scenario: Rule A. (Rule B's own gate also matches this implied BMI —
    /// the spec's "When Rule A applies with another rule" paragraph names
    /// exactly this case; `testRuleAWithAnotherRuleShowsOnlyTheNotRightNowPage`
    /// below is that paragraph's own scenario. This test only proves the
    /// page selection the worked example asserts.)
    func testRuleA() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 53.0, averageAtLeast28DaysEarlierKg: nil)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertTrue(rules.contains(.a))
        XCTAssertEqual(UnderweightCheck.notRightNowReasons(rules), [.weight])
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [])
    }

    /// Scenario: Rule B.
    func testRuleB() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, currentAverageKg: 56.0, averageAtLeast28DaysEarlierKg: nil)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(rules, [.b])
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [.fallingWeight])
        XCTAssertEqual(GPSuggestionPage.line(for: .fallingWeight), "Your weight has come down since you started.")
    }

    /// Scenario: Rule C.
    func testRuleC() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 66.0, averageAtLeast28DaysEarlierKg: 70.0)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(rules, [.c])
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [.quickChange])
        XCTAssertEqual(GPSuggestionPage.line(for: .quickChange), "Your weight has changed quickly over the last four weeks.")
    }

    /// Scenario: Rule C with the caution flag.
    func testRuleCWithTheCautionFlag() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 18.9, cautionFlag: true, currentAverageKg: 54.2, averageAtLeast28DaysEarlierKg: 56.0)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(rules, [.c], "3% in place of 5% still fires; neither Rule A nor Rule B applies at this BMI")
    }

    /// Scenario: No rule applies.
    func testNoRuleApplies() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 68.5, averageAtLeast28DaysEarlierKg: 70.0)
        XCTAssertEqual(UnderweightCheck.rulesThatApply(input), [])
    }

    /// When no weigh-in is 28 or more days old, the app MUST NOT apply Rule
    /// C: `averageAtLeast28DaysEarlierKg` is `nil`.
    func testNoRuleCWithoutAnOldEnoughWeighIn() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 60.0, averageAtLeast28DaysEarlierKg: nil)
        XCTAssertFalse(UnderweightCheck.rulesThatApply(input).contains(.c))
    }

    /// When Rule A applies with another rule, the app MUST show the
    /// not-right-now page only.
    func testRuleAWithAnotherRuleShowsOnlyTheNotRightNowPage() {
        // Implied BMI well below 18.5, and also 1.0+ below the onboarding BMI (Rule B's own gate) and a 28-day fall (Rule C's own gate).
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 50.0, averageAtLeast28DaysEarlierKg: 70.0)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertTrue(rules.contains(.a))
        XCTAssertEqual(UnderweightCheck.notRightNowReasons(rules), [.weight])
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [], "Rule A alone shows; the GP suggestion page shows nothing")
    }

    /// When Rules B and C both apply, the page MUST show both reasons.
    func testRulesBAndCBothApply() {
        let input = UnderweightCheckInput(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, currentAverageKg: 56.0, averageAtLeast28DaysEarlierKg: 70.0)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(Set(rules), [.b, .c])
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [.fallingWeight, .quickChange])
    }

    // MARK: mm-t22.23, exact falls on the boundary ("Rule C applies when the
    // current value is 5% or more below that earlier value.")

    /// Exact 5% falls that `Double` puts a few units in the last place off.
    func testRuleCOnAnExactFivePercentFall() {
        for (earlier, current) in [(149.60, 142.12), (46.0, 43.7), (70.0, 66.5)] {
            let input = UnderweightCheckInput(heightCm: 150, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: current, averageAtLeast28DaysEarlierKg: earlier)
            XCTAssertTrue(UnderweightCheck.rulesThatApply(input).contains(.c), "\(earlier) kg to \(current) kg is a 5% fall")
        }
        let justAbove = UnderweightCheckInput(heightCm: 150, onboardingBMI: 24.2, cautionFlag: false, currentAverageKg: 142.13, averageAtLeast28DaysEarlierKg: 149.60)
        XCTAssertFalse(UnderweightCheck.rulesThatApply(justAbove).contains(.c), "a fall of less than 5% does not apply")
    }

    /// An exact 3% fall with the caution flag set.
    func testRuleCOnAnExactThreePercentFallWithTheCautionFlag() {
        let input = UnderweightCheckInput(heightCm: 150, onboardingBMI: 18.9, cautionFlag: true, currentAverageKg: 39.77, averageAtLeast28DaysEarlierKg: 41.0)
        XCTAssertTrue(UnderweightCheck.rulesThatApply(input).contains(.c))
    }

    /// Rule B on an exact fall of 1.0: 150 cm and 42.84 kg is an implied
    /// BMI of exactly 19.04, and the onboarding BMI is 20.04.
    func testRuleBOnAnExactFallOfOne() {
        let input = UnderweightCheckInput(heightCm: 150, onboardingBMI: 20.04, cautionFlag: false, currentAverageKg: 42.84, averageAtLeast28DaysEarlierKg: nil)
        XCTAssertEqual(UnderweightCheck.rulesThatApply(input), [.b])
    }

    /// Rule A does not apply on an implied BMI of exactly 18.5: 160 cm and
    /// 47.36 kg.
    func testRuleAOnAnImpliedBMIOfExactly18Point5() {
        let input = UnderweightCheckInput(heightCm: 160, onboardingBMI: 19.2, cautionFlag: true, currentAverageKg: 47.36, averageAtLeast28DaysEarlierKg: nil)
        XCTAssertFalse(UnderweightCheck.rulesThatApply(input).contains(.a))
    }
}
