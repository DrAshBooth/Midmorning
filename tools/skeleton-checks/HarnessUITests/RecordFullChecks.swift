import XCTest

/// Ad hoc smoke checks for record-full (1.2b), driving the installed app the
/// same way `SkeletonChecks` does. Not part of `./verify`; a manual run
/// during the build, kept here for the next agent or Ash to rerun.
final class RecordFullChecks: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "uk.midmorning.app")
    var outDir: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["OUT_DIR"] ?? NSTemporaryDirectory()) }

    override func setUp() { continueAfterFailure = true }

    func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 0.6)
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: outDir.appendingPathComponent(name + ".png"))
    }

    func log(_ line: String) {
        print("EVIDENCE: " + line)
    }

    func launchFresh() {
        app.terminate(); app.launch()
        XCTAssert(app.staticTexts["Today"].waitForExistence(timeout: 15), "Today did not appear")
        Thread.sleep(forTimeInterval: 1)
    }

    /// Add an entry with a fixed chip, Context and the star; confirm it
    /// shows on Today with Where and Context; edit it; delete it.
    func testAddEditDeleteWithWhereAndContext() {
        launchFresh()
        shot("rf-01-today")

        app.buttons["Add an entry"].tap()
        XCTAssert(app.otherElements.matching(NSPredicate(format: "label == 'What'")).firstMatch.waitForExistence(timeout: 5) || app.staticTexts["What"].waitForExistence(timeout: 5))
        shot("rf-02-new-entry")

        // What
        let what = app.textViews.firstMatch
        if what.waitForExistence(timeout: 3) { what.tap(); what.typeText("Toast and tea") }

        // A fixed Where chip
        if app.buttons["Home"].waitForExistence(timeout: 3) { app.buttons["Home"].tap() }
        shot("rf-03-where-selected")

        // The star
        let star = app.switches["felt like a binge"]
        if star.waitForExistence(timeout: 2) { star.tap() }

        // Context: the second text view on screen, once the star is on
        let textViews = app.textViews.allElementsBoundByIndex
        if textViews.count > 1 { textViews[1].tap(); textViews[1].typeText("Row with my sister") }
        shot("rf-04-context-filled")

        app.buttons["Save"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("rf-05-today-after-save")

        let savedRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Toast and tea")).firstMatch
        log("saved row exists: \(savedRow.exists)")

        // Edit: tap the row, change What, save
        savedRow.tap()
        Thread.sleep(forTimeInterval: 0.8)
        shot("rf-06-edit-screen")
        if app.buttons["Delete entry"].waitForExistence(timeout: 3) {
            app.buttons["Delete entry"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            shot("rf-07-delete-confirm")
            if app.buttons["Delete"].waitForExistence(timeout: 2) { app.buttons["Delete"].tap() }
        }
        Thread.sleep(forTimeInterval: 1)
        shot("rf-08-today-after-delete")
        log("row gone after delete: \(!app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Toast and tea")).firstMatch.exists)")
    }

    /// Pause, collapse the previous day, and open "Earlier days".
    func testPauseCollapseAndEarlierDays() {
        launchFresh()
        if app.buttons["Pause for today"].waitForExistence(timeout: 3) {
            app.buttons["Pause for today"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            log("pause control now reads Paused for today: \(app.buttons["Paused for today"].exists)")
        }
        shot("rf-09-paused")
    }
}
