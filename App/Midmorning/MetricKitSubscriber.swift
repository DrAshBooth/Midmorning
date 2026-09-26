import Foundation
import MetricKit

/// Receives MetricKit crash diagnostics and keeps only a count
/// (data-and-privacy spec, "No record content in the system log or crash
/// reports": "The app MUST receive MetricKit crash diagnostics. From each
/// diagnostic the app MUST keep only a count in `Local.store`. The app MUST
/// NOT keep, show or send the diagnostic payload."). A thin adapter with no
/// logic of its own; `Record.RecordStore.incrementCrashCount()` is the
/// tested part. `onDiagnostics` is `nil` until the store opens, so a
/// diagnostic MetricKit delivers before the first successful open is not
/// counted — MetricKit re-delivers on its own schedule, not once per app
/// launch. Untestable under `swift test` (MetricKit delivers no diagnostic
/// in the simulator); device check, `mm-t41.15`.
///
/// `MXMetricManager` can call `didReceive` on a background queue, and
/// `RecordStore` is not thread-safe, so this locks the property (MetricKit's
/// own thread, plain `didReceive`) and always calls it on the main actor
/// (every store access).
final class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    private let lock = NSLock()
    private var storedOnDiagnostics: (@MainActor () -> Void)?

    var onDiagnostics: (@MainActor () -> Void)? {
        get { lock.withLock { storedOnDiagnostics } }
        set { lock.withLock { storedOnDiagnostics = newValue } }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard !payloads.isEmpty else { return }
        let callback = onDiagnostics
        Task { @MainActor in
            callback?()
        }
    }
}
