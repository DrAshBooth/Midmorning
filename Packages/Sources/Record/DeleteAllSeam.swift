import Foundation

/// The seam the settings screen's "Delete everything" calls (settings spec,
/// "The Privacy group"; data-and-privacy spec, "Delete-all"). The App
/// target's `RealDeleteAllSeam` conforms to it over `LocalDeletion`.
public protocol DeleteAllSeam: Sendable {
    /// Deletes every row on this device. The real implementation also
    /// writes an erasure marker before it deletes; this protocol only
    /// states the one call the Privacy group's "Delete everything" makes.
    func deleteEverything() throws
}
