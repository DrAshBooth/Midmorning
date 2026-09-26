import Foundation

extension AppLifecycleState {
    /// A tap on a reminder opens its screen only while the real screen shows:
    /// no cover and no pending new-entry route (app-lock spec, "The cover").
    /// Until then the route waits, so no reminder screen shows above the
    /// cover. "Add" is the one exception: it uses the pending-route rule
    /// ("A new entry before authentication") and does not wait here.
    public var opensAReminderRoute: Bool {
        coverMode == .none && pendingRoute == nil
    }
}
