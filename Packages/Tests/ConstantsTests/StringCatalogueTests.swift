import XCTest
@testable import Constants

/// content spec, "Strings live in catalogues" (mm-t11.39): a package gives
/// `CatalogueText`, and `StringCatalogue` fills it from an `.xcstrings` file
/// the way Foundation fills it in the app.
final class StringCatalogueTests: XCTestCase {
    private func catalogue(_ json: String) throws -> StringCatalogue {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("StringCatalogueTests-\(UUID().uuidString).xcstrings")
        try Data(json.utf8).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return try StringCatalogue(contentsOf: url)
    }

    private let json = """
    {"sourceLanguage":"en-GB","version":"1.0","strings":{
      "line":{"localizations":{"en-GB":{"stringUnit":{"state":"translated","value":"%1$@ at %2$@ still happens."}}}},
      "wasThat":{"localizations":{"en-GB":{"stringUnit":{"state":"translated","value":"Skipped, or was that %@?"}}}},
      "meals %lld":{"localizations":{"en-GB":{"variations":{"plural":{
        "zero":{"stringUnit":{"state":"translated","value":"no meals"}},
        "one":{"stringUnit":{"state":"translated","value":"%lld meal"}},
        "other":{"stringUnit":{"state":"translated","value":"%lld meals"}}}}}}},
      "hours %lld":{"localizations":{"en-GB":{"variations":{"plural":{
        "one":{"stringUnit":{"state":"translated","value":"%lld hour"}},
        "other":{"stringUnit":{"state":"translated","value":"%lld hours"}}}}}}},
      "day":{"localizations":{"en-GB":{"stringUnit":{"state":"translated","value":"This day has %1$@."}}}}
    }}
    """

    func testPositionalAndPlainPlaceholders() throws {
        let c = try catalogue(json)
        XCTAssertEqual(try c.render(.key("line", .verbatim("Lunch"), .verbatim("12:30"))), "Lunch at 12:30 still happens.")
        XCTAssertEqual(try c.render(.key("wasThat", .verbatim("14:45"))), "Skipped, or was that 14:45?")
    }

    func testPluralFormsPickByCount() throws {
        let c = try catalogue(json)
        XCTAssertEqual(try c.render(.key("meals %lld", .count(0))), "no meals")
        XCTAssertEqual(try c.render(.key("meals %lld", .count(1))), "1 meal")
        XCTAssertEqual(try c.render(.key("meals %lld", .count(5))), "5 meals")
        XCTAssertEqual(try c.render(.key("hours %lld", .count(0))), "0 hours", "no zero form: the other form")
    }

    func testANestedEntryAndAList() throws {
        let c = try catalogue(json)
        XCTAssertEqual(try c.render(.key("day", .key("meals %lld", .count(2)))), "This day has 2 meals.")
        XCTAssertEqual(try c.render(.list([.verbatim("13:05"), .key("wasThat", .verbatim("13:30"))])), "13:05, Skipped, or was that 13:30?")
    }

    func testAMissingKeyFails() throws {
        let c = try catalogue(json)
        XCTAssertThrowsError(try c.render(.key("not.a.key")))
    }

    /// The app's own catalogue reads from this repository.
    func testTheAppCatalogueReads() throws {
        let c = try StringCatalogue.appCatalogue()
        XCTAssertEqual(try c.render(.key("entry.save")), "Save")
    }
}
