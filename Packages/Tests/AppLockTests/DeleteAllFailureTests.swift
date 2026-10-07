import XCTest
@testable import AppLock

/// A seam whose deletion always fails, as when the store directory cannot
/// be removed.
private struct FailingDeleteAllSeam: DeleteAllPerforming {
    struct Failure: Error {}
    func deleteEverything() async throws { throw Failure() }
    func deleteFromThisDevice() async throws { throw Failure() }
}

/// A seam whose first deletion fails and whose next deletions succeed.
private actor FailsOnceDeleteAllSeam: DeleteAllPerforming {
    struct Failure: Error {}
    private var hasFailed = false
    func deleteEverything() async throws { try failTheFirstTime() }
    func deleteFromThisDevice() async throws { try failTheFirstTime() }
    private func failTheFirstTime() throws {
        guard hasFailed else {
            hasFailed = true
            throw Failure()
        }
    }
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

        XCTAssertEqual(controller.coverDeletionOutcome, .failed)
        XCTAssertEqual(controller.state.coverMode, .locked, "the cover stays")
        XCTAssertEqual(DeleteAllOutcome.failureMessage.english, "Could not delete. Try again.")
    }

    /// Ruling r17-04 (mm-t41.27): after a failed "Delete from this device",
    /// the cover shows the same line as after a failed "Delete everything",
    /// under its controls. The cover stays, with no "Unlock".
    func testAFailedDeleteFromThisDeviceShowsTheSameFailureLineOnTheCover() async {
        let controller = controller(seam: FailingDeleteAllSeam())
        controller.handle(.enrolmentChanged)

        let deleted = await controller.confirmDeleteFromThisDevice()

        XCTAssertFalse(deleted, "the deleted screen does not show")
        XCTAssertEqual(controller.coverDeletionOutcome, .failed)
        XCTAssertEqual(controller.state.coverMode, .lockedAfterEnrolmentChange, "the cover stays")
    }

    /// A second "Delete from this device" removes the line while it runs.
    /// When it succeeds, the line does not show again.
    func testASuccessfulRetryOfDeleteFromThisDeviceRemovesTheLine() async {
        let seam = FailsOnceDeleteAllSeam()
        let controller = controller(seam: seam)
        controller.handle(.enrolmentChanged)
        await controller.confirmDeleteFromThisDevice()
        XCTAssertEqual(controller.coverDeletionOutcome, .failed)

        let deleted = await controller.confirmDeleteFromThisDevice()

        XCTAssertTrue(deleted)
        XCTAssertEqual(controller.coverDeletionOutcome, .deleted)
    }

    /// A new deletion removes the line while it runs; a success shows the
    /// deleted screen, with no line.
    func testASuccessfulDeletionShowsNoFailureLine() async {
        let controller = controller(seam: RecordingDeleteAllSeam())

        await controller.confirmDeleteEverything()

        XCTAssertEqual(controller.coverDeletionOutcome, .deleted)
    }

    /// "Unlock" takes the cover away, and the line with it: the next cover
    /// shows no old failure.
    func testUnlockRemovesTheFailureLine() async {
        let controller = controller(seam: FailingDeleteAllSeam())
        await controller.confirmDeleteEverything()

        await controller.tapUnlock()

        XCTAssertNil(controller.coverDeletionOutcome)
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
