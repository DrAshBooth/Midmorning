import XCTest
@testable import Content

/// "One in-app link on a card" (mm-t11.2). "The 'Feeling fat' card"
/// scenario is deferred: mm-t35.12, because that card ships with the body
/// image module.
final class InAppLinkTests: XCTestCase {
    /// Scenario: Two links
    func testTwoLinksFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage3.twolinks", links: [
            CardLink(target: "Feeling fat notes"),
            CardLink(target: "Your alternatives list"),
        ])
        let issues = ContentChecks.links([card])
        XCTAssertTrue(issues.contains { $0.id == "stage3.twolinks" && $0.message.contains("2 links") })
    }

    /// Scenario: A web link
    func testWebLinkFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage3.weblink", links: [CardLink(target: "https://example.org")])
        let issues = ContentChecks.links([card])
        XCTAssertTrue(issues.contains { $0.id == "stage3.weblink" && $0.message.contains("outside the app") })
    }

    func testOneInAppLinkPasses() {
        let card = fixtureCard(links: [CardLink(target: "Feeling fat notes")])
        XCTAssertEqual(ContentChecks.links([card]), [])
    }

    func testNoShippedFirstCutCardHoldsALink() {
        // Stage 1 and 2 cards ship with no in-app link in the first cut.
        XCTAssertEqual(ContentChecks.links(Shipped.bundle.cards), [])
    }
}
