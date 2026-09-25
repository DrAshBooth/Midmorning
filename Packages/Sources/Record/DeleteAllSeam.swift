import Foundation

/// The seam "Delete everything" calls (settings spec, "The Privacy group";
/// design.md, "Pure seams the packages expose": `ErasureZone`). `local-
/// delete-all` (4.1) builds the real state machine over `ErasureZone`; this
/// change's README names `StubDeleteAllSeam` as the stub the Privacy group
/// calls until 4.1 merges.
public protocol DeleteAllSeam: Sendable {
    /// Deletes every row on this device. The real implementation also
    /// writes an erasure marker before it deletes; this protocol only
    /// states the one call the Privacy group's "Delete everything" makes.
    func deleteEverything() throws
}

/// Does nothing and never throws. `local-delete-all` (4.1) replaces this
/// with the real `ErasureZone` state machine.
public struct StubDeleteAllSeam: DeleteAllSeam {
    public init() {}
    public func deleteEverything() throws {}
}
