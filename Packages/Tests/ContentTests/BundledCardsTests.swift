import XCTest
@testable import Content

/// "The app bundles the cards" (mm-t11.7). All three scenarios are built
/// here.
final class BundledCardsTests: XCTestCase {
    /// Scenario: Airplane mode. `BundleLoader` reads only local files under
    /// `Resources`; nothing in the Content package makes a network call, so
    /// every card is readable with no network. This test proves the load
    /// path itself needs nothing but the local directory.
    func testTheBundleLoadsFromLocalFilesOnly() throws {
        let bundle = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, environment: [:])
        XCTAssertFalse(bundle.cards.isEmpty)
        let card = bundle.card(id: "stage2.clock")
        XCTAssertNotNil(card)
        XCTAssertFalse(card!.body.isEmpty)
    }

    /// Scenario: No runtime text. The literal lint, run against the app's
    /// real source with its real catalogue keys, names no file.
    func testLiteralLintNamesNoFileInTheShippedApp() throws {
        let validKeys = try AppCatalogueKeys.load()
        let failures = try LiteralLint.scan(
            directory: RepositoryRoot.appDirectory,
            root: RepositoryRoot.path,
            validKeys: validKeys
        )
        XCTAssertEqual(failures, [], "\(failures)")
    }

    /// Scenario: A placeholder
    func testPlaceholderInACardFailsAndNamesTheCardId() {
        let card = fixtureCard(id: "stage2.placeholder", body: "Your day starts at {weighInDay}.")
        let issues = ContentChecks.noRuntimePlaceholder([card])
        XCTAssertEqual(issues.map(\.id), ["stage2.placeholder"])
    }

    func testAnOrdinaryCardHoldsNoPlaceholder() {
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder([fixtureCard()]), [])
    }

    func testShippedCardsHoldNoPlaceholder() {
        XCTAssertEqual(ContentChecks.noRuntimePlaceholder(Shipped.bundle.cards), [])
    }
}
