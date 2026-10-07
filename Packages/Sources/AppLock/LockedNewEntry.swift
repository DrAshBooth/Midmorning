import Foundation

extension AppLifecycleState {
    /// App-lock spec, "A new entry before authentication" (ruling r17-01,
    /// mm-t15.22). While the app is locked, the new-entry screen that a
    /// reminder "Add" opens shows only the four fixed Where chips and each
    /// place the person adds on that screen. A custom place is a `ListItem`
    /// in `Record.store`, so its text comes from the record, and no record
    /// text shows before authentication. After "Unlock", or after the
    /// request at Save succeeds, the app is not locked, and the screen
    /// shows the custom chips too. With the app lock off, no
    /// authentication protects the record, so the screen shows them at
    /// once.
    public var newEntryShowsSavedPlaces: Bool {
        !(appLockEnabled && isLocked)
    }
}
