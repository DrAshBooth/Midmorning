import XCTest
@testable import Content

/// "Every bundled string family has ids" (mm-t11.14): the bundle rule and
/// the content test checks. Each family's own strings are sibling beads'
/// work (mm-t11.28 to mm-t11.36, mm-t11.38); their tests cover the
/// scenarios named there.
final class StringFamilyIdsTests: XCTestCase {
    /// Scenario: Two strings with one id
    func testTwoStringsWithOneIdFailsAndNamesIt() {
        let entries = [
            StringEntry(id: "support.samaritans.title", text: "Samaritans"),
            StringEntry(id: "support.samaritans.title", text: "Samaritans (Welsh)"),
        ]
        let issues = ContentChecks.idUniqueness(entries)
        XCTAssertEqual(issues.map(\.id), ["support.samaritans.title"])
    }

    func testUniqueIdsPass() {
        let entries = [StringEntry(id: "a", text: "one"), StringEntry(id: "b", text: "two")]
        XCTAssertEqual(ContentChecks.idUniqueness(entries), [])
    }

    /// Scenario: Sign-off covers the strings (a fixture bundle)
    func testAStringChangeWithNoVersionRiseFailsTheLockCheckLikeACard() {
        let before = ContentBundle(contentVersion: 5, cards: [], strings: [StringEntry(id: "opening.stage5", text: "Original text.")])
        let lock = ContentLock(contentVersion: 5, bundleHash: before.bundleHash)
        let after = ContentBundle(contentVersion: 5, cards: [], strings: [StringEntry(id: "opening.stage5", text: "Changed text.")])
        XCTAssertTrue(ContentLock.disagrees(lock, with: after))
    }

    func testShippedStringsHoldNoDuplicateId() {
        XCTAssertEqual(ContentChecks.idUniqueness(Shipped.bundle.strings), [])
    }

    func testShippedStringsFollowUnpositionedPlaceholderAndPluralRules() {
        for entry in Shipped.bundle.strings {
            XCTAssertFalse(
                CatalogueRules.hasUnpositionedMultiplePlaceholders(entry.text),
                "\(entry.id) holds more than one placeholder without positions"
            )
            if CatalogueRules.requiresPluralForms(entry.text) {
                XCTAssertNotNil(entry.plural, "\(entry.id) holds a bare count placeholder and needs plural forms")
            }
        }
    }
}
