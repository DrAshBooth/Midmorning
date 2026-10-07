import Foundation
import Record
import AppLock

/// The seeded stores for the app-lock checks in
/// `HarnessUITests/AutomatedChecks+AppLock.swift` (rulings r13-19 and
/// r16-01, epic mm-t45). Each scenario is a scenario of
/// `AutomatedScenarios` with other app-lock values in `Local.store`. The
/// app lock is on in each one, so the app opens locked. The app-lock test
/// seam (`App/Midmorning/AppLock/AppLockTestSeam.swift`) answers each
/// system authentication request.
///
/// - `lock-week1`: `week1`, with the app lock on and "Lock after" at its
///   default ("At once").
/// - `lock-week1-30s`: `week1`, with the app lock on and "Lock after" "30
///   seconds".
/// - `lock-review`: `review`, with the app lock on and "Lock after" "At
///   once". Stage 2 is open, so Today shows "Today's plan" and "Weekly
///   review".
/// - `lock-face-only`: `week1`, with the app lock on, "Face ID only" on and
///   the kept enrolment state hash "A". The test seam returns the current
///   hash. A different hash is an enrolment change.
/// - `lock-gym`: `week1`, with the app lock on and the saved custom place
///   "Gym" (ruling r17-01, mm-t15.22).
@MainActor
enum AppLockScenarios {
    static let names: Set<String> = ["lock-week1", "lock-week1-30s", "lock-review", "lock-face-only", "lock-gym"]

    /// Seeds `scenario`, writes its result line, and ends the process. The
    /// seeder's `main.swift` calls this in one line.
    static func run(_ scenario: String, storeURL: URL) -> Never {
        MainActor.assumeIsolated {
            do {
                try seed(scenario, storeURL: storeURL)
            } catch {
                FileHandle.standardError.write(Data("Seeder: \(error)\n".utf8))
                exit(1)
            }
        }
        exit(0)
    }

    static func seed(_ scenario: String, storeURL: URL) throws {
        let base = scenario == "lock-review" ? "review" : "week1"
        try AutomatedScenarios.seed(base, storeURL: storeURL)
        let store = try RecordStore(directory: storeURL.deletingLastPathComponent())
        try store.setLocalSettingValue("true", key: AppLockSettingsKeys.enabled)
        switch scenario {
        case "lock-week1-30s":
            try store.setLocalSettingValue("30", key: AppLockSettingsKeys.lockAfterSeconds)
        case "lock-face-only":
            try store.setLocalSettingValue("true", key: AppLockSettingsKeys.faceOrTouchOnly)
            try store.setLocalSettingValue("A", key: AppLockSettingsKeys.enrolmentStateHash)
        case "lock-gym":
            try store.touchCustomPlace("Gym", at: Date().addingTimeInterval(-7200))
        default:
            break
        }
        print("seeded \(scenario) on \(base)")
    }
}
