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

    /// Scenario: A rule string with its numbers. Ruling r13-12 splits the
    /// two counts into two strings, "rule.stage2" and "rule.stage2.count",
    /// each with one count and its own plural forms.
    func testRuleStage2FillsBothCounts() {
        XCTAssertEqual(ShippedRule.stage2(gate: 5, recordedDays: 2), "Opens after 5 recorded days. You have 2.")
        XCTAssertEqual(ShippedRule.stage2(gate: 1, recordedDays: 0), "Opens after 1 recorded day. You have 0.")
    }

    /// Scenario: The stage 3 rule string. "rule.stage3" takes two text
    /// placeholders, filled from "rule.stage3.days" and "rule.stage3.weeks".
    func testRuleStage3Text() {
        XCTAssertEqual(Shipped.bundle.string(id: "rule.stage3")?.text, "Opens after %1$@, or %2$@ after your plan starts")
        XCTAssertEqual(ShippedRule.stage3(days: 7, weeks: 2), "Opens after 7 days on your plan, or 2 weeks after your plan starts")
        XCTAssertEqual(ShippedRule.stage3(days: 1, weeks: 1), "Opens after 1 day on your plan, or 1 week after your plan starts")
    }

    /// Ruling r13-12: a string holds at most one count, and each count
    /// carries plural forms.
    func testEveryRuleStringHoldsAtMostOneCountWithPluralForms() {
        for entry in Shipped.bundle.strings where entry.id.hasPrefix("rule.") {
            XCTAssertLessThanOrEqual(CatalogueRules.countPlaceholderCount(entry.text), 1, entry.id)
            if CatalogueRules.requiresPluralForms(entry.text) {
                XCTAssertNotNil(entry.plural, entry.id)
            }
        }
    }

    /// Scenario: A rule string with three placeholders
    func testARuleStage3WithAThirdPlaceholderFailsAndNamesIt() {
        let issues = ruleStringPlaceholderIssues(id: "rule.stage3", text: "Opens after %1$lld days, %2$lld weeks, %3$lld months", expectedPositions: 2)
        XCTAssertEqual(issues.map(\.id), ["rule.stage3"])
    }

    func testRuleStage3HoldsExactlyTwoPositionalPlaceholders() {
        let entry = Shipped.bundle.string(id: "rule.stage3")!
        let positions = Set(CatalogueRules.placeholders(in: entry.text).map(\.position))
        XCTAssertEqual(positions, [1, 2])
    }

    func testEveryOtherRuleStringHoldsAtMostOnePlaceholder() {
        for id in ["rule.stage2", "rule.stage2.count", "rule.stage3.days", "rule.stage3.weeks", "rule.stage4", "rule.stage5", "rule.stage6", "rule.stage7"] {
            let entry = Shipped.bundle.string(id: id)!
            XCTAssertLessThanOrEqual(CatalogueRules.placeholders(in: entry.text).count, 1, id)
        }
    }

    /// "rule.stage2" is two sentences, and each ends with a full stop. Each
    /// sentence is its own string (ruling r13-12).
    func testRuleStage2IsTwoSentencesEachEndingWithAFullStop() {
        for id in ["rule.stage2", "rule.stage2.count"] {
            let entry = Shipped.bundle.string(id: id)!
            for form in [entry.text, entry.form(for: 0), entry.form(for: 1), entry.form(for: 2)] {
                let sentences = form.split(separator: ".").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                XCTAssertEqual(sentences.count, 1, id)
                XCTAssertTrue(form.hasSuffix("."), id)
            }
        }
    }

    func testEveryOtherRuleStringOfOneSentenceDoesNotEndWithAFullStop() {
        for id in ["rule.stage3", "rule.stage3.days", "rule.stage3.weeks", "rule.stage4", "rule.stage5", "rule.stage6", "rule.stage7"] {
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

/// The shipped rule strings, filled the way `Programme` fills them: each
/// count picks its own plural form.
enum ShippedRule {
    static func entry(_ id: String) -> StringEntry {
        guard let entry = Shipped.bundle.string(id: id) else { fatalError("no bundle string \(id)") }
        return entry
    }

    static func count(_ id: String, _ value: Int) -> String {
        PositionalFormat.fill(entry(id).form(for: value), with: [value])
    }

    static func stage2(gate: Int, recordedDays: Int) -> String {
        count("rule.stage2", gate) + " " + count("rule.stage2.count", recordedDays)
    }

    static func stage3(days: Int, weeks: Int) -> String {
        String(format: entry("rule.stage3").text, count("rule.stage3.days", days), count("rule.stage3.weeks", weeks))
    }
}

/// A pure helper mirroring what a family-specific check would do for
/// "rule.stage3": fail when the text holds more or fewer than
/// `expectedPositions` distinct positional placeholders.
private func ruleStringPlaceholderIssues(id: String, text: String, expectedPositions: Int) -> [ContentIssue] {
    let positions = Set(CatalogueRules.placeholders(in: text).compactMap(\.position))
    return positions.count == expectedPositions ? [] : [ContentIssue(id: id, message: "holds \(positions.count) positional placeholders, expected \(expectedPositions)")]
}
