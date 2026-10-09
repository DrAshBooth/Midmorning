import Foundation

/// When Today opens a reminder route (ruling r20-01, mm-t45.12; reminders
/// spec, "A tap on a reminder opens its screen from Today"). The App
/// target's `ReminderRouteOpening` asks `step` each time a fact changes:
/// a new route, the cover, a hold, or a sheet of Today.
///
/// Two holds make the route wait (`held`):
/// - A new-entry screen with a draft (`Record.NewEntryDraft`). The ruling
///   keeps that screen and its draft in front, and the route opens after
///   the screen closes.
/// - A safeguarding page: the not-right-now page or the GP suggestion
///   page. Each page has one control, "Done", and the app does not show
///   the page again until a rule fires again (safeguarding spec, "The
///   not-right-now page", "The GP suggestion page"). An empty navigation
///   path removes the screen under the page, and SwiftUI then closes the
///   page with no "Done". So the route waits until "Done". The ruling does
///   not name this case. Ash decides it (mm-t45.12, label human).
///
/// A sheet of Today stays over Today's navigation stack. A route that
/// opens under the sheet does not show, and a second sheet cannot show
/// over it. So the route waits while such a sheet shows, except in two
/// cases. A new-entry sheet with no draft closes first. A sheet that is
/// already the route's own screen stays, and the route changes nothing.
public enum TodayRouteGate {
    /// A sheet that Today shows over its navigation stack.
    public enum TodaySheet: Sendable, Equatable {
        case newEntry, planBuilder, editEntry, closeTheDay
    }

    /// What Today does with the route now.
    public enum Step: Sendable, Equatable {
        /// The route stays in the inbox. A later change opens it.
        case wait
        /// Today closes its new-entry sheet, which holds no draft. The route
        /// stays in the inbox and opens after the dismissal ends.
        case closeTheNewEntrySheet
        /// The route's own screen already shows as Today's sheet. Today
        /// takes the route and empties its navigation path, and the sheet
        /// stays.
        case keep
        /// Today takes the route, empties its navigation path and opens the
        /// route's screen.
        case open
    }

    /// - Parameters:
    ///   - held: A new-entry screen with a draft or a safeguarding page
    ///     shows.
    ///   - sheetOnScreen: The sheet of Today that shows, from its appearance
    ///     until its dismissal ends.
    ///   - routeScreenShows: `sheetOnScreen` is the route's own screen.
    public static func step(held: Bool, sheetOnScreen: TodaySheet?, routeScreenShows: Bool) -> Step {
        if held { return .wait }
        guard let sheetOnScreen else { return .open }
        if routeScreenShows { return .keep }
        return sheetOnScreen == .newEntry ? .closeTheNewEntrySheet : .wait
    }
}
