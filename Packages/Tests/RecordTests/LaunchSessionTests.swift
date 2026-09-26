import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Launch safety" and "File protection" (mm-t41.17,
/// mm-t41.19, mm-t41.21). `AppLockRootView` and `App/Midmorning/
/// LaunchMarker.swift` call these same `Record` functions; the view itself
/// has no test runner (`no-app-target-test-runner`).
@MainActor
final class LaunchSessionTests: XCTestCase {
    private var root: URL!
    private var markerURL: URL { StoreLayout.launchMarkerURL(applicationSupportDirectory: root) }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("LaunchSessionTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func markerContent() -> String? {
        try? String(contentsOf: markerURL, encoding: .utf8)
    }

    /// "Try again" and a second protected-data notice open the store again
    /// in the same process. The streak rises once for the launch, not once
    /// for each attempt.
    func testASecondOpenAttemptInTheSameLaunchDoesNotGrowTheStreak() {
        _ = LaunchMarkerFile.begin(at: markerURL) // an earlier launch left the marker.
        let session = LaunchSession(markerURL: markerURL)

        let first = session.begin()
        let second = session.begin()

        XCTAssertTrue(first.markerWasUncleared)
        XCTAssertEqual(first, second)
        XCTAssertEqual(markerContent(), "1", "one launch with an uncleared marker, whatever the number of attempts")
    }

    /// Scenario: Launch failures counted — once per launch, on the first
    /// store that opens.
    func testTheLaunchFailureCountRisesOncePerLaunch() throws {
        _ = LaunchMarkerFile.begin(at: markerURL)
        let session = LaunchSession(markerURL: markerURL)
        session.begin()
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)

        session.countLaunchFailureIfNeeded(in: store)
        session.countLaunchFailureIfNeeded(in: store)

        XCTAssertEqual(try store.diagnosticsCounts(contentVersion: 1).launchFailures, 1)
    }

    func testNoLaunchFailureIsCountedAfterALaunchThatReachedToday() throws {
        let session = LaunchSession(markerURL: markerURL)
        session.begin()
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)

        session.countLaunchFailureIfNeeded(in: store)

        XCTAssertEqual(try store.diagnosticsCounts(contentVersion: 1).launchFailures, 0)
    }

    /// Scenario: Marker cleared — the marker stays after the store opens,
    /// and goes only when Today appears.
    func testTheMarkerStaysUntilTodayAppears() throws {
        let session = LaunchSession(markerURL: markerURL)
        session.begin()
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
        session.countLaunchFailureIfNeeded(in: store)
        XCTAssertNotNil(markerContent(), "the store opened, but Today has not appeared yet")

        session.clearAfterTodayAppears()

        XCTAssertNil(markerContent())
        let next = LaunchSession(markerURL: markerURL).begin()
        XCTAssertFalse(next.markerWasUncleared)
        XCTAssertEqual(next.launchOutcome.newConsecutiveUnclearedCount, 0)
    }

    /// "File protection": "Every other file the app writes MUST carry
    /// NSFileProtectionComplete."
    func testTheMarkerFileCarriesCompleteProtectionAndNoBackup() throws {
        LaunchSession(markerURL: markerURL).begin()

        let attributes = try FileManager.default.attributesOfItem(atPath: markerURL.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        XCTAssertEqual(try markerURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    /// "Delete-all": "The app MUST keep that screen after 'Done' until the
    /// next launch. The app MUST start onboarding only at the next launch."
    /// A lock and unlock on the deleted screen opens no store.
    func testTheRootTriesToOpenOnlyFromTheWaitingAndFailurePhases() {
        XCTAssertTrue(AppStoreOpening.triesToOpen(from: .waitingForProtectedData))
        XCTAssertTrue(AppStoreOpening.triesToOpen(from: .failedToOpen))
        XCTAssertFalse(AppStoreOpening.triesToOpen(from: .deleted))
        XCTAssertFalse(AppStoreOpening.triesToOpen(from: .running))
        XCTAssertFalse(AppStoreOpening.triesToOpen(from: .safeMode))
    }
}
