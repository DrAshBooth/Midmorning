import XCTest
@testable import Content

/// "The card screen and the card list" (mm-t11.12).
final class CardScreenTests: XCTestCase {
    /// Scenario: The list for stage 1
    func testStage1ListMatchesTheCatalogueOrderWithNoTickOrCount() {
        let titles = CardList.titles(for: .stage(1), in: Shipped.bundle)
        XCTAssertEqual(titles, [
            "Why write it down",
            "How to make an entry",
            "The star",
            "How it keeps itself going",
            "Weighing once a week",
        ])
    }

    func testStage2ListMatchesTheCatalogueOrder() {
        let titles = CardList.titles(for: .stage(2), in: Shipped.bundle)
        XCTAssertEqual(titles, [
            "Eating by the clock",
            "Three meals and two or three snacks",
            "No gap over four hours",
            "After a skipped meal or a binge",
            "When, not what",
        ])
    }

    /// Scenario: VoiceOver headings (over a `CardScreen` value; mm-t21.23
    /// wires it into the Programme screen and proves it on a device)
    func testVoiceOverStopsAtTheTitleAndOneThingToDo() {
        let card = Shipped.bundle.card(id: "stage1.why")!
        let screen = CardScreen(card: card)
        XCTAssertEqual(screen.voiceOverHeadings, ["Why write it down", "One thing to do"])
    }

    func testTheScreenShowsNoImageAndOnlyTheAllowedControls() {
        let card = Shipped.bundle.card(id: "stage1.why")!
        let screen = CardScreen(card: card)
        XCTAssertTrue(screen.showsNoImage)
        XCTAssertEqual(screen.controls, [.close, .getSupport, .scroll])
    }

    func testTheScreenAddsTheLinkControlWhenTheCardHoldsOne() {
        let card = fixtureCard(links: [CardLink(target: "Feeling fat notes")])
        let screen = CardScreen(card: card)
        XCTAssertEqual(screen.controls, [.close, .getSupport, .link(CardLink(target: "Feeling fat notes")), .scroll])
    }

    /// Scenario: Largest text size (over a `CardScreen` value, with no live
    /// dependency; mm-t21.23 runs it end to end on a device). The screen
    /// model itself never truncates: it keeps a long card's full text with
    /// no length cap, which a fixed line limit in the view would break.
    func testTheScreenKeepsTheFullTextWithNoTruncation() {
        let longBody = Array(repeating: "A long sentence with several words in it.", count: 40).joined(separator: " ")
        let card = fixtureCard(body: longBody, oneThing: "One long sentence that names a single clear action to take.")
        let screen = CardScreen(card: card)
        XCTAssertEqual(screen.body, longBody)
        XCTAssertEqual(screen.body.count, longBody.count)
        XCTAssertEqual(screen.oneThing, card.oneThing)
    }
}
