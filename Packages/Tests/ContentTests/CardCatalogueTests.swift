import XCTest
@testable import Content

/// "The card catalogue" (mm-t11.13). First cut: only stage 1 and 2 cards
/// ship, so "Every id present" checks the stage 1 and 2 ids only; each
/// later stage's bead extends the check to its own ids (deferred.md).
final class CardCatalogueTests: XCTestCase {
    static let stage1And2Ids = [
        "stage1.why", "stage1.entry", "stage1.star", "stage1.cycle", "stage1.weighin",
        "stage2.clock", "stage2.pattern", "stage2.gap", "stage2.makingup", "stage2.when",
    ]

    /// Scenario: Every id present (restricted to stage 1 and 2)
    func testAllStage1And2IdsArePresent() {
        let issues = ContentChecks.shippedIdsPresent(Shipped.bundle, shippedIds: Self.stage1And2Ids)
        XCTAssertEqual(issues, [])
        XCTAssertEqual(Shipped.bundle.cards.count, 10)
    }

    func testStage1And2TitlesMatchTheCatalogue() {
        let expected: [String: String] = [
            "stage1.why": "Why write it down",
            "stage1.entry": "How to make an entry",
            "stage1.star": "The star",
            "stage1.cycle": "How it keeps itself going",
            "stage1.weighin": "Weighing once a week",
            "stage2.clock": "Eating by the clock",
            "stage2.pattern": "Three meals and two or three snacks",
            "stage2.gap": "No gap over four hours",
            "stage2.makingup": "After a skipped meal or a binge",
            "stage2.when": "When, not what",
        ]
        for (id, title) in expected {
            XCTAssertEqual(Shipped.bundle.card(id: id)?.title, title, id)
        }
    }

    /// Scenario: A renamed card
    func testARenamedCardKeepsItsId() {
        var cards = Shipped.bundle.cards
        let index = cards.firstIndex { $0.id == "stage2.gap" }!
        let renamed = Card(
            id: cards[index].id, section: cards[index].section, title: "Four hours at most",
            body: cards[index].body, oneThing: cards[index].oneThing
        )
        cards[index] = renamed
        XCTAssertEqual(renamed.id, "stage2.gap")
        XCTAssertEqual(renamed.title, "Four hours at most")
    }

    /// Scenario: The stage 2 list
    func testStage2ListOrder() {
        XCTAssertEqual(CardList.titles(for: .stage(2), in: Shipped.bundle), [
            "Eating by the clock",
            "Three meals and two or three snacks",
            "No gap over four hours",
            "After a skipped meal or a binge",
            "When, not what",
        ])
    }

    /// Scenario: A retired card (a fixture bundle)
    func testARetiredCardStaysInTheBundleButNotInTheList() {
        let cards = [
            fixtureCard(id: "stage3.urges", section: .stage(3), title: "Urges rise and pass"),
            fixtureCard(id: "stage3.list", section: .stage(3), title: "Your alternatives list"),
            fixtureCard(id: "stage3.twenty", section: .stage(3), title: "The twenty minutes"),
            fixtureCard(id: "stage3.after", section: .stage(3), title: "After the urge", retired: true),
        ]
        let bundle = ContentBundle(contentVersion: 4, cards: cards, strings: [])
        XCTAssertNotNil(bundle.card(id: "stage3.after"))
        XCTAssertEqual(CardList.titles(for: .stage(3), in: bundle), [
            "Urges rise and pass", "Your alternatives list", "The twenty minutes",
        ])
    }

    /// Scenario: A missing id (a fixture catalogue)
    func testAMissingIdFailsAndNamesIt() {
        let bundle = ContentBundle(contentVersion: 3, cards: [
            fixtureCard(id: "stage3.urges", section: .stage(3)),
            fixtureCard(id: "stage3.list", section: .stage(3)),
        ], strings: [])
        let issues = ContentChecks.shippedIdsPresent(bundle, shippedIds: ["stage3.urges", "stage3.list", "stage3.twenty"])
        XCTAssertEqual(issues.map(\.id), ["stage3.twenty"])
    }

    /// Scenario: A shipped id removed (a fixture catalogue)
    func testAShippedIdRemovedFailsAndNamesIt() {
        let shippedInVersion1 = ["stage5.sixweeks", "stage5.changed", "stage5.modules"]
        let version2Bundle = ContentBundle(contentVersion: 2, cards: [
            fixtureCard(id: "stage5.sixweeks", section: .stage(5)),
            fixtureCard(id: "stage5.modules", section: .stage(5)),
        ], strings: [])
        let issues = ContentChecks.shippedIdsPresent(version2Bundle, shippedIds: shippedInVersion1)
        XCTAssertEqual(issues.map(\.id), ["stage5.changed"])
    }

    func testShippedCardsHoldNoDuplicateId() {
        let ids = Shipped.bundle.cards.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
