import XCTest
import Constants
import Programme
@testable import Content

/// Ruling r13-02 (mm-t11.41, mm-t11.45): the app shows signed-off text from
/// Swift constants in `Programme`, and the content bundle holds a copy of
/// each for the clinical sign-off. These tests prove that each Swift constant
/// equals its bundle copy, so the text the app shows is the text the
/// reviewer signs off.
final class SignedTextCopiesTests: XCTestCase {
    private func bundleText(_ id: String, file: StaticString = #filePath, line: UInt = #line) -> String? {
        let text = Shipped.bundle.string(id: id)?.text
        XCTAssertNotNil(text, "the bundle has no string \(id)", file: file, line: line)
        return text
    }

    private func assertCopy(_ swift: String, _ id: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(swift, bundleText(id, file: file, line: line), id, file: file, line: line)
    }

    // MARK: - Programme: opening sentences and rule strings

    func testEveryOpeningSentenceHasAnEqualBundleCopy() {
        for stage in Stage.allCases {
            guard let sentence = stage.openingSentence else {
                XCTAssertNil(Shipped.bundle.string(id: "opening.stage\(stage.rawValue)"), "stage \(stage.rawValue) has no opening card")
                continue
            }
            assertCopy(sentence, "opening.stage\(stage.rawValue)")
        }
    }

    func testTheStage2RuleStringEqualsItsTwoBundleStrings() {
        for gate in [0, 1, 2, 5] {
            for recorded in [0, 1, 2, 4] {
                XCTAssertEqual(StageRuleText.stage2(gate: gate, recordedDaysCount: recorded), ShippedRule.stage2(gate: gate, recordedDays: recorded))
            }
        }
    }

    func testTheStage3RuleStringEqualsItsBundleStrings() {
        for (days, fallbackDays) in [(7, 14), (1, 7), (2, 21)] {
            var constants = ProgrammeConstants.default
            constants.daysOnPlanForStage3 = days
            constants.recordDaysForStage3Fallback = fallbackDays
            XCTAssertEqual(StageRuleText.stage3(constants: constants), ShippedRule.stage3(days: days, weeks: fallbackDays / 7))
        }
    }

    /// Ruling r13-02 fixes the three wrong bundle rule strings: stage 4
    /// adds "or a week from now", and stages 5 and 7 open a number of weeks
    /// after the plan starts.
    func testTheStage4To7RuleStringsEqualTheirBundleStrings() {
        assertCopy(StageRuleText.stage4, "rule.stage4")
        assertCopy(StageRuleText.stage6, "rule.stage6")
        for weeks in [0, 1, 6, 10] {
            XCTAssertEqual(StageRuleText.weeksAfterPlanStarts(weeks), ShippedRule.count("rule.stage5", weeks))
            XCTAssertEqual(StageRuleText.weeksAfterPlanStarts(weeks), ShippedRule.count("rule.stage7", weeks))
        }
        let constants = ProgrammeConstants.default
        XCTAssertEqual(
            StageRuleText.string(for: .takingStock, constants: constants, recordedDaysCount: 0),
            ShippedRule.count("rule.stage5", constants.weekOfTakingStock)
        )
        XCTAssertEqual(
            StageRuleText.string(for: .stayingOnTrack, constants: constants, recordedDaysCount: 0),
            ShippedRule.count("rule.stage7", constants.weekOfStayingOnTrack)
        )
        XCTAssertEqual(ShippedRule.count("rule.stage7", 10), "Opens 10 weeks after your plan starts")
    }

    /// The Today card controls show catalogue keys; the bundle copies are
    /// "todaycard.plan.setup" and "todaycard.read".
    func testTheTodayCardControlsEqualTheirBundleCopies() throws {
        let url = RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings")
        let catalogue = try XCStringsCatalogue.read(from: url)
        XCTAssertEqual(catalogue["programme.card.setItUp"], bundleText("todaycard.plan.setup"))
        XCTAssertEqual(catalogue["programme.card.read"], bundleText("todaycard.read"))
    }

