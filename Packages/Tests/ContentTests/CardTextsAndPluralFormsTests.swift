import XCTest
@testable import Content

/// mm-t11.42: every card rule reads the title, the body and the one thing
/// to do; every string rule reads the plural forms; no two cards share an
/// id. content spec, "The forbidden list", "Plain UK English", "Tone of
/// every card", "The app bundles the cards", "Every bundled string family
/// has ids".
final class CardTextsAndPluralFormsTests: XCTestCase {
    /// "The content test MUST fail when a card holds a word from it": a
    /// forbidden word in the title.
    func testAForbiddenWordInTheTitleFailsAndNamesTheCard() {
        let card = fixtureCard(id: "stage2.plan", title: "Your recovery plan")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.map(\.id), ["stage2.plan"])
        XCTAssertTrue(issues.first?.message.contains("recovery") ?? false)
    }

    /// A forbidden word in the one thing to do.
    func testAForbiddenWordInTheOneThingFailsAndNamesTheCard() {
        let card = fixtureCard(id: "stage1.entry", oneThing: "Log your next meal.")
        let issues = ContentChecks.forbiddenWordsInCards([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.entry"])
        XCTAssertTrue(issues.first?.message.contains("log") ?? false)
    }

    func testUKSpellingIsCheckedInTheTitle() {
        let card = fixtureCard(id: "stage1.why", title: "Realize what happens")
        XCTAssertEqual(ContentChecks.ukSpelling([card]).map(\.id), ["stage1.why"])
    }

    func testHowTheCardAddressesThePersonIsCheckedInTheOneThing() {
        let card = fixtureCard(id: "stage1.star", oneThing: "The user stars the entry.")
        XCTAssertEqual(ContentChecks.addressesPerson([card]).map(\.id), ["stage1.star"])
    }

    func testAPlaceholderInTheOneThingFails() {
        let card = fixtureCard(id: "stage1.weighin", oneThing: "Weigh yourself on {weighInDay}.")
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder([card]).map(\.id), ["stage1.weighin"])
    }

    func testBingeOutsideTheAllowedPhrasesInTheTitleFails() {
        let card = fixtureCard(id: "stage2.makingup", title: "After you binge")
        XCTAssertEqual(ContentChecks.bingeUsageViolations([card]).map(\.id), ["stage2.makingup"])
    }

    /// A clean card passes every rule in all three texts.
    func testACleanCardPassesEveryRule() {
        let card = fixtureCard(title: "The star", body: "After a binge, the next planned meal still happens.", oneThing: "Star the next entry that felt like a binge.")
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards([card]), [])
        XCTAssertEqual(ContentChecks.ukSpelling([card]), [])
        XCTAssertEqual(ContentChecks.addressesPerson([card]), [])
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder([card]), [])
        XCTAssertEqual(ContentChecks.bingeUsageViolations([card]), [])
    }

    /// A forbidden word in a plural form fails, although the base text is
    /// clean.
    func testAForbiddenWordInAPluralFormFails() {
        let entry = StringEntry(
            id: "rule.stage2",
            text: "Opens after %lld recorded days.",
            plural: PluralForms(zero: "No recorded days yet.", one: "One day in your tracker.", other: "%lld recorded days.")
        )
        let issues = ContentChecks.forbiddenWordsInStrings([entry])
        XCTAssertEqual(issues.map(\.id), ["rule.stage2"])
        XCTAssertTrue(issues.first?.message.contains("tracker") ?? false)
    }

    func testAPlaceholderInAPluralFormFails() {
        let entry = StringEntry(id: "reflection.1", text: "What went well?", plural: PluralForms(zero: "What went well?", one: "What went well on {weekday}?", other: "What went well?"))
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder(in: entry).map(\.id), ["reflection.1"])
    }

    func testTwoCardsWithOneIdFailAndNameIt() {
        let cards = [fixtureCard(id: "stage1.why"), fixtureCard(id: "stage1.why", title: "Another card")]
        XCTAssertEqual(ContentChecks.cardIdUniqueness(cards).map(\.id), ["stage1.why"])
    }

    func testACardWithNoIdFails() {
        XCTAssertEqual(ContentChecks.cardIdUniqueness([fixtureCard(id: "")]).map(\.message), ["a card has no id"])
    }

    /// The shipped bundle passes every widened rule.
    func testTheShippedBundlePassesEveryWidenedRule() {
        let bundle = Shipped.bundle
        XCTAssertEqual(ContentChecks.cardIdUniqueness(bundle.cards), [])
        XCTAssertEqual(ContentChecks.forbiddenWordsInCards(bundle.cards), [])
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(bundle.strings), [])
        XCTAssertEqual(ContentChecks.ukSpelling(bundle.cards), [])
        XCTAssertEqual(ContentChecks.addressesPerson(bundle.cards), [])
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder(bundle.cards), [])
        XCTAssertEqual(ContentChecks.bingeUsageViolations(bundle.cards), [])
    }
}
