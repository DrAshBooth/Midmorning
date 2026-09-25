import XCTest
@testable import Content

/// "Every card ends with the one thing to do" (mm-t11.4). All five
/// scenarios are built here.
final class OneThingTests: XCTestCase {
    /// Scenario: The end of a card
    func testHowToMakeAnEntryEndsWithOneThingToDo() {
        let card = Shipped.bundle.card(id: "stage1.entry")!
        let screen = CardScreen(card: card)
        XCTAssertEqual(screen.oneThing, "Write down the next thing you eat within a few minutes of eating it.")
        XCTAssertEqual(screen.voiceOverHeadings.last, CardScreen.oneThingHeading)
    }

    /// Scenario: The one thing of "How it keeps itself going"
    func testHowItKeepsItselfGoingOneThing() {
        let card = Shipped.bundle.card(id: "stage1.cycle")!
        XCTAssertEqual(card.oneThing, "Notice the next time a strict rule comes right before an urge.")
    }

    /// Scenario: The one thing of "After a skipped meal or a binge"
    func testAfterASkippedMealOrABingeOneThing() {
        let card = Shipped.bundle.card(id: "stage2.makingup")!
        XCTAssertEqual(card.oneThing, "The next planned meal happens on time, whatever happened after the last one.")
    }

    /// Scenario: A card with no one thing to do
    func testEmptyOneThingFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage1.empty", oneThing: "")
        let issues = ContentChecks.oneThingPresent([card])
        XCTAssertEqual(issues.map(\.id), ["stage1.empty"])
    }

    func testWhitespaceOnlyOneThingFails() {
        let card = fixtureCard(id: "stage1.blank", oneThing: "   ")
        XCTAssertEqual(ContentChecks.oneThingPresent([card]).map(\.id), ["stage1.blank"])
    }

    /// Scenario: Two actions. The content spec frames this as the clinical
    /// reviewer's own judgement at sign-off, not a machine MUST-fail rule
    /// ("the clinical reviewer sends the card back"). This heuristic flags
    /// the spec's own example as advisory input to that review; it is not
    /// wired into `ContentChecks`, which the release gate runs.
    func testTwoActionsHeuristicFlagsTheSpecExample() {
        XCTAssertTrue(looksLikeTwoActions("Plan tomorrow and set your weigh-in day."))
    }

    func testTwoActionsHeuristicPassesTheShippedOneThingSentences() {
        for card in Shipped.bundle.cards {
            XCTAssertFalse(looksLikeTwoActions(card.oneThing), "\(card.id): \(card.oneThing)")
        }
    }

    func testShippedCardsAllHoldAOneThing() {
        XCTAssertEqual(ContentChecks.oneThingPresent(Shipped.bundle.cards), [])
    }
}

/// An advisory heuristic for "Two actions": two imperative clauses joined
/// by "and", each with its own verb. It is not a MUST-fail rule; the
/// clinical reviewer decides at sign-off.
private func looksLikeTwoActions(_ oneThing: String) -> Bool {
    let sentence = oneThing.hasSuffix(".") ? String(oneThing.dropLast()) : oneThing
    let clauses = sentence.components(separatedBy: " and ")
    guard clauses.count == 2 else { return false }
    let verbs = ["plan", "set", "choose", "write", "add", "check", "find", "put", "turn", "look", "notice", "trust", "sketch"]
    return clauses.allSatisfy { clause in
        guard let firstWord = clause.split(separator: " ").first?.lowercased() else { return false }
        return verbs.contains(firstWord)
    }
}
