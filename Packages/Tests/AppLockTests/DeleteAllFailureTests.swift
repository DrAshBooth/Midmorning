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
