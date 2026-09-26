import XCTest
@testable import Programme

/// Safeguarding spec, "What is a treatment claim" (mm-t14.27).
final class TreatmentClaimTests: XCTestCase {
    func testScreen1Passes() {
        XCTAssertTrue(TreatmentClaim.passes("Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT."))
    }

    func testACardDraftFails() {
        XCTAssertFalse(TreatmentClaim.passes("Midmorning treats binge eating"))
    }

    func testAMarketingDraftFails() {
        XCTAssertFalse(TreatmentClaim.passes("based on the treatment NICE recommends"))
    }

    func testANegativeStatementPasses() {
        XCTAssertTrue(TreatmentClaim.passes("It is not therapy, and it does not replace your GP or anyone treating you."))
    }

    func testAForbiddenFormFails() {
        XCTAssertFalse(TreatmentClaim.passes("for bingers"))
    }

    func testEveryOnboardingStringPasses() {
        for string in OnboardingStrings.all {
            XCTAssertTrue(TreatmentClaim.passes(string), "\"\(string)\" should pass the treatment-claim check")
        }
    }
}
