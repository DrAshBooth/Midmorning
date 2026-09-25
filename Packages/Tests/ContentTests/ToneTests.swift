import XCTest
@testable import Content

/// "Tone of every card" (mm-t11.5). All four scenarios are built here.
/// "A lapse" is also a matter for the clinical reviewer's own reading at
/// sign-off; the machine checks below cover what a machine can check.
final class ToneTests: XCTestCase {
    /// Scenario: Cheerleading
    func testCheerleadingFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage1.cheer", body: "You've got this!")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.cheer"])
    }

    /// Scenario: A lapse. "A slip is a slip" ships with staying-on-track
    /// (3.6); here the check is that the shipped stage 2 card covering a
    /// lapse-like moment, "After a skipped meal or a binge", adds no
    /// praise or blame word and states the plain fact.
    func testAfterASkippedMealOrABingeAddsNoPraiseOrBlame() {
        let card = Shipped.bundle.card(id: "stage2.makingup")!
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([card]), [])
        let praiseOrBlame = ["should", "shouldn't", "failed", "failure", "bad", "good job", "well done"]
        XCTAssertNil(WordMatcher.firstMatch(in: card.body, entries: praiseOrBlame))
    }

    /// Scenario: The word binge in a card
    func testTheWordBingeInAnAllowedPhrasePasses() {
        let card = fixtureCard(body: "after a binge, the next planned meal still happens")
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([card]), [])
        XCTAssertEqual(ContentChecks.bingeUsageViolations([card]), [])
    }

    /// Scenario: A forbidden form of binge
    func testBingeEpisodeFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage1.episode", body: "a binge episode happened")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.episode"])
    }

    func testBingeOutsideTheAllowedPhrasesFails() {
        let card = fixtureCard(id: "stage1.bareword", body: "The binge was hard to write about.")
        let issues = ContentChecks.bingeUsageViolations([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.bareword"])
    }

    func testShippedCardsUseBingeOnlyInTheAllowedPhrases() {
        XCTAssertEqual(ContentChecks.bingeUsageViolations(Shipped.bundle.cards), [])
    }
}
