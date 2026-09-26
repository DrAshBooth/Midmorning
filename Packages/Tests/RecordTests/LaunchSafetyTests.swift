import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Launch safety".
final class LaunchSafetyTests: XCTestCase {
    /// Scenario: Marker cleared. Today appeared last launch, so the marker
    /// file is gone; this launch finds no marker and the streak resets.
    func testMarkerClearedResetsTheStreakToZero() {
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: false, previousConsecutiveUnclearedCount: 2)
        XCTAssertFalse(outcome.enterSafeMode)
        XCTAssertEqual(outcome.newConsecutiveUnclearedCount, 0)
    }

    /// Scenario: Launch failures counted (the streak half; the lifetime
    /// count itself is `RecordStoreTests`' `incrementLaunchFailureCount`).
    func testFirstUnclearedMarkerRaisesTheStreakToOneAndStaysOutOfSafeMode() {
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: true, previousConsecutiveUnclearedCount: 0)
        XCTAssertFalse(outcome.enterSafeMode)
        XCTAssertEqual(outcome.newConsecutiveUnclearedCount, 1)
    }

    /// Scenario: Third launch with an uncleared marker (built here over
    /// fixture facts — `mm-t42.20` runs the real three-launch restart end to
    /// end).
    func testThirdConsecutiveUnclearedMarkerEntersSafeMode() {
        var streak = 0
        var enteredSafeMode = [Bool]()
        for _ in 1...3 {
            let outcome = LaunchSafety.startLaunch(markerWasUncleared: true, previousConsecutiveUnclearedCount: streak)
            streak = outcome.newConsecutiveUnclearedCount
            enteredSafeMode.append(outcome.enterSafeMode)
        }
        XCTAssertEqual(enteredSafeMode, [false, false, true], "only the third consecutive uncleared launch enters safe mode")
        XCTAssertEqual(streak, 3)
    }

    /// A device stuck past three keeps counting; safe mode does not toggle
    /// off again on its own.
    func testAFourthConsecutiveUnclearedMarkerStaysInSafeMode() {
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: true, previousConsecutiveUnclearedCount: 3)
        XCTAssertTrue(outcome.enterSafeMode)
        XCTAssertEqual(outcome.newConsecutiveUnclearedCount, 4)
    }
}

/// data-and-privacy spec, "Launch safety": "Store fails to open", "Try
/// again"; "File protection": "Launch before the first unlock".
final class AppStoreOpeningTests: XCTestCase {
    /// Scenario: Launch before the first unlock. Protected data being
    /// unavailable wins even when opening would otherwise have succeeded, so
    /// the app never attempts the open at all.
    func testProtectedDataUnavailableWaitsRegardlessOfWhetherOpenWouldSucceed() {
        XCTAssertEqual(AppStoreOpening.attempt(protectedDataAvailable: false, openSucceeded: true), .waitingForProtectedData)
        XCTAssertEqual(AppStoreOpening.attempt(protectedDataAvailable: false, openSucceeded: false), .waitingForProtectedData)
    }

    /// Scenario: Store fails to open. Protected data is available, but the
    /// container still throws (built here over fixture facts — `mm-t42.20`
    /// runs a real container failure end to end).
    func testProtectedDataAvailableButOpenFailsShowsFailed() {
        XCTAssertEqual(AppStoreOpening.attempt(protectedDataAvailable: true, openSucceeded: false), .failed)
    }

    /// Scenario: Try again. The same decision, retried, now succeeds.
    func testTryAgainAfterAFailureCanOpen() {
        XCTAssertEqual(AppStoreOpening.attempt(protectedDataAvailable: true, openSucceeded: true), .opened)
    }
}
