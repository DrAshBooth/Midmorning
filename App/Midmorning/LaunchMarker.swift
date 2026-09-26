import Foundation
import Record

/// The app's one `Record.LaunchSession` (data-and-privacy spec, "Launch
/// safety"). `AppLockRootView` begins it at the first store open attempt
/// with protected data available, and every later attempt in the same
/// process ("Try again", protected data again) reuses it, so the streak and
/// the failure count rise at most once per launch. `RunningRootView` and
/// `SafeModeView` clear the marker after Today appears, never earlier:
/// onboarding, Today's first load and the scheduler run all come before the
/// clear, so a crash in any of them still counts. `LaunchSafetyWiringTests`
/// and `LaunchSessionTests` drive the same `Record` functions.
@MainActor
enum LaunchMarker {
    private static var session: LaunchSession?

    /// The session for this process, made on the first call.
    static func session(applicationSupportDirectory: URL) -> LaunchSession {
        if let session { return session }
        let new = LaunchSession(markerURL: StoreLayout.launchMarkerURL(applicationSupportDirectory: applicationSupportDirectory))
        session = new
        return new
    }

    /// "The app MUST clear the marker after Today appears." Runs after the
    /// current main-actor work, so Today's own first load and the
    /// `onAppear` scheduler run finish first.
    static func clearAfterTodayAppears() {
        Task { @MainActor in
            session?.clearAfterTodayAppears()
        }
    }
}
