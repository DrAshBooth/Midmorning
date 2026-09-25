import XCTest
@testable import Content

/// "Each stage has three to five cards" (mm-t11.1). The first-cut content
/// test applies the rule to stages 1 and 2, the only stages the bundle
/// ships; a later stage's bead extends it to its own stage.
final class CardCountTests: XCTestCase {
    func testShippedStage1And2HoldThreeToFiveCards() {
        let issues = ContentChecks.cardCounts(Shipped.bundle, sections: [.stage(1), .stage(2)])
        XCTAssertEqual(issues, [], "stage 1 and stage 2 should each hold 3 to 5 cards")
    }

    /// Scenario: A stage with four cards
    func testStageWithFourCardsPasses() {
        let bundle = ContentBundle(contentVersion: 1, cards: (1...4).map {
            fixtureCard(id: "stage3.card\($0)", section: .stage(3))
        }, strings: [])
        let issues = ContentChecks.cardCounts(bundle, sections: [.stage(3)])
        XCTAssertEqual(issues, [])
    }

    /// Scenario: A stage with six cards
    func testStageWithSixCardsFailsAndNamesTheStage() {
        let bundle = ContentBundle(contentVersion: 1, cards: (1...6).map {
            fixtureCard(id: "stage2.card\($0)", section: .stage(2))
        }, strings: [])
        let issues = ContentChecks.cardCounts(bundle, sections: [.stage(2)])
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues[0].message.contains("stage 2"))
    }

    /// Scenario: A long card
    func testLongCardFailsAndNamesTheCardId() {
        let longBody = Array(repeating: "word", count: 501).joined(separator: " ")
        let card = fixtureCard(id: "stage1.toolong", body: longBody)
        let issues = ContentChecks.wordLimit([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.toolong"])
    }

    func testFiveHundredWordsIsWithinTheLimit() {
        let body = Array(repeating: "word", count: 500).joined(separator: " ")
        let card = fixtureCard(body: body)
        XCTAssertEqual(ContentChecks.wordLimit([card]), [])
    }

    /// Scenario: A card with an image
    func testCardWithAnImageReferenceFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage1.withimage", body: "See this. ![a diagram](diagram.png) More text.")
        let issues = ContentChecks.noImageReference([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.withimage"])
    }

    func testAnOrdinaryCardHasNoImageReference() {
        XCTAssertEqual(ContentChecks.noImageReference([fixtureCard()]), [])
    }

    func testShippedCardsAreWithinTheWordLimitAndHoldNoImage() {
        XCTAssertEqual(ContentChecks.wordLimit(Shipped.bundle.cards), [])
        XCTAssertEqual(ContentChecks.noImageReference(Shipped.bundle.cards), [])
    }
}
