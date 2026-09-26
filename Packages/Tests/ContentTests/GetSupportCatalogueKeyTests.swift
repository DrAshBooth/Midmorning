import XCTest
@testable import Content

/// Safeguarding spec, "Get support on every screen" (mm-t14.42): one
/// catalogue key holds the control's text, so a change to "Get support" is
/// made once. `GetSupportModifier` and the three AppLock screens that have
/// no navigation bar all read it.
final class GetSupportCatalogueKeyTests: XCTestCase {
    func testOneCatalogueKeyForGetSupport() throws {
        let catalogue = try XCStringsCatalogue.read(from: RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings"))
        let keys = catalogue.filter { $0.value == "Get support" }.map(\.key)
        XCTAssertEqual(keys, ["today.getSupport"])
    }
}