    // MARK: - Weekly review: the reflection and week-1 questions

    func testTheReviewQuestionsEqualTheirBundleCopies() {
        XCTAssertEqual(ReviewContent.reflectionQuestions.count, 3)
        for (index, question) in ReviewContent.reflectionQuestions.enumerated() {
            assertCopy(question, "reflection.\(index + 1)")
        }
        XCTAssertEqual(ReviewContent.weekOneQuestions.count, 3)
        for (index, question) in ReviewContent.weekOneQuestions.enumerated() {
            assertCopy(question, "week1.\(index + 1)")
        }
    }

    // MARK: - Safeguarding: the GP paragraph

    func testTheGPParagraphEqualsItsBundleCopies() {
        assertCopy(GPParagraph.text(for: .standard), "gp.default")
        assertCopy(GPParagraph.text(for: .selfHarm), "gp.selfharm")
        assertCopy(GPParagraph.text(for: .under18), "gp.under18")
        assertCopy(GPParagraphCopy.copyLabel, "gp.copy")
        assertCopy(GPParagraphCopy.copiedLabel, "gp.copiedlabel")
        assertCopy(GPParagraphCopy.voiceOverAnnouncement, "gp.copiedlabel")
        assertCopy(GPParagraphCopy.copiedConfirmationLine, "gp.copied")
    }

    // MARK: - Safeguarding: the support sheet

    func testTheSupportSheetEqualsItsBundleCopies() {
        assertCopy(SupportSheet.title, "support.title")
        assertCopy(SupportSheet.beatTitle, "support.beat.title")
        assertCopy(SupportSheet.beatIntro, "support.beat.description")
        let beatIds = ["support.beat.england", "support.beat.scotland", "support.beat.wales", "support.beat.ni"]
        XCTAssertEqual(SupportSheet.beatNumbers.count, beatIds.count)
        for (entry, id) in zip(SupportSheet.beatNumbers, beatIds) {
            assertCopy("\(entry.label) \(entry.number)", id)
        }
        assertCopy(SupportSheet.beatHoursLine, "support.beat.hours")
        assertCopy(CommonLabels.beatWebchat, "support.beatwebchat")
        assertCopy(SupportSheet.beatWebchatURLString, "support.beatwebchat.url")
        assertCopy(CommonLabels.samaritansName, "support.samaritans.title")
        assertCopy(SupportSheet.samaritansNumber, "support.samaritans.number")
        assertCopy(SupportSheet.samaritansLine, "support.samaritans.line")
        assertCopy("\(SupportSheet.samaritansWelshLabel): \(SupportSheet.samaritansWelshNumber).", "support.samaritans.welsh")
        assertCopy(SupportSheet.lifelineTitle, "support.lifeline.title")
        assertCopy(SupportSheet.lifelineNumber, "support.lifeline.number")
        assertCopy(SupportSheet.lifelineLine, "support.lifeline.line")
        assertCopy(SupportSheet.nhs111Title, "support.nhs111.title")
        assertCopy(SupportSheet.nhs111Number, "support.nhs111.number")
        assertCopy(SupportSheet.nhs111Line, "support.nhs111.line")
        assertCopy(SupportSheet.nhs111RegionLine, "support.nhs111.note")
        assertCopy(SupportSheet.emergencyTitle, "support.emergency.title")
        assertCopy(SupportSheet.emergencyNumber, "support.emergency.title")
        assertCopy(SupportSheet.emergencyLine, "support.emergency.line")
        assertCopy(CommonLabels.talkToYourGP, "support.gp.title")
        assertCopy(SupportSheet.compensationLine, "support.gp.compensation")
        assertCopy(SupportSheet.callRecentsWarning, "support.callwarning")
        assertCopy(SupportSheet.copiedConfirmationLine, "support.copied")
        assertCopy(SelfHarmItem.supportLine, "support.selfharm")
    }

