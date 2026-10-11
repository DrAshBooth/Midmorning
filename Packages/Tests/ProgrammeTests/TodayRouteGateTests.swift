import XCTest
@testable import Programme

/// Rulings r20-01, r22-01 and r22-02 (mm-t45.12, mm-t45.23): when Today
/// opens a reminder route (`TodayRouteGate`, used by
/// `ReminderRouteOpening` in the App target). The UI tests in
/// tools/skeleton-checks/HarnessUITests/AutomatedChecks+RouteFromAnyScreen.swift
/// do the same cases on the simulator.
final class TodayRouteGateTests: XCTestCase {
    private func step(held: Bool = false, routeScreen: Bool = false, _ sheet: TodayRouteGate.TodaySheet? = nil, closing: Bool = false, routeScreenShows: Bool = false) -> TodayRouteGate.Step {
        TodayRouteGate.step(held: held, holdsAreTheRouteScreen: routeScreen, sheetOnScreen: sheet, sheetIsClosing: closing, routeScreenShows: routeScreenShows)
    }

    /// With no sheet and no hold, the route opens: Today empties its
    /// navigation path, then opens the route's screen.
    func testWithNoSheetAndNoHoldTheRouteOpens() {
        XCTAssertEqual(step(), .open)
    }

    /// A new-entry sheet with input stays, and the route waits until that
    /// sheet closes. The same for a new-entry screen with input on the
    /// close-the-day screen, for a safeguarding page, and for a screen that
    /// holds answers (r22-01).
    func testAHoldMakesTheRouteWait() {
        XCTAssertEqual(step(held: true), .wait, "a safeguarding page, or the weekly review, the re-screen or the weigh-in screen")
        XCTAssertEqual(step(held: true, .newEntry), .wait, "Today's new-entry sheet with input")
    }

    /// Ruling r22-01: when every hold is the route's own screen (the
    /// weigh-in screen for the weigh-in day reminder, the review of the due
    /// week for the weekly review reminder), the screen stays and the route
    /// opens nothing more.
    func testTheRoutesOwnScreenOnTheStackStays() {
        XCTAssertEqual(step(held: true, routeScreen: true), .keepTheScreen)
    }

    /// Which hold is the route's own screen.
    func testTheRouteScreenOfEachHold() {
        typealias Hold = TodayRouteGate.Hold
        XCTAssertTrue(Hold.weighInScreen.isScreen(of: .weighIn, latestDueWeek: nil))
        XCTAssertFalse(Hold.weighInScreen.isScreen(of: .today, latestDueWeek: nil))
        XCTAssertFalse(Hold.weighInScreen.isScreen(of: .weeklyReview, latestDueWeek: 3))
        XCTAssertTrue(Hold.weeklyReview(week: 3).isScreen(of: .weeklyReview, latestDueWeek: 3))
        XCTAssertFalse(Hold.weeklyReview(week: 2).isScreen(of: .weeklyReview, latestDueWeek: 3), "an earlier week: the due review opens after the person leaves")
        XCTAssertFalse(Hold.weeklyReview(week: nil).isScreen(of: .weeklyReview, latestDueWeek: 3), "a review of an earlier run")
        XCTAssertFalse(Hold.weeklyReview(week: 3).isScreen(of: .weighIn, latestDueWeek: 3))
        for hold in [Hold.newEntryDraft, .safeguardingPage, .rescreen, .checkIn] {
            for route in [ReminderTapRoute.today, .newEntry, .todaysPlan, .closeTheDay(dayKey: nil), .weighIn, .weeklyReview] {
                XCTAssertFalse(hold.isScreen(of: route, latestDueWeek: 1), "\(hold) is not the screen of \(route)")
            }
        }
    }

    /// A new-entry sheet with no input closes first. The route opens after
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
    /// sheet stays and the route changes nothing more. Ruling r22-02: the
    /// same with input in the sheet, so the midday reminder over a
    /// new-entry screen with input opens no second new-entry screen, and
    /// the close-the-day reminder over the close-the-day screen's own
    /// new-entry sheet with input keeps both.
    func testTheRoutesOwnSheetStays() {
        XCTAssertEqual(step(.closeTheDay, routeScreenShows: true), .keep)
        XCTAssertEqual(step(.planBuilder, routeScreenShows: true), .keep)
        XCTAssertEqual(step(.newEntry, routeScreenShows: true), .keep)
        XCTAssertEqual(step(held: true, .newEntry, routeScreenShows: true), .keep, "the midday reminder over input")
        XCTAssertEqual(step(held: true, .closeTheDay, routeScreenShows: true), .keep, "the close-the-day screen's own new-entry sheet with input")
    }

    /// A sheet that is closing makes the route wait until its dismissal
    /// ends, also when it is the route's own screen: it is not the route's
    /// screen any more. Then the route opens.
    func testAClosingSheetMakesTheRouteWaitUntilItsDismissalEnds() {
        XCTAssertEqual(step(.newEntry, closing: true, routeScreenShows: true), .wait)
        XCTAssertEqual(step(.newEntry, closing: true), .wait, "an empty new-entry sheet that is closing")
        XCTAssertEqual(step(.closeTheDay, closing: true, routeScreenShows: true), .wait)
        XCTAssertEqual(step(.planBuilder, closing: true, routeScreenShows: true), .wait)
        XCTAssertEqual(step(), .open, "the dismissal ended")
    }
}
