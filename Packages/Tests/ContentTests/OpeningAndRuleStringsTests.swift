import XCTest
@testable import Content

/// "the opening.stage2 string" (mm-t11.28) and "the rule.stage2 to
/// rule.stage7 strings" (mm-t11.29).
final class OpeningAndRuleStringsTests: XCTestCase {
    /// Scenario: An opening sentence
    func testOpeningStage2Text() {
        let entry = Shipped.bundle.string(id: "opening.stage2")
        XCTAssertEqual(entry?.text, "You can now plan when to eat. The app reminds you at each planned meal.")
    }

    /// Scenario: A rule string with its numbers
    func testRuleStage2FillsBothPositionalPlaceholders() {
        let entry = Shipped.bundle.string(id: "rule.stage2")!
        XCTAssertEqual(entry.text, "Opens after %1$lld recorded days. You have %2$lld.")
        XCTAssertEqual(PositionalFormat.fill(entry.text, with: [5, 2]), "Opens after 5 recorded days. You have 2.")
    }

    /// Scenario: The stage 3 rule string
    func testRuleStage3Text() {
        let entry = Shipped.bundle.string(id: "rule.stage3")!
        XCTAssertEqual(entry.text, "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts")
        XCTAssertEqual(PositionalFormat.fill(entry.text, with: [7, 2]), "Opens after 7 days on your plan, or 2 weeks after your plan starts")
    }

    /// Scenario: A rule string with three placeholders
    func testARuleStage3WithAThirdPlaceholderFailsAndNamesIt() {
        let issues = ruleStringPlaceholderIssues(id: "rule.stage3", text: "Opens after %1$lld days, %2$lld weeks, %3$lld months", expectedPositions: 2)
        XCTAssertEqual(issues.map(\.id), ["rule.stage3"])
    }

    func testRuleStage2And3HoldExactlyTwoPositionalPlaceholders() {
        for id in ["rule.stage2", "rule.stage3"] {
            let entry = Shipped.bundle.string(id: id)!
            let positions = Set(CatalogueRules.placeholders(in: entry.text).map(\.position))
            XCTAssertEqual(positions, [1, 2], id)
        }
    }

    func testEveryOtherRuleStringHoldsAtMostOnePlaceholder() {
        for id in ["rule.stage4", "rule.stage5", "rule.stage6", "rule.stage7"] {
            let entry = Shipped.bundle.string(id: id)!
            XCTAssertLessThanOrEqual(CatalogueRules.placeholders(in: entry.text).count, 1, id)
        }
    }

    func testRuleStage2IsTwoSentencesEachEndingWithAFullStop() {
        let text = Shipped.bundle.string(id: "rule.stage2")!.text
        let sentences = text.split(separator: ".").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(sentences.count, 2)
        XCTAssertTrue(text.hasSuffix("."))
    }

    func testEveryOtherRuleStringOfOneSentenceDoesNotEndWithAFullStop() {
        for id in ["rule.stage3", "rule.stage4", "rule.stage5", "rule.stage6", "rule.stage7"] {
            let text = Shipped.bundle.string(id: id)!.text
            XCTAssertFalse(CatalogueRules.endsWithFullStop(text), id)
        }
    }

    func testRuleStringsHoldNoForbiddenWordAndFollowUKSpelling() {
        let ruleEntries = Shipped.bundle.strings.filter { $0.id.hasPrefix("rule.") || $0.id == "opening.stage2" }
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(ruleEntries), [])
        for entry in ruleEntries {
            XCTAssertNil(USSpellings.firstMatch(in: entry.text), entry.id)
        }
    }
}

/// A pure helper mirroring what a family-specific check would do for
/// "rule.stage3": fail when the text holds more or fewer than
/// `expectedPositions` distinct positional placeholders.
private func ruleStringPlaceholderIssues(id: String, text: String, expectedPositions: Int) -> [ContentIssue] {
    let positions = Set(CatalogueRules.placeholders(in: text).compactMap(\.position))
    return positions.count == expectedPositions ? [] : [ContentIssue(id: id, message: "holds \(positions.count) positional placeholders, expected \(expectedPositions)")]
}
