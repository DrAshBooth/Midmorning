import XCTest
@testable import Content

/// content spec, "Strings live in catalogues", scenario "A card view's
/// language" (mm-t21.30). `CardScreenView` writes the card view with
/// `bundle.language`; `RecordTests.ProgrammeStoreTests.testACardViewsLanguage`
/// proves that the store keeps it.
final class CardViewLanguageTests: XCTestCase {
    /// The shipped bundle is en-GB, the base language and the one language
    /// V1 ships.
    func testTheShippedBundleIsEnGB() {
        XCTAssertEqual(Shipped.bundle.language, "en-GB")
        XCTAssertEqual(ContentBundle.baseLanguage, "en-GB")
    }
}
