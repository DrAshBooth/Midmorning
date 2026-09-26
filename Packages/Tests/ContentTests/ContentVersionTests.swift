import XCTest
@testable import Content

/// "Content versions" (mm-t11.8; ruling r13-01, mm-t11.40 and mm-t11.49).
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

    /// Scenario: A catalogue string changes. Ruling r13-01: the hash covers
    /// the signed keys of the real `Localizable.xcstrings`.
    /// "entry.delete.confirmTitle" is a signed key (the "entry." prefix), so
    /// "Delete this entry?" to "Remove this entry?" with no version rise
    /// fails the lock check.
    func testACatalogueStringChangeWithNoVersionRiseFailsTheLockCheck() throws {
        let lock = try XCTUnwrap(ContentLock.read(from: RepositoryRoot.contentResourcesDirectory))
        let signed = try SignedCatalogueKeys.read(from: RepositoryRoot.contentResourcesDirectory)
        XCTAssertTrue(signed.allPrefixes.contains("entry."))
        let catalogue = try catalogueCopy(changing: "entry.delete.confirmTitle", from: "Delete this entry?", to: "Remove this entry?")
        let changed = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, catalogue: catalogue, environment: [:])
        XCTAssertEqual(changed.contentVersion, lock.contentVersion)
        XCTAssertEqual(changed.signedCatalogue["entry.delete.confirmTitle"]?.value, "Remove this entry?")
        XCTAssertTrue(ContentLock.disagrees(lock, with: changed))
    }

    /// Scenario: Interface text changes. Ruling r13-01: no signed prefix
    /// matches "common.cancel", so it is interface text. "Cancel" to "Close"
    /// leaves the hash as it is, needs no version rise, and the sign-off
    /// list does not hold the key.
    func testAnInterfaceTextChangePassesTheLockCheck() throws {
        let lock = try XCTUnwrap(ContentLock.read(from: RepositoryRoot.contentResourcesDirectory))
        let signed = try SignedCatalogueKeys.read(from: RepositoryRoot.contentResourcesDirectory)
        XCTAssertFalse(signed.isSigned("common.cancel"))
        let catalogue = try catalogueCopy(changing: "common.cancel", from: "Cancel", to: "Close")
        let changed = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, catalogue: catalogue, environment: [:])
        XCTAssertEqual(changed.contentVersion, lock.contentVersion)
        XCTAssertNil(changed.signedCatalogue["common.cancel"])
        XCTAssertFalse(ContentLock.disagrees(lock, with: changed))
        XCTAssertEqual(changed.bundleHash, Shipped.bundle.bundleHash)
        XCTAssertFalse(changed.signOffIds.contains("common.cancel"))
    }

    /// Scenario: A reminder key with no prefix. A catalogue key with the
    /// segment "reminders" holds reminder text, so a signed prefix must
    /// match it. With no "today.reminders." prefix, the check names
    /// "today.reminders.denied".
    func testAReminderKeyWithNoPrefixIsNamed() throws {
        let keys = try XCStringsCatalogue.readEntries(from: RepositoryRoot.appCatalogueURL).keys
        XCTAssertTrue(keys.contains("today.reminders.denied"))
        let withoutToday = SignedCatalogueKeys(prefixes: ["reminders": ["reminders.", "settings.reminders."]])
        XCTAssertTrue(withoutToday.unsignedKeys(withSegment: "reminders", in: keys).contains("today.reminders.denied"))
        // A format part after the first space is not a segment.
        XCTAssertEqual(withoutToday.unsignedKeys(withSegment: "reminders", in: ["today.reminders %lld", "today.title"]), ["today.reminders %lld"])
    }

    /// The real check: each catalogue key with the segment "reminders"
    /// matches a prefix in signed-catalogue-keys.json. The test names each
    /// key that does not.
    func testEveryReminderKeyMatchesASignedPrefix() throws {
        let signed = try SignedCatalogueKeys.read(from: RepositoryRoot.contentResourcesDirectory)
        let keys = try XCStringsCatalogue.readEntries(from: RepositoryRoot.appCatalogueURL).keys
        XCTAssertTrue(keys.contains { $0.split(separator: ".").contains("reminders") })
        for key in signed.unsignedKeys(withSegment: "reminders", in: keys) {
            XCTFail("\(key) has the segment \"reminders\" and matches no prefix in \(SignedCatalogueKeys.fileName)")
        }
    }

    /// Ruling r13-01 puts reminder text under the hash. A change to the
    /// permission line on Today, with no version rise, fails the lock check.
    func testAReminderLineChangeWithNoVersionRiseFailsTheLockCheck() throws {
        let lock = try XCTUnwrap(ContentLock.read(from: RepositoryRoot.contentResourcesDirectory))
        let catalogue = try catalogueCopy(
            changing: "today.reminders.denied",
            from: "Notifications are off in iOS Settings.",
            to: "Notifications are turned off in iOS Settings."
        )
        let changed = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, catalogue: catalogue, environment: [:])
        XCTAssertEqual(changed.contentVersion, lock.contentVersion)
        XCTAssertTrue(ContentLock.disagrees(lock, with: changed))
    }

    /// A change to a plural form of a signed key also changes the hash.
    func testAPluralFormChangeOfASignedKeyChangesTheHash() throws {
        let key = "reminders.action.snooze %lld"
        let url = RepositoryRoot.appCatalogueURL
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var strings = try XCTUnwrap(json["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings[key] as? [String: Any])
        let changed = try JSONSerialization.data(withJSONObject: entry)
        let text = String(decoding: changed, as: UTF8.self).replacingOccurrences(of: "Remind me in %lld minute\"", with: "Remind me after %lld minute\"")
        XCTAssertNotEqual(text, String(decoding: changed, as: UTF8.self))
        strings[key] = try JSONSerialization.jsonObject(with: Data(text.utf8))
        json["strings"] = strings
        let copy = try writeTemporaryCatalogue(JSONSerialization.data(withJSONObject: json))
        let bundle = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, catalogue: copy, environment: [:])
        XCTAssertNotEqual(bundle.bundleHash, Shipped.bundle.bundleHash)
    }

    /// Ruling r13-01: one file lists the signed prefixes, grouped by the
    /// record, reminders and safeguarding families. Each prefix names at
    /// least one real key, so the list stays up to date.
    func testEverySignedPrefixNamesARealCatalogueKey() throws {
        let signed = try SignedCatalogueKeys.read(from: RepositoryRoot.contentResourcesDirectory)
        XCTAssertEqual(Set(signed.prefixes.keys), ["record", "reminders", "safeguarding"])
        let keys = try XCStringsCatalogue.readEntries(from: RepositoryRoot.appCatalogueURL).keys
        for prefix in signed.allPrefixes {
            XCTAssertTrue(keys.contains { $0.hasPrefix(prefix) }, "no catalogue key starts with \(prefix)")
        }
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["entry.delete.confirmTitle"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["reminders.title.midday"])
        // The reminders capability also owns the text of the Reminders group
        // in settings and the permission line on Today.
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["settings.reminders.denied.line"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["settings.reminders.quietHoursNotSent"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["today.reminders.denied"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["today.reminders.notDetermined"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["today.gapBand.accessibilityLabel %lld"])
        XCTAssertNotNil(Shipped.bundle.signedCatalogue["safeguarding.exportControl"])
        XCTAssertNil(Shipped.bundle.signedCatalogue["common.cancel"])
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
            #"{"cards":{},"catalogue":{},"contentVersion":1,"strings":{"a":{"text":"b"}}}"#
        )
        let withCatalogue = ContentBundle(
            contentVersion: 1, cards: [], strings: [],
            signedCatalogue: [
                "entry.save": XCStringsCatalogue.Entry(value: "Save"),
                "n %lld": XCStringsCatalogue.Entry(value: nil, plural: ["one": "%lld day", "other": "%lld days"]),
            ]
        )
        XCTAssertEqual(
            CanonicalJSON.string(from: withCatalogue.canonicalJSON),
            #"{"cards":{},"catalogue":{"entry.save":{"value":"Save"},"n %lld":{"plural":{"one":"%lld day","other":"%lld days"}}},"contentVersion":1,"strings":{}}"#
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
        XCTAssertEqual(Set(fields.keys), ["contentVersion", "cards", "strings", "catalogue"])
    }

    func testShippedContentMatchesItsLock() throws {
        let lock = try XCTUnwrap(ContentLock.read(from: RepositoryRoot.contentResourcesDirectory))
        XCTAssertFalse(ContentLock.disagrees(lock, with: Shipped.bundle))
        XCTAssertEqual(lock.contentVersion, Shipped.bundle.contentVersion)
        XCTAssertFalse(Shipped.bundle.signedCatalogue.isEmpty, "the lock hash covers the signed catalogue keys")
    }

    /// A copy of the app's catalogue with one plain value changed, in a
    /// temporary file that the test's teardown removes.
    private func catalogueCopy(changing key: String, from old: String, to new: String) throws -> URL {
        let url = RepositoryRoot.appCatalogueURL
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var strings = try XCTUnwrap(json["strings"] as? [String: Any])
        var entry = try XCTUnwrap(strings[key] as? [String: Any])
        var localizations = try XCTUnwrap(entry["localizations"] as? [String: Any])
        var enGB = try XCTUnwrap(localizations["en-GB"] as? [String: Any])
        var unit = try XCTUnwrap(enGB["stringUnit"] as? [String: Any])
        XCTAssertEqual(unit["value"] as? String, old)
        unit["value"] = new
        enGB["stringUnit"] = unit
        localizations["en-GB"] = enGB
        entry["localizations"] = localizations
        strings[key] = entry
        json["strings"] = strings
        return try writeTemporaryCatalogue(JSONSerialization.data(withJSONObject: json))
    }

    private func writeTemporaryCatalogue(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ContentVersionTests-\(UUID().uuidString).xcstrings")
        try data.write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}
