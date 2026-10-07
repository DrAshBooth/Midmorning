import Foundation

/// The file half of `LaunchSafety` (data-and-privacy spec, "Launch safety",
/// "File protection"). The marker holds the streak of launches that ended
/// before Today appeared. The App target's `LaunchMarker` calls this
/// through one `LaunchSession` per process.
///
/// A launch that finds an uncleared marker writes its launch failure into
/// the marker as an uncounted failure at once, before the store opens. So
/// a launch that stops in the store open, for example in a schema migration
/// that crashes, keeps its failure (mm-t42.30). The first launch that opens
/// the store for writing adds the uncounted failures to `Local.store`.
/// Safe mode opens the store read-only (ruling r13-05, mm-t42.23), so a
/// safe-mode launch cannot add its launch failure or a MetricKit crash
/// count to `Local.store`. The marker then keeps those as uncounted
/// failures and uncounted crashes, and the next launch with a read-write
/// store adds them. The content is one of:
/// - "<streak>": not cleared, and nothing uncounted.
/// - "<streak> <failures>": not cleared, with uncounted failures.
/// - "<streak> <failures> <crashes>": not cleared, with uncounted crashes.
/// - "- <failures>" or "- <failures> <crashes>": cleared (Today appeared),
///   with uncounted failures or crashes.
public enum LaunchMarkerFile {
    public struct Outcome: Sendable, Equatable {
        public let markerWasUncleared: Bool
        public let launchOutcome: LaunchOutcome
        /// Launch failures that `Local.store` does not hold yet: the failure
        /// of this launch when the marker was uncleared, and each failure
        /// that an earlier launch kept in the marker. An earlier launch keeps
        /// its failure when it was in safe mode, or when it stopped before
        /// its store opened for writing.
        public let uncountedFailures: Int
        /// MetricKit crashes that an earlier safe-mode launch received but
        /// could not add to `Local.store`.
        public let uncountedCrashes: Int

        public init(markerWasUncleared: Bool, launchOutcome: LaunchOutcome, uncountedFailures: Int = 0, uncountedCrashes: Int = 0) {
            self.markerWasUncleared = markerWasUncleared
            self.launchOutcome = launchOutcome
            self.uncountedFailures = uncountedFailures
            self.uncountedCrashes = uncountedCrashes
        }
    }

    /// The marker's content, read from the file.
    struct Content: Equatable {
        /// `nil` when the marker is cleared.
        var streak: Int?
        var uncountedFailures: Int
        var uncountedCrashes: Int

        init(streak: Int?, uncountedFailures: Int, uncountedCrashes: Int = 0) {
            self.streak = streak
            self.uncountedFailures = uncountedFailures
            self.uncountedCrashes = uncountedCrashes
        }

        /// A marker that this code cannot read counts as not cleared, with
        /// a streak of 0.
        init(text: String) {
            let parts = text.split(whereSeparator: \.isWhitespace).map(String.init)
            func count(at index: Int) -> Int {
                parts.count > index ? max(Int(parts[index]) ?? 0, 0) : 0
            }
            let streak: Int? = parts.first == "-" ? nil : (parts.first.flatMap { Int($0) } ?? 0)
            self.init(streak: streak, uncountedFailures: count(at: 1), uncountedCrashes: count(at: 2))
        }

        var text: String {
            let head = streak.map(String.init) ?? "-"
            if uncountedCrashes > 0 { return "\(head) \(uncountedFailures) \(uncountedCrashes)" }
            return uncountedFailures > 0 ? "\(head) \(uncountedFailures)" : head
        }

        /// True when a cleared marker holds nothing to count, so the file
        /// can go.
        var isEmptyAfterClear: Bool {
            streak == nil && uncountedFailures == 0 && uncountedCrashes == 0
        }
    }

