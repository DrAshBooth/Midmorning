import Foundation
import MetricKit
import Record

/// Receives MetricKit diagnostics and keeps only a count of the crashes
/// (data-and-privacy spec, "No record content in the system log or crash
/// reports": "The app MUST receive MetricKit crash diagnostics. From each
/// diagnostic the app MUST keep only a count in `Local.store`. The app MUST
/// NOT keep, show or send the diagnostic payload."). Each delivery adds the
/// number of its crash diagnostics; hang, CPU and disk diagnostics add
/// nothing. MetricKit delivers each payload once and can deliver it before
/// the store opens, so `Record.CrashCountRelay` keeps that count until
/// `AppLockRootView` connects the store. A delivery to a process that ends
/// before the store opens is not counted. `CrashCountRelayTests` proves the
/// count; MetricKit delivers no diagnostic in the simulator, so the real
/// delivery is a device check (`mm-t41.15`).
///
/// `MXMetricManager` can call `didReceive` on a background queue, and
/// `RecordStore` is not thread-safe, so this locks the relay (MetricKit's
/// own thread, plain `didReceive`) and always writes on the main actor.
final class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    private let lock = NSLock()
    private var relay = CrashCountRelay()
    private var addCrashes: (@MainActor (Int) -> Void)?

    /// The store opened: `addCrashes` gets every crash that waited, then
    /// every later one.
    func connect(addCrashes: @escaping @MainActor (Int) -> Void) {
        let waiting = lock.withLock {
            self.addCrashes = addCrashes
            return relay.connect()
        }
        guard waiting > 0 else { return }
        Task { @MainActor in addCrashes(waiting) }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let crashes = CrashCountRelay.crashCount(inPayloadCrashCounts: payloads.map { $0.crashDiagnostics?.count })
        let (now, callback) = lock.withLock { (relay.receive(crashes: crashes), addCrashes) }
        guard now > 0, let callback else { return }
        Task { @MainActor in callback(now) }
    }
}
