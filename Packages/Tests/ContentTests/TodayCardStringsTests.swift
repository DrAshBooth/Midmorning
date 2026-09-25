import XCTest
@testable import Content

/// "the Today card strings" (mm-t11.30). The Focus card strings wait for
/// 2.5 (mm-t25.16), with the Focus card.
final class TodayCardStringsTests: XCTestCase {
    /// Scenario: The plan card text
    func testThePlanCardText() {
        XCTAssertEqual(Shipped.bundle.string(id: "todaycard.plan")?.text, "Your plan isn't set yet. It takes about two minutes.")
        XCTAssertEqual(Shipped.bundle.string(id: "todaycard.plan.setup")?.text, "Set it up")
    }

    func testTodayCardReadText() {
        XCTAssertEqual(Shipped.bundle.string(id: "todaycard.read")?.text, "Read")
    }

    func testTodayCardControlsAreWithinTheCharacterLimit() {
        for id in ["todaycard.plan.setup", "todaycard.read"] {
            let text = Shipped.bundle.string(id: id)!.text
            XCTAssertFalse(CatalogueRules.exceedsLimit(text, kind: .navigationOrCardControl), id)
            XCTAssertFalse(CatalogueRules.endsWithFullStop(text), "\(id) is a control label and must not end with a full stop")
        }
    }

    func testTodayCardMessageEndsWithAFullStop() {
        XCTAssertTrue(CatalogueRules.endsWithFullStop(Shipped.bundle.string(id: "todaycard.plan")!.text))
    }

    func testFocusCardStringsAreNotYetInTheFirstCutBundle() {
        // "todaycard.focus" and "todaycard.focus.yes" wait for 2.5
        // (mm-t25.16), with the Focus card (decision 63).
        XCTAssertNil(Shipped.bundle.string(id: "todaycard.focus"))
        XCTAssertNil(Shipped.bundle.string(id: "todaycard.focus.yes"))
    }
}
