import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "The app blocks third-party keyboards". The App
/// target's `AppDelegate.application(_:shouldAllowExtensionPointIdentifier:)`
/// maps `UIApplication.ExtensionPointIdentifier` to `ExtensionPointKind` and
/// calls `KeyboardBlockPolicy.shouldAllow`; this proves the decision itself
/// with no UIKit import, so it runs under `swift test` on macOS.
final class KeyboardBlockTests: XCTestCase {
    /// Scenario: Third-party keyboard installed.
    func testKeyboardExtensionPointIsBlocked() {
        XCTAssertFalse(KeyboardBlockPolicy.shouldAllow(.keyboard))
    }

    /// Scenario: Dictation. Dictation is not the keyboard extension point,
    /// so it is never blocked; nor is any other extension point (the share
    /// sheet, an action extension, and so on).
    func testEveryOtherExtensionPointStaysAllowed() {
        XCTAssertTrue(KeyboardBlockPolicy.shouldAllow(.other))
    }
}
