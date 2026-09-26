import Foundation

/// The file half of `LaunchSafety` (data-and-privacy spec, "Launch safety",
/// "File protection"). The marker holds only the streak of launches that
/// ended before Today appeared. The App target's `LaunchMarker` calls this
/// through one `LaunchSession` per process.
public enum LaunchMarkerFile {
    public struct Outcome: Sendable, Equatable {
        public let markerWasUncleared: Bool
        public let launchOutcome: LaunchOutcome

        public init(markerWasUncleared: Bool, launchOutcome: LaunchOutcome) {
            self.markerWasUncleared = markerWasUncleared
            self.launchOutcome = launchOutcome
        }
    }

    /// "The app MUST write a launch marker file at start." Reads the
    /// previous streak from the marker file when a launch left it, then
    /// writes the new streak. The write is atomic and carries
    /// `NSFileProtectionComplete` ("Every other file the app writes MUST
    /// carry NSFileProtectionComplete"). The marker is also excluded from
    /// backup, so a restore onto a new device never brings back an old
    /// streak.
    public static func begin(at url: URL) -> Outcome {
        let previousContent = try? String(contentsOf: url, encoding: .utf8)
        let markerWasUncleared = previousContent != nil
        let previousStreak = previousContent
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? 0
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: markerWasUncleared, previousConsecutiveUnclearedCount: previousStreak)
        try? Data(String(outcome.newConsecutiveUnclearedCount).utf8).write(to: url, options: [.atomic, .completeFileProtection])
        try? FileProtection.excludeFromBackup(url)
        return Outcome(markerWasUncleared: markerWasUncleared, launchOutcome: outcome)
    }

    /// "The app MUST clear the marker after Today appears."
    public static func clear(at url: URL, fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: url)
    }
}

/// One launch of the app process (data-and-privacy spec, "Launch safety").
/// The root view can try to open the store more than once in one process
/// (protected data becomes available, "Try again"). The marker streak and
/// the lifetime failure count must each rise at most once per launch, so
/// `begin()` and `countLaunchFailureIfNeeded(in:)` act only on the first
/// call.
@MainActor
public final class LaunchSession {
    public let markerURL: URL
    public private(set) var outcome: LaunchMarkerFile.Outcome?
    private var launchFailureCounted = false

    public init(markerURL: URL) {
        self.markerURL = markerURL
    }

    /// Writes the marker on the first call only. Every later call returns
    /// the outcome of the first call.
    @discardableResult
    public func begin() -> LaunchMarkerFile.Outcome {
        if let outcome { return outcome }
        let first = LaunchMarkerFile.begin(at: markerURL)
        outcome = first
        return first
    }

    /// "The app MUST add one to the launch failure count in `Local.store`
    /// each time it finds an uncleared marker." Once per launch, on the
    /// first store that opens.
    public func countLaunchFailureIfNeeded(in store: RecordStore) {
        guard !launchFailureCounted, outcome?.markerWasUncleared == true else { return }
        launchFailureCounted = true
        _ = try? store.incrementLaunchFailureCount()
    }

    /// Call after Today (or safe mode's Today) appears.
    public func clearAfterTodayAppears() {
        LaunchMarkerFile.clear(at: markerURL)
    }
}

/// The phase of the app's root view, as far as the store open is concerned
/// (design.md, "Store opening is lazy and checks protected data first").
public enum StoreOpenPhase: Sendable, Equatable {
    case waitingForProtectedData
    case failedToOpen
    case running
    case safeMode
    case deleted
}

extension AppStoreOpening {
    /// Whether the root view tries to open the store from `phase`: at
    /// launch, when protected data becomes available, or on "Try again".
    /// Never after Delete-all or "Delete from this device": data-and-
    /// privacy spec, "Delete-all": "The app MUST keep that screen after
    /// 'Done' until the next launch. The app MUST start onboarding only at
    /// the next launch."
    public static func triesToOpen(from phase: StoreOpenPhase) -> Bool {
        switch phase {
        case .waitingForProtectedData, .failedToOpen: return true
        case .running, .safeMode, .deleted: return false
        }
    }
}
