import XCTest
@testable import Content

/// "Catalogue rules" (mm-t11.15). "Rendering at AX5" is a device check, on
/// the epic's device-check bead. The other eight scenarios are built here.
final class CatalogueRulesTests: XCTestCase {
    /// Scenario: A count without plural forms
    func testCountWithNoPluralFormsRequiresThem() {
        XCTAssertTrue(CatalogueRules.requiresPluralForms("%lld recorded days"))
        let issues = ContentChecks.catalogueRuleIssues(id: "fixture.count", text: "%lld recorded days", kind: nil, plural: nil)
        XCTAssertTrue(issues.contains { $0.id == "fixture.count" && $0.message.contains("plural") })
    }

    func testCountWithPluralFormsPasses() {
        let plural = PluralForms(zero: "No recorded days", one: "%lld recorded day", other: "%lld recorded days")
        let issues = ContentChecks.catalogueRuleIssues(id: "fixture.count", text: "%lld recorded days", kind: nil, plural: plural)
        XCTAssertFalse(issues.contains { $0.message.contains("plural") })
    }

    /// Scenario: A literal constant
    func testLiteralConstantIsDetected() {
        XCTAssertTrue(CatalogueRules.hasLiteralConstant("Buzz at 20 minutes"))
    }

    func testAPlaceholderIsNotALiteralConstant() {
        XCTAssertFalse(CatalogueRules.hasLiteralConstant("Buzz at %lld minutes"))
    }

    func testAPositionPrefixIsNotALiteralConstant() {
        XCTAssertFalse(CatalogueRules.hasLiteralConstant("Opens after %1$lld recorded days. You have %2$lld."))
    }

    func testASingleDigitIsNotFlagged() {
        XCTAssertFalse(CatalogueRules.hasLiteralConstant("Stage 2 opens after your plan."))
    }

    /// Scenario: Two placeholders without positions
    func testTwoPlaceholdersWithoutPositionsIsDetected() {
        XCTAssertTrue(CatalogueRules.hasUnpositionedMultiplePlaceholders("A day runs from %@ to %@."))
    }

    func testTwoPositionalPlaceholdersPass() {
        XCTAssertFalse(CatalogueRules.hasUnpositionedMultiplePlaceholders("A day runs from %1$@ to %2$@."))
    }

    /// Scenario: A control label over the limit
    func testControlLabelOverTheLimitFailsAndNamesTheLimit() {
        let text = String(repeating: "x", count: 17)
        let issues = ContentChecks.catalogueRuleIssues(id: "fixture.control", text: text, kind: .navigationOrCardControl, plural: nil)
        XCTAssertTrue(issues.contains { $0.id == "fixture.control" && $0.message.contains("16") })
    }

    func testControlLabelAtTheLimitPasses() {
        let text = String(repeating: "x", count: 16)
        XCTAssertFalse(CatalogueRules.exceedsLimit(text, kind: .navigationOrCardControl))
    }

    /// Scenario: A full stop on a label
    func testFullStopOnALabelFailsAndNamesTheId() {
        XCTAssertTrue(CatalogueRules.endsWithFullStop("Weekly summary."))
    }

    func testALabelWithNoFullStopPasses() {
        XCTAssertFalse(CatalogueRules.endsWithFullStop("Weekly summary"))
    }

    /// Scenario: A bare plural
    func testBarePluralBingesFailsAndNamesTheId() {
        let issues = ContentChecks.catalogueRuleIssues(id: "fixture.plural", text: "Look back at your binges.", kind: nil, plural: nil)
        XCTAssertTrue(issues.contains { $0.id == "fixture.plural" && $0.message.contains("binges") })
    }

    func testAllowedSingularBingePasses() {
        XCTAssertFalse(CatalogueRules.hasBarePluralBinges("after a binge"))
    }

    /// Scenario: The sign-off list
    func testTheReadmeSignOffListMatchesTheCatalogueIds() throws {
        let signOffListURL = RepositoryRoot.path.appendingPathComponent("Packages/Content/SIGNOFF.md")
        let readme = try String(contentsOf: signOffListURL, encoding: .utf8)
        let listed = signOffListIds(in: readme)
        XCTAssertFalse(listed.isEmpty, "the README's Sign-off list section should not be empty")
        let expected = Set(Shipped.bundle.cards.map(\.id) + Shipped.bundle.strings.map(\.id))
        XCTAssertEqual(Set(listed), expected)
    }

    /// Scenario: The Contact placeholder
    func testContactPlaceholderPasses() {
        XCTAssertTrue(CatalogueRules.isValidContactValue("contact@example.invalid"))
    }

    func testContactEmailAddressPasses() {
        XCTAssertTrue(CatalogueRules.isValidContactValue("support@midmorning.uk"))
    }

    func testContactNeitherPlaceholderNorEmailFails() {
        XCTAssertFalse(CatalogueRules.isValidContactValue("not an email"))
    }

    func testTheSentenceCaseAndFullStopRulesDoNotApplyToAboutContact() {
        // "about.contact" holds a bare address with no sentence-case or
        // full-stop shape; the caller simply never runs those two checks
        // for this one id, which `isValidContactValue` covers instead.
        XCTAssertFalse(CatalogueRules.isSentenceCase("contact@example.invalid"))
        XCTAssertTrue(CatalogueRules.isValidContactValue("contact@example.invalid"))
    }

    /// The shipped "about.contact" entry (settings spec, "The About group";
    /// decision 99): the About group shows this value until mm-t43.17 sets
    /// the confirmed support email, and either form passes this rule.
    func testShippedAboutContactHoldsThePlaceholderAndPassesTheRule() {
        let entry = Shipped.bundle.string(id: "about.contact")
        XCTAssertEqual(entry?.text, "contact@example.invalid")
        XCTAssertTrue(CatalogueRules.isValidContactValue(entry!.text))
    }
}

/// Extracts the ids from the README's "## Sign-off list" fenced code block.
private func signOffListIds(in readme: String) -> [String] {
    guard let headingRange = readme.range(of: "## Sign-off list") else { return [] }
    let afterHeading = readme[headingRange.upperBound...]
    guard let fenceStart = afterHeading.range(of: "```") else { return [] }
    let afterFenceStart = afterHeading[fenceStart.upperBound...]
    guard let fenceEnd = afterFenceStart.range(of: "```") else { return [] }
    let block = afterFenceStart[..<fenceEnd.lowerBound]
    return block.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
}
