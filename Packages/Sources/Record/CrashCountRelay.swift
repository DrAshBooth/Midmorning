import Foundation

/// The count half of MetricKit crash diagnostics (data-and-privacy spec, "No
/// record content in the system log or crash reports": "From each
/// diagnostic the app MUST keep only a count in `Local.store`"; "The
/// Diagnostics counts come from the device"). The App target's
/// `MetricKitSubscriber` holds one relay under a lock. MetricKit can deliver
/// before the store opens, so the relay keeps that count until the store
/// opens, then hands it over.
public struct CrashCountRelay: Sendable, Equatable {
    public private(set) var isConnected = false
    public private(set) var waiting = 0

    public init() {}

    /// The number of crashes in one MetricKit delivery: the sum of each
    /// payload's crash diagnostics. A payload that holds only hang, CPU or
    /// disk diagnostics adds nothing, and a payload with two crashes adds
    /// two.
    public static func crashCount(inPayloadCrashCounts crashCounts: [Int?]) -> Int {
        crashCounts.reduce(0) { $0 + ($1 ?? 0) }
    }

    /// Takes the crashes of one delivery. Returns the number to add to the
    /// store now: all of them once the store is open, else none (the relay
    /// keeps them).
    public mutating func receive(crashes: Int) -> Int {
        guard crashes > 0 else { return 0 }
        guard isConnected else {
            waiting += crashes
            return 0
        }
        return crashes
    }

    /// The store opened. Returns the number of crashes that waited, to add
    /// to the store now.
    public mutating func connect() -> Int {
        isConnected = true
        defer { waiting = 0 }
        return waiting
    }
}