    // MARK: - Safeguarding: the exclusion, not-right-now and GP suggestion pages

    func testTheExclusionPageEqualsItsBundleCopies() {
        assertCopy(ExclusionPage.heading, "exclusion.heading")
        assertCopy(ExclusionPage.intro, "exclusion.intro")
        assertCopy(ExclusionPage.whatToDoInstead, "exclusion.whattodo")
        assertCopy(ExclusionPage.closing, "exclusion.closing")
        let ids: [ExclusionReason: String] = [
            .selfHarm: "exclusion.selfharm", .age: "exclusion.age", .weight: "exclusion.weight",
            .pregnancy: "exclusion.pregnancy", .treatment: "exclusion.treatment",
        ]
        for reason in ExclusionReason.allCases {
            assertCopy(ExclusionPage.paragraph(for: reason), ids[reason]!)
        }
        assertCopy(CommonLabels.cautionSheetBody, "caution.sheet")
    }

    func testTheNotRightNowPageEqualsItsBundleCopies() {
        assertCopy(NotRightNowPage.heading, "notrightnowpage.heading")
        assertCopy(NotRightNowPage.selfHarmReason, "notrightnow.selfharm")
        assertCopy(NotRightNowPage.weightReason, "notrightnow.weight")
        assertCopy(NotRightNowPage.recordStaysLine, "notrightnowpage.recordstays")
        assertCopy(NotRightNowPage.remindersPausedLine, "notrightnowpage.reminderspaused")
        assertCopy(NotRightNowPage.remindersStayOnLine, "notrightnowpage.remindersstayon")
        // Pregnancy and treatment show the exclusion page's own strings.
        assertCopy(NotRightNowPage.paragraph(for: .pregnancy)!, "exclusion.pregnancy")
        assertCopy(NotRightNowPage.paragraph(for: .treatment)!, "exclusion.treatment")
    }

    func testTheGPSuggestionPageEqualsItsBundleCopies() {
        assertCopy(GPSuggestionPage.heading, "gpsuggestion.heading")
        assertCopy(GPSuggestionPage.diagnosisLine, "gpsuggestion.diagnosis")
        let ids: [GPSuggestionReason: String] = [
            .fallingWeight: "gpsuggestion.fallingweight", .quickChange: "gpsuggestion.quickchange",
            .deterioration: "gpsuggestion.deterioration", .gettingWorse: "gpsuggestion.gettingworse",
        ]
        for (reason, id) in ids {
            assertCopy(GPSuggestionPage.line(for: reason) + " " + GPSuggestionPage.supportingLine(for: reason), id)
        }
    }

    // MARK: - Safeguarding: the screening questions and answers

    func testTheScreeningQuestionsAndAnswersEqualTheirBundleCopies() {
        let questions = ScreeningQuestionCatalog.questions
        XCTAssertEqual(questions.count, 6)
        assertCopy(questions[0], "screening.question.age")
        assertCopy(questions[1], "screening.question.height")
        assertCopy(questions[2], "screening.question.weight")
        // questions[3], the treatment question, has no bundle copy yet: it
        // holds "therapist", a word on the full forbidden list.
        assertCopy(questions[4], "screening.question.pregnancy")
        assertCopy(questions[5], "screening.question.selfharm")
        assertCopy(ScreeningQuestionCatalog.selfHarmSecondQuestion, "screening.question.selfharm.how")
        assertCopy(Screen2Content.ageQuestion, "screening.question.age")
        assertCopy(Screen2Content.heightQuestion, "screening.question.height")
        assertCopy(Screen2Content.weightQuestion, "screening.question.weight")
        assertCopy(Screen2Content.pregnancyQuestion, "screening.question.pregnancy")
        assertCopy(CommonLabels.ratherNotSay, "screening.answer.rathernotsay")
        assertCopy(CommonLabels.doesNotApplyToMe, "screening.answer.doesnotapply")
        assertCopy(CommonLabels.treatmentYesWithAgreement, "screening.answer.treatmentyes")
    }
}
