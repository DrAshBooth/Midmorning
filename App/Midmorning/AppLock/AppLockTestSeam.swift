#if DEBUG
import Foundation
import AppLock
import Constants

/// The app-lock test seam for the UI tests in
/// `tools/skeleton-checks/HarnessUITests` (rulings r13-19 and r16-01, epic
/// mm-t45). A simulator cannot answer a real system authentication request
/// from a test, so these tests could not drive the app lock before.
///
/// The seam obeys three rules:
/// - It is compiled only in a Debug build: every line of this file is
///   inside `#if DEBUG`, and so is each line in another App file that names
///   it. `AppLockTestSeamSourceTests` (package, in `./verify`) proves this
///   and proves that the Release configuration does not set `DEBUG`. So a
///   Release build holds no seam.
/// - It is on only when the launch environment holds `environmentKey`. A UI
///   test sets it in `XCUIApplication.launchEnvironment`. A launch from the
///   Home Screen, or from Xcode with no such variable, uses the real calls.
/// - It replaces two calls and nothing else: the system authentication
///   request (`LAContextAuthenticator`, through
///   `AppLockControllerFactory`) and the enrolment state hash
///   (`EnrolmentHash.current`). The device's `Biometry`, the cover, the
///   controller, the store and the deletion stay real.
///
/// The value of `environmentKey` is the path of a JSON script file (see
/// `Script`). The test writes the file, and it can change it at any time,
/// for example between two taps. Each request reads the file again.
enum AppLockTestSeam {
    static let environmentKey = "MIDMORNING_APP_LOCK_SCRIPT"

    /// One scripted result of a system authentication request. The
    /// protocol `AuthenticationPerforming` returns only success or no
    /// success, so the app treats the three results other than `succeed`
    /// the same, as it does with the real request.
    enum Outcome: String, Codable {
        /// The person authenticates.
        case succeed
        /// The biometric does not match, or iOS stops it (lockout).
        case fail
        /// The person cancels the request.
        case cancel
        /// The device has no passcode: `LAContextAuthenticator` makes no
        /// request and returns `false`.
        case noPasscode
    }

    /// The script file.
    struct Script: Codable {
        /// The results of the next requests, first to last. Each request
        /// takes the first result and writes the file again without it.
        /// A request when the list is empty does not succeed, and the log
        /// records it as "unscripted", so a test can find a request that it
        /// did not expect.
        var results: [Outcome]
        /// What `EnrolmentHash.current()` returns. A change of this value
        /// is an enrolment change. `nil`: the device gives no hash.
        var enrolmentHash: String?
    }

    /// The script file, when the seam is on.
    static var scriptURL: URL? {
        guard let path = ProcessInfo.processInfo.environment[environmentKey], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// The log file beside the script: one line for each request, in the
    /// form "<policy> <reason key> <result>". The test reads it to count
    /// the requests and to see the policy of each one.
    static func logURL(for scriptURL: URL) -> URL {
        scriptURL.deletingPathExtension().appendingPathExtension("log")
    }

    /// The script as the file holds it now, or `nil` when the seam is off.
    /// A file that is missing or that does not decode gives an empty
    /// script, so no request succeeds by chance.
    static func currentScript() -> Script? {
        guard let url = scriptURL else { return nil }
        guard let data = try? Data(contentsOf: url), let script = try? JSONDecoder().decode(Script.self, from: data) else {
            return Script(results: [], enrolmentHash: nil)
        }
        return script
    }

    /// Takes the next result from the script file and writes one line to
    /// the log.
    static func takeNextOutcome(reason: CatalogueText, policy: AuthenticationPolicy) -> Outcome? {
        guard let url = scriptURL, var script = currentScript() else { return nil }
        let outcome = script.results.isEmpty ? nil : script.results.removeFirst()
        if let data = try? JSONEncoder().encode(script) {
            try? data.write(to: url, options: .atomic)
        }
        let reasonKey: String
        switch reason {
        case .entry(let key, _): reasonKey = key
        default: reasonKey = "other"
        }
        let line = "\(policy == .biometricsOnly ? "biometricsOnly" : "biometricsAndPasscode") \(reasonKey) \(outcome?.rawValue ?? "unscripted")\n"
        let log = logURL(for: url)
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? Data(line.utf8).write(to: log, options: .atomic)
        }
        return outcome
    }
}

/// The scripted system authentication request. It waits a short time, as
/// the real request does, then returns the next result of the script.
struct ScriptedAuthenticator: AuthenticationPerforming {
    /// A scripted authenticator when the seam is on; else `nil`.
    static func fromLaunchEnvironment() -> ScriptedAuthenticator? {
        AppLockTestSeam.scriptURL == nil ? nil : ScriptedAuthenticator()
    }

    func authenticate(reason: CatalogueText, policy: AuthenticationPolicy) async -> Bool {
        let outcome = AppLockTestSeam.takeNextOutcome(reason: reason, policy: policy)
        try? await Task.sleep(nanoseconds: 300_000_000)
        return outcome == .succeed
    }
}
#endif
