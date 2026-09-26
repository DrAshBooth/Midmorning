import XCTest

/// Ruling r13-19 (mm-t43.30): the navigation and text checks that the
/// device-check beads held, as UI tests on the simulator. Each test names
/// its device-check bead and the check it replaces.
///
/// Run these with `tools/skeleton-checks/automated-checks.sh`. The script
/// builds and installs the app, seeds the stores (`seeder`, scenarios
/// `week1`, `review` and `corrupt`) and gives this bundle two paths:
/// `APP_DATA`, the app's data container, and `STORES`, the seeded stores.
/// Before each launch a test puts one seeded store into the container, so
/// every test starts from a known record.
final class AutomatedChecks: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "uk.midmorning.app")
    private let environment = ProcessInfo.processInfo.environment

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard environment["APP_DATA"] != nil, environment["STORES"] != nil else {
            throw XCTSkip("Run these checks with tools/skeleton-checks/automated-checks.sh")
        }
    }

    /// After a failure, keeps the screen and the accessibility hierarchy in
    /// `OUT_DIR`, so that the person who runs the checks can see what
    /// showed.
    override func tearDown() {
        if (testRun?.totalFailureCount ?? 0) > 0, let out = environment["OUT_DIR"], app.state != .notRunning {
            let name = name.split(separator: " ").last.map { String($0.dropLast()) } ?? "failure"
            let directory = URL(fileURLWithPath: out)
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
            try? app.debugDescription.write(to: directory.appendingPathComponent("\(name).txt"), atomically: true, encoding: .utf8)
        }
        app.terminate()
    }

    // MARK: Launch with a seeded store

    /// Puts the seeded store `scenario` (or no store) into the app's
    /// container, writes the launch marker when one is given, and launches
    /// the app with a UK locale.
    func launch(_ scenario: String?, launchMarker: String? = nil) throws {
        app.terminate()
        let fileManager = FileManager.default
        let support = URL(fileURLWithPath: environment["APP_DATA"]!).appendingPathComponent("Library/Application Support")
        let record = support.appendingPathComponent("Record")
        let marker = support.appendingPathComponent("LaunchMarker")
        try? fileManager.removeItem(at: record)
        try? fileManager.removeItem(at: marker)
        try fileManager.createDirectory(at: record, withIntermediateDirectories: true)
        if let scenario {
            let seeded = URL(fileURLWithPath: environment["STORES"]!).appendingPathComponent(scenario)
            for file in try fileManager.contentsOfDirectory(at: seeded, includingPropertiesForKeys: nil) {
                try fileManager.copyItem(at: file, to: record.appendingPathComponent(file.lastPathComponent))
            }
        }
        if let launchMarker {
            try Data(launchMarker.utf8).write(to: marker)
        }
        app.launchArguments = ["-AppleLanguages", "(en-GB)", "-AppleLocale", "en_GB"]
        app.launch()
    }

    /// Launches with `scenario` and waits for Today.
    func launchOnToday(_ scenario: String) throws {
        try launch(scenario)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "Today shows after the launch")
    }

    // MARK: Helpers

    func element(labelled label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    func element(labelBeginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    func element(labelContaining text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Swipes up until `element` is on screen. A SwiftUI list makes a row
    /// only when the row comes near the screen.
    @discardableResult
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 8) -> Bool {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    /// Waits for the navigation bar of the screen `title`.
    func assertScreen(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 8), "the screen \"\(title)\" shows", file: file, line: line)
    }

    /// safeguarding spec, "The support sheet": one tap on `button` opens
    /// the sheet, and the sheet lists its six items: Beat, Samaritans,
    /// Lifeline, NHS 111, 999 and the GP. Then "Close" closes it.
    func assertSupportSheetOpens(from button: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(button.waitForExistence(timeout: 8), "\"Get support\" shows", file: file, line: line)
        button.tap()
        let sheet = app.navigationBars["Get support"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 8), "one tap opens the support sheet", file: file, line: line)
        let items: [(String, NSPredicate)] = [
            ("Beat", NSPredicate(format: "label CONTAINS %@", "0808 801 0677")),
            ("Samaritans", NSPredicate(format: "label CONTAINS %@", "116 123")),
            ("Lifeline", NSPredicate(format: "label CONTAINS %@", "0808 808 8000")),
            ("NHS 111", NSPredicate(format: "label ENDSWITH %@", ", 111")),
            ("999", NSPredicate(format: "label ENDSWITH %@", ", 999")),
            ("GP", NSPredicate(format: "label == %@", "Talk to your GP")),
        ]
        for (name, predicate) in items {
            let item = app.descendants(matching: .any).matching(predicate).firstMatch
            XCTAssertTrue(scrollTo(item), "the support sheet lists \(name)", file: file, line: line)
        }
        sheet.buttons["Close"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5), "Close closes the support sheet", file: file, line: line)
    }

    /// The "Get support" control in the navigation bar of the screen `title`.
    func getSupport(on title: String) -> XCUIElement {
        app.navigationBars[title].buttons["Get support"]
    }

    func tapToolbar(_ label: String) {
        let button = app.toolbars.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 8), "the bottom toolbar shows \"\(label)\"")
        button.tap()
    }

    func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// Opens the current day heading's menu ("Day options") and taps `item`.
    func tapDayMenu(_ item: String) {
        let menu = app.buttons["Day options"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 8), "the current day heading shows its menu")
        menu.tap()
        let button = app.buttons[item].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "the day menu offers \"\(item)\"")
        button.tap()
    }

    // MARK: mm-t13.8 (settings)

    /// mm-t13.8 item 1, "Reach the settings screen": one tap on "Settings"
    /// in Today's bottom toolbar opens the settings screen.
    func testSettingsOneTapFromToday() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
    }

    /// mm-t13.8 item 2, "Privacy notice": Settings, then "Privacy", opens
    /// the notice. The notice shows the controller, the contact, who reads
    /// the contact inbox, Apple, the App Analytics line, the backup line
    /// and the ICO line. `PrivacyNoticeTextTests` proves the words.
    func testPrivacyNotice() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let privacy = app.buttons["Privacy"].firstMatch
        XCTAssertTrue(scrollTo(privacy), "the Privacy group shows \"Privacy\"")
        privacy.tap()
        assertScreen("Privacy notice")
        for part in ["Who controls your data", "The team confirms the controller", "Contact", "@", "The team reads this inbox.",
                     "Apple", "App Analytics", "A backup of your device", "(ICO)"] {
            XCTAssertTrue(scrollTo(element(labelContaining: part)), "the notice shows \"\(part)\"")
        }
    }

    /// mm-t13.8, comment of mm-t22.21: "Get support" on the settings
    /// screen, the Reminders group screen and the privacy notice opens the
    /// real support sheet with all six items. (The call itself stays a
    /// device check.)
    func testGetSupportOnTheSettingsScreens() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        assertSupportSheetOpens(from: getSupport(on: "Settings"))
        app.buttons["Reminders"].firstMatch.tap()
        assertScreen("Reminders")
        assertSupportSheetOpens(from: getSupport(on: "Reminders"))
        goBack()
        assertScreen("Settings")
        let privacy = app.buttons["Privacy"].firstMatch
        XCTAssertTrue(scrollTo(privacy))
        privacy.tap()
        assertScreen("Privacy notice")
        assertSupportSheetOpens(from: getSupport(on: "Privacy notice"))
    }

    // MARK: mm-t12b.1 (record-full)

    /// mm-t12b.1, comment of mm-t12b.20 and mm-t12.37, item 1: Today's
    /// bottom toolbar shows "Programme" and "Settings", and "Reviews" only
    /// from the first due weekly review. Programme spec, "Before the first
    /// weekly review": in week 1 the toolbar shows no "Reviews".
    func testTheToolbarBeforeTheFirstReview() throws {
        try launchOnToday("week1")
        XCTAssertTrue(app.toolbars.buttons["Programme"].exists)
        XCTAssertTrue(app.toolbars.buttons["Settings"].exists)
        XCTAssertFalse(app.toolbars.buttons["Reviews"].exists, "no \"Reviews\" before the first weekly review")
        tapToolbar("Programme")
        assertScreen("Programme")
    }

    /// mm-t12b.1, comment of mm-t12b.20 and mm-t12.37, item 3: with no
    /// setting row, Settings shows "Gap bands" on, quiet hours on from
    /// 22:00 to 07:00, "Remind me again in" 15 minutes and the unit kg.
    func testSettingsShowTheDefaults() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let gapBands = app.switches["Gap bands"].firstMatch
        XCTAssertTrue(scrollTo(gapBands))
        XCTAssertEqual(gapBands.value as? String, "1", "\"Gap bands\" is on")
        let unit = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Unit")).firstMatch
        XCTAssertTrue(scrollTo(unit))
        XCTAssertTrue(unit.staticTexts["kg"].exists, "the unit is kg")
        app.swipeDown(); app.swipeDown(); app.swipeDown()
        app.buttons["Reminders"].firstMatch.tap()
        assertScreen("Reminders")
        let remindAgain = element(labelBeginningWith: "Remind me again in")
        XCTAssertTrue(scrollTo(remindAgain))
        XCTAssertTrue("\(remindAgain.label) \(remindAgain.value ?? "")".contains("15 minutes"), "\"Remind me again in\" is 15 minutes")
        let quietHours = app.switches["Quiet hours"].firstMatch
        XCTAssertTrue(scrollTo(quietHours))
        XCTAssertEqual(quietHours.value as? String, "1", "quiet hours are on")
        // The two time pickers under "Quiet hours": "Start" and "End".
        let pickers = app.buttons.matching(NSPredicate(format: "label == %@", "Time Picker")).allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(pickers.count, 2)
        let quietStartAndEnd = pickers.suffix(2).map { $0.value as? String }
        XCTAssertEqual(quietStartAndEnd, ["22:00", "07:00"], "quiet hours run from 22:00 to 07:00")
    }

    /// mm-t12b.1, comment of mm-t11.39: the record strings from the
    /// catalogue. The new-entry screen shows "felt like a binge", and with
    /// the star on "Context" and "What was going on just before?". The
    /// Where chips show Home, Work, Out and Travelling. Today shows "3
    /// entries" on the collapsed previous day and "Paused" when the day
    /// expands; "Fasting" and "Didn't record" on the current day; "1 entry"
    /// on a collapsed current day. The gap band reads "Gap of more than 4
    /// hours".
    func testRecordStrings() throws {
        try launchOnToday("review")
        // The gap band between the 08:00 and the 13:30 entry.
        XCTAssertTrue(scrollTo(element(labelled: "Gap of more than 4 hours")), "the gap band reads \"Gap of more than 4 hours\"")
        // The previous record day: collapsed by default, then expanded.
        let count = element(labelled: "3 entries")
        XCTAssertTrue(scrollTo(count), "the collapsed previous day shows \"3 entries\"")
        let previousMenu = app.buttons.matching(identifier: "Day options").element(boundBy: 1)
        XCTAssertTrue(scrollTo(previousMenu))
        previousMenu.tap()
        app.buttons["Expand day"].firstMatch.tap()
        XCTAssertTrue(scrollTo(element(labelled: "Paused")), "the previous day shows \"Paused\"")
        // The current record day.
        app.swipeDown(); app.swipeDown(); app.swipeDown()
        tapDayMenu("Fasting today")
        XCTAssertTrue(element(labelled: "Fasting").waitForExistence(timeout: 5), "the current day shows \"Fasting\"")
        tapDayMenu("Didn't record")
        XCTAssertTrue(element(labelled: "Didn't record").waitForExistence(timeout: 5), "the current day shows \"Didn't record\"")
        tapDayMenu("Didn't record")
        tapDayMenu("Fasting today")
        tapDayMenu("Collapse day")
        XCTAssertTrue(element(labelled: "2 entries").waitForExistence(timeout: 5), "the collapsed current day shows \"2 entries\"")
        // The new-entry screen.
        app.buttons["Add an entry"].firstMatch.tap()
        let star = app.switches["felt like a binge"].firstMatch
        XCTAssertTrue(star.waitForExistence(timeout: 8), "the new-entry screen shows \"felt like a binge\"")
        for chip in ["Home", "Work", "Out", "Travelling"] {
            XCTAssertTrue(app.buttons[chip].firstMatch.exists, "the Where chips show \"\(chip)\"")
        }
        // The Context field's label: "Context", and "What was going on just
        // before?" while the star is on.
        XCTAssertTrue(element(labelled: "Context").exists, "the new-entry screen shows \"Context\"")
        let knob = star.switches.firstMatch
        (knob.exists ? knob : star).tap()
        XCTAssertTrue(element(labelled: "What was going on just before?").waitForExistence(timeout: 5), "with the star on, the field reads \"What was going on just before?\"")
        app.buttons["Cancel"].firstMatch.tap()
    }

    /// mm-t12b.1, comment of mm-t22.21: "Get support" on the earlier-days
    /// list and on one earlier day opens the real support sheet.
    func testGetSupportOnEarlierDays() throws {
        try launchOnToday("review")
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        assertSupportSheetOpens(from: getSupport(on: "Earlier days"))
        let firstDay = app.cells.firstMatch
        XCTAssertTrue(firstDay.waitForExistence(timeout: 5))
        firstDay.tap()
        let dayGetSupport = app.navigationBars.buttons["Get support"].firstMatch
        XCTAssertTrue(app.buttons["Previous day"].waitForExistence(timeout: 8), "one earlier day shows")
        assertSupportSheetOpens(from: dayGetSupport)
    }

    /// mm-t12b.1, comment of mm-t12b.24: on the most recent earlier day
    /// the next-day control is off; on the earliest day with an entry the
    /// previous-day control is off; "Today" returns to Today. Comment of
    /// mm-t12b.19: the day menu and both chevrons have a hit area of at
    /// least 44 by 44 points.
    func testEarlierDayControls() throws {
        try launchOnToday("review")
        let dayMenu = app.buttons["Day options"].firstMatch
        XCTAssertTrue(dayMenu.waitForExistence(timeout: 8))
        XCTAssertGreaterThanOrEqual(dayMenu.frame.width, 44, "the day menu is at least 44 points wide")
        XCTAssertGreaterThanOrEqual(dayMenu.frame.height, 44, "the day menu is at least 44 points high")
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        app.cells.firstMatch.tap()
        let previous = app.buttons["Previous day"]
        let next = app.buttons["Next day"]
        XCTAssertTrue(previous.waitForExistence(timeout: 8))
        for control in [previous, next] {
            XCTAssertGreaterThanOrEqual(control.frame.width, 44, "\(control.label) is at least 44 points wide")
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, "\(control.label) is at least 44 points high")
        }
        XCTAssertFalse(next.isEnabled, "the most recent earlier day has no next day")
        var taps = 0
        while previous.isEnabled && taps < 20 {
            previous.tap()
            taps += 1
        }
        XCTAssertFalse(previous.isEnabled, "the earliest day with an entry has no previous day")
        XCTAssertEqual(taps, 6, "the seeded record holds seven earlier days")
        app.navigationBars.buttons["Today"].firstMatch.tap()
        assertScreen("Today")
    }

    // MARK: mm-t14.28 (onboarding and safeguarding)

    /// mm-t14.28, comment of mm-t14.42: on Today, "Get support" is the
    /// trailing item of the navigation bar, and one tap opens the support
    /// sheet.
    func testGetSupportOnToday() throws {
        try launchOnToday("week1")
        let bar = app.navigationBars["Today"]
        let getSupport = bar.buttons["Get support"]
        XCTAssertTrue(getSupport.waitForExistence(timeout: 5))
        let trailing = bar.buttons.allElementsBoundByIndex.max { $0.frame.maxX < $1.frame.maxX }
        XCTAssertEqual(trailing?.label, "Get support", "\"Get support\" is the trailing item")
        assertSupportSheetOpens(from: getSupport)
    }

    /// mm-t14.28, comment of mm-t14.42: the store-open fault screen shows
    /// "Get support". Comment of mm-t22.21 on mm-t41.15: it opens the real
    /// support sheet.
    func testGetSupportOnTheStoreOpenFailureScreen() throws {
        try launch("corrupt")
        XCTAssertTrue(element(labelled: "Midmorning cannot open your record on this device.").waitForExistence(timeout: 20), "the store-open fault screen shows")
        assertSupportSheetOpens(from: app.buttons["Get support"].firstMatch)
    }

    /// mm-t14.28, comment of mm-t14.42: the deleted screen shows "Get
    /// support". Comment of mm-t22.21 on mm-t41.15: it opens the real
    /// support sheet.
    func testGetSupportOnTheDeletedScreen() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let delete = app.buttons["Delete everything"].firstMatch
        XCTAssertTrue(scrollTo(delete))
        delete.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == %@", "Delete everything"))
        XCTAssertTrue(confirm.element(boundBy: 1).waitForExistence(timeout: 5), "the confirmation shows")
        confirm.allElementsBoundByIndex.last!.tap()
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "the deleted screen shows")
        assertSupportSheetOpens(from: app.buttons["Get support"].firstMatch)
    }

    // MARK: mm-t21.24 (programme)

    /// mm-t21.24 item 1: "Get support" on the stage screen opens the
    /// support sheet.
    func testGetSupportOnTheStageScreen() throws {
        try launchOnToday("week1")
        tapToolbar("Programme")
        assertScreen("Programme")
        element(labelBeginningWith: "Getting started").tap()
        assertScreen("Getting started")
        assertSupportSheetOpens(from: getSupport(on: "Getting started"))
    }

    /// mm-t21.24 item 5: the restart re-screen shows "Get support" in its
    /// navigation bar. Safeguarding spec, "Restart re-screen": one tap
    /// opens the support sheet.
    func testGetSupportOnTheRestartRescreen() throws {
        try launchOnToday("week1")
        tapToolbar("Programme")
        assertScreen("Programme")
        let restart = app.buttons["Start week 1 again"].firstMatch
        XCTAssertTrue(scrollTo(restart))
        restart.tap()
        assertScreen("A few questions first")
        assertSupportSheetOpens(from: getSupport(on: "A few questions first"))
    }

    // MARK: mm-t22.16 (weigh-in)

    /// mm-t22.16 item 1, "The route from Today": on the weigh-in day,
    /// "Programme", then "Getting started", then "Weigh-in" opens the
    /// weigh-in screen with the weight input, after three taps.
    func testTheWeighInRouteFromToday() throws {
        try launchOnToday("week1")
        tapToolbar("Programme")                                   // tap 1
        assertScreen("Programme")
        element(labelBeginningWith: "Getting started").tap()      // tap 2
        assertScreen("Getting started")
        let weighIn = app.buttons["Weigh-in"].firstMatch
        XCTAssertTrue(scrollTo(weighIn), "the Tools group shows \"Weigh-in\"")
        weighIn.tap()                                             // tap 3
        assertScreen("Weigh-in")
        let weight = app.textFields["Weight"].firstMatch
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "the weigh-in screen shows the weight input")
    }

    // MARK: mm-t23.15 and mm-t42.14 (the plan builder)

    /// mm-t23.15, comment of mm-t22.21, and the mm-t42.14 description:
    /// "Get support" in the plan builder opens the real support sheet.
    func testGetSupportInThePlanBuilder() throws {
        try launchOnToday("review")
        tapDayMenu("Today's plan")
        assertScreen("Today's plan")
        assertSupportSheetOpens(from: getSupport(on: "Today's plan"))
    }

    // MARK: mm-t32.17 (weekly review)

    /// mm-t32.17, navigation depth, programme spec "One tap to each
    /// screen": when the first weekly review is due, one tap on
    /// "Programme", "Reviews" or "Settings" reaches its screen, and one tap
    /// reaches Get support. "The route from Today": one tap on "Weekly
    /// review" opens the due review.
    func testOneTapToEachScreen() throws {
        try launchOnToday("review")
        for (control, screen) in [("Programme", "Programme"), ("Reviews", "Reviews"), ("Settings", "Settings")] {
            tapToolbar(control)
            assertScreen(screen)
            goBack()
            assertScreen("Today")
        }
        assertSupportSheetOpens(from: getSupport(on: "Today"))
        let weeklyReview = app.buttons["Weekly review"].firstMatch
        XCTAssertTrue(weeklyReview.waitForExistence(timeout: 5), "Today shows \"Weekly review\" while the review is due")
        weeklyReview.tap()
        assertScreen("Weekly review")
    }

    /// mm-t32.17: "Get support" on the review screen and on the "Reviews"
    /// list opens the support sheet.
    func testGetSupportOnTheReviewAndTheReviewsList() throws {
        try launchOnToday("review")
        tapToolbar("Reviews")
        assertScreen("Reviews")
        assertSupportSheetOpens(from: getSupport(on: "Reviews"))
        goBack()
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        assertSupportSheetOpens(from: getSupport(on: "Weekly review"))
    }

    // MARK: mm-t42.14 (export)

    /// mm-t42.14, "Opens the export screen", the GP suggestion page: "I'm
    /// getting worse" on the review opens the GP suggestion page, and its
    /// export control opens the export screen.
    func testExportFromTheGPSuggestionPage() throws {
        try launchOnToday("review")
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        let worse = app.buttons["I'm getting worse"].firstMatch
        XCTAssertTrue(scrollTo(worse))
        worse.tap()
        XCTAssertTrue(element(labelled: "It might help to see your GP").waitForExistence(timeout: 8), "the GP suggestion page shows")
        let export = app.buttons["Export your record to take with you"].firstMatch
        XCTAssertTrue(scrollTo(export))
        export.tap()
        assertScreen("Export")
        XCTAssertTrue(app.buttons["Make PDF"].firstMatch.waitForExistence(timeout: 5) || scrollTo(app.buttons["Make PDF"].firstMatch), "the export screen shows \"Make PDF\"")
    }

    /// mm-t42.14, "Opens the export screen", the not-right-now page: "Yes"
    /// and then "Yes" to the self-harm item on the review opens the
    /// not-right-now page, and its export control opens the export screen.
    func testExportFromTheNotRightNowPage() throws {
        try launchOnToday("review")
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        // Each row of an inline picker carries the picker's label, the
        // question. The rows are "No", "Yes" and "Rather not say", in that
        // order, so "Yes" is the second row.
        let firstStep = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Over the last two weeks"))
        XCTAssertTrue(scrollTo(firstStep.element(boundBy: 1)), "the self-harm item shows \"Yes\"")
        firstStep.element(boundBy: 1).tap()
        let secondStep = app.buttons.matching(NSPredicate(format: "label == %@", "Have you thought about how you would do it?"))
        let secondYes = secondStep.element(boundBy: 1)
        XCTAssertTrue(scrollTo(secondYes), "the second step of the self-harm item shows")
        // "Done" sits over the bottom of the form; a row under it takes no tap.
        let done = app.buttons["Done"].firstMatch
        var swipes = 0
        while secondYes.frame.maxY > done.frame.minY - 8 && swipes < 5 {
            app.swipeUp()
            swipes += 1
        }
        secondYes.tap()
        XCTAssertTrue(element(labelled: "This may not be right for you now").waitForExistence(timeout: 8), "the not-right-now page shows")
        let export = app.buttons["Export your record to take with you"].firstMatch
        XCTAssertTrue(scrollTo(export))
        export.tap()
        assertScreen("Export")
    }

    /// mm-t42.14, "Opens the export screen", safe mode: the third launch in
    /// a row that stopped before Today opens safe mode's own Today, and its
    /// "Export" opens the export screen. Safe mode also shows "Get
    /// support".
    func testExportFromSafeMode() throws {
        try launch("week1", launchMarker: "2")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "safe mode's Today shows")
        XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
        assertSupportSheetOpens(from: getSupport(on: "Today"))
        app.buttons["Export"].firstMatch.tap()
        assertScreen("Export")
    }

    // MARK: mm-t41.15 and mm-t42.14 (Diagnostics)

    /// mm-t41.15 "Diagnostics" (the same check as mm-t42.14
    /// "Diagnostics"): the About group's Diagnostics page shows the eight
    /// counts and no entry, weight or plan. Comment of mm-t22.21 on
    /// mm-t41.15: its "Get support" opens the real support sheet.
    func testDiagnosticsShowsTheEightCounts() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let diagnostics = app.buttons["Diagnostics"].firstMatch
        XCTAssertTrue(scrollTo(diagnostics))
        diagnostics.tap()
        assertScreen("Diagnostics")
        let counts = ["Launch failures", "Last successful sync day", "Schema version", "Content version",
                      "Pending reminders", "Queue length", "Last reconcile outcome", "Crash count"]
        for count in counts {
            XCTAssertTrue(scrollTo(element(labelBeginningWith: count)), "Diagnostics shows \"\(count)\"")
        }
        let rows = app.cells.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(rows.count, counts.count, "Diagnostics shows eight rows and nothing else: \(rows)")
        for content in ["Toast and tea", "70.4", "70,4", "Breakfast", "Lunch"] {
            XCTAssertFalse(element(labelContaining: content).exists, "Diagnostics shows no record content (\(content))")
        }
        assertSupportSheetOpens(from: getSupport(on: "Diagnostics"))
    }
}
