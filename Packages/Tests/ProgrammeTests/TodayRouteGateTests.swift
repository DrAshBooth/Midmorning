import XCTest
@testable import Programme

/// Ruling r20-01 (mm-t45.12): when Today opens a reminder route
/// (`TodayRouteGate`, used by `ReminderRouteOpening` in the App target).
/// The UI tests in
/// tools/skeleton-checks/HarnessUITests/AutomatedChecks+RouteFromAnyScreen.swift
/// do the same cases on the simulator.
final class TodayRouteGateTests: XCTestCase {
    private func step(held: Bool = false, _ sheet: TodayRouteGate.TodaySheet? = nil, closing: Bool = false, routeScreenShows: Bool = false) -> TodayRouteGate.Step {
        TodayRouteGate.step(held: held, sheetOnScreen: sheet, sheetIsClosing: closing, routeScreenShows: routeScreenShows)
    }

    /// With no sheet and no hold, the route opens: Today empties its
    /// navigation path, then opens the route's screen.
    func testWithNoSheetAndNoHoldTheRouteOpens() {
        XCTAssertEqual(step(), .open)
    }

    /// "An open new-entry sheet with a draft stays, and the route waits
    /// until that sheet closes." The same for a new-entry screen with a
    /// draft on the close-the-day screen, and for a safeguarding page.
    func testAHoldMakesTheRouteWait() {
        XCTAssertEqual(step(held: true), .wait, "a safeguarding page on a screen of Today's stack")
        XCTAssertEqual(step(held: true, .newEntry), .wait, "Today's new-entry sheet with a draft")
        XCTAssertEqual(step(held: true, .newEntry, routeScreenShows: true), .wait, "the midday reminder over a draft")
        XCTAssertEqual(step(held: true, .closeTheDay, routeScreenShows: true), .wait, "the close-the-day screen's own new-entry sheet with a draft")
    }

    /// A new-entry sheet with no draft closes first. The route opens after
    /// the dismissal.
    func testAnEmptyNewEntrySheetClosesFirst() {
        XCTAssertEqual(step(.newEntry), .closeTheNewEntrySheet)
    }

    /// Another sheet of Today stays, and the route waits until it closes.
    /// An open under the sheet would not show.
    func testAnotherSheetOfTodayMakesTheRouteWait() {
        XCTAssertEqual(step(.closeTheDay), .wait)
        XCTAssertEqual(step(.planBuilder), .wait)
        XCTAssertEqual(step(.editEntry), .wait)
    }

    /// When the sheet is the route's own screen (for example the
    /// close-the-day reminder while the close-the-day screen shows), the
    /// sheet stays and the route changes nothing more.
    func testTheRoutesOwnSheetStays() {
        XCTAssertEqual(step(.closeTheDay, routeScreenShows: true), .keep)
        XCTAssertEqual(step(.planBuilder, routeScreenShows: true), .keep)
        XCTAssertEqual(step(.newEntry, routeScreenShows: true), .keep)
    }

    /// A sheet that is closing makes the route wait until its dismissal
    /// ends, also when it is the route's own screen. The midday reminder
    /// over a new-entry draft: after "Save", the hold ends and the sheet
    /// closes, in either order. Each order gives `.wait` until both end,
    /// and then `.open`, so a second new-entry screen opens (the reminders
    /// spec: the reminder's screen opens after the new-entry screen
    /// closes; mm-t45.23, question 2, is open).
    func testAClosingSheetMakesTheRouteWaitUntilItsDismissalEnds() {
        XCTAssertEqual(step(.newEntry, closing: true, routeScreenShows: true), .wait, "the hold ended first")
        XCTAssertEqual(step(held: true), .wait, "the dismissal ended first")
        XCTAssertEqual(step(), .open, "both ended")
        XCTAssertEqual(step(.newEntry, closing: true), .wait, "an empty new-entry sheet that is closing")
        XCTAssertEqual(step(.closeTheDay, closing: true, routeScreenShows: true), .wait)
        XCTAssertEqual(step(.planBuilder, closing: true, routeScreenShows: true), .wait)
    }
}
