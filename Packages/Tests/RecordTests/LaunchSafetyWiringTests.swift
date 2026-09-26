import Foundation
import XCTest
@testable import Record

/// mm-t42.20, the wiring bead: two `mm-t41.3` scenarios built there only
/// over fixture facts now run end to end over real components.
/// `App/Midmorning/LaunchMarker.swift` and `AppLockRootView.attemptOpen`
/// (App target, untested by `swift test`) call the same
/// `Record.LaunchMarkerFile` these tests call (mm-t41.17).
@MainActor
final class LaunchSafetyWiringTests: XCTestCase {
    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// One launch: the real `LaunchMarkerFile.begin` the App target's
    /// `LaunchSession` calls. The caller decides whether to "clear" (delete
    /// the file) to simulate Today appearing.
    private func beginLaunch(markerURL: URL) -> LaunchOutcome {
        LaunchMarkerFile.begin(at: markerURL).launchOutcome
    }

    /// Scenario: Third launch with an uncleared marker, over a real marker
    /// file on disk (mm-t41.3 built this over fixture booleans only). A
    /// launch already left the marker on disk before the scenario's own two
    /// launches "in a row" (`LaunchSafety.startLaunch` only counts a streak
    /// from a marker that already existed when the launch began, the same
    /// precondition `LaunchSafetyTests`' fixture streak of 0 stands in for).
    func testThirdConsecutiveLaunchWithARealUnclearedMarkerFileEntersSafeMode() throws {
        let directory = try makeDirectory()
        let markerURL = directory.appendingPathComponent("launch-marker.txt")
        _ = beginLaunch(markerURL: markerURL) // an earlier launch already left the marker.

        // Launch 1 of 2 "in a row": ends before Today appears.
        let first = beginLaunch(markerURL: markerURL)
        XCTAssertFalse(first.enterSafeMode)
        // Launch 2 of 2: same — still no marker clear.
        let second = beginLaunch(markerURL: markerURL)
        XCTAssertFalse(second.enterSafeMode)
        // "Opens it a third time": the app opens Today with Export and Get
        // support.
        let third = beginLaunch(markerURL: markerURL)
        XCTAssertTrue(third.enterSafeMode)
        XCTAssertTrue(FileManager.default.fileExists(atPath: markerURL.path), "the marker file itself still exists; safe mode clears it only once its own reduced Today appears")
    }

    /// Scenario: Marker cleared, chained after safe mode: safe mode's own
    /// Today appearing clears the marker, so the next launch starts a fresh
    /// streak (data-and-privacy spec, "Launch safety": "Marker cleared").
    func testSafeModesOwnTodayClearsTheMarkerForTheNextLaunch() throws {
        let directory = try makeDirectory()
        let markerURL = directory.appendingPathComponent("launch-marker.txt")
        for _ in 1...4 { _ = beginLaunch(markerURL: markerURL) }

        // Safe mode's reduced Today appears: the marker clears, exactly as
        // it would after the ordinary Today appears.
        LaunchMarkerFile.clear(at: markerURL)

        let next = beginLaunch(markerURL: markerURL)
        XCTAssertFalse(next.enterSafeMode)
        XCTAssertEqual(next.newConsecutiveUnclearedCount, 0)
    }

    /// Scenario: Store fails to open, over a real container failure: a
    /// plain file sits where `RecordStore` needs to create its own
    /// directory contents, so `ModelContainer` throws for real (mm-t41.3
    /// built this over a fixture boolean only).
    func testARealContainerFailureReportsFailedNotWaiting() throws {
        let directory = try makeDirectory()
        // `RecordStore.init(directory:)` appends "Record.store" under this
        // path; putting a plain file at the parent forces every attempt to
        // create that path to fail.
        let blockedDirectory = directory.appendingPathComponent("blocked")
        try Data().write(to: blockedDirectory)

        var openSucceeded = true
        do {
            _ = try RecordStore(directory: blockedDirectory)
        } catch {
            openSucceeded = false
        }
        XCTAssertFalse(openSucceeded, "creating a store under a path that is already a plain file must throw")
        XCTAssertEqual(AppStoreOpening.attempt(protectedDataAvailable: true, openSucceeded: openSucceeded), .failed)
        // The store files are unchanged: the blocking file is still there,
        // untouched, exactly as it was before the attempt.
        XCTAssertTrue(FileManager.default.fileExists(atPath: blockedDirectory.path))
    }
}
