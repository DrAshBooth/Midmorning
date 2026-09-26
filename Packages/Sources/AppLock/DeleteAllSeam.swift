import Foundation

/// The two deletions the cover routes to, both owned by `data-and-privacy`.
/// 4.1 (`local-delete-all`) is not merged yet, so this change's controls
/// call a stub through this seam; the change README names it as a stub
/// (mm-t15.7, mm-t15.10 notes). 4.1 replaces the app's registered
/// implementation; it never changes this protocol's shape without a spec
/// change.
public protocol DeleteAllPerforming: Sendable {
    /// Requirement: "Delete everything from the cover". Deletes every
    /// device's copy, as `data-and-privacy`'s "Delete-all" states. Throws
    /// when the deletion fails, so the cover never shows the deleted
    /// screen for a deletion that did not happen.
    func deleteEverything() async throws
    /// Requirement: "Delete from this device after an enrolment change".
    /// Deletes only this device's copy, as `data-and-privacy`'s "Delete
    /// from this device" states. Throws when the deletion fails.
    func deleteFromThisDevice() async throws
}

/// A seam that only records each call, for a test to assert the cover
/// routed to the right one and nothing else. The App target's own stub
/// (until 4.1 lands) also shows the "Everything is deleted" screen; that
/// belongs to the view, not this seam.
public actor RecordingDeleteAllSeam: DeleteAllPerforming {
    public private(set) var deleteEverythingCallCount = 0
    public private(set) var deleteFromThisDeviceCallCount = 0

    public init() {}

    public func deleteEverything() async {
        deleteEverythingCallCount += 1
    }

    public func deleteFromThisDevice() async {
        deleteFromThisDeviceCallCount += 1
    }
}
