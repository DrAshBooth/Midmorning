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
/// every test starts from a known record. It also gives `CONTENT_DRAFT`,
/// the draft state that `testDraftShowsAboveTheCardTitle` expects.
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

    /// Taps the button of a dialog: "Delete" or "Cancel" in "Delete this
    /// entry?". A swipe action with the same label can stay on screen under
    /// the dialog, so the dialog's own button is the last match.
    ///
    /// mm-t12b.28: on iOS 27 the dialog is a popover that shows no
    /// "Cancel"; a tap outside the popover cancels. Until that bug is fixed,
    /// "Cancel" taps outside the popover when the dialog shows no "Cancel".
    /// The fix of mm-t12b.28 makes this helper require the "Cancel" button.
    func tapDialogButton(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let inSheet = app.sheets.buttons[label]
        if inSheet.exists {
            inSheet.tap()
            return
        }
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", label))
        if label == "Cancel", matches.count == 0 {
            let outside = app.otherElements["PopoverDismissRegion"].firstMatch
            XCTAssertTrue(outside.exists, "the dialog shows \"Cancel\" or closes with a tap outside it", file: file, line: line)
            outside.tap()
            return
        }
        XCTAssertGreaterThan(matches.count, 0, "the dialog shows \"\(label)\"", file: file, line: line)
        matches.element(boundBy: matches.count - 1).tap()
    }

    /// Scrolls up with a slow drag from the upper part of the screen until
    /// `element` can take a tap above `limit` (for example, the top of a
    /// "Done" bar). A swipe from the centre of the screen can start on the
    /// text field that has the keyboard; then it selects text and does not
    /// scroll.
    @discardableResult
    func dragTo(_ element: XCUIElement, above limit: CGFloat = .infinity, maxDrags: Int = 12) -> Bool {
        for _ in 0..<maxDrags {
            if element.exists, element.isHittable, element.frame.maxY < limit { return true }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.32))
            start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.14)))
        }
        return element.exists && element.isHittable && element.frame.maxY < limit
    }

    /// Turns the switch `label` on or off with a tap on the switch itself.
    func flipSwitch(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[label].firstMatch
        XCTAssertTrue(scrollTo(toggle), "the switch \"\(label)\" shows", file: file, line: line)
        let knob = toggle.switches.firstMatch
        (knob.exists ? knob : toggle).tap()
    }

    /// The "Save" control in the navigation bar of the new-entry or the
    /// edit screen. The keyboard's toolbar holds a second "Save".
    func tapSaveInTheNavigationBar() {
        app.navigationBars.buttons["Save"].firstMatch.tap()
    }

    /// Taps "Add an entry" on Today and waits for the new-entry screen.
    func openNewEntry(file: StaticString = #filePath, line: UInt = #line) {
        app.buttons["Add an entry"].firstMatch.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "the new-entry screen shows", file: file, line: line)
        dismissKeyboardTip()
    }

    /// The first use of the keyboard on a new simulator can show a tip with
    /// "Continue". The new-entry and the edit screens have no "Continue".
    func dismissKeyboardTip() {
        let tip = app.buttons["Continue"].firstMatch
        if tip.waitForExistence(timeout: 1) { tip.tap() }
    }

    /// Opens "Add a place", types `place` and leaves the field open, so that
    /// the next control decides what happens to the typed place.
    func typePlace(_ place: String, file: StaticString = #filePath, line: UInt = #line) {
        let addAPlace = app.buttons["Add a place"].firstMatch
        XCTAssertTrue(scrollTo(addAPlace), "the Where control shows \"Add a place\"", file: file, line: line)
        addAPlace.tap()
        let field = app.textViews["Add a place"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "\"Add a place\" opens a field", file: file, line: line)
        field.tap()
        dismissKeyboardTip()
        field.typeText(place)
    }

    /// A chip on the new-entry or the edit screen whose label begins with
    /// `prefix`. Smart punctuation can change a typed "'" to "’", so a test
    /// finds a typed place by the letters before it.
    func chip(beginningWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// The rows of step 1 or step 2 of the self-harm item at the review, top
    /// to bottom. Each row reads its own answer ("No", "Yes", "I'd rather
    /// not say"), not the question (mm-t32.28).
    func reviewSelfHarmRows(step: Int) -> [XCUIElement] {
        let answers = NSPredicate(format: "label IN %@", ["No", "Yes", "I'd rather not say"])
        let rows = app.buttons.matching(answers).allElementsBoundByIndex.sorted { $0.frame.minY < $1.frame.minY }
        // Step 1 has three rows; step 2, when it shows, has the next two.
        return step == 1 ? Array(rows.prefix(3)) : Array(rows.dropFirst(3).prefix(2))
    }

    /// Scrolls to the row `answer` of step 1 or step 2 of the self-harm item
    /// at the review, and taps it. "Done" sits over the bottom of the form,
    /// so the row must be above "Done" before the tap.
    func tapReviewSelfHarmRow(step: Int, answer: String, file: StaticString = #filePath, line: UInt = #line) {
        let index = ["No": 0, "Yes": 1, "I'd rather not say": 2][answer]!
        let done = app.buttons["Done"].firstMatch
        var row: XCUIElement?
        for _ in 0..<10 {
            let rows = reviewSelfHarmRows(step: step)
            if rows.count > index, rows[index].isHittable, rows[index].frame.maxY < done.frame.minY - 8 {
                row = rows[index]
                break
            }
            app.swipeUp()
        }
        guard let row else {
            XCTFail("step \(step) of the self-harm item shows \"\(answer)\"", file: file, line: line)
            return
        }
        row.tap()
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
    /// expands; "Fasting" and "Didn't record" on the current day; "2
    /// entries" on a collapsed current day (the count line with more than
    /// one entry; the one-entry form is `testEarlierDayRowsAndMenu`). The
    /// gap band reads "Gap of more than 4 hours".
    func testRecordStrings() throws {
        try launchOnToday("review")
        // The gap band between the two entries of the current record day.
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
        tapReviewSelfHarmRow(step: 1, answer: "Yes")
        tapReviewSelfHarmRow(step: 2, answer: "Yes")
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

    // MARK: Flow checks (review of 26 September 2026, r13-19)

    /// mm-t12b.1, comment of mm-t12b.10: on an earlier day, a tap on a row
    /// opens the edit screen and a change shows on the day after "Save"; a
    /// swipe shows "Delete this entry?" first; the heading menu offers
    /// "Collapse day", "Fasting today" and "Didn't record", and no control
    /// that creates an entry; "Didn't record" shows its line under the
    /// heading; "Collapse day" shows the count line.
    func testEarlierDayRowsAndMenu() throws {
        try launchOnToday("review")
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.buttons["Previous day"].waitForExistence(timeout: 8), "one earlier day shows")
        XCTAssertFalse(app.buttons["Add an entry"].exists, "an earlier day shows no \"Add an entry\"")
        // The most recent earlier day holds one entry, "Porridge".
        let row = element(labelContaining: "Porridge")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "the earlier day shows its entry")
        // A tap opens the edit screen; a change shows after Save.
        row.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8), "a tap on a row opens the edit screen")
        let what = app.textViews["What"].firstMatch
        XCTAssertTrue(what.waitForExistence(timeout: 5))
        what.tap()
        dismissKeyboardTip()
        what.typeText(" and jam")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(element(labelContaining: "Porridge and jam").waitForExistence(timeout: 8), "the change shows on the earlier day after Save")
        // A swipe asks first.
        let changed = element(labelContaining: "Porridge and jam")
        changed.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(element(labelled: "Delete this entry?").waitForExistence(timeout: 5), "a swipe shows \"Delete this entry?\" first")
        tapDialogButton("Cancel")
        XCTAssertTrue(changed.waitForExistence(timeout: 5), "Cancel keeps the entry")
        // The heading menu.
        let menu = app.buttons["Day options"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        for item in ["Collapse day", "Fasting today", "Didn't record"] {
            XCTAssertTrue(app.buttons[item].firstMatch.waitForExistence(timeout: 5), "the earlier day's menu offers \"\(item)\"")
        }
        // The back control of this screen also reads "Earlier days"; the
        // menu adds no second one.
        for item in ["Earlier days", "Today's plan", "Add an entry"] {
            let all = app.buttons.matching(NSPredicate(format: "label == %@", item)).count
            let inBars = app.navigationBars.buttons.matching(NSPredicate(format: "label == %@", item)).count
            XCTAssertEqual(all - inBars, 0, "the earlier day's menu offers no \"\(item)\"")
        }
        app.buttons["Didn't record"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Didn't record"].waitForExistence(timeout: 5), "\"Didn't record\" shows its line under the heading")
        tapDayMenu("Collapse day")
        XCTAssertTrue(element(labelled: "1 entry").waitForExistence(timeout: 5), "the collapsed earlier day shows the count line \"1 entry\"")
    }

    /// mm-t12b.1, comment of mm-t12b.9: on a current day with entries,
    /// "Collapse day" shows the count line, and "Pause for today" still
    /// shows under it; one tap changes it to "Paused for today". With
    /// "Didn't record" on, the collapsed day shows the heading and the count
    /// line only.
    func testACollapsedDayKeepsPauseForToday() throws {
        try launchOnToday("review")
        tapDayMenu("Collapse day")
        let count = element(labelled: "2 entries")
        XCTAssertTrue(count.waitForExistence(timeout: 5), "the collapsed current day shows the count line")
        let pause = app.buttons["Pause for today"].firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "a collapsed day still shows \"Pause for today\"")
        XCTAssertLessThan(count.frame.minY, pause.frame.minY, "\"Pause for today\" shows under the count line")
        pause.tap()
        XCTAssertTrue(app.buttons["Paused for today"].firstMatch.waitForExistence(timeout: 5), "one tap changes it to \"Paused for today\"")
        tapDayMenu("Didn't record")
        XCTAssertTrue(count.waitForExistence(timeout: 5), "the count line stays")
        XCTAssertFalse(app.staticTexts["Didn't record"].exists, "a collapsed day shows no state line")
        for what in ["Toast and tea", "Rice and beans"] {
            XCTAssertFalse(element(labelContaining: what).exists, "a collapsed day shows no entry (\(what))")
        }
    }

    /// mm-t12b.1, comment of mm-t12b.6: a save into a collapsed current
    /// day expands the day and shows the entry, and the day stays expanded
    /// after the app opens again on the same record day. (The save at 23:30
    /// in the previous-day segment turns the time wheel; it stays a device
    /// check.)
    func testASaveExpandsACollapsedDay() throws {
        try launchOnToday("review")
        tapDayMenu("Collapse day")
        XCTAssertTrue(element(labelled: "2 entries").waitForExistence(timeout: 5))
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Apple")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(element(labelContaining: "Apple").waitForExistence(timeout: 8), "the save expands the day and shows the entry")
        XCTAssertTrue(element(labelContaining: "Rice and beans").exists, "the expanded day shows its other entries")
        // Open the app again, with the same store.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        XCTAssertTrue(element(labelContaining: "Apple").waitForExistence(timeout: 5), "the day stays expanded after the app opens again")
    }

    /// mm-t12b.1, comment of mm-t12b.12: a place typed in "Add a place" and
    /// not confirmed with Return saves with a tap on Save in the navigation
    /// bar; Today shows it; the next new-entry screen shows it as a chip
    /// after "Travelling". A place typed before Cancel makes no chip. The
    /// same on the edit screen.
    func testATypedPlaceSavesAndBecomesAChip() throws {
        try launchOnToday("week1")
        openNewEntry()
        typePlace("Mum's")
        tapSaveInTheNavigationBar()
        let savedRow = element(labelContaining: ", Mum")
        XCTAssertTrue(savedRow.waitForExistence(timeout: 8), "Today shows the entry with the typed place")
        openNewEntry()
        let mums = chip(beginningWith: "Mum")
        let travelling = app.buttons["Travelling"].firstMatch
        XCTAssertTrue(mums.waitForExistence(timeout: 5), "the next new-entry screen shows the chip")
        let sameLine = abs(mums.frame.midY - travelling.frame.midY) < 4
        XCTAssertTrue(sameLine ? mums.frame.minX > travelling.frame.maxX : mums.frame.minY > travelling.frame.maxY,
                      "the new chip shows after \"Travelling\"")
        typePlace("Gran")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        openNewEntry()
        XCTAssertFalse(chip(beginningWith: "Gran").exists, "a place typed before Cancel makes no chip")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        // The edit screen.
        XCTAssertTrue(savedRow.waitForExistence(timeout: 5))
        savedRow.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8), "the edit screen shows")
        typePlace("Beach")
        tapSaveInTheNavigationBar()
        let beachRow = element(labelContaining: ", Beach")
        XCTAssertTrue(beachRow.waitForExistence(timeout: 8), "Today shows the place typed on the edit screen")
        beachRow.tap()
        XCTAssertTrue(chip(beginningWith: "Beach").waitForExistence(timeout: 8), "the edit screen shows the new chip")
        typePlace("Park")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(beachRow.waitForExistence(timeout: 5))
        beachRow.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8))
        XCTAssertFalse(chip(beginningWith: "Park").exists, "a place typed before Cancel on the edit screen makes no chip")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
    }

    /// mm-t12b.1, comment of mm-t12b.7: a swipe on an entry row and
    /// "Delete" show "Delete this entry?" with "Delete", and the row stays
    /// on screen while the dialog shows. A cancel keeps the entry. "Delete"
    /// removes it, with no message. (The "Cancel" button waits for bug
    /// mm-t12b.28. The VoiceOver action and the planned meal row from stage
    /// 2 stay device checks.)
    func testDeleteAnEntryAsksFirst() throws {
        try launchOnToday("week1")
        let row = element(labelContaining: "Toast and tea")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(element(labelled: "Delete this entry?").waitForExistence(timeout: 5), "\"Delete this entry?\" shows")
        // The "Cancel" button part of this check is not automated: on iOS 27
        // the dialog shows no "Cancel" (bug mm-t12b.28). `tapDialogButton`
        // cancels with a tap outside the dialog until that bug is fixed.
        XCTAssertTrue(row.exists, "the row stays on screen while the dialog shows")
        tapDialogButton("Cancel")
        XCTAssertTrue(element(labelled: "Delete this entry?").waitForNonExistence(timeout: 5))
        XCTAssertTrue(row.exists, "Cancel keeps the entry")
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(element(labelled: "Delete this entry?").waitForExistence(timeout: 5))
        tapDialogButton("Delete")
        XCTAssertTrue(row.waitForNonExistence(timeout: 5), "Delete removes the entry")
        XCTAssertEqual(app.alerts.count, 0, "the delete shows no message")
        XCTAssertFalse(element(labelContaining: "eleted").exists, "the delete shows no message")
    }

    /// mm-t13.8, comment of mm-t13.11: with stage 2 open and a gap of more
    /// than 4 hours on the current day, the band shows. "Gap bands" off in
    /// Settings removes it; on again shows it again.
    func testTheGapBandsSwitch() throws {
        try launchOnToday("review")
        let band = element(labelled: "Gap of more than 4 hours")
        XCTAssertTrue(band.waitForExistence(timeout: 5), "the band shows")
        tapToolbar("Settings")
        assertScreen("Settings")
        flipSwitch("Gap bands")
        XCTAssertEqual(app.switches["Gap bands"].firstMatch.value as? String, "0", "\"Gap bands\" is off")
        goBack()
        assertScreen("Today")
        XCTAssertTrue(band.waitForNonExistence(timeout: 5), "with \"Gap bands\" off, the band is gone")
        tapToolbar("Settings")
        assertScreen("Settings")
        flipSwitch("Gap bands")
        XCTAssertEqual(app.switches["Gap bands"].firstMatch.value as? String, "1", "\"Gap bands\" is on")
        goBack()
        assertScreen("Today")
        XCTAssertTrue(band.waitForExistence(timeout: 5), "with \"Gap bands\" on again, the band shows again")
    }

    /// mm-t13.8, comment of mm-t13.13: "Day starts at" offers only 00:00 to
    /// 12:00 in whole hours; 06:00 stays after the person leaves Settings
    /// and opens it again. (The part about a second device needs sync, 4.1b.)
    func testDayStartsAtOffersWholeHoursToNoon() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let dayStart = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Day starts at")).firstMatch
        XCTAssertTrue(scrollTo(dayStart))
        XCTAssertTrue(dayStart.staticTexts["04:00"].exists || dayStart.label.contains("04:00"), "the day starts at 04:00")
        dayStart.tap()
        for hour in 0...12 {
            let item = String(format: "%02d:00", hour)
            XCTAssertTrue(app.buttons[item].firstMatch.waitForExistence(timeout: hour == 0 ? 5 : 1), "\"Day starts at\" offers \(item)")
        }
        for item in ["13:00", "23:00", "04:30"] {
            XCTAssertFalse(app.buttons[item].exists, "\"Day starts at\" offers no \(item)")
        }
        app.buttons["06:00"].firstMatch.tap()
        goBack()
        assertScreen("Today")
        tapToolbar("Settings")
        assertScreen("Settings")
        XCTAssertTrue(scrollTo(dayStart))
        XCTAssertTrue(dayStart.staticTexts["06:00"].exists || dayStart.label.contains("06:00"), "\"Day starts at\" shows 06:00 when Settings opens again")
    }

    /// mm-t21.24, comment of mm-t21.28: "Start week 1 again" and "Today"
    /// change Today at once, with no restart of the app: the "Weekly
    /// review" line goes, because no review is due in the new week 1. Stage
    /// 2 stays open (programme spec, "Start week 1 again": "Every open stage
    /// MUST stay open"), so Today still shows no "Getting started" line.
    /// The settings part of that check is `testTheGapBandsSwitch`; the plan
    /// part is on the follow-up bead.
    func testTodayShowsTheNewWeekAfterARestart() throws {
        try launchOnToday("review")
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForExistence(timeout: 8), "before the restart, the review is due")
        XCTAssertFalse(app.buttons["Getting started"].exists, "before the restart, stage 2 is open")
        tapToolbar("Programme")
        assertScreen("Programme")
        let restart = app.buttons["Start week 1 again"].firstMatch
        XCTAssertTrue(scrollTo(restart))
        restart.tap()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForExistence(timeout: 8), "the start-day choice shows, with no re-screen")
        app.collectionViews.buttons["Today"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForNonExistence(timeout: 5))
        goBack()
        assertScreen("Today")
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForNonExistence(timeout: 5), "at once, Today shows no \"Weekly review\" line: no review is due in the new week 1")
        XCTAssertFalse(app.buttons["Getting started"].exists, "stage 2 stays open after the restart")
        tapToolbar("Programme")
        assertScreen("Programme")
        XCTAssertTrue(element(labelled: "Week 1").waitForExistence(timeout: 5), "the Programme screen shows \"Week 1\"")
    }

    /// mm-t21.24, comment of mm-t21.29: a content bundle with no sign-off
    /// file is a draft. Settings, About, shows "Draft" beside the content
    /// version, and a stage 1 card opened from the "Getting started" screen
    /// shows "Draft" above the card title. Today's "Read" opens the same
    /// card screen (`CardScreenView`); the `week1` store is on the first
    /// recorded day, when Today shows no stage 1 card.
    ///
    /// The script gives the expected state in `CONTENT_DRAFT`: "1" when
    /// `Packages/Content/Resources` holds no sign-off file for the content
    /// version, "0" when it holds one. The test does not find the state
    /// from the screen, so a build that loses "Draft" in both places fails.
    /// `ProgrammeScreenTextTests` proves the rule from the bundle.
    func testDraftShowsAboveTheCardTitle() throws {
        guard let expected = environment["CONTENT_DRAFT"], ["0", "1"].contains(expected) else {
            XCTFail("CONTENT_DRAFT is not set: run this check with tools/skeleton-checks/automated-checks.sh")
            return
        }
        let isDraft = expected == "1"
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let contentVersion = element(labelled: "Content version")
        XCTAssertTrue(scrollTo(contentVersion), "About shows the content version")
        let aboutDraft = app.staticTexts["Draft"].firstMatch
        if isDraft {
            XCTAssertTrue(aboutDraft.waitForExistence(timeout: 3), "About shows \"Draft\" for a bundle with no sign-off")
            XCTAssertEqual(aboutDraft.frame.midY, contentVersion.frame.midY, accuracy: 12, "\"Draft\" shows beside the content version")
        } else {
            XCTAssertFalse(aboutDraft.exists, "About shows no \"Draft\" for a signed bundle")
        }
        goBack()
        assertScreen("Today")
        tapToolbar("Programme")
        assertScreen("Programme")
        element(labelBeginningWith: "Getting started").tap()
        assertScreen("Getting started")
        let card = app.buttons["Why write it down"].firstMatch
        XCTAssertTrue(scrollTo(card), "the \"Getting started\" screen lists the card \"Why write it down\"")
        card.tap()
        assertScreen("Why write it down")
        let bar = app.navigationBars.firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 8))
        let title = app.scrollViews.staticTexts[bar.identifier].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "the card screen shows the card title")
        let cardDraft = app.scrollViews.staticTexts["Draft"].firstMatch
        if isDraft {
            XCTAssertTrue(cardDraft.waitForExistence(timeout: 3), "the card screen shows \"Draft\" for a bundle with no sign-off")
            XCTAssertLessThanOrEqual(cardDraft.frame.maxY, title.frame.minY, "\"Draft\" shows above the card title")
        } else {
            XCTAssertFalse(cardDraft.exists, "a signed bundle shows no \"Draft\"")
        }
    }

    /// mm-t22.16, comment of mm-t22.24: on the weigh-in screen with "st
    /// lb", 10 st 25 lb and Save show "That number is outside the range the
    /// app accepts. Check it and try again." and save nothing; 10 st 13 lb
    /// saves. The screen fills the input with the day's own weigh-in during
    /// its 10-minute edit window, so an empty input after a new open proves
    /// that nothing saved.
    func testAPoundsValueOutOfRangeSavesNothing() throws {
        try launchOnToday("week1")
        func openWeighIn() {
            tapToolbar("Programme")
            assertScreen("Programme")
            element(labelBeginningWith: "Getting started").tap()
            assertScreen("Getting started")
            let weighIn = app.buttons["Weigh-in"].firstMatch
            XCTAssertTrue(scrollTo(weighIn))
            weighIn.tap()
            assertScreen("Weigh-in")
        }
        func backToToday() {
            goBack()
            assertScreen("Getting started")
            goBack()
            assertScreen("Programme")
            goBack()
            assertScreen("Today")
        }
        openWeighIn()
        let unit = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Unit")).firstMatch
        XCTAssertTrue(scrollTo(unit))
        unit.tap()
        app.buttons["st lb"].firstMatch.tap()
        let stone = app.textFields["Stone"].firstMatch
        let pounds = app.textFields["Pounds"].firstMatch
        XCTAssertTrue(stone.waitForExistence(timeout: 5), "\"st lb\" shows the stone and pounds fields")
        for _ in 0..<4 where !stone.isHittable { app.swipeDown() }
        stone.tap()
        stone.typeText("10")
        pounds.tap()
        pounds.typeText("25")
        app.buttons["Save"].firstMatch.tap()
        let refusal = element(labelled: "That number is outside the range the app accepts. Check it and try again.")
        XCTAssertTrue(refusal.waitForExistence(timeout: 5), "10 st 25 lb shows the refusal")
        backToToday()
        openWeighIn()
        XCTAssertTrue(stone.waitForExistence(timeout: 5))
        XCTAssertNotEqual(stone.value as? String, "10", "10 st 25 lb saved nothing")
        stone.tap()
        stone.typeText("10")
        pounds.tap()
        pounds.typeText("13")
        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(refusal.waitForNonExistence(timeout: 5), "10 st 13 lb shows no refusal")
        backToToday()
        openWeighIn()
        XCTAssertTrue(stone.waitForExistence(timeout: 5))
        XCTAssertEqual(stone.value as? String, "10", "10 st 13 lb saved")
        XCTAssertEqual(pounds.value as? String, "13", "10 st 13 lb saved")
    }

    /// mm-t24.22, comment of mm-t24.37, item 3: onboarding screen 3 shows
    /// the quiet hours pickers at 22:00 and 07:00. mm-t14.28, comment of
    /// mm-t11.39: screen 3 shows "Today, <weekday date>", "Tomorrow,
    /// <weekday date>" and "A day runs from 04:00 to 03:59.". (The part "a
    /// new time keeps its hour and minute" turns the time wheel; it is on
    /// the follow-up bead.)
    func testOnboardingScreen3() throws {
        try launch(nil)
        let firstContinue = app.buttons["Continue"].firstMatch
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows")
        XCTAssertTrue(scrollTo(firstContinue))
        firstContinue.tap()
        // Screen 2: "No" to the three questions, then an age, a height and a
        // weight that exclude nothing. The questions come first, while no
        // keyboard covers the lower part of the form.
        // "Continue" sits over the bottom of the form; a row under it takes
        // no tap.
        let continueButton = app.buttons["Continue"].firstMatch
        for question in 1...3 {
            var answered = false
            for _ in 0..<8 {
                let open = app.buttons.matching(NSPredicate(format: "label == %@", "No")).allElementsBoundByIndex
                    .filter { $0.isHittable && !$0.isSelected && $0.frame.maxY < continueButton.frame.minY - 8 }
                    .sorted { $0.frame.minY < $1.frame.minY }
                if let first = open.first {
                    first.tap()
                    answered = true
                    break
                }
                app.swipeUp()
            }
            XCTAssertTrue(answered, "screen 2 shows question \(question) with \"No\"")
        }
        // The fields from the bottom up, so that each field is above the
        // number pad of the field before it.
        for (label, value) in [("Weight in kilograms", "65"), ("Height in centimetres", "170"), ("How old are you?", "30")] {
            let field = app.textFields[label].firstMatch
            for _ in 0..<8 where !(field.exists && field.isHittable) { app.swipeDown() }
            XCTAssertTrue(field.isHittable, "screen 2 shows \"\(label)\"")
            field.tap()
            field.typeText(value)
        }
        app.buttons["Continue"].firstMatch.tap()
        assertScreen("Your start")
        XCTAssertTrue(element(labelBeginningWith: "Today, ").waitForExistence(timeout: 5), "screen 3 shows \"Today, <weekday date>\"")
        XCTAssertTrue(element(labelBeginningWith: "Tomorrow, ").exists, "screen 3 shows \"Tomorrow, <weekday date>\"")
        XCTAssertTrue(scrollTo(element(labelled: "A day runs from 04:00 to 03:59.")), "screen 3 shows the day boundary line")
        let pickers = app.buttons.matching(NSPredicate(format: "label == %@", "Time Picker"))
        for _ in 0..<8 where pickers.count < 2 { app.swipeUp() }
        XCTAssertEqual(pickers.allElementsBoundByIndex.map { $0.value as? String }, ["22:00", "07:00"], "the quiet hours pickers show 22:00 and 07:00")
    }

    /// mm-t32.17, comment of mm-t32.19: after an answer under "What made
    /// things harder?", "I'm getting worse" and "Done" on the GP page, the
    /// review is not finished: back on Today, the "Weekly review" line still
    /// shows, and the review opens again with the answer. (The seeded
    /// record holds no earlier review, so no pinned note shows.)
    func testGettingWorseKeepsTheReviewDue() throws {
        try launchOnToday("review")
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        let harder = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)", "What made things harder?", XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
        XCTAssertTrue(scrollTo(harder))
        harder.tap()
        dismissKeyboardTip()
        harder.typeText("Late shifts")
        let worse = app.buttons["I'm getting worse"].firstMatch
        XCTAssertTrue(dragTo(worse, above: app.buttons["Done"].firstMatch.frame.minY - 8), "the review shows \"I'm getting worse\"")
        worse.tap()
        XCTAssertTrue(element(labelled: "It might help to see your GP").waitForExistence(timeout: 8), "the GP suggestion page shows")
        // The review's own "Done" stays in the hierarchy under the page, so
        // the page's "Done" is found inside the page.
        let page = app.scrollViews.containing(NSPredicate(format: "label == %@", "It might help to see your GP")).firstMatch
        let done = page.buttons["Done"].firstMatch
        XCTAssertTrue(scrollTo(done), "the GP suggestion page shows \"Done\"")
        done.tap()
        XCTAssertTrue(element(labelled: "It might help to see your GP").waitForNonExistence(timeout: 5))
        assertScreen("Weekly review")
        goBack()
        assertScreen("Today")
        let line = app.buttons["Weekly review"].firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 5), "Today still shows the \"Weekly review\" line")
        line.tap()
        assertScreen("Weekly review")
        XCTAssertTrue(scrollTo(harder))
        XCTAssertEqual(harder.value as? String, "Late shifts", "the review keeps the answer")
    }

    /// mm-t32.17, comment of mm-t32.20: after "No" to the self-harm item
    /// and "Done", the review opens again from the "Reviews" list; after a
    /// second "Done", it opens a third time. Each time the item shows "You
    /// answered this.".
    func testTheAnsweredSelfHarmItemStaysAnswered() throws {
        try launchOnToday("review")
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        tapReviewSelfHarmRow(step: 1, answer: "No")
        app.buttons["Done"].firstMatch.tap()
        assertScreen("Today")
        tapToolbar("Reviews")
        assertScreen("Reviews")
        for open in 2...3 {
            let row = element(labelBeginningWith: "Week 1")
            XCTAssertTrue(row.waitForExistence(timeout: 5), "the \"Reviews\" list shows the week 1 review")
            row.tap()
            assertScreen("Weekly review")
            let answered = element(labelled: "You answered this.")
            XCTAssertTrue(scrollTo(answered), "open \(open): the self-harm item shows \"You answered this.\"")
            app.buttons["Done"].firstMatch.tap()
            assertScreen("Reviews")
        }
    }

    /// mm-t32.17, comment of mm-t32.24: at the review, step 1 "Yes", step
    /// 2 "No", then step 1 "No" and "Yes" again: step 2 shows again with no
    /// answer. (The same check at the restart re-screen is on the follow-up
    /// bead.)
    func testStepTwoLosesItsAnswerWhenStepOneChanges() throws {
        try launchOnToday("review")
        app.buttons["Weekly review"].firstMatch.tap()
        assertScreen("Weekly review")
        tapReviewSelfHarmRow(step: 1, answer: "Yes")
        tapReviewSelfHarmRow(step: 2, answer: "No")
        XCTAssertTrue(reviewSelfHarmRows(step: 2).first?.isSelected ?? false, "step 2 holds \"No\"")
        tapReviewSelfHarmRow(step: 1, answer: "No")
        XCTAssertTrue(reviewSelfHarmRows(step: 2).isEmpty, "step 2 hides after step 1 \"No\"")
        tapReviewSelfHarmRow(step: 1, answer: "Yes")
        let stepTwo = reviewSelfHarmRows(step: 2)
        XCTAssertEqual(stepTwo.count, 2, "step 2 shows again")
        XCTAssertFalse(stepTwo.contains { $0.isSelected }, "step 2 shows no answer")
    }
}
