import Foundation

/// The file half of `LaunchSafety` (data-and-privacy spec, "Launch safety",
/// "File protection"). The marker holds the streak of launches that ended
/// before Today appeared. The App target's `LaunchMarker` calls this
/// through one `LaunchSession` per process.
///
/// Safe mode opens the store read-only (ruling r13-05, mm-t42.23), so a
/// safe-mode launch cannot add its launch failure to `Local.store`. The
/// marker then also holds that failure as an uncounted failure, and the
/// next launch with a read-write store adds it. The content is one of:
/// - "<streak>": not cleared, and no uncounted failure.
/// - "<streak> <uncounted>": not cleared, with uncounted failures.
/// - "- <uncounted>": cleared (Today appeared), with uncounted failures.
public enum LaunchMarkerFile {
    public struct Outcome: Sendable, Equatable {
        public let markerWasUncleared: Bool
        public let launchOutcome: LaunchOutcome
        /// Launch failures that an earlier safe-mode launch found but could
        /// not add to `Local.store`.
        public let uncountedFailures: Int

        public init(markerWasUncleared: Bool, launchOutcome: LaunchOutcome, uncountedFailures: Int = 0) {
            self.markerWasUncleared = markerWasUncleared
            self.launchOutcome = launchOutcome
            self.uncountedFailures = uncountedFailures
        }
    }

    /// The marker's content, read from the file.
    struct Content: Equatable {
        /// `nil` when the marker is cleared.
        var streak: Int?
        var uncountedFailures: Int

        init(streak: Int?, uncountedFailures: Int) {
            self.streak = streak
            self.uncountedFailures = uncountedFailures
        }

        /// A marker that this code cannot read counts as not cleared, with
        /// a streak of 0.
        init(text: String) {
            let parts = text.split(whereSeparator: \.isWhitespace).map(String.init)
            let uncounted = parts.count > 1 ? max(Int(parts[1]) ?? 0, 0) : 0
            if parts.first == "-" {
                self.init(streak: nil, uncountedFailures: uncounted)
            } else {
                self.init(streak: parts.first.flatMap { Int($0) } ?? 0, uncountedFailures: uncounted)
            }
        }

        var text: String {
            let head = streak.map(String.init) ?? "-"
            return uncountedFailures > 0 ? "\(head) \(uncountedFailures)" : head
        }
    }

    /// "The app MUST write a launch marker file at start." Reads the
    /// previous streak from the marker file when a launch left it, then
    /// writes the new streak. The write is atomic and carries
    /// `NSFileProtectionComplete` ("Every other file the app writes MUST
    /// carry NSFileProtectionComplete"). The marker is also excluded from
    /// backup, so a restore onto a new device never brings back an old
    /// streak. The uncounted failures stay in the marker.
    public static func begin(at url: URL) -> Outcome {
        let previous = (try? String(contentsOf: url, encoding: .utf8)).map(Content.init(text:))
        let markerWasUncleared = previous?.streak != nil
        let previousStreak = previous?.streak ?? 0
        let uncounted = previous?.uncountedFailures ?? 0
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: markerWasUncleared, previousConsecutiveUnclearedCount: previousStreak)
        write(Content(streak: outcome.newConsecutiveUnclearedCount, uncountedFailures: uncounted), at: url)
        return Outcome(markerWasUncleared: markerWasUncleared, launchOutcome: outcome, uncountedFailures: uncounted)
    }

    /// "The app MUST clear the marker after Today appears."
    public static func clear(at url: URL, fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: url)
    }

    /// Clears the marker, but keeps the uncounted failures in it when there
    /// are some. The next launch then finds a cleared marker.
    static func clear(at url: URL, keepingUncountedFailures uncounted: Int) {
        guard uncounted > 0 else { return clear(at: url) }
        write(Content(streak: nil, uncountedFailures: uncounted), at: url)
    }

    static func write(_ content: Content, at url: URL) {
        try? Data(content.text.utf8).write(to: url, options: [.atomic, .completeFileProtection])
        try? FileProtection.excludeFromBackup(url)
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
    /// The failures in the marker that `Local.store` does not hold yet.
    public private(set) var uncountedFailures = 0

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
        uncountedFailures = first.uncountedFailures
        return first
    }

    /// "The app MUST add one to the launch failure count in `Local.store`
    /// each time it finds an uncleared marker." Once per launch, on the
    /// first store that opens. This also adds the failures that an earlier
    /// safe-mode launch kept in the marker. A read-only store (safe mode)
    /// takes no write: the marker keeps this launch's failure for the next
    /// launch instead.
    public func countLaunchFailureIfNeeded(in store: RecordStore) {
        guard !launchFailureCounted, let outcome else { return }
        launchFailureCounted = true
        let failures = uncountedFailures + (outcome.markerWasUncleared ? 1 : 0)
        guard failures > 0 else { return }
        var counted = 0
        if !store.isReadOnly {
            while counted < failures, (try? store.incrementLaunchFailureCount()) != nil {
                counted += 1
            }
        }
        uncountedFailures = failures - counted
        LaunchMarkerFile.write(
            .init(streak: outcome.launchOutcome.newConsecutiveUnclearedCount, uncountedFailures: uncountedFailures),
            at: markerURL
        )
    }

    /// Call after Today (or safe mode's Today) appears.
    public func clearAfterTodayAppears() {
        LaunchMarkerFile.clear(at: markerURL, keepingUncountedFailures: uncountedFailures)
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
