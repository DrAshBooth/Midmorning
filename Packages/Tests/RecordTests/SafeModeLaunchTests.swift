import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "Launch safety", with safe mode's read-only open
/// (ruling r13-05, mm-t42.23). Each launch here makes the same calls, in the
/// same order, as `AppLockRootView.openStoreAndController`: `begin()`, the
/// store open with `readOnly` set from the marker, then
/// `countLaunchFailureIfNeeded(in:)`. Today appearing is
/// `clearAfterTodayAppears()`.
@MainActor
final class SafeModeLaunchTests: XCTestCase {
    private var root: URL!
    private var markerURL: URL { StoreLayout.launchMarkerURL(applicationSupportDirectory: root) }

    override func setUpWithError() throws {
        root = try makeTemporaryDirectory()
    }

    private func markerContent() -> String? {
        try? String(contentsOf: markerURL, encoding: .utf8)
    }

    /// One launch, as the root view runs it. Returns the session and the
    /// store, or `nil` for the store when the open throws.
    private func launch() -> (session: LaunchSession, store: RecordStore?) {
        let session = LaunchSession(markerURL: markerURL)
        let outcome = session.begin()
        let store = try? RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: outcome.launchOutcome.enterSafeMode)
        if let store { session.countLaunchFailureIfNeeded(in: store) }
        return (session, store)
    }

    private func launchFailures() throws -> Int {
        try autoreleasepool {
            try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true)
                .diagnosticsCounts(contentVersion: 1).launchFailures
        }
    }

    /// Scenario "Third launch with an uncleared marker": two failed launches,
    /// then the third open. Safe mode opens the store read-only and the
    /// launch failure count in `Local.store` does not change.
    func testTheThirdOpenAfterTwoFailedLaunchesOpensTheStoreReadOnly() throws {
        // Launch 1 is the first launch: it makes the store, then ends
        // before Today appears.
        let first = launch()
        XCTAssertEqual(first.store?.isReadOnly, false)
        // Launch 2 finds the marker, counts one failure, and ends too.
        let second = launch()
        XCTAssertEqual(second.store?.isReadOnly, false)
        XCTAssertEqual(second.session.outcome?.launchOutcome.enterSafeMode, false)

        let third = launch()

        XCTAssertEqual(third.session.outcome?.launchOutcome.enterSafeMode, true)
        XCTAssertEqual(third.store?.isReadOnly, true)
        XCTAssertEqual(try third.store?.diagnosticsCounts(contentVersion: 1).launchFailures, 1, "safe mode adds nothing to Local.store")
        XCTAssertEqual(third.session.uncountedFailures, 1)
        XCTAssertEqual(markerContent(), "2 1", "the marker keeps safe mode's launch failure")
    }

    /// "The app MUST add one to the launch failure count in `Local.store`
    /// each time it finds an uncleared marker." Safe mode's own failure
    /// reaches `Local.store` at the next ordinary launch.
    func testTheNextOrdinaryLaunchAddsSafeModesLaunchFailure() throws {
        _ = launch()
        _ = launch()
        let safeMode = launch()
        XCTAssertEqual(safeMode.store?.isReadOnly, true)
        // Safe mode's Today appears.
        safeMode.session.clearAfterTodayAppears()
        XCTAssertEqual(markerContent(), "- 1", "the marker is cleared, and it keeps the uncounted failure")

        let next = launch()

        XCTAssertEqual(next.session.outcome?.markerWasUncleared, false, "safe mode's Today cleared the marker")
        XCTAssertEqual(next.session.outcome?.launchOutcome.enterSafeMode, false)
        XCTAssertEqual(next.store?.isReadOnly, false)
        XCTAssertEqual(try next.store?.diagnosticsCounts(contentVersion: 1).launchFailures, 2, "the failure launch 2 found, and the one safe mode found")
        XCTAssertEqual(next.session.uncountedFailures, 0)
        XCTAssertEqual(markerContent(), "0")
        next.session.clearAfterTodayAppears()
        XCTAssertNil(markerContent(), "with no uncounted failure, the clear deletes the file")
    }

    /// A safe-mode launch that also ends before its Today appears: the
    /// next open is safe mode again, and the marker keeps both failures.
    func testASecondSafeModeLaunchKeepsBothFailures() throws {
        _ = launch()
        _ = launch()
        _ = launch() // safe mode, ends before its Today appears.

        let again = launch()

        XCTAssertEqual(again.session.outcome?.launchOutcome.enterSafeMode, true)
        XCTAssertEqual(again.store?.isReadOnly, true)
        XCTAssertEqual(markerContent(), "3 2")
        XCTAssertEqual(try launchFailures(), 1)
    }

    /// The marker content: a marker from an earlier build holds only a
    /// streak; text that cannot be read counts as not cleared.
    func testTheMarkerContentReadsEveryForm() {
        XCTAssertEqual(LaunchMarkerFile.Content(text: "2"), .init(streak: 2, uncountedFailures: 0))
        XCTAssertEqual(LaunchMarkerFile.Content(text: "2 1\n"), .init(streak: 2, uncountedFailures: 1))
        XCTAssertEqual(LaunchMarkerFile.Content(text: "- 3"), .init(streak: nil, uncountedFailures: 3))
        XCTAssertEqual(LaunchMarkerFile.Content(text: "?"), .init(streak: 0, uncountedFailures: 0))
        XCTAssertEqual(LaunchMarkerFile.Content(streak: 4, uncountedFailures: 0).text, "4")
        XCTAssertEqual(LaunchMarkerFile.Content(streak: nil, uncountedFailures: 2).text, "- 2")
    }

    /// A cleared marker that keeps uncounted failures is not an uncleared
    /// marker: the streak starts again at 0.
    func testAClearedMarkerWithUncountedFailuresStartsANewStreak() throws {
        try Data("- 1".utf8).write(to: markerURL)

        let outcome = LaunchMarkerFile.begin(at: markerURL)

        XCTAssertFalse(outcome.markerWasUncleared)
        XCTAssertEqual(outcome.launchOutcome, LaunchOutcome(enterSafeMode: false, newConsecutiveUnclearedCount: 0))
        XCTAssertEqual(outcome.uncountedFailures, 1)
        XCTAssertEqual(markerContent(), "0 1")
    }
}
