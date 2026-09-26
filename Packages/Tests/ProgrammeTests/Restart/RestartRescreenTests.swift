import XCTest
@testable import Programme

/// Covers safeguarding spec.md, "Re-screening at a restart" (mm-t36.1).
/// "Restart from a check-in" is `deferred: mm-t36.19`. "The restart's height
/// wins on another device" is a store-level scenario, in
/// `RecordTests.RestartStoreTests`. "Self-harm Yes then Yes at a restart"
/// and "Underweight at a re-screen" are built here over fixture facts, with
/// no live dependency on `weekly-review`; `mm-t32.16` runs each end to end.
final class RestartRescreenTests: XCTestCase {
    private let dayStart = 4

    /// Scenario: Restart a year later.
    func testRestartAYearLater() {
        let askedAt = moment(2026, 1, 5, 9)
        let required = RestartGate.rescreenRequired(askedAt: askedAt, now: moment(2027, 1, 20), currentRecordDay: dayKey(2027, 1, 20), dayStart: dayStart, calendar: engineTestCalendar)
        XCTAssertTrue(required)
    }

    /// Scenario: Restart within 84 record days.
    func testRestartWithin84RecordDays() {
        let askedAt = moment(2026, 1, 5, 9)
        // 56 record days later.
        let required = RestartGate.rescreenRequired(askedAt: askedAt, now: moment(2026, 3, 2), currentRecordDay: dayKey(2026, 3, 2), dayStart: dayStart, calendar: engineTestCalendar)
        XCTAssertFalse(required)
    }

    /// Scenario: Restart on the 84th record day.
    func testRestartOnThe84thRecordDay() {
        let askedAt = moment(2026, 1, 5, 9)
        let required = RestartGate.rescreenRequired(askedAt: askedAt, now: moment(2026, 3, 30), currentRecordDay: dayKey(2026, 3, 30), dayStart: dayStart, calendar: engineTestCalendar)
        XCTAssertFalse(required, "exactly 84 record days later still asks nothing")
    }

