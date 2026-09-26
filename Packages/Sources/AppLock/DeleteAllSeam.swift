import Foundation
import Constants

/// The result of one "Delete everything" (data-and-privacy spec,
/// "Delete-all"; ruling r14-01, mm-t41.26). After `.failed` the app stays
/// on the screen where the person tapped "Delete everything" (the cover,
/// the settings screen or the store-failure page). That screen shows
/// `failureMessage` as one line under its controls, in the same form as
/// the record's "Could not save. Try again.", and no other text about the
/// failure.
public enum DeleteAllOutcome: Sendable, Equatable {
    case deleted
    case failed

    /// "Could not delete. Try again."
    public static let failureMessage: CatalogueText = .key("applock.deleteEverything.failed")

    /// The outcome of a deletion that throws when it fails, as
    /// `Record.DeleteAllSeam.deleteEverything()` does for the settings
    /// screen and the store-failure page.
    public static func of(_ deletion: () throws -> Void) -> DeleteAllOutcome {
        do {
            try deletion()
            return .deleted
        } catch {
            return .failed
        }
    }
}

/// The two deletions the cover routes to, both owned by `data-and-privacy`.
/// The App target's `RealDeleteAllSeam` conforms to it over
/// `Record.LocalDeletion`. Do not change this protocol's shape without a
/// spec change.
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
/// routed to the right one and nothing else. The "Everything is deleted"
/// screen belongs to the view, not to this seam.
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
