#if DEBUG
import Foundation

/// Debug builds only (rulings r13-19 and r16-01, mm-t14.28). The simulator
/// has no app for a `tel://` URL, so a UI test cannot see if a call starts.
/// When the launch environment holds `MIDMORNING_CALL_RECORD=1`,
/// `NumberRow.startCall` also writes the call's URL as one line to
/// `tmp/CallRecord` in the app's container. The UI tests in
/// `tools/skeleton-checks` read that file: "Call" on the Recents warning
/// writes one line, and "Cancel" writes none. With no such launch
/// environment, this type does nothing. A Release build does not hold it:
/// `SupportCallSourceTests` (AutomatedDeviceChecksTests) checks that this
/// file and its one call are inside `#if DEBUG`.
enum CallRecorder {
    static let environmentKey = "MIDMORNING_CALL_RECORD"
    static let fileName = "CallRecord"

    static func record(_ url: URL) {
        guard ProcessInfo.processInfo.environment[environmentKey] == "1" else { return }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let line = Data((url.absoluteString + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: file) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        } else {
            try? line.write(to: file)
        }
    }
}
#endif
