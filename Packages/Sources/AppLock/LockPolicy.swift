import Foundation
import Constants

/// The pure rule for "When the app asks": `LockPolicy.shouldAsk` takes the
/// continuous-clock moment the app entered the background, the current
/// continuous-clock moment, and the grace period, and decides whether the
/// app must make the system authentication request. The app's own
/// `ContinuousClockReading` protocol supplies both moments from
/// `mach_continuous_time`, which counts through sleep; this function never
/// reads a clock itself, so a test drives it with fixed numbers.
public enum LockPolicy {
    /// Scenario: "Policy with a stub clock" (31 - 0 >= 30 is true, 29 - 0 >=
    /// 30 is false). Scenario: "Policy with no grace" (1 - 0 >= 0 is true).
    public static func shouldAsk(enteredBackgroundAt: TimeInterval, now: TimeInterval, grace: TimeInterval) -> Bool {
        now - enteredBackgroundAt >= grace
    }
}

/// A source of continuous-clock seconds, ticks that advance through sleep
/// (app-lock spec, "When the app asks": "measure the grace period with
/// `mach_continuous_time`, which counts through sleep, not with the
/// calendar"). The App target's implementation reads `mach_continuous_time`;
/// a test supplies a stub.
public protocol ContinuousClockReading: Sendable {
    func continuousSeconds() -> TimeInterval
}

/// A test's stub continuous clock: a fixed or settable reading, never the
/// real clock.
public final class StubContinuousClock: ContinuousClockReading, @unchecked Sendable {
    private let lock = NSLock()
    private var value: TimeInterval

    public init(_ value: TimeInterval = 0) {
        self.value = value
    }

    public func set(_ value: TimeInterval) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    public func continuousSeconds() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

/// The four "Lock after" choices and their labels (app-lock spec, "Lock
/// after"). The values come from `ProgrammeConstants.lockGraceSecondsChoices`,
/// so the settings screen and this function never disagree. Each label is a
/// catalogue key and its count, never English (content spec, "Strings live
/// in catalogues").
public enum LockGrace {
    /// The four choices, in the Privacy group's own order: LOCK_GRACE_SECONDS
    /// from `ProgrammeConstants` (programme spec, "The constants live in one
    /// value").
    public static let choices: [Int] = ProgrammeConstants.default.lockGraceSecondsChoices

    /// "At once" for no grace, "%lld minutes" for whole minutes and
    /// "%lld seconds" for the rest. The count enters the string through its
    /// plural forms (content spec, "Catalogue rules").
    public static func label(forSeconds seconds: Int) -> CatalogueText {
        if seconds <= 0 { return .key("applock.lockAfter.atOnce") }
        if seconds % 60 == 0 { return .key("applock.lockAfter.minutes %lld", .count(seconds / 60)) }
        return .key("applock.lockAfter.seconds %lld", .count(seconds))
    }
}
