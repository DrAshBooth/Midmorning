import XCTest
@testable import AppLock

/// app-lock spec, "Fallback to the device passcode" and "Face ID only or
/// Touch ID only".
final class AuthenticationPolicyTests: XCTestCase {
    /// Scenario: Turn on — "the next system authentication request offers
    /// Face ID and no 'Enter Passcode'".
    func testFaceOrTouchOnlySelectsTheBiometricsOnlyPolicy() {
        XCTAssertEqual(AuthenticationPolicy.policy(faceOrTouchOnly: true), .biometricsOnly)
    }

    /// Scenario: Face ID fails — off, the request still offers the
    /// passcode.
    func testOffSelectsTheBiometricsAndPasscodePolicy() {
        XCTAssertEqual(AuthenticationPolicy.policy(faceOrTouchOnly: false), .biometricsAndPasscode)
    }

    // MARK: Requirement: Face ID only or Touch ID only — enrolment state

    /// Scenario: Enrolment changed.
    func testHasChangedWhenTheHashDiffersFromTheKeptOne() {
        XCTAssertTrue(EnrolmentState.hasChanged(current: "new-hash", kept: "old-hash"))
    }

    /// Scenario: Not shown before an enrolment change.
    func testHasNotChangedWhenTheHashMatchesTheKeptOne() {
        XCTAssertFalse(EnrolmentState.hasChanged(current: "same-hash", kept: "same-hash"))
    }

    func testHasNotChangedWithNoKeptHashYet() {
        XCTAssertFalse(EnrolmentState.hasChanged(current: "first-hash", kept: nil))
    }
}
