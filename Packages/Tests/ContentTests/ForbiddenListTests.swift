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

    // MARK: - Ruling r17-02: the permitted sentences

    /// The full lists stay as they are. The exception is a list of exact
    /// sentences, not a word taken off a list.
    func testTheListsStayFullAndThePermittedSentencesAreExactlyThese() {
        for word in ["CBT", "therapy", "therapist"] {
            XCTAssertTrue(ForbiddenList.full.contains(word), word)
        }
        XCTAssertTrue(ForbiddenList.short.contains("CBT"))
        XCTAssertEqual(ForbiddenList.permittedSentences, [
            "It is not therapy.",
            "It is not therapy, and it does not replace your GP or anyone treating you.",
            "It uses ideas from CBT.",
            "Are you getting help from a clinic or a therapist for your eating at the moment?",
        ])
    }

    /// The three signed-off strings pass under their own ids, with the full
    /// list.
    func testTheThreeSignedOffStringsPass() {
        let entries = [
            StringEntry(id: "onboarding.screen1.line1", text: "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT."),
            StringEntry(id: "onboarding.screen1.line3", text: "It is not therapy, and it does not replace your GP or anyone treating you."),
            StringEntry(id: "screening.question.treatment", text: "Are you getting help from a clinic or a therapist for your eating at the moment?"),
        ]
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(entries), [])
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings([StringEntry(id: "onboarding.a", text: "It is not therapy.")]), [])
    }

    /// A permitted sentence is skipped as a whole, exact string. A change to
    /// a letter, the case, a hyphen or the punctuation makes the test check
    /// it again, and the test names the word.
    func testASentenceThatIsNotExactlyPermittedFails() {
        let cases: [(text: String, word: String)] = [
            ("It uses ideas from CBT-E.", "CBT-E"),
            ("it uses ideas from CBT.", "CBT"),
            ("It uses ideas from CBT", "CBT"),
            ("It uses ideas from CBT!", "CBT"),
            ("Midmorning uses ideas from CBT.", "CBT"),
            ("It is not therapy, and it is not for weight loss.", "therapy"),
            ("Are you getting help from a therapist for your eating at the moment?", "therapist"),
            ("Is your therapist happy for you to use this?", "therapist"),
        ]
        for (text, word) in cases {
            let issues = ContentChecks.forbiddenWordsInStrings([StringEntry(id: "onboarding.a", text: text)])
            XCTAssertEqual(issues.count, 1, text)
            XCTAssertEqual(issues.first?.id, "onboarding.a", text)
            XCTAssertTrue(issues.first?.message.contains("\"\(word)\"") ?? false, text)
        }
    }

    /// The test checks every other sentence of a string that holds a
    /// permitted sentence. A phrase on a list does not join across a
    /// permitted sentence.
    func testTheOtherSentencesOfAStringAreStillChecked() {
        let issues = ContentChecks.forbiddenWordsInStrings([
            StringEntry(id: "onboarding.a", text: "Midmorning is CBT for binge eating. It uses ideas from CBT."),
            StringEntry(id: "onboarding.b", text: "It uses ideas from CBT. It is therapy in your pocket."),
            StringEntry(id: "support.a", text: "It is not therapy. Well done."),
        ])
        XCTAssertEqual(issues.map(\.id), ["onboarding.a", "onboarding.b", "support.a"])
        XCTAssertTrue(issues[0].message.contains("\"CBT\""))
        XCTAssertTrue(issues[1].message.contains("\"therapy\""))
        XCTAssertTrue(issues[2].message.contains("\"well done\""))
        XCTAssertEqual(ForbiddenList.checkedParts(of: "Well. It uses ideas from CBT. Done."), ["Well.", "Done."])
        XCTAssertEqual(ForbiddenList.firstMatch(in: "Well. It uses ideas from CBT. Done.", id: "onboarding.a"), nil)
    }

    /// The exception reads the sentences of a card too.
    func testACardSentenceThatIsNotExactlyPermittedFails() {
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([fixtureCard(body: "It is not therapy. It is a programme.")]), [])
        let issues = ContentChecks.forbiddenWordsInCards([fixtureCard(id: "stage1.therapy", body: "It is not therapy. Therapy is not the word.")])
        XCTAssertEqual(issues.map(\.id), ["stage1.therapy"])
    }

    func testSentencesKeepTheirCharacters() {
        XCTAssertEqual(
            ForbiddenList.sentences(of: "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT."),
            ["Midmorning is a 12-week self-help programme for people who binge eat.", "It uses ideas from CBT."]
        )
        XCTAssertEqual(ForbiddenList.sentences(of: "One? Two!  Three"), ["One?", "Two!", "Three"])
        XCTAssertEqual(ForbiddenList.sentences(of: ""), [])
        XCTAssertEqual(ForbiddenList.checkedParts(of: "It uses ideas from CBT."), [])
    }

    func testShippedCardsAndStringsHoldNoForbiddenWord() {
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards(Shipped.bundle.cards), [])
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(Shipped.bundle.strings), [])
    }
}
