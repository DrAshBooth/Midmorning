import Foundation
import UserNotifications
import Record
import AppLock

/// The real conformer of `Record.DeleteAllSideEffects`:
/// `UNUserNotificationCenter` and (once `2.5` links the WidgetKit extension)
/// `WidgetCenter`. Untestable under `swift test` (both need a device or a
/// simulator); `LocalDeletionTests` (`RecordTests`) drives `LocalDeletion`
/// through a fake instead (built here over fixture facts, with no live
/// dependency — `mm-t42.20` runs it end to end).
struct SystemDeleteAllSideEffects: DeleteAllSideEffects {
    func cancelEveryNotification() {
        let centre = UNUserNotificationCenter.current()
        centre.removeAllPendingNotificationRequests()
        centre.removeAllDeliveredNotifications()
    }

    func reloadWidgets() {
        // `2.5` (widgets-and-intents) links the WidgetKit extension; until
        // then the app has no timeline to reload.
    }
}

/// The real deletion behind both call sites: the Privacy group's "Delete
/// everything" (`Record.DeleteAllSeam`) and the cover's "Delete
/// everything"/"Delete from this device" (`AppLock.DeleteAllPerforming`). A
/// thin adapter over `Record.LocalDeletion`, the tested engine
/// (data-and-privacy spec: "Delete-all", "Delete from this device"). A plain
/// class, not an actor: `DeleteAllSeam.deleteEverything()` is a synchronous,
/// throwing call the Privacy group's button action makes directly, and an
/// actor cannot satisfy that from outside without `await` (Swift's
/// actor-isolation rule), so this type stays nonisolated and safe to call
/// from either call site's own actor.
final class RealDeleteAllSeam: DeleteAllSeam, DeleteAllPerforming, @unchecked Sendable {
    private let deletion: LocalDeletion
    private let sideEffects: DeleteAllSideEffects

    init(deletion: LocalDeletion, sideEffects: DeleteAllSideEffects = SystemDeleteAllSideEffects()) {
        self.deletion = deletion
        self.sideEffects = sideEffects
    }

    // MARK: Record.DeleteAllSeam — the Privacy group's "Delete everything"

    func deleteEverything() throws {
        try deletion.perform(sideEffects: sideEffects)
    }

    // MARK: AppLock.DeleteAllPerforming — the cover

    func deleteEverything() async {
        try? deletion.perform(sideEffects: sideEffects)
    }

    func deleteFromThisDevice() async {
        try? deletion.perform(sideEffects: sideEffects)
    }
}

extension RealDeleteAllSeam {
    /// Builds a seam from the app's own file locations
    /// (`StoreLocation`/`StoreLayout`), for a caller with no already-open
    /// store or controller to read paths from — the Privacy group's
    /// "Delete everything" (`SettingsView`'s default `deleteAllSeam`) and
    /// `AppLockRootView`'s own controller each call this, so both share the
    /// same paths with no state threaded between them; `LocalDeletion`
    /// holds no mutable state, so two independent instances are safe.
    static func usingAppFileLocations() -> RealDeleteAllSeam {
        let applicationSupportDirectory = (try? StoreLocation.applicationSupportDirectory()) ?? FileManager.default.temporaryDirectory
        return RealDeleteAllSeam(deletion: LocalDeletion(
            directory: StoreLayout.storeDirectory(applicationSupportDirectory: applicationSupportDirectory),
            appGroupDirectory: StoreLocation.appGroupDirectory(),
            launchMarkerURL: StoreLayout.launchMarkerURL(applicationSupportDirectory: applicationSupportDirectory)
        ))
    }
}
