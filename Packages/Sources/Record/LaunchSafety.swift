import Foundation

/// The launch marker's own streak, kept in the marker file itself (never in
/// `Local.store`), so the safe-mode decision needs no store to open first
/// (data-and-privacy spec, "Launch safety"; design.md, "The launch marker
/// tracks a streak, separately from the lifetime count"). The App target
/// writes the marker at start, clears it once Today appears, and keeps the
/// separate lifetime failure count `Local.store` holds for the Diagnostics
/// page.
public struct LaunchOutcome: Sendable, Equatable {
    public let enterSafeMode: Bool
    public let newConsecutiveUnclearedCount: Int

    public init(enterSafeMode: Bool, newConsecutiveUnclearedCount: Int) {
        self.enterSafeMode = enterSafeMode
        self.newConsecutiveUnclearedCount = newConsecutiveUnclearedCount
    }
}

public enum LaunchSafety {
    /// On the third consecutive launch with an uncleared marker, the app
    /// enters safe mode.
    public static let safeModeThreshold = 3

    /// The pure decision at app start, before Today appears. `markerWasUncleared`
    /// is whether the marker file from the previous launch still exists,
    /// never cleared. `previousConsecutiveUnclearedCount` is the streak the
    /// marker file's own content held.
    public static func startLaunch(markerWasUncleared: Bool, previousConsecutiveUnclearedCount: Int) -> LaunchOutcome {
        guard markerWasUncleared else {
            return LaunchOutcome(enterSafeMode: false, newConsecutiveUnclearedCount: 0)
        }
        let streak = previousConsecutiveUnclearedCount + 1
        return LaunchOutcome(enterSafeMode: streak >= safeModeThreshold, newConsecutiveUnclearedCount: streak)
    }
}

/// Whether the store container should open at all right now, and what the
/// app shows next (data-and-privacy spec, "Launch safety", "File
/// protection"; design.md, "Store opening is lazy and checks protected data
/// first"). A pure decision over two device facts, checked in this order, so
/// the app never attempts an open while the device is locked.
public enum AppStoreOpenState: Sendable, Equatable {
    case waitingForProtectedData
    case opened
    case failed
}

public enum AppStoreOpening {
    public static func attempt(protectedDataAvailable: Bool, openSucceeded: Bool) -> AppStoreOpenState {
        guard protectedDataAvailable else { return .waitingForProtectedData }
        return openSucceeded ? .opened : .failed
    }
}