    /// Scenario: New BMI.
    func testNewBMI() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 65, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertFalse(result.excluded)
        XCTAssertEqual(result.newHeightCm, 170)
        XCTAssertEqual(result.newOnboardingBMI, 22.49, accuracy: 0.01)
    }

    /// Scenario: Excluded at a restart.
    func testExcludedAtARestart() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 65, pregnancy: .yes, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertEqual(result.reasons, [.pregnancy])
        XCTAssertTrue(result.excluded)
    }

    /// Scenario: Self-harm Yes then No at a restart.
    func testSelfHarmYesThenNoAtARestart() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 65, pregnancy: .no, treatment: .no, selfHarmFirst: .yes, selfHarmSecond: .no)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertFalse(result.excluded)
        XCTAssertTrue(result.selfHarmSupportLineShows)
    }

    /// Scenario: Cancel after a re-screen. The replacement fields are ready
    /// to write regardless of the start-day choice that follows; the app
    /// layer writes them once, on any outcome but exclusion, and only the
    /// start day write depends on "Today"/"Tomorrow" vs "Cancel".
    func testCancelAfterARescreen() {
        let firstAskedAt = moment(2026, 1, 5, 9)
        let answers = RescreenAnswers(heightCm: 172, weightKg: 65, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: firstAskedAt)
        XCTAssertFalse(result.excluded)
        XCTAssertEqual(result.newOnboardingBMI, 21.97, accuracy: 0.01)
        // 56 record days after the re-screen's own askedAt, not the original.
        let required = RestartGate.rescreenRequired(askedAt: result.newAskedAt, now: moment(2026, 3, 2), currentRecordDay: dayKey(2026, 3, 2), dayStart: dayStart, calendar: engineTestCalendar)
        XCTAssertFalse(required)
    }

    /// Scenario: askedAt in the future.
    func testAskedAtInTheFuture() {
        let required = RestartGate.rescreenRequired(askedAt: moment(2027, 1, 1), now: moment(2026, 10, 1), currentRecordDay: dayKey(2026, 10, 1), dayStart: dayStart, calendar: engineTestCalendar)
        XCTAssertTrue(required)
    }

    /// Scenario: Restarts less than 84 record days apart.
    func testRestartsLessThan84RecordDaysApart() {
        let firstAskedAt = moment(2026, 1, 5, 9)
        // Restart on 6 March, 60 record days later: no re-screen; the last
        // screening stays 5 January (no re-screen ran, so `askedAt` is
        // unchanged).
        XCTAssertFalse(RestartGate.rescreenRequired(askedAt: firstAskedAt, now: moment(2026, 3, 6), currentRecordDay: dayKey(2026, 3, 6), dayStart: dayStart, calendar: engineTestCalendar))
        // Restart on 5 April, 90 record days after the 5 January screening:
        // re-screens before the start-day choice.
        XCTAssertTrue(RestartGate.rescreenRequired(askedAt: firstAskedAt, now: moment(2026, 4, 5), currentRecordDay: dayKey(2026, 4, 5), dayStart: dayStart, calendar: engineTestCalendar))
    }

    /// Scenario: Self-harm Yes then Yes at a restart.
    func testSelfHarmYesThenYesAtARestart() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 65, pregnancy: .no, treatment: .no, selfHarmFirst: .yes, selfHarmSecond: .yes)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertEqual(result.reasons, [.selfHarm])
    }

    /// Scenario: Underweight at a re-screen.
    func testUnderweightAtARescreen() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 53, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertEqual(result.reasons, [.weight])
        XCTAssertTrue(result.remindersPausedByWeightReason)
    }

    // MARK: mm-t21.25, the rules read the unrounded BMI ("The app MUST
    // compute the BMI as `onboarding` defines"; onboarding spec, "The
    // one-time BMI": "The app MUST pass the unrounded BMI to
    // `safeguarding`.").

    /// 174 cm and 56 kg is a BMI of 18.4965. Rounded to 2 dp it is 18.50,
    /// which does not exclude; the unrounded value is below 18.5.
    func testUnroundedBMIJustBelow18Point5Excludes() {
        for (heightCm, weightKg) in [(174.0, 56.0), (186.0, 64.0), (BMI.heightCm(feet: 6, inches: 3), BMI.weightKg(stone: 10, pounds: 8))] {
            let answers = RescreenAnswers(heightCm: heightCm, weightKg: weightKg, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
            let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
            XCTAssertEqual(result.reasons, [.weight], "\(heightCm) cm, \(weightKg) kg")
            XCTAssertTrue(result.remindersPausedByWeightReason)
        }
    }

    /// 214 cm and 87 kg is a BMI of 18.997. Rounded to 2 dp it is 19.00,
    /// which loses the caution flag; the unrounded value is below 19.0.
    func testUnroundedBMIJustBelow19SetsTheCautionFlag() {
        let answers = RescreenAnswers(heightCm: 214, weightKg: 87, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertFalse(result.excluded)
        XCTAssertTrue(result.newCautionFlag)
        XCTAssertEqual(result.newOnboardingBMI, BMI.value(heightCm: 214, weightKg: 87), "the Profile keeps the unrounded BMI, as at onboarding")
    }

    /// Scenario "Caution band" at a re-screen: 170 cm and 54 kg.
    func testCautionBandAtARescreen() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 54, pregnancy: .no, treatment: .no, selfHarmFirst: .no, selfHarmSecond: nil)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertFalse(result.excluded)
        XCTAssertTrue(result.newCautionFlag, "the re-screen shows the caution sheet before the start-day choice")
    }

    // MARK: mm-t21.23, "wiring: scenarios that need 2.1, end to end" — the
    // not-right-now page's own reason ordering (safeguarding spec, "The
    // not-right-now page"), run from a real re-screen's answers rather than
    // a fixture reasons array.

    /// Scenario: Two reasons at a re-screen.
    func testTwoReasonsAtARescreen() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 53, pregnancy: .no, treatment: .no, selfHarmFirst: .yes, selfHarmSecond: .yes)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertEqual(result.reasons, [.selfHarm, .weight], "self-harm above weight")
        XCTAssertEqual(NotRightNowPage.paragraph(for: .selfHarm), NotRightNowPage.selfHarmReason)
        XCTAssertTrue(result.remindersPausedByWeightReason)
        XCTAssertEqual(NotRightNowPage.remindersLine(for: result.reasons), NotRightNowPage.remindersPausedLine)
    }

    /// Scenario: Four reasons at a re-screen.
    func testFourReasonsAtARescreen() {
        let answers = RescreenAnswers(heightCm: 170, weightKg: 53, pregnancy: .yes, treatment: .yes, selfHarmFirst: .yes, selfHarmSecond: .yes)
        let result = RestartRescreen.evaluate(answers, now: moment(2026, 6, 1))
        XCTAssertEqual(result.reasons, [.selfHarm, .weight, .pregnancy, .treatment])
        XCTAssertEqual(NotRightNowPage.paragraph(for: .pregnancy), ExclusionPage.paragraph(for: .pregnancy))
        XCTAssertEqual(NotRightNowPage.paragraph(for: .treatment), ExclusionPage.paragraph(for: .treatment))
    }
}
