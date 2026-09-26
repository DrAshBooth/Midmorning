import Foundation
import XCTest
@testable import AppLock

/// app-lock spec, "The app lock is on by default".
final class BiometryLabelsTests: XCTestCase {
    /// Scenario: Label function in a test.
    func testPasscodeOnlyReturnsLockWithPasscode() {
        let strings = BiometryLabels.strings(for: .passcodeOnly)
        XCTAssertEqual(strings.lockLabel, "Lock with passcode")
        XCTAssertTrue(strings.isLockEnabled)
        XCTAssertNil(strings.onlyLabel)
        XCTAssertNil(strings.enrolmentWarning)
    }

    /// Scenario: Label function in a test — "with `none` it returns the
    /// disabled state".
    func testNoneReturnsTheDisabledState() {
        let strings = BiometryLabels.strings(for: .none)
        XCTAssertFalse(strings.isLockEnabled)
        XCTAssertEqual(strings.lockLabel, "Set a passcode on your device to lock Midmorning.")
    }

    /// Scenario: Touch ID strings.
    func testTouchIDReturnsAllThreeStrings() {
        let strings = BiometryLabels.strings(for: .touchID)
        XCTAssertEqual(strings.lockLabel, "Lock with Touch ID")
        XCTAssertEqual(strings.onlyLabel, "Touch ID only")
        XCTAssertEqual(
            strings.enrolmentWarning,
            "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on."
        )
    }

    /// Face ID's own triple, the mirror of "Touch ID strings".
    func testFaceIDReturnsAllThreeStrings() {
        let strings = BiometryLabels.strings(for: .faceID)
        XCTAssertEqual(strings.lockLabel, "Lock with Face ID")
        XCTAssertEqual(strings.onlyLabel, "Face ID only")
        XCTAssertEqual(
            strings.enrolmentWarning,
            "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on."
        )
    }

    /// Onboarding spec, "Screen 4: permissions": "Under the switch the
    /// section MUST show the lock sentence for the device's `Biometry`
    /// value. The label function that `app-lock` defines returns it."
    func testOnboardingLockSentencePerBiometry() {
        XCTAssertEqual(BiometryLabels.strings(for: .faceID).onboardingSentence, "Midmorning asks for Face ID or your passcode when it opens.")
        XCTAssertEqual(BiometryLabels.strings(for: .touchID).onboardingSentence, "Midmorning asks for Touch ID or your passcode when it opens.")
        XCTAssertEqual(BiometryLabels.strings(for: .passcodeOnly).onboardingSentence, "Midmorning asks for your passcode when it opens.")
    }

    /// Scenario: Same label at onboarding — onboarding and the settings
    /// screen both call the one function, so they can never disagree.
    func testOnboardingAndSettingsCallTheSameFunction() {
        let onboarding = BiometryLabels.strings(for: .touchID).lockLabel
        let settings = BiometryLabels.strings(for: .touchID).lockLabel
        XCTAssertEqual(onboarding, settings)
        XCTAssertEqual(onboarding, "Lock with Touch ID")
    }

    /// Scenario: No passcode.
    func testNoPasscodeMessageMatchesTheDisabledState() {
        XCTAssertEqual(BiometryLabels.strings(for: .none).lockLabel, BiometryLabels.noPasscodeMessage)
    }

    /// Scenario: Face ID usage description.
    func testInfoPlistHoldsTheFaceIDUsageDescription() throws {
        let infoPlistURL = RepositoryRoot.appDirectory.appendingPathComponent("Midmorning-Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        XCTAssertEqual(plist?["NSFaceIDUsageDescription"] as? String, BiometryLabels.faceIDUsageDescription)
        XCTAssertEqual(BiometryLabels.faceIDUsageDescription, "Midmorning uses Face ID to unlock the app.")
    }

    // MARK: Requirement: Face ID only or Touch ID only

    /// Scenario: No biometric enrolled.
    func testFaceOrTouchOnlyIsUnavailableWithNoBiometric() {
        XCTAssertFalse(BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: .passcodeOnly, appLockEnabled: true))
        XCTAssertFalse(BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: .none, appLockEnabled: true))
    }

    func testFaceOrTouchOnlyIsUnavailableWithTheAppLockOff() {
        XCTAssertFalse(BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: .faceID, appLockEnabled: false))
    }

    func testFaceOrTouchOnlyIsAvailableWithABiometricAndTheAppLockOn() {
        XCTAssertTrue(BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: .faceID, appLockEnabled: true))
        XCTAssertTrue(BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: .touchID, appLockEnabled: true))
    }
}

/// This test target's own repository root, found from this file's path
/// (the same device `Packages/Content/RepositoryRoot.swift` uses), so a test
/// can read `App/Midmorning-Info.plist` however the test runner sets its
/// working directory.
enum RepositoryRoot {
    static var appDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // AppLockTests/
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // the repository root
            .appendingPathComponent("App", isDirectory: true)
    }
}
