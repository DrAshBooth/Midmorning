import XCTest
@testable import AppLock

/// A seam whose deletion always fails, as when the store directory cannot
/// be removed.
private struct FailingDeleteAllSeam: DeleteAllPerforming {
    struct Failure: Error {}
    func deleteEverything() async throws { throw Failure() }
    func deleteFromThisDevice() async throws { throw Failure() }
}

/// data-and-privacy spec, "Delete-all" and "Delete from this device"
/// (mm-t41.20): the cover shows the deleted screen only when the deletion
/// succeeded. `CoverView` shows it only when these calls return `true`.
@MainActor
final class DeleteAllFailureTests: XCTestCase {
    private func controller(seam: DeleteAllPerforming) -> AppLockController {
        AppLockController(state: .launch(appLockEnabled: true), authenticator: FakeAuthenticator(result: true), deleteAllSeam: seam)
    }

    func testAFailedDeleteEverythingReportsFailure() async {
        let deleted = await controller(seam: FailingDeleteAllSeam()).confirmDeleteEverything()
        XCTAssertFalse(deleted)
    }

    func testAFailedDeleteFromThisDeviceReportsFailure() async {
        let deleted = await controller(seam: FailingDeleteAllSeam()).confirmDeleteFromThisDevice()
        XCTAssertFalse(deleted)
    }

    /// Ruling r14-01 (mm-t41.26), scenario "Deletion fails from the
    /// cover": the cover shows "Could not delete. Try again." under its
    /// controls.
    func testAFailedDeleteEverythingShowsTheFailureLineOnTheCover() async {
        let controller = controller(seam: FailingDeleteAllSeam())

        await controller.confirmDeleteEverything()

        XCTAssertEqual(controller.deleteEverythingOutcome, .failed)
        XCTAssertEqual(controller.state.coverMode, .locked, "the cover stays")
        XCTAssertEqual(DeleteAllOutcome.failureMessage.english, "Could not delete. Try again.")
    }

    /// A new deletion removes the line while it runs; a success shows the
    /// deleted screen, with no line.
    func testASuccessfulDeletionShowsNoFailureLine() async {
        let controller = controller(seam: RecordingDeleteAllSeam())

        await controller.confirmDeleteEverything()

        XCTAssertEqual(controller.deleteEverythingOutcome, .deleted)
    }

    /// "Unlock" takes the cover away, and the line with it: the next cover
    /// shows no old failure.
    func testUnlockRemovesTheFailureLine() async {
        let controller = controller(seam: FailingDeleteAllSeam())
        await controller.confirmDeleteEverything()

        await controller.tapUnlock()

        XCTAssertNil(controller.deleteEverythingOutcome)
    }

    /// The settings screen and the store-failure page call a deletion that
    /// throws (`Record.DeleteAllSeam`): the same outcome and the same line.
    func testTheOutcomeOfAThrowingDeletion() {
        struct Failure: Error {}
        XCTAssertEqual(DeleteAllOutcome.of { throw Failure() }, .failed)
        XCTAssertEqual(DeleteAllOutcome.of {}, .deleted)
    }

    func testASuccessfulDeletionReportsSuccess() async {
        let seam = RecordingDeleteAllSeam()
        let controller = controller(seam: seam)
        let everything = await controller.confirmDeleteEverything()
        let thisDevice = await controller.confirmDeleteFromThisDevice()
        XCTAssertTrue(everything)
        XCTAssertTrue(thisDevice)
        let everythingCalls = await seam.deleteEverythingCallCount
        XCTAssertEqual(everythingCalls, 1)
    }
}
