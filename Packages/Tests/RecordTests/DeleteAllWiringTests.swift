import Foundation
import XCTest
@testable import Record
@testable import Plan
import AppLock

/// mm-t42.20, the wiring bead: scenarios several earlier epics proved only
/// structurally ("a fresh store is exactly the post-delete state") now run
/// against `Record.LocalEraser`, the real deletion engine `mm-t41`
/// (local-delete-all) built, over a real directory it actually erases and
/// recreates. `weigh-in`'s own `WeighInStoreTests.testDeleteAllLeavesNoWeighIn`
/// already does this; these are its counterparts for plan, programme,
/// onboarding and app-lock.
@MainActor
final class DeleteAllWiringTests: XCTestCase {
    private func makeStore() throws -> (store: RecordStore, directory: URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (try RecordStore(directory: directory), directory)
    }

    /// regular-eating-plan spec, "The plan's data stays on the device",
    /// Scenario: Delete-all.
    func testDeleteAllLeavesNoTemplateNoDayPlanAndDefaultSlotLabels() throws {
        let (store, directory) = try makeStore()
        try store.setTemplateSlotsJSON(PlanCodec.encode([PlannedMeal(slotIndex: 1, time: "08:00")]), kind: .weekday, changedAt: .now)
        try store.setDayPlan(dateKey: "2026-10-06", slotsJSON: PlanCodec.encode([PlannedMeal(slotIndex: 2, time: "13:00")]), windowBeforeMinutes: 60, windowAfterMinutes: 90, setAt: .now, setBy: "device", changedAt: .now)
        try store.setSlotLabel("Elevenses", index: 1, changedAt: .now)

        try LocalEraser.eraseAndRecreate(directory: directory)
        let reopened = try RecordStore(directory: directory)

        XCTAssertEqual(try reopened.templateSlotsJSON(.weekday), "[]")
        XCTAssertNil(try reopened.dayPlan(dateKey: "2026-10-06"))
        XCTAssertNil(try reopened.slotLabel(index: 1), "the default labels apply")
    }

    /// programme spec, "The app keeps the stage state", Scenario:
    /// Delete-all.
    func testDeleteAllLeavesNoStageOpenedRowAndNoCardAnswer() throws {
        let (store, directory) = try makeStore()
        try store.recordStageOpened(3, at: Date(timeIntervalSince1970: 1_760_000_000))
        try store.setCardAnswer("Open", id: "opening.2", changedAt: .now)

        try LocalEraser.eraseAndRecreate(directory: directory)
        let reopened = try RecordStore(directory: directory)

        XCTAssertEqual(try reopened.stageOpenedRows(), [])
        XCTAssertEqual(try reopened.answeredCardIds(), [])
    }

    /// onboarding spec, "Four screens, once, in order", Scenario: After
    /// Delete-all — the next launch starts onboarding again, because a
    /// fresh store's `onboardingCompleted()` is false.
    func testAfterDeleteAllTheStoreStartsOnboardingAgain() throws {
        let (store, directory) = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: .now)
        try store.setOnboardingCompleted(true)
        XCTAssertTrue(try store.onboardingCompleted())

        try LocalEraser.eraseAndRecreate(directory: directory)
        let reopened = try RecordStore(directory: directory)

        XCTAssertFalse(try reopened.onboardingCompleted())
        XCTAssertNil(try reopened.profile())
    }

    /// app-lock spec, "Face ID only or Touch ID only", Scenario: Delete
    /// everything after an enrolment change — over a real `AppLockController`
    /// and a real `LocalDeletion`-backed seam (`AppLockControllerTests`
    /// proves the controller never asks to authenticate, using a call-count
    /// fake seam; this proves the same tap, plugged into the real deletion
    /// engine, actually erases the directory).
    func testDeleteEverythingAfterAnEnrolmentChangeReallyErasesTheDirectory() async throws {
        let (store, directory) = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: .now)

        let seam = LocalDeletionBackedSeam(deletion: LocalDeletion(directory: directory, appGroupDirectory: nil, launchMarkerURL: directory.appendingPathComponent("marker")))
        let controller = AppLockController(state: .launch(appLockEnabled: true), authenticator: FakeAuthenticator(result: true), deleteAllSeam: seam)

        controller.handle(.enrolmentChanged)
        let authenticated = await controller.tapDeleteEverything()
        XCTAssertTrue(authenticated, "an enrolment change needs no authentication, the same as \"Delete from this device\"")
        await controller.confirmDeleteEverything()

        let reopened = try RecordStore(directory: directory)
        XCTAssertNil(try reopened.profile())
    }
}

/// Wraps the real `Record.LocalDeletion` as an `AppLock.DeleteAllPerforming`
/// seam, the same shape `App/Midmorning/AppLock/RealDeleteAllSeam.swift`
/// gives the cover — but over `FakeDeleteAllSideEffects` (`LocalDeletionTests
/// .swift`, this target), since the real `UNUserNotificationCenter` crashes
/// outside an app bundle (confirmed empirically; `ununnotificationcenter
/// -crashes-under-swift-test`, `bd memories`).
private struct LocalDeletionBackedSeam: DeleteAllPerforming {
    let deletion: LocalDeletion

    func deleteEverything() async {
        try? deletion.perform(sideEffects: FakeDeleteAllSideEffects())
    }

    func deleteFromThisDevice() async {
        try? deletion.perform(sideEffects: FakeDeleteAllSideEffects())
    }
}
