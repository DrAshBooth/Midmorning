import Foundation

/// When Today opens a reminder route (rulings r20-01, r22-01 and r22-02;
/// reminders spec, "A tap on a reminder opens its screen from Today"). The
/// App target's `ReminderRouteOpening` asks `step` each time a fact
/// changes: a new route, the cover, a hold, or a sheet of Today.
///
/// A hold makes the route wait (`Hold`):
/// - A new-entry screen with input (`Record.NewEntryDraft`): text, a
///   chosen Where, a typed place or the star. The screen and its input
///   stay in front, and the route opens after the screen closes (r20-01,
///   r22-02).
/// - A safeguarding page: the not-right-now page or the GP suggestion
///   page. Each page has one control, "Done", and the app does not show
///   the page again until a rule fires again (safeguarding spec). So the
///   route waits until "Done" (r22-01).
/// - A screen that holds answers: the weekly review, the check-in, the
///   restart re-screen and the weigh-in screen. The screen stays, and the
///   route opens after the person leaves it (r22-01). When that screen is
///   the route's own screen (`Hold.isScreen(of:)`), the app keeps it and
///   does not open it a second time.
///
/// A sheet of Today stays over Today's navigation stack. A route that
/// opens under the sheet does not show, and a second sheet cannot show
/// over it. So the route waits while such a sheet shows, except in two
/// cases (r22-02). A new-entry sheet with no input closes first. A sheet
/// that is already the route's own screen stays, with or without input,
/// and the route changes nothing: for example, the midday reminder over a
/// new-entry screen opens no second new-entry screen.
///
/// A sheet that is closing is not the route's own screen any more. So the
/// route waits until the dismissal ends, and then opens.
public enum TodayRouteGate {
    /// A sheet that Today shows over its navigation stack.
    public enum TodaySheet: Sendable, Equatable {
        case newEntry, planBuilder, editEntry, closeTheDay
    }

    /// A screen or a page that makes a route wait while it shows.
    public enum Hold: Sendable, Equatable, Hashable {
        /// A new-entry screen with input.
        case newEntryDraft
        /// The not-right-now page or the GP suggestion page.
        case safeguardingPage
        /// The weigh-in screen.
        case weighInScreen
        /// The weekly review of `week` in the current run, or of an earlier
        /// run when `week` is nil (a review from the "Reviews" list).
        case weeklyReview(week: Int?)
        /// The check-in. The app has no check-in screen yet; the
        /// `staying-on-track` build gives its screen this hold.
        case checkIn
        /// The restart re-screen.
        case rescreen

        /// This hold is the screen that `route` opens: the weigh-in screen
        /// for the weigh-in day reminder, or the review of the latest due
        /// week (`latestDueWeek`) for the weekly review reminder.
        public func isScreen(of route: ReminderTapRoute, latestDueWeek: Int?) -> Bool {
            switch (self, route) {
            case (.weighInScreen, .weighIn): return true
            case (.weeklyReview(let week), .weeklyReview): return week != nil && week == latestDueWeek
            default: return false
            }
        }
    }

    /// What Today does with the route now.
    public enum Step: Sendable, Equatable {
        /// The route stays in the inbox. A later change opens it.
        case wait
        /// Today closes its new-entry sheet, which holds no input. The route
        /// stays in the inbox and opens after the dismissal ends.
        case closeTheNewEntrySheet
        /// The route's own screen already shows as Today's sheet. Today
        /// takes the route and empties its navigation path, and the sheet
        /// stays.
        case keep
        /// The route's own screen already shows on Today's navigation stack
        /// and holds the route. Today takes the route and changes nothing.
        case keepTheScreen
        /// Today takes the route, empties its navigation path and opens the
        /// route's screen.
        case open
    }

    /// - Parameters:
    ///   - holds: The holds that show (`Hold`).
    ///   - holdsAreTheRouteScreen: Each hold is the route's own screen
    ///     (`Hold.isScreen(of:latestDueWeek:)`).
    ///   - sheetOnScreen: The sheet of Today that shows, from its appearance
    ///     until its dismissal ends.
    ///   - sheetIsClosing: The dismissal of `sheetOnScreen` started and did
    ///     not end yet: its presentation value is already off.
    ///   - routeScreenShows: `sheetOnScreen` is the route's own screen.
    public static func step(held: Bool, holdsAreTheRouteScreen: Bool = false, sheetOnScreen: TodaySheet?, sheetIsClosing: Bool, routeScreenShows: Bool) -> Step {
        if sheetOnScreen != nil, !sheetIsClosing, routeScreenShows { return .keep }
        if held { return holdsAreTheRouteScreen ? .keepTheScreen : .wait }
        guard let sheetOnScreen else { return .open }
        if sheetIsClosing { return .wait }
        return sheetOnScreen == .newEntry ? .closeTheNewEntrySheet : .wait
    }
}
