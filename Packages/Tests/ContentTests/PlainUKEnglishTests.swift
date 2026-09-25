import XCTest
@testable import Content

/// "Plain UK English" (mm-t11.3). "Plain words" is deferred: mm-t31.15,
/// because it is the clinical reviewer's own judgement on the card "Urges
/// rise and pass", which ships with the urge toolkit.
final class PlainUKEnglishTests: XCTestCase {
    /// Scenario: UK spelling
    func testUSSpellingFailsAndNamesTheCardIdAndWord() {
        let card = fixtureCard(id: "stage1.us", body: "You will realize this soon.")
        let issues = ContentChecks.ukSpelling([card])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].id, "stage1.us")
        XCTAssertTrue(issues[0].message.contains("realize"))
    }

    func testUKSpellingPasses() {
        let card = fixtureCard(body: "You will realise this soon, in colour.")
        XCTAssertEqual(ContentChecks.ukSpelling([card]), [])
    }

    /// Scenario: How the card addresses the person
    func testAddressingThePersonAsUserFails() {
        let card = fixtureCard(id: "stage1.user", body: "Tell the user what happened.")
        let issues = ContentChecks.addressesPerson([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.user"])
    }

    func testAddressingThePersonAsClientFails() {
        let card = fixtureCard(id: "stage1.client", body: "This card speaks to the client directly.")
        let issues = ContentChecks.addressesPerson([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.client"])
    }

    func testAddressingThePersonAsYouPasses() {
        XCTAssertEqual(ContentChecks.addressesPerson([fixtureCard(body: "This card speaks to you directly.")]), [])
    }

    func testShippedCardsUseUKSpellingAndAddressYou() {
        XCTAssertEqual(ContentChecks.ukSpelling(Shipped.bundle.cards), [])
        XCTAssertEqual(ContentChecks.addressesPerson(Shipped.bundle.cards), [])
    }
}
