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

    // MARK: - Weekly review: the controls, the list rows and the summary

    func testTheReviewControlsEqualTheirBundleCopies() {
        assertCopy(ReviewContent.reviewsListTitle, "review.list.title")
        assertCopy(ReviewContent.noRowsAccessibilityHint, "review.list.empty")
        assertCopy(ReviewContent.oneThingToChangeQuestion, "review.onething")
        assertCopy(ReviewContent.gettingWorseButton, "review.gettingworse")
        assertCopy(ReviewContent.gettingWorseHint, "review.gettingworse.hint")
        assertCopy(ReviewContent.selfHarmAnsweredLine, "review.selfharm.answered")
        assertCopy(ReviewContent.weeklySummarySwitchLabel, "review.summaryswitch")
    }

    /// Ruling r13-12: a row with the starred count shows two counts, so it
    /// is "review.row" and "review.row.starred", joined by one space.
    func testTheReviewsListRowsEqualTheirBundleCopies() {
        for week in [1, 2, 12] {
            for starred in [0, 1, 4] {
                XCTAssertEqual(
                    ReviewContent.rowText(week: week, dateRange: "12–18 October", starredCount: starred),
                    ShippedText.format("review.row", count: week, "12–18 October") + " " + ShippedRule.count("review.row.starred", starred),
                    "review.row"
                )
            }
            XCTAssertEqual(
                ReviewContent.rowTextWithoutCount(week: week, dateRange: "28 September–4 October"),
                ShippedText.format("review.row.nocount", count: week, "28 September–4 October"),
                "review.row.nocount"
            )
        }
        XCTAssertEqual(ReviewContent.rowText(week: 3, dateRange: "12–18 October", starredCount: 4), "Week 3, 12–18 October. Starred entries: 4.")
    }

    /// Each summary sentence equals its bundle copy, filled with the same
    /// values. Ruling r13-12: the starred part with a last-week count fills
    /// "review.summary.starred.twoweeks" with two one-count strings, and the
    /// urge part joins two one-count sentences with one space.
    func testTheSummarySentencesEqualTheirBundleCopies() {
        for count in [0, 1, 2, 26] {
            XCTAssertEqual(ReviewSummary.daysText(count), ShippedRule.count("review.summary.days", count), "review.summary.days")
            XCTAssertEqual(ReviewSummary.starredText(thisWeek: count, lastWeek: nil), ShippedRule.count("review.summary.starred", count), "review.summary.starred")
            XCTAssertEqual(ReviewSummary.planText(count), ShippedRule.count("review.summary.plan", count), "review.summary.plan")
            XCTAssertEqual(ReviewSummary.pausedText(count), ShippedRule.count("review.summary.paused", count), "review.summary.paused")
            for other in [0, 1, 6] {
                XCTAssertEqual(
                    ReviewSummary.starredText(thisWeek: count, lastWeek: other),
                    ShippedText.format(
                        "review.summary.starred.twoweeks",
                        ShippedRule.count("review.summary.starred.thisweek", count),
                        ShippedRule.count("review.summary.starred.lastweek", other)
                    ),
                    "review.summary.starred.twoweeks"
                )
                XCTAssertEqual(
                    ReviewSummary.urgeText(urges: count, passed: other),
                    ShippedRule.count("review.summary.urges", count) + " " + ShippedRule.count("review.summary.passed", other),
                    "review.summary.urges"
                )
            }
        }
        XCTAssertEqual(
            ReviewSummary.gapText(duration: "6 hours 20 minutes", weekday: "Tuesday", from: "12:40", to: "19:00"),
            ShippedText.format("review.summary.gap", "6 hours 20 minutes", "Tuesday", "12:40", "19:00"),
            "review.summary.gap"
        )
        XCTAssertEqual(ReviewSummary.weighInText(weekday: "Wednesday"), ShippedText.format("review.summary.weighin", "Wednesday"), "review.summary.weighin")
        XCTAssertEqual(ReviewSummary.wordsText("tired, ok, flat"), ShippedText.format("review.summary.words", "tired, ok, flat"), "review.summary.words")
        // The person reads the text that the weekly-review spec gives.
        XCTAssertEqual(ReviewSummary.starredText(thisWeek: 4, lastWeek: 6), "Starred entries: 4 this week, 6 last week.")
        XCTAssertEqual(ReviewSummary.urgeText(urges: 3, passed: 2), "Urges: 3. Passed: 2.")
    }

    // MARK: - Onboarding: screens 1, 2 and 4

    /// Lines 1 and 3 of screen 1 hold "CBT" and "therapy", words on the
    /// forbidden list. They have no bundle copy until decision mm-t11.47
    /// (mm-t11.48). Line 4 is the support sheet's compensation line.
    func testTheOnboardingTextEqualsItsBundleCopies() {
        assertCopy(Screen1Content.title, "onboarding.screen1.title")
        XCTAssertEqual(Screen1Content.lines.count, 7)
        assertCopy(Screen1Content.lines[1], "onboarding.screen1.line2")
        assertCopy(Screen1Content.lines[3], "support.gp.compensation")
        assertCopy(Screen1Content.lines[4], "onboarding.screen1.line5")
        assertCopy(Screen1Content.lines[5], "onboarding.screen1.line6")
        assertCopy(Screen1Content.lines[6], "onboarding.screen1.line7")
        assertCopy(Screen1Content.continueLabel, "onboarding.continue")
        assertCopy(Screen2Content.title, "onboarding.screen2.title")
        assertCopy(Screen2Content.heightWeightIntro, "onboarding.screen2.intro")
        assertCopy(Screen2Content.continueLabel, "onboarding.continue")
        assertCopy(Screen4Content.title, "onboarding.screen4.title")
        assertCopy(Screen4Content.yourRecordHeading, "onboarding.screen4.recordheading")
        assertCopy(Screen4Content.yourRecordSentence, "onboarding.screen4.recordsentence")
        assertCopy(Screen4Content.thisDeviceOnly, "onboarding.screen4.thisdevice")
        assertCopy(Screen4Content.iCloudLaterVersion, "onboarding.screen4.icloud")
        assertCopy(Screen4Content.notificationsExplanation, "onboarding.screen4.notifications")
        assertCopy(Screen4Content.allowNotifications, "onboarding.screen4.allownotifications")
        assertCopy(Screen4Content.widgetExplanation, "onboarding.screen4.widget")
        assertCopy(Screen4Content.showMeHow, "onboarding.screen4.showmehow")
        assertCopy(Screen4Content.widgetInstructions, "onboarding.screen4.widgetinstructions")
        assertCopy(Screen4Content.startLabel, "onboarding.screen4.start")
    }

    /// Onboarding screen 3 and the unanswered message are keys in the app's
    /// string catalogue. Each key that no signed prefix names (ruling r13-01)
    /// has a bundle copy with the same text.
    func testTheOnboardingCatalogueTextEqualsItsBundleCopies() throws {
        let catalogue = try XCStringsCatalogue.read(from: RepositoryRoot.appCatalogueURL)
        let copies: [(key: String, id: String)] = [
            ("onboarding.screen3.title", "onboarding.start.title"),
            ("onboarding.startDay.question", "onboarding.start.question"),
            ("onboarding.startDay.today", "onboarding.start.today"),
            ("onboarding.startDay.tomorrow", "onboarding.start.tomorrow"),
            ("onboarding.dayBoundary", "onboarding.start.dayboundary"),
            ("weighIn.day", "onboarding.start.weighinday"),
            ("weighIn.wontBeWeighing", "onboarding.start.wontweigh"),
            ("onboarding.weighIn.explanation", "onboarding.start.weighin"),
            ("onboarding.unanswered", "onboarding.pleaseanswer"),
        ]
        for copy in copies {
            XCTAssertEqual(catalogue[copy.key], bundleText(copy.id), copy.id)
        }
        XCTAssertEqual(Screen3Content.weighInExplanation, .key("onboarding.weighIn.explanation"))
        XCTAssertEqual(Screen3Content.unansweredMessage, .key("onboarding.unanswered"))
        let signed = try SignedCatalogueKeys.read(from: RepositoryRoot.contentResourcesDirectory)
        let bundleTexts = Set(Shipped.bundle.strings.flatMap(\.readableTexts))
        for (key, value) in catalogue where key.hasPrefix("onboarding.") && !signed.isSigned(key) {
            XCTAssertTrue(bundleTexts.contains(value), "\(key) has no bundle copy and no signed prefix")
        }
    }

    // MARK: - Every signed-off Swift constant has a bundle copy

    /// Scenario "A signed-off Swift constant with no bundle copy". The scan
    /// reads every Swift file in the signed-off Programme folders. Each
    /// `static let` string constant must equal a bundle string. Each string
    /// that a `return`, a `case` or a line of an array holds must be in a
    /// bundle string or a signed catalogue string, because the code can join
    /// it with other parts. The test names each string that fails.
    /// A string with `\(` is a template, and the tests above cover it. A
    /// multi-line literal fails the test, because the scan cannot read it.
    func testEverySignedOffSwiftConstantHasABundleCopy() throws {
        // A part that a test above joins into one bundle string.
        let joinedParts: Set<String> = [
            "SupportSheet.samaritansWelshLabel", "SupportSheet.samaritansWelshNumber", // "support.samaritans.welsh"
            "GPParagraph.selfHarmAddition", // "gp.selfharm"
        ]
        // Text with a word from the forbidden list. It waits for decision
        // mm-t11.47 (mm-t11.48).
        let waitingForDecision: Set<String> = [
            Screen1Content.lines[0], Screen1Content.lines[2], Screen2Content.treatmentQuestion,
        ]
        // A file that holds the phrases a check looks for. The app does not
        // show these phrases.
        let notShown: Set<String> = ["TreatmentClaim"]

        let bundleTexts = Set(Shipped.bundle.strings.flatMap(\.readableTexts))
        let knownTexts = Array(bundleTexts) + Shipped.bundle.signedCatalogue.values.flatMap(\.texts)
        let programme = RepositoryRoot.path.appendingPathComponent("Packages/Programme")
        let sources = try ["Onboarding", "Safeguarding", "WeeklyReview", "Engine"].flatMap { folder in
            try FileManager.default.contentsOfDirectory(at: programme.appendingPathComponent(folder), includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "swift" }
        }
        let literal = #""((?:[^"\\]|\\.)*)""#
        let constant = try NSRegularExpression(pattern: #"static let (\w+)(?:\s*:\s*String)?\s*=\s*"# + literal)
        let part = try NSRegularExpression(
            pattern: #"^[ \t]*(?:(?:case\b[^"\n]*|default)[ \t]*:[ \t]*)?(?:return[ \t]+)?"# + literal + #"[ \t]*,?[ \t]*(?://.*)?$"#,
            options: .anchorsMatchLines
        )
        func matches(_ regex: NSRegularExpression, in text: String) -> [[String]] {
            regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
                (1..<match.numberOfRanges).map { String(text[Range(match.range(at: $0), in: text)!]) }
            }
        }
        func shown(_ text: String) -> String? {
            let value = text.replacingOccurrences(of: #"\""#, with: "\"")
            guard !value.contains("\\("), value.contains(where: \.isLetter), !waitingForDecision.contains(value) else { return nil }
            return value
        }
        var scanned = 0
        for source in sources {
            let file = source.deletingPathExtension().lastPathComponent
            guard !notShown.contains(file) else { continue }
            let text = try String(contentsOf: source, encoding: .utf8)
            XCTAssertFalse(text.contains("\"\"\""), "\(file) holds a multi-line literal, which this scan cannot read")
            for groups in matches(constant, in: text) where !joinedParts.contains("\(file).\(groups[0])") {
                guard let value = shown(groups[1]) else { continue }
                scanned += 1
                XCTAssertTrue(bundleTexts.contains(value), "\(file).\(groups[0]) has no bundle copy")
            }
            for groups in matches(part, in: text) {
                guard let value = shown(groups[0]) else { continue }
                scanned += 1
                XCTAssertTrue(knownTexts.contains { $0.contains(value) }, "\(file): \"\(value)\" is in no bundle string and no signed catalogue string")
            }
        }
        XCTAssertGreaterThan(scanned, 80)
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

/// Fills a bundle string's placeholders, the same way the app fills them:
/// a count picks the plural form, and a `%@` takes text.
enum ShippedText {
    /// The string `id`, with its plural form for `count` and the values in
    /// placeholder order.
    static func format(_ id: String, count: Int, _ texts: String...) -> String {
        let entry = ShippedRule.entry(id)
        return String(format: entry.form(for: count), arguments: [count as CVarArg] + texts.map { $0 as CVarArg })
    }

    /// The string `id`, with no count, filled with `texts`.
    static func format(_ id: String, _ texts: String...) -> String {
        String(format: ShippedRule.entry(id).text, arguments: texts.map { $0 as CVarArg })
    }
}