    /// "The app MUST write a launch marker file at start." Reads the
    /// previous streak from the marker file when a launch left it, then
    /// writes the new streak. The write is atomic and carries
    /// `NSFileProtectionComplete` ("Every other file the app writes MUST
    /// carry NSFileProtectionComplete"). The marker is also excluded from
    /// backup, so a restore onto a new device never brings back an old
    /// streak. The uncounted failures and crashes stay in the marker.
    ///
    /// "The app MUST add one to the launch failure count in `Local.store`
    /// each time it finds an uncleared marker." When the marker is
    /// uncleared, this write also adds this launch's failure to the
    /// uncounted failures. The store is not open yet, so the marker keeps
    /// the failure until a store open for writing adds it to `Local.store`
    /// (`LaunchSession.countLaunchFailureIfNeeded(in:)`). A launch that
    /// stops in the store open does not lose its failure (mm-t42.30).
    public static func begin(at url: URL) -> Outcome {
        let previous = (try? String(contentsOf: url, encoding: .utf8)).map(Content.init(text:))
        let markerWasUncleared = previous?.streak != nil
        let previousStreak = previous?.streak ?? 0
        let uncounted = (previous?.uncountedFailures ?? 0) + (markerWasUncleared ? 1 : 0)
        let crashes = previous?.uncountedCrashes ?? 0
        let outcome = LaunchSafety.startLaunch(markerWasUncleared: markerWasUncleared, previousConsecutiveUnclearedCount: previousStreak)
        write(Content(streak: outcome.newConsecutiveUnclearedCount, uncountedFailures: uncounted, uncountedCrashes: crashes), at: url)
        return Outcome(markerWasUncleared: markerWasUncleared, launchOutcome: outcome, uncountedFailures: uncounted, uncountedCrashes: crashes)
    }

    /// "The app MUST clear the marker after Today appears."
    public static func clear(at url: URL, fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: url)
    }

    /// Writes `content`. A cleared marker that holds nothing to count
    /// deletes the file. So a cleared marker keeps the uncounted failures
    /// and crashes when there are some, and the next launch finds it
    /// cleared.
    static func write(_ content: Content, at url: URL) {
        guard !content.isEmptyAfterClear else { return clear(at: url) }
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
    /// The MetricKit crashes in the marker that `Local.store` does not hold
    /// yet.
    public private(set) var uncountedCrashes = 0
    /// True after Today appeared: the marker holds no streak now.
    private var markerCleared = false
    /// True after Delete-all or "Delete from this device" deleted the
    /// marker. The session then writes no marker again, so the deletion
    /// leaves no file (data-and-privacy spec, "Delete-all").
    private var ended = false

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
        uncountedCrashes = first.uncountedCrashes
        return first
    }

    /// "The app MUST add one to the launch failure count in `Local.store`
    /// each time it finds an uncleared marker." Once per launch, on the
    /// first store that opens. `begin()` already wrote this launch's
    /// failure into the marker, with the failures and the crashes that
    /// earlier launches kept there. This adds all of them to `Local.store`
    /// and removes them from the marker. A read-only store (safe mode)
    /// takes no write: the marker keeps them for the next launch instead.
    public func countLaunchFailureIfNeeded(in store: RecordStore) {
        guard !launchFailureCounted, outcome != nil else { return }
        launchFailureCounted = true
        let failures = uncountedFailures
        guard failures > 0 || uncountedCrashes > 0 else { return }
        var countedFailures = 0
        var countedCrashes = 0
        if !store.isReadOnly {
            while countedFailures < failures, (try? store.incrementLaunchFailureCount()) != nil {
                countedFailures += 1
            }
            while countedCrashes < uncountedCrashes, (try? store.incrementCrashCount()) != nil {
                countedCrashes += 1
            }
        }
        uncountedFailures = failures - countedFailures
        uncountedCrashes -= countedCrashes
        writeMarker()
    }

    /// Safe mode's MetricKit crashes (data-and-privacy spec, "No record
    /// content in the system log or crash reports": the count only). Safe
    /// mode writes nothing to `Local.store` (ruling r13-05, mm-t42.23), and
    /// MetricKit delivers each payload once. So the marker keeps the count,
    /// and the next launch that opens the store for writing adds it.
    public func keepCrashesForTheNextLaunch(_ crashes: Int) {
        guard crashes > 0 else { return }
        uncountedCrashes += crashes
        writeMarker()
    }

    /// Call after Today (or safe mode's Today) appears.
    public func clearAfterTodayAppears() {
        markerCleared = true
        writeMarker()
    }

    /// Call after Delete-all or "Delete from this device" deleted the
    /// marker file. The session writes no marker again in this process.
    public func endAfterDeletion() {
        ended = true
    }

    /// The marker as this session knows it now: the streak until Today
    /// appears, then no streak, and the counts that `Local.store` does not
    /// hold yet.
    private func writeMarker() {
        guard !ended else { return }
        let streak: Int?
        if markerCleared {
            streak = nil
        } else if let outcome {
            streak = outcome.launchOutcome.newConsecutiveUnclearedCount
        } else {
            return
        }
        LaunchMarkerFile.write(
            .init(streak: streak, uncountedFailures: uncountedFailures, uncountedCrashes: uncountedCrashes),
            at: markerURL
        )
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
