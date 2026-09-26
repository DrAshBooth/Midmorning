import XCTest
@testable import Content

/// "Strings live in catalogues" (mm-t11.11). mm-t21.30 builds "A card
/// view's language": `CardViewLanguageTests` below, and
/// `RecordTests.ProgrammeStoreTests.testACardViewsLanguage` for the card
/// view the store keeps.
final class LiteralLintTests: XCTestCase {
    /// Scenario: A literal in code
    func testLiteralInCodeFailsAndNamesTheFileAndLine() {
        let source = "struct V: View {\n  var body: some View {\n    Button(\"Save\") { }\n  }\n}\n"
        let failures = LiteralLint.scanFile(text: source, file: "App/Midmorning/V.swift", validKeys: [])
        XCTAssertEqual(failures, [LiteralLintFailure(file: "App/Midmorning/V.swift", line: 3, literal: "Save")])
    }

    /// Scenario: A catalogue key
    func testCatalogueKeyPasses() {
        let source = "Text(\"entry.save\")\n"
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: ["entry.save"])
        XCTAssertEqual(failures, [])
    }

    /// Scenario: The verbatim escape
    func testVerbatimEscapePasses() {
        let source = "Text(verbatim: \"\\u{2014}\")\n"
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: [])
        XCTAssertEqual(failures, [])
    }

    /// Scenario: A call over several lines
    func testMultilineCallIsOutsideTheLint() {
        let source = "Button(\n  \"Save\"\n) { }\n"
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: [])
        XCTAssertEqual(failures, [])
    }

    /// Scenario: A literal outside the six calls
    func testLiteralOutsideTheSixCallsPasses() {
        let source = "let key = \"entry.save\"\n"
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: [])
        XCTAssertEqual(failures, [])
    }

    /// Scenario: A device in another language. The base language is en-GB
    /// and V1 ships en-GB only, so every catalogue key resolves to en-GB
    /// text regardless of the device language; there is no other
    /// localization to fall back to.
    func testTheCatalogueShipsEnGBOnly() throws {
        let catalogue = try XCStringsCatalogue.read(
            from: RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings")
        )
        XCTAssertFalse(catalogue.isEmpty)
        for (key, value) in catalogue {
            XCTAssertFalse(value.isEmpty, "\(key) has no en-GB value")
        }
    }

    func testAdditionalLintCoverage() {
        // Two checked calls on lines that should both fail.
        let source = """
        .navigationTitle("Home")
        .accessibilityLabel("Close")
        .accessibilityValue("42")
        Label("Add", systemImage: "plus")
        """
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: [])
        XCTAssertEqual(failures.map(\.literal), ["Home", "Close", "42", "Add"])
    }

    func testACallSiteThatIsPartOfALongerIdentifierIsNotMatched() {
        let source = "MyButton(\"Save\")\n" // not the checked `Button(` call
        let failures = LiteralLint.scanFile(text: source, file: "V.swift", validKeys: [])
        XCTAssertEqual(failures, [])
    }

    /// data-and-privacy spec, "The privacy notice": the backup line is the
    /// one sentence the requirement quotes verbatim. Scenario "Privacy
    /// notice" checks the screen holds it; this checks the catalogue holds
    /// the exact words, so a later edit cannot drift from the requirement
    /// text without a spec change.
    func testPrivacyNoticeBackupLineMatchesTheRequirementVerbatim() throws {
        let catalogue = try XCStringsCatalogue.read(
            from: RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings")
        )
        XCTAssertEqual(
            catalogue["settings.privacyNotice.backup.body"],
            "A backup of your device can hold reminder times until the app cancels them. It never holds your entries."
        )
    }

    /// Scenario: Erasure. "WHEN the person reads the section on deleting
    /// their data THEN it names 'Delete everything' in the settings screen."
    func testPrivacyNoticeNamesDeleteEverythingInTheErasureSection() throws {
        let catalogue = try XCStringsCatalogue.read(
            from: RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings")
        )
        let yourData = try XCTUnwrap(catalogue["settings.privacyNotice.yourData.body"])
        XCTAssertTrue(yourData.contains("Delete everything"))
    }
}
