import Foundation
import Record

/// The file half of `Record.LaunchSafety`: writes the marker at start, reads
/// back the previous launch's streak from the marker's own content (never
/// from `Local.store`, so the safe-mode decision needs no store to open
/// first — design.md, "The launch marker tracks a streak, separately from
/// the lifetime count"), and clears it once Today appears.
enum LaunchMarker {
    struct Outcome {
        let markerWasUncleared: Bool
        let launchOutcome: LaunchOutcome
    }

    /// Data-and-privacy spec, "Launch safety": "The app MUST write a launch
    /// marker file at start." Reads the previous streak from the marker
    /// file (if it still exists from a launch that never cleared it), then
    /// overwrites it with the new streak, so a crash right after this call
    /// still leaves the right count for the next launch to find.
    static func beginLaunch(applicationSupportDirectory: URL, fileManager: FileManager = .default) -> Outcome {
        let url = StoreLayout.launchMarkerURL(applicationSupportDirectory: applicationSupportDirectory)
        let previousContent = try? String(contentsOf: url, encoding: .utf8)
        let markerWasUncleared = previousContent != nil
        let previousStreak = previousContent
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? 0
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: markerWasUncleared, previousConsecutiveUnclearedCount: previousStreak)
        try? String(outcome.newConsecutiveUnclearedCount).write(to: url, atomically: true, encoding: .utf8)
        return Outcome(markerWasUncleared: markerWasUncleared, launchOutcome: outcome)
    }

    /// Data-and-privacy spec, "Launch safety": "The app MUST clear the
    /// marker after Today appears." This app has no onboarding gate yet, so
    /// reaching the running phase (task 3.1's own scope note) stands in for
    /// "Today appears".
    static func clearAfterTodayAppears(applicationSupportDirectory: URL, fileManager: FileManager = .default) {
        let url = StoreLayout.launchMarkerURL(applicationSupportDirectory: applicationSupportDirectory)
        try? fileManager.removeItem(at: url)
    }
}
