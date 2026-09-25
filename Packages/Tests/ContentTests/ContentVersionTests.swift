import XCTest
@testable import Content

/// "Content versions" (mm-t11.8). All six scenarios are built here.
final class ContentVersionTests: XCTestCase {
    private func bundle(bodyWord: String) -> ContentBundle {
        ContentBundle(
            contentVersion: 2,
            cards: [fixtureCard(id: "stage1.star", title: "The star", body: "The \(bodyWord) is yours to decide.")],
            strings: []
        )
    }

    /// Scenario: A card's body changes
    func testABodyChangeWithNoVersionRiseFailsTheLockCheck() {
        let original = bundle(bodyWord: "star")
        let lock = ContentLock(contentVersion: 2, bundleHash: original.bundleHash)
        let changed = bundle(bodyWord: "asterisk") // one word changed, version left at 2
        XCTAssertTrue(ContentLock.disagrees(lock, with: changed))
    }

    /// Scenario: A catalogue string changes
    func testACatalogueStringChangeWithNoVersionRiseFailsTheLockCheck() {
        let original = ContentBundle(contentVersion: 3, cards: [], strings: [StringEntry(id: "entry.save", text: "Save")])
        let lock = ContentLock(contentVersion: 3, bundleHash: original.bundleHash)
        let changed = ContentBundle(contentVersion: 3, cards: [], strings: [StringEntry(id: "entry.save", text: "Keep")])
        XCTAssertTrue(ContentLock.disagrees(lock, with: changed))
    }

    /// Scenario: The version rises with the lock
    func testARaisedVersionWithAMatchingLockPasses() {
        let v2 = ContentBundle(contentVersion: 2, cards: [], strings: [StringEntry(id: "a", text: "one")])
        let v3 = ContentBundle(contentVersion: 3, cards: [], strings: [StringEntry(id: "a", text: "two")])
        let staleLock = ContentLock(contentVersion: 2, bundleHash: v2.bundleHash)
        // The stale lock still matches v2's own hash; the check only fires
        // when the versions are equal and the hashes differ.
        XCTAssertFalse(ContentLock.disagrees(staleLock, with: v2))
        let freshLock = ContentLock(contentVersion: 3, bundleHash: v3.bundleHash)
        XCTAssertFalse(ContentLock.disagrees(freshLock, with: v3))
    }

    /// Scenario: A title changes. The id MUST stay the same; a title
    /// change with no version rise still fails the lock check, because the
    /// title is part of the canonical JSON the hash covers.
    func testATitleChangeKeepsTheIdAndFailsTheStaleLock() {
        let before = ContentBundle(contentVersion: 4, cards: [fixtureCard(id: "stage1.star", title: "The star")], strings: [])
        let lock = ContentLock(contentVersion: 4, bundleHash: before.bundleHash)
        let after = ContentBundle(contentVersion: 4, cards: [fixtureCard(id: "stage1.star", title: "Felt like a binge")], strings: [])
        XCTAssertEqual(after.card(id: "stage1.star")?.id, "stage1.star")
        XCTAssertTrue(ContentLock.disagrees(lock, with: after))
    }

    /// Scenario: The bundle hash. The bundle hash is the SHA-256 of the
    /// canonical JSON: sorted keys, no whitespace, UTF-8. This checks the
    /// canonical text itself, so a change to the writer's key order or
    /// spacing shows up here, then checks the hash is a 64-character lower-
    /// case hex string that changes when the content does.
    func testTheBundleHashIsTheSHA256OfTheCanonicalJSON() {
        let bundle = ContentBundle(contentVersion: 1, cards: [], strings: [StringEntry(id: "a", text: "b")])
        XCTAssertEqual(
            CanonicalJSON.string(from: bundle.canonicalJSON),
            #"{"cards":{},"contentVersion":1,"strings":{"a":{"text":"b"}}}"#
        )
        XCTAssertEqual(bundle.bundleHash, CanonicalJSON.sha256Hex(of: bundle.canonicalJSON))
        XCTAssertEqual(bundle.bundleHash.count, 64)
        XCTAssertTrue(bundle.bundleHash.allSatisfy(\.isHexDigit))
        XCTAssertTrue(bundle.bundleHash.allSatisfy { !$0.isUppercase })
        let changed = ContentBundle(contentVersion: 1, cards: [], strings: [StringEntry(id: "a", text: "c")])
        XCTAssertNotEqual(bundle.bundleHash, changed.bundleHash)
    }

    /// Scenario: An update with new content. `ContentBundle` carries no
    /// "what's new" field, so the app has no data to build such a message
    /// from; raising the version changes only `contentVersion`.
    func testTheBundleCarriesNoNewContentMessageField() {
        guard case .object(let fields) = bundle(bodyWord: "star").canonicalJSON else {
            return XCTFail("expected an object")
        }
        XCTAssertEqual(Set(fields.keys), ["contentVersion", "cards", "strings"])
    }

    func testShippedContentMatchesItsLock() throws {
        let lock = try XCTUnwrap(ContentLock.read(from: RepositoryRoot.contentResourcesDirectory))
        XCTAssertFalse(ContentLock.disagrees(lock, with: Shipped.bundle))
        XCTAssertEqual(lock.contentVersion, Shipped.bundle.contentVersion)
    }
}
