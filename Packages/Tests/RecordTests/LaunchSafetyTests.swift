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

    /// Scenario: Third launch with an uncleared marker (ruling r13-13,
    /// mm-t41.25): "the app ends before Today appears on two launches in a
    /// row and the person opens it a third time". The first launch finds no
    /// marker; the second and the third each find the marker the launch
    /// before left. `LaunchSafetyWiringTests` runs the same three launches
    /// over a real marker file.
    func testThirdOpenAfterTwoFailedLaunchesEntersSafeMode() {
        var markerWasUncleared = false
        var streak = 0
        var enteredSafeMode = [Bool]()
        for _ in 1...3 {
            let outcome = LaunchSafety.startLaunch(markerWasUncleared: markerWasUncleared, previousConsecutiveUnclearedCount: streak)
            streak = outcome.newConsecutiveUnclearedCount
            enteredSafeMode.append(outcome.enterSafeMode)
            markerWasUncleared = true // this launch ends before Today appears.
        }
        XCTAssertEqual(enteredSafeMode, [false, false, true], "the third open after two failed launches enters safe mode")
        XCTAssertEqual(streak, 2, "two failed launches in a row came before the third open")
    }

    /// One failed launch is not enough: the second open is an ordinary
    /// launch.
    func testSecondOpenAfterOneFailedLaunchStaysOutOfSafeMode() {
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: true, previousConsecutiveUnclearedCount: 0)
        XCTAssertFalse(outcome.enterSafeMode)
        XCTAssertEqual(outcome.newConsecutiveUnclearedCount, 1)
    }

    /// A device stuck past two keeps counting; safe mode does not toggle
    /// off again on its own.
    func testAFourthOpenAfterThreeFailedLaunchesStaysInSafeMode() {
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: true, previousConsecutiveUnclearedCount: 2)
        XCTAssertTrue(outcome.enterSafeMode)
        XCTAssertEqual(outcome.newConsecutiveUnclearedCount, 3)
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
