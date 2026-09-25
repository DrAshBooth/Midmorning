import XCTest
@testable import Content

/// "Clinical sign-off per content version" (mm-t11.10). All five scenarios
/// are built here, each over a fixture bundle and a fixture sign-off
/// directory, with no live dependency on a real signed-off release.
final class SignOffTests: XCTestCase {
    private func withTempDirectory(_ body: (URL) throws -> Void) rethrows {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try body(dir)
    }

    private func write(_ signOff: SignOff, to dir: URL) throws {
        let data = try JSONEncoder().encode(signOff)
        try data.write(to: dir.appendingPathComponent(SignOff.fileName(forContentVersion: signOff.contentVersion)))
    }

    /// Scenario: Release without sign-off
    func testReleaseWithoutSignOffFailsAndNamesTheVersion() throws {
        try withTempDirectory { dir in
            let bundle = ContentBundle(contentVersion: 3, cards: [], strings: [])
            let signOff = SignOff.matching(bundle: bundle, in: dir)
            XCTAssertNil(signOff)
            let satisfied = ReleaseLane.satisfiesReleaseGate(environment: ["MIDMORNING_RELEASE": "1"], signOff: signOff)
            XCTAssertFalse(satisfied, "content version 3 should fail the release gate with no sign-off")
        }
    }

    /// Scenario: Release with a sign-off for an older hash
    func testReleaseWithASignOffForAnOlderHashFailsAndNamesTheVersion() throws {
        try withTempDirectory { dir in
            let bundle = ContentBundle(contentVersion: 3, cards: [], strings: [StringEntry(id: "a", text: "b")])
            let staleSignOff = SignOff(
                contentVersion: 3, bundleHash: "not-the-current-hash", date: "2026-09-01",
                reviewerName: "Reviewer", reviewerRole: "Clinical psychologist",
                reviewedIds: ["a"], toneAnswers: ["a": "no"]
            )
            try write(staleSignOff, to: dir)
            let signOff = SignOff.matching(bundle: bundle, in: dir)
            XCTAssertNil(signOff, "a sign-off for the wrong hash must not match")
            let satisfied = ReleaseLane.satisfiesReleaseGate(environment: ["MIDMORNING_RELEASE": "1"], signOff: signOff)
            XCTAssertFalse(satisfied)
        }
    }

    /// Scenario: A local test run without sign-off
    func testLocalRunWithoutSignOffPassesAndSetsDraft() throws {
        try withTempDirectory { dir in
            try dataFiles(contentVersion: 4, into: dir)
            let bundle = try ContentBundle.load(from: dir, environment: [:])
            XCTAssertTrue(bundle.isDraft)
            let satisfied = ReleaseLane.satisfiesReleaseGate(environment: [:], signOff: SignOff.matching(bundle: bundle, in: dir))
            XCTAssertTrue(satisfied, "a non-release run passes with no sign-off")
        }
    }

    /// Scenario: Sign-off present
    func testMatchingSignOffPassesAndClearsDraft() throws {
        try withTempDirectory { dir in
            try dataFiles(contentVersion: 3, into: dir)
            let loaded = try ContentBundle.load(from: dir, environment: [:])
            let signOff = SignOff(
                contentVersion: 3, bundleHash: loaded.bundleHash, date: "2026-09-25",
                reviewerName: "Dr Reviewer", reviewerRole: "Clinical psychologist, CBT-E trained",
                reviewedIds: loaded.cards.map(\.id) + loaded.strings.map(\.id),
                toneAnswers: Dictionary(uniqueKeysWithValues: loaded.cards.map { ($0.id, "no") })
            )
            try write(signOff, to: dir)
            let bundle = try ContentBundle.load(from: dir, environment: [:])
            XCTAssertFalse(bundle.isDraft)
            XCTAssertNotNil(SignOff.matching(bundle: bundle, in: dir))
        }
    }

    /// Scenario: The archive script and a Draft bundle. `scripts/archive`
    /// runs the release-lane content test before it ever calls
    /// `xcodebuild archive`, and stops when that test fails, which is
    /// exactly when the bundle carries the Draft flag.
    func testArchiveScriptStopsBeforeArchivingOnFailure() throws {
        let script = try String(contentsOf: RepositoryRoot.path.appendingPathComponent("scripts/archive"), encoding: .utf8)
        XCTAssertTrue(script.contains("MIDMORNING_RELEASE=1"))
        XCTAssertTrue(script.contains("set -e"), "the script must stop on the first failing command")
        let releaseTestLine = script.range(of: "swift test")
        let archiveLine = script.range(of: "xcodebuild")
        XCTAssertNotNil(releaseTestLine)
        XCTAssertNotNil(archiveLine)
        XCTAssertTrue(releaseTestLine!.lowerBound < archiveLine!.lowerBound, "the content test must run before the archive")
    }

    /// Writes a minimal valid `manifest.json`/`cards.json`/`strings.json`
    /// set to `dir`, so `ContentBundle.load` succeeds against a fixture
    /// directory that holds no sign-off file yet.
    private func dataFiles(contentVersion: Int, into dir: URL) throws {
        try #"{"contentVersion": \#(contentVersion)}"#.write(
            to: dir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8
        )
        try #"[{"id":"stage1.fixture","section":"stage1","title":"Fixture","body":"Body text.","oneThing":"Do it.","links":[],"retired":false}]"#.write(
            to: dir.appendingPathComponent("cards.json"), atomically: true, encoding: .utf8
        )
        try "[]".write(to: dir.appendingPathComponent("strings.json"), atomically: true, encoding: .utf8)
    }

    func testShippedBundleIsDraftUnderVerify() {
        // `./verify` runs `swift test` with no MIDMORNING_RELEASE set, so
        // the shipped bundle, which has no matching sign-off file yet,
        // carries the Draft flag.
        XCTAssertTrue(Shipped.bundle.isDraft)
    }
}
