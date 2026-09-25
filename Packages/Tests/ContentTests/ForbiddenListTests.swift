import XCTest
@testable import Content

/// "The forbidden list" (mm-t11.6). All eight scenarios are built here.
final class ForbiddenListTests: XCTestCase {
    func testForbiddenListHoldsNoDiaryOrNotes() {
        XCTAssertFalse(ForbiddenList.full.contains("diary"))
        XCTAssertFalse(ForbiddenList.full.contains("notes"))
        XCTAssertFalse(ForbiddenList.short.contains("diary"))
        XCTAssertFalse(ForbiddenList.short.contains("notes"))
    }

    /// Scenario: A forbidden word
    func testForbiddenWordFailsAndNamesTheCardIdAndWord() {
        let card = fixtureCard(id: "stage1.treats", body: "This programme treats binge eating.")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].id, "stage1.treats")
        XCTAssertTrue(issues[0].message.contains("treats"))
    }

    /// Scenario: A capital letter
    func testCapitalLetterStillMatchesCaseInsensitively() {
        let card = fixtureCard(id: "stage1.capital", body: "Treatment is not the word.")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues[0].message.lowercased().contains("treatment"))
    }

    /// Scenario: Part of a longer word
    func testPartOfALongerWordPasses() {
        let card = fixtureCard(body: "The card was untreated by the change.")
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([card]), [])
    }

    /// Scenario: A hyphen inside a word
    func testHyphenInsideAWordFailsAndNamesIt() {
        let card = fixtureCard(id: "stage1.cbte", body: "This is not CBT-E.")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues[0].message.contains("CBT-E"))
    }

    /// Scenario: Notes is allowed
    func testFeelingFatNotesPhrasePasses() {
        let card = fixtureCard(body: "Open Feeling fat notes from here.")
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([card]), [])
    }

    /// Scenario: A support string names treatment
    func testSupportStringNamingTreatmentPassesTheShortList() {
        let entry = StringEntry(id: "support.gp", text: "Your GP can talk about treatment options with you.")
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings([entry]), [])
    }

    /// Scenario: A support string on the short list
    func testSupportStringOnTheShortListFails() {
        let entry = StringEntry(id: "notrightnow.selfharm", text: "well done")
        let issues = ContentChecks.forbiddenWordsInStrings([entry])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].id, "notrightnow.selfharm")
        XCTAssertTrue(issues[0].message.contains("well done"))
    }

    /// Scenario: A question on the full list
    func testQuestionOnTheFullListFails() {
        let entry = StringEntry(id: "maintenance.2", text: "How do you feel about your recovery?")
        let issues = ContentChecks.forbiddenWordsInStrings([entry])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].id, "maintenance.2")
        XCTAssertTrue(issues[0].message.contains("recovery"))
    }

    func testShippedCardsAndStringsHoldNoForbiddenWord() {
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards(Shipped.bundle.cards), [])
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(Shipped.bundle.strings), [])
    }
}
