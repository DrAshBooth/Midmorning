import XCTest
@testable import Content

/// "Catalogue rules": "Every string with a count MUST carry plural forms
/// with the categories zero, one and other." Ruling r13-12 (mm-t11.43): every
/// `%lld` is a count, with or without a position, and a `%@` is not. A string
/// holds at most one count, so that its plural forms follow that count; a
/// string with two counts becomes two strings with one count each.
final class CountAndPluralFormsTests: XCTestCase {
    func testAPositionalCountNeedsPluralForms() {
        XCTAssertTrue(CatalogueRules.requiresPluralForms("Opens after %1$lld recorded days"))
        let issues = ContentChecks.catalogueRuleIssues(id: "fixture.count", text: "Opens after %1$lld recorded days", kind: nil, plural: nil)
        XCTAssertTrue(issues.contains { $0.id == "fixture.count" && $0.message.contains("plural") })
    }

    func testATextPlaceholderNeedsNoPluralForms() {
        XCTAssertFalse(CatalogueRules.requiresPluralForms("Your weigh-in day is %@."))
        XCTAssertFalse(CatalogueRules.requiresPluralForms("Opens after %1$@, or %2$@ after your plan starts"))
    }

    func testTwoCountsInOneStringFailAndNameIt() {
        let text = "Opens after %1$lld recorded days. You have %2$lld."
        XCTAssertTrue(CatalogueRules.holdsMoreThanOneCount(text))
        let plural = PluralForms(zero: text, one: text, other: text)
        let issues = ContentChecks.catalogueRuleIssues(id: "rule.stage2", text: text, kind: nil, plural: plural)
        XCTAssertTrue(issues.contains { $0.id == "rule.stage2" && $0.message.contains("more than one count") })
    }

    func testOneCountAndOneTextPlaceholderPass() {
        XCTAssertFalse(CatalogueRules.holdsMoreThanOneCount("Week %1$lld, %2$@"))
        XCTAssertEqual(CatalogueRules.countPlaceholderCount("Week %1$lld, %2$@"), 1)
    }

    /// Every shipped bundle string holds at most one count, and each string
    /// with a count carries plural forms.
    func testEveryShippedBundleStringHoldsAtMostOneCount() {
        for entry in Shipped.bundle.strings {
            for text in entry.readableTexts {
                XCTAssertFalse(CatalogueRules.holdsMoreThanOneCount(text), entry.id)
            }
            if CatalogueRules.requiresPluralForms(entry.text) {
                XCTAssertNotNil(entry.plural, entry.id)
            }
        }
    }

    /// The same two rules over the app's own `Localizable.xcstrings`: a key
    /// whose text holds a count carries the plural forms zero, one and
    /// other, and no text holds two counts.
    func testEveryAppCatalogueStringHoldsAtMostOneCountWithPluralForms() throws {
        let url = RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings")
        let entries = try XCStringsCatalogue.readEntries(from: url)
        XCTAssertFalse(entries.isEmpty)
        for (key, entry) in entries {
            for text in entry.texts {
                XCTAssertFalse(CatalogueRules.holdsMoreThanOneCount(text), key)
            }
            if entry.texts.contains(where: CatalogueRules.requiresPluralForms) {
                XCTAssertEqual(Set(entry.plural.keys).intersection(["zero", "one", "other"]), ["zero", "one", "other"], key)
            }
        }
    }
}
