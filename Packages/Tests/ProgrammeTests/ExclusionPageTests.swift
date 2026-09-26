import XCTest
@testable import Programme

/// Safeguarding spec, "The exclusion page" (mm-t14.19).
final class ExclusionPageTests: XCTestCase {
    func testUnder18() {
        let reasons = ExclusionPage.ordered([.age])
        XCTAssertEqual(reasons, [.age])
        XCTAssertEqual(ExclusionPage.paragraph(for: .age), "Midmorning is built for adults. Beat's Youthline is for anyone under 18: 0808 801 0711.")
        XCTAssertEqual(GPParagraph.variant(for: reasons), .under18)
    }

    func testSelfHarmFirst() {
        let reasons = ExclusionPage.ordered([.weight, .selfHarm])
        XCTAssertEqual(reasons, [.selfHarm, .weight])
        XCTAssertEqual(GPParagraph.variant(for: reasons), .selfHarm)
    }

    func testTwoReasonsPregnancyAndTreatmentOrder() {
        let reasons = ExclusionPage.ordered([.treatment, .pregnancy])
        XCTAssertEqual(reasons, [.pregnancy, .treatment])
    }

    /// "Done": onboarding's coordinator returns to "What this is and isn't";
    /// this content module states no navigation, only the fixed strings the
    /// page shows around "Done".
    func testFixedContent() {
        XCTAssertEqual(ExclusionPage.heading, "Not right now")
        XCTAssertEqual(ExclusionPage.closing, "You can come back if this changes.")
        XCTAssertEqual(ExclusionPage.whatToDoInstead, "What to do instead")
    }

    func testEveryReasonHasAParagraph() {
        for reason in ExclusionReason.allCases {
            XCTAssertFalse(ExclusionPage.paragraph(for: reason).isEmpty)
        }
    }
}
