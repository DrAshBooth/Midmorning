import Foundation

/// What the App target's cover window does for one `AppLifecycleState`
/// (mm-t15.15, mm-t15.18). The cover lives in a window of its own, above
/// every sheet and full-screen cover of the app's own window, because an
/// overlay on Today cannot cover a presentation.
public enum CoverWindowMode: Sendable, Equatable {
    /// No cover and no pending route: the app's own window shows.
    case hidden
    /// The "Midmorning"-only cover of the inactive app. The window shows,
    /// but it does not take the keyboard, so Notification Centre does not
    /// close the keyboard of a sheet.
    case shown
    /// The locked cover, or the new-entry screen of a pending route. The
    /// window shows and takes the keyboard and VoiceOver.
    case shownWithFocus
}

extension AppLifecycleState {
    /// Requirement "The cover": "While the app is locked, the app MUST show
    /// the cover over every screen, Get support included." Requirement "A
    /// new entry before authentication": the pending route's new-entry
    /// screen presents from the same window, whose root never has another
    /// presentation. So the window shows for as long as the route waits,
    /// and a sheet in the app's own window cannot stop the screen.
    public var coverWindowMode: CoverWindowMode {
        if pendingRoute != nil { return .shownWithFocus }
        switch coverMode {
        case .none: return .hidden
        case .privacyOnly: return .shown
        case .locked, .lockedAfterEnrolmentChange: return .shownWithFocus
        }
    }
}
