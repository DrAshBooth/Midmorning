import XCTest
@testable import Programme

/// safeguarding spec, "No question about vomiting or laxatives", scenario
/// "Weekly review" (mm-t32.18). Runs `ScreeningQuestionCatalog
/// .mentionsCompensation(_:)` against every question the weekly review and
/// the self-harm item show.
final class NoCompensationQuestionAtAWeeklyReviewTests: XCTestCase {
    func testWeeklyReviewQuestionsMentionNoCompensation() {
        let questions = ReviewContent.reflectionQuestions
            + ReviewContent.weekOneQuestions
            + [ReviewContent.oneThingToChangeQuestion]
            + [ScreeningQuestionCatalog.questions[5], ScreeningQuestionCatalog.selfHarmSecondQuestion]
            + [ReviewContent.gettingWorseButton]
        for question in questions {
            XCTAssertFalse(ScreeningQuestionCatalog.mentionsCompensation(question), "\"\(question)\" mentions a compensation word")
        }
    }
}
