import XCTest
@testable import Programme

/// Onboarding spec, "Screen 2: the screening questions" and "The one-time
/// BMI"; safeguarding spec, "Re-screening at a restart" (mm-t14.34,
/// mm-t21.26, mm-t21.34, mm-t22.24). Onboarding screen 2 and the restart
/// re-screen both run `ScreeningForm.firstIssue` when the person taps
/// "Continue", show its message under that question and move VoiceOver
/// focus to it.
final class ScreeningFormTests: XCTestCase {
    private func input(
        ageText: String? = "34",
        height: TypedMeasure = .value(170),
        weight: TypedMeasure = .value(60),
        treatment: Bool = true,
        pregnancy: Bool = true,
        selfHarmFirst: SelfHarmFirstAnswer? = .no,
        selfHarmSecond: Bool = false
    ) -> ScreeningFormInput {
        ScreeningFormInput(ageText: ageText, height: height, weight: weight, treatmentAnswered: treatment, pregnancyAnswered: pregnancy, selfHarmFirst: selfHarmFirst, selfHarmSecondAnswered: selfHarmSecond)
    }

    /// Scenario "Screening continues".
    func testEveryAnswerGivenHasNoIssue() {
        XCTAssertNil(ScreeningForm.firstIssue(input()))
    }

    /// Scenario "One answer missing": the pregnancy question.
    func testOneAnswerMissing() {
        let issue = ScreeningForm.firstIssue(input(pregnancy: false))
        XCTAssertEqual(issue, ScreeningFormIssue(field: .pregnancy, problem: .unanswered))
        XCTAssertEqual(issue?.problem.message(), "Please answer this one.")
    }

    /// An empty height or weight shows "Please answer this one." under that
    /// field (mm-t14.34).
    func testEmptyHeightAndWeightAreUnanswered() {
        XCTAssertEqual(ScreeningForm.firstIssue(input(height: .missing)), ScreeningFormIssue(field: .height, problem: .unanswered))
        XCTAssertEqual(ScreeningForm.firstIssue(input(weight: .missing)), ScreeningFormIssue(field: .weight, problem: .unanswered))
        XCTAssertEqual(ScreeningForm.firstIssue(input(ageText: "")), ScreeningFormIssue(field: .age, problem: .unanswered))
    }

    /// "Yes" to the first self-harm question and no answer to "Have you
    /// thought about how you would do it?" stops on the second question
    /// (mm-t14.34).
    func testSecondSelfHarmQuestionUnanswered() {
        XCTAssertEqual(ScreeningForm.firstIssue(input(selfHarmFirst: .yes)), ScreeningFormIssue(field: .selfHarmSecond, problem: .unanswered))
        XCTAssertNil(ScreeningForm.firstIssue(input(selfHarmFirst: .yes, selfHarmSecond: true)))
        XCTAssertEqual(ScreeningForm.firstIssue(input(selfHarmFirst: nil)), ScreeningFormIssue(field: .selfHarmFirst, problem: .unanswered))
    }

    /// Scenario "Weight below the range".
    func testWeightBelowTheRange() {
        let issue = ScreeningForm.firstIssue(input(weight: .value(20)))
        XCTAssertEqual(issue, ScreeningFormIssue(field: .weight, problem: .weightOutOfRange))
        XCTAssertEqual(issue?.problem.message(), "Enter a weight of 30 kg or more.")
    }

    /// Scenario "Height outside the range".
    func testHeightOutsideTheRange() {
        let issue = ScreeningForm.firstIssue(input(height: .value(90)))
        XCTAssertEqual(issue, ScreeningFormIssue(field: .height, problem: .heightOutOfRange))
        XCTAssertEqual(issue?.problem.message(), "Enter a height between 100 and 250 cm.")
    }

    /// Scenario "No upper weight bound".
    func testNoUpperWeightBound() {
        XCTAssertNil(ScreeningForm.firstIssue(input(weight: .value(320))))
    }

    /// The first unanswered question, in screen order.
    func testTheFirstIssueInScreenOrder() {
        let issue = ScreeningForm.firstIssue(input(height: .missing, weight: .value(20), treatment: false))
        XCTAssertEqual(issue?.field, .height)
    }

    /// The restart re-screen asks no age (safeguarding spec, "Re-screening
    /// at a restart"). A re-screen typo such as 17 cm or 6 kg stops on that
    /// field, as at onboarding (mm-t21.26).
    func testTheRescreenAsksNoAgeAndChecksTheRanges() {
        XCTAssertNil(ScreeningForm.firstIssue(input(ageText: nil)))
        XCTAssertEqual(ScreeningForm.firstIssue(input(ageText: nil, height: .value(17))), ScreeningFormIssue(field: .height, problem: .heightOutOfRange))
        XCTAssertEqual(ScreeningForm.firstIssue(input(ageText: nil, weight: .value(6))), ScreeningFormIssue(field: .weight, problem: .weightOutOfRange))
    }

    /// Inches accept 0 to 11 and pounds accept 0 to 13 (mm-t22.24; weigh-in
    /// spec, "The number and its unit": "pounds as a whole number from 0 to
    /// 13").
    func testInchesAndPoundsRanges() {
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: "30"), .partOutOfRange)
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: "-1"), .partOutOfRange)
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: "11"), .value(BMI.heightCm(feet: 5, inches: 11)))
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: "0"), .value(BMI.heightCm(feet: 5, inches: 0)))
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "25"), .partOutOfRange)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "14"), .partOutOfRange)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "13"), .value(BMI.weightKg(stone: 10, pounds: 13)))
        XCTAssertEqual(ScreeningForm.firstIssue(input(height: TypedMeasureParser.heightCm(feet: "5", inches: "30"))), ScreeningFormIssue(field: .height, problem: .heightOutOfRange))
        XCTAssertEqual(ScreeningForm.firstIssue(input(weight: TypedMeasureParser.weightKg(stone: "10", pounds: "25"))), ScreeningFormIssue(field: .weight, problem: .weightOutOfRange))
    }

    /// The weigh-in screen reads "st lb" through the same parse (weigh-in
    /// spec, "The number and its unit"). Scenario "Stone and pounds": 10 st
    /// 7 lb keeps 66.68 kg. 10 st 25 lb is refused with the range message.
    func testWeighInStoneAndPounds() {
        XCTAssertEqual(WeighInWeight.storedKg(TypedMeasureParser.weightKg(stone: "10", pounds: "7").value ?? 0), 66.68)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "25"), .partOutOfRange)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "7").value, WeighInWeight.kg(stone: 10, pounds: 7))
    }

    /// Scenario "Imperial input": 5 ft 7 in and 8 st 7 lb.
    func testImperialInput() {
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: "7").value ?? 0, 170.18, accuracy: 0.001)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "8", pounds: "7").value ?? 0, 53.98, accuracy: 0.01)
    }

    /// An empty part, a word or a value that is not finite is not an answer.
    func testMissingParts() {
        XCTAssertEqual(TypedMeasureParser.heightCm(centimetres: ""), .missing)
        XCTAssertEqual(TypedMeasureParser.heightCm(centimetres: "nan"), .missing)
        XCTAssertEqual(TypedMeasureParser.weightKg(kilograms: "inf"), .missing)
        XCTAssertEqual(TypedMeasureParser.heightCm(feet: "5", inches: ""), .missing)
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "", pounds: "3"), .missing)
        XCTAssertEqual(TypedMeasureParser.heightCm(centimetres: "170"), .value(170))
        XCTAssertEqual(TypedMeasureParser.weightKg(kilograms: "60.5"), .value(60.5))
    }
}
