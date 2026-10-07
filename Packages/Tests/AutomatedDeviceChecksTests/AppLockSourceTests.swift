import Foundation
import XCTest

/// Source checks for two app-lock rulings whose App code `swift test`
/// cannot run. `LockedNewEntryTests` (AppLock) proves the package value.
/// These tests prove that the App files use it. The device-check bead
/// mm-t15.14 holds the checks on a device.
final class AppLockSourceTests: XCTestCase {
    /// The source of an App file with no comments and no white space, so a
    /// match does not depend on the line breaks.
    private func compactSource(_ path: String) throws -> String {
        try ScreenText.source(path).filter { !$0.isWhitespace }
    }

    private func compact(_ text: String) -> String {
        text.filter { !$0.isWhitespace }
    }

    // MARK: Ruling r17-01 (mm-t15.22): app-lock "A new entry before authentication"

    /// The new-entry screen on the cover gets the locked state's value. A
    /// call with no `showsSavedPlaces:` uses the default `true`, and the
    /// locked screen then shows custom places from the record.
    func testTheCoverPassesTheLockedValueToTheNewEntryScreen() throws {
        let source = try compactSource("AppLock/AppLockCoverWindow.swift")
        guard let start = source.range(of: "NewEntryView(") else {
            return XCTFail("AppLockCoverWindow.swift shows no NewEntryView")
        }
        let rest = source[start.upperBound...]
        XCTAssertTrue(
            rest.contains(compact("showsSavedPlaces: controller.state.newEntryShowsSavedPlaces")),
            "the cover's NewEntryView gets no showsSavedPlaces from the controller state"
        )
    }

    /// While `showsSavedPlaces` is `false`, the screen does not read the
    /// custom places when it opens.
    func testTheNewEntryScreenReadsTheCustomPlacesOnlyWhenItShowsThem() throws {
        let source = try compactSource("NewEntryView.swift")
        guard let start = source.range(of: ".onAppear{") else {
            return XCTFail("NewEntryView.swift has no onAppear")
        }
        let rest = source[start.upperBound...]
        let end = rest.range(of: "Task{")?.lowerBound ?? rest.endIndex
        let onAppear = String(rest[..<end])
        let read = compact("customPlaces = (try? store.customPlaces()) ?? []")
        XCTAssertTrue(
            onAppear.contains(compact("if showsSavedPlaces {") + read + "}"),
            "onAppear reads the custom places with no showsSavedPlaces guard"
        )
        XCTAssertEqual(onAppear.components(separatedBy: "store.customPlaces()").count - 1, 1, "onAppear reads the custom places one time, under the guard")
    }

    /// The Where chips filter the saved custom places with
    /// `showsSavedPlaces`. The places added on the screen still show.
    func testTheWhereChipsFilterTheSavedPlaces() throws {
        let source = try compactSource("NewEntryView.swift")
        XCTAssertTrue(
            source.contains(compact("customPlaces: unsavedPlaces.chips(savedPlaces: showsSavedPlaces ? customPlaces : [])")),
            "the Where chips do not filter the saved places with showsSavedPlaces"
        )
    }

    // MARK: Ruling r15-03 (mm-t15.21): app-lock "Face ID only or Touch ID only"

    /// A biometrics-only request shows no fallback button. With no empty
    /// title, iOS shows "Enter Password" after a failed attempt, and a
    /// tester can read it as an offer of the device passcode (scenario
    /// "Face ID fails at Turn on").
    func testABiometricsOnlyRequestShowsNoFallbackButton() throws {
        let source = try compactSource("AppLock/LocalAuthenticationAdapter.swift")
        XCTAssertTrue(
            source.contains(compact("if policy == .biometricsOnly { context.localizedFallbackTitle = \"\" }")),
            "a biometrics-only request keeps the default fallback button"
        )
    }
}
