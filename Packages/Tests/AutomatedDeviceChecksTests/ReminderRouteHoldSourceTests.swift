import Foundation
import XCTest

/// Ruling r20-01 (mm-t45.12): which screens make a reminder route wait
/// (`holdsReminderRoutes` in `Reminders/ReminderRouteOpening.swift`). The
/// package tests `TodayRouteGateTests` and `NewEntryDraftTests` prove
/// the rules. These checks prove from the source text only that each
/// screen calls the hold, on its own `NavigationStack`, and that Today
/// tells the gate about each of its sheets. The UI tests in
/// `AutomatedChecks+RouteFromAnyScreen.swift` prove the result on the
/// simulator.
final class ReminderRouteHoldSourceTests: XCTestCase {
    /// The text after the body's `NavigationStack {` and its closing brace:
    /// the modifiers of the stack itself.
    private func stackModifiers(_ path: String) throws -> String {
        let source = try ScreenText.source(path)
        guard let open = source.range(of: "var body: some View { NavigationStack {") else {
            XCTFail("\(path): the body is a NavigationStack")
            return ""
        }
        var depth = 1
        var index = open.upperBound
        while index < source.endIndex, depth > 0 {
            if source[index] == "{" { depth += 1 }
            if source[index] == "}" { depth -= 1 }
            index = source.index(after: index)
        }
        return String(source[index...])
    }

    /// safeguarding spec, "The not-right-now page" and "The GP suggestion
    /// page": each page holds a route until "Done", so an empty navigation
    /// path does not close the page with no "Done".
    func testEachSafeguardingPageHoldsTheRoute() throws {
        for path in ["Safeguarding/NotRightNowPageView.swift", "Safeguarding/GPSuggestionPageView.swift"] {
            XCTAssertTrue(try stackModifiers(path).hasPrefix(" .holdsReminderRoutes() "), "\(path): the page's NavigationStack holds the route")
        }
    }

    /// The new-entry screen holds the route while it holds a draft.
    func testTheNewEntryScreenHoldsTheRouteWhileItHoldsADraft() throws {
        let modifiers = try stackModifiers("NewEntryView.swift")
        XCTAssertTrue(modifiers.hasPrefix(" .holdsReminderRoutes(NewEntryDraft.holdsADraft(what: what, context: context, whereSelection: whereSelection, pendingPlace: pendingPlace, feltLikeABinge: feltLikeABinge)) "), "NewEntryView's NavigationStack holds the route while it holds a draft")
    }

    /// Today sets `sheetOnScreen` when each of its four sheets appears, and
    /// clears it when each dismissal ends.
    func testTodayTellsTheGateAboutEachSheet() throws {
        let source = try ScreenText.source("TodayView.swift")
        for sheet in ["newEntry", "planBuilder", "editEntry", "closeTheDay"] {
            XCTAssertTrue(source.contains(".onAppear { sheetOnScreen = .\(sheet) }"), "Today sets sheetOnScreen to .\(sheet)")
        }
        XCTAssertEqual(source.components(separatedBy: "onDismiss: { sheetOnScreen = nil }").count - 1, 3, "three sheets clear sheetOnScreen when their dismissal ends")
        XCTAssertTrue(source.contains(".sheet(isPresented: $showingNewEntry, onDismiss: newEntryDismissed)"), "the new-entry sheet clears it in newEntryDismissed")
        XCTAssertTrue(source.contains("private func newEntryDismissed() { newEntryInitialTime = nil addEntryFocused = true sheetOnScreen = nil }"), "newEntryDismissed clears sheetOnScreen")
    }

    /// The gate learns when a sheet of Today is closing, from the sheet's
    /// own presentation value (`TodayRouteGate`, `sheetIsClosing`). So the
    /// midday reminder over a new-entry draft has one result after "Save".
    func testTheGateLearnsWhenASheetOfTodayIsClosing() throws {
        let source = try ScreenText.source("Reminders/ReminderRouteOpening.swift")
        XCTAssertTrue(source.contains("sheetOnScreen: sheetOnScreen, sheetIsClosing: sheetIsClosing, routeScreenShows:"), "ReminderRouteOpening passes sheetIsClosing to the gate")
        for value in ["case .newEntry: return !showingNewEntry", "case .closeTheDay: return !isShowingCloseTheDay", "case .planBuilder: return planBuilderMode == nil"] {
            XCTAssertTrue(source.contains(value), "sheetIsClosing reads \(value)")
        }
    }
}
