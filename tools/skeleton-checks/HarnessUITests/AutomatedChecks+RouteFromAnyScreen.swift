import XCTest

/// Ruling r20-01 (9 October 2026, bug mm-t45.12): a reminder tap empties
/// Today's navigation path first, then opens its own screen (the weigh-in
/// screen, the review, the plan builder, Close the day, Today). An open
/// new-entry sheet with a draft stays, and the route waits until that
/// sheet closes. The app-lock pending-route rule for "Add" does not
/// change (`testTheReminderAddOverASheet` in `AutomatedChecks+AppLock.swift`).
///
/// These tests start each tap while another screen is on Today's stack
/// ("Programme", "Getting started", "Settings" and the privacy notice,
/// "Reviews"), or while the new-entry sheet holds a draft. The taps that
/// start on Today are in `AutomatedChecks+ReminderTaps.swift`.
///
/// The reminders are simulated notifications, as in
/// `AutomatedChecks+ReminderTaps.swift`: the test writes the payload into
/// `$OUT/push`, and `push-relay.sh` sends it with `xcrun simctl push`. Each
/// payload has the category and the userInfo of the app's own reminder of
/// that kind (`Scheduler.requests`), and its own body text ("Route check
/// <code>"), so the test taps only its own banner. Each tap is from the
/// background, with the app lock off. A tap on a real banner stays a device
/// check of mm-t22.16 and mm-t24.22.
extension AutomatedChecks {
    // MARK: Helpers (private to this file)

    /// The record day key ("yyyy-MM-dd") of the current record day, in the
    /// Mac's zone. The seeded stores keep the default day start, 04:00.
    private func routeTapDayKey() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let day = Date().addingTimeInterval(-4 * 3600)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }

    /// The userInfo of the app's own reminder of `kind` (not a planned
    /// meal) on the current record day.
    private func routeTapUserInfo(_ kind: String) -> [String: String] {
        ["dayKey": routeTapDayKey(), "kind": kind]
    }

    /// The userInfo of the app's own planned meal reminder
    /// (`ReminderUserInfo.dictionary`): Lunch at 13:00 on the current
    /// record day, Mid-afternoon next at 16:00. A tap on it opens Today.
    private var routeTapPlannedMealUserInfo: [String: String] {
        ["dayKey": routeTapDayKey(), "slotIndex": "2", "plannedTime": "13:00", "nextPlannedTime": "16:00",
         "snoozeCount": "0", "quietHours": "22:00-07:00", "snoozeMinutes": "15"]
    }

    /// Goes to the Home Screen, sends a simulated reminder with `category`
    /// and `userInfo` through `push-relay.sh`, taps its banner, and waits
    /// until the app is in front again.
    private func tapARouteReminder(category: String = "openOnly", userInfo: [String: String], _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCUIDevice.shared.press(.home)
        let icon = springboard.icons["Midmorning"].firstMatch
        XCTAssertTrue(icon.waitForExistence(timeout: 10), "\(message): the Home Screen shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 1)
        let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["OUT_DIR"]!).appendingPathComponent("push")
        let name = UUID().uuidString
        let marker = "Route check \(name.prefix(6))"
        var payload: [String: Any] = userInfo
        payload["aps"] = [
            "alert": ["title": "Midmorning", "body": marker],
            "category": category, "sound": "default", "thread-id": "uk.midmorning.reminders",
        ] as [String: Any]
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let temporary = folder.appendingPathComponent("\(name).tmp")
            try JSONSerialization.data(withJSONObject: payload).write(to: temporary)
            try FileManager.default.moveItem(at: temporary, to: folder.appendingPathComponent("\(name).apns"))
        } catch {
            XCTFail("\(message): cannot write the reminder payload: \(error)", file: file, line: line)
            return
        }
        let sent = folder.appendingPathComponent("\(name).sent")
        let deadline = Date().addingTimeInterval(20)
        while !FileManager.default.fileExists(atPath: sent.path), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.3)
        }
        let output = (try? String(contentsOf: folder.appendingPathComponent("\(name).out"), encoding: .utf8)) ?? "no output; is push-relay.sh running?"
        XCTAssertTrue(FileManager.default.fileExists(atPath: sent.path), "\(message): push-relay.sh sends the reminder: \(output)", file: file, line: line)
        let banner = springboard.descendants(matching: .any).matching(identifier: "NotificationShortLookView")
            .matching(NSPredicate(format: "label CONTAINS %@", marker)).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 15), "\(message): the reminder \"\(marker)\" shows its banner", file: file, line: line)
        banner.tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20), "\(message): the app comes to the front", file: file, line: line)
    }

    /// Only Today shows: one navigation bar, "Today", and no new-entry
    /// screen.
    private func assertOnlyTodayShowsAfterTheRoute(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 15), "\(message): Today shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(app.navigationBars.count, 1, "\(message): only Today shows: \(app.navigationBars.allElementsBoundByIndex.map(\.identifier))", file: file, line: line)
        XCTAssertFalse(app.switches["felt like a binge"].exists, "\(message): no new-entry screen shows", file: file, line: line)
    }

    /// The screen `title` shows on Today's stack: one Back goes to Today,
    /// and not to the screen that showed before the tap (`before`). The
    /// test waits 2 seconds before Back, because in step (3) of
    /// `testReminderTapFromAnotherScreenGoesBackToToday` the weigh-in
    /// screen already shows before the tap.
    private func assertTheRouteOpensOnToday(_ title: String, before: String?, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let bar = app.navigationBars[title]
        XCTAssertTrue(bar.waitForExistence(timeout: 20), "\(message): \"\(title)\" shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 2)
        let back = bar.buttons.element(boundBy: 0)
        XCTAssertTrue(back.exists, "\(message): \"\(title)\" has a Back control", file: file, line: line)
        if let before {
            XCTAssertNotEqual(back.label, before, "\(message): the Back control of \"\(title)\" does not go back to \"\(before)\"", file: file, line: line)
        }
        XCTAssertTrue(["Today", "Back"].contains(back.label), "\(message): the Back control of \"\(title)\" goes back to Today: \"\(back.label)\"", file: file, line: line)
        back.tap()
        XCTAssertTrue(bar.waitForNonExistence(timeout: 8), "\(message): Back closes \"\(title)\"", file: file, line: line)
        if let before {
            XCTAssertFalse(app.navigationBars[before].exists, "\(message): after Back, \"\(before)\" does not show", file: file, line: line)
        }
        assertOnlyTodayShowsAfterTheRoute("\(message), after Back", file: file, line: line)
    }

    /// Taps `control` in Today's bottom toolbar and waits for its screen.
    private func openFromTheToolbar(_ control: String, file: StaticString = #filePath, line: UInt = #line) {
        tapToolbar(control)
        XCTAssertTrue(app.navigationBars[control].waitForExistence(timeout: 8), "the screen \"\(control)\" shows", file: file, line: line)
    }

    /// Opens "Add an entry" on Today and types `what` into What: the
    /// new-entry sheet holds a draft.
    private func openANewEntryDraft(_ what: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        openNewEntry(file: file, line: line)
        let field = app.textViews["What"].firstMatch
        field.tap()
        field.typeText(what)
        XCTAssertEqual(field.value as? String, what, "the new-entry sheet holds the draft \"\(what)\"", file: file, line: line)
        return field
    }

    /// After a tap while the new-entry sheet holds `draft`: the sheet still
    /// shows with its draft, and the route's screen (`waiting`) does not
    /// show under the sheet.
    private func assertTheDraftStays(_ field: XCUIElement, holds draft: String, waiting: String?, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(field.waitForExistence(timeout: 15), "\(message): the new-entry sheet still shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(field.exists, "\(message): the new-entry sheet stays", file: file, line: line)
        XCTAssertEqual(field.value as? String, draft, "\(message): the sheet still holds the draft \"\(draft)\"", file: file, line: line)
        if let waiting {
            XCTAssertFalse(app.navigationBars[waiting].exists, "\(message): \"\(waiting)\" does not open under the sheet; the route waits", file: file, line: line)
        }
    }

    // MARK: mm-t45.12: a tap while another screen is on Today's stack

    /// Ruling r20-01 (mm-t45.12), the steps of the bug: seeded store
    /// `week1` (stage 1, the weigh-in day is today). (1) On "Programme",
    /// tap a planned meal reminder: only Today shows, and "Programme" does
    /// not stay. (2) On "Programme", tap the weigh-in day reminder: the
    /// weigh-in screen opens, and Back goes to Today, not to "Programme".
    /// (3) Three screens deep ("Programme", "Getting started", "Weigh-in"),
    /// tap the weigh-in day reminder: the weigh-in screen opens on Today,
    /// and Back goes to Today. (4) On the privacy notice under "Settings",
    /// tap a planned meal reminder: only Today shows. Reminders spec,
    /// "Actions on a planned meal reminder": "A tap on the reminder itself
    /// MUST open Today." "The weigh-in day reminder": "A tap MUST open the
    /// weigh-in screen."
    func testReminderTapFromAnotherScreenGoesBackToToday() throws {
        try launchOnToday("week1")
        allowNotificationsFromToday()
        // (1)
        openFromTheToolbar("Programme")
        tapARouteReminder(category: "plannedMeal", userInfo: routeTapPlannedMealUserInfo, "(1) a planned meal reminder on \"Programme\"")
        assertOnlyTodayShowsAfterTheRoute("(1) a planned meal reminder on \"Programme\"")
        // (2)
        openFromTheToolbar("Programme")
        tapARouteReminder(userInfo: routeTapUserInfo("weighInDay"), "(2) the weigh-in day reminder on \"Programme\"")
        XCTAssertTrue(app.textFields["Weight"].firstMatch.waitForExistence(timeout: 20), "(2) the weigh-in screen shows the weight input")
        assertTheRouteOpensOnToday("Weigh-in", before: "Programme", "(2) the weigh-in day reminder on \"Programme\"")
        // (3)
        openFromTheToolbar("Programme")
        element(labelBeginningWith: "Getting started").tap()
        assertScreen("Getting started")
        let weighIn = app.buttons["Weigh-in"].firstMatch
        XCTAssertTrue(scrollTo(weighIn), "(3) \"Getting started\" shows \"Weigh-in\"")
        weighIn.tap()
        assertScreen("Weigh-in")
        tapARouteReminder(userInfo: routeTapUserInfo("weighInDay"), "(3) the weigh-in day reminder three screens deep")
        assertTheRouteOpensOnToday("Weigh-in", before: "Getting started", "(3) the weigh-in day reminder three screens deep")
        // (4)
        openFromTheToolbar("Settings")
        let privacy = app.buttons["Privacy"].firstMatch
        XCTAssertTrue(scrollTo(privacy), "(4) Settings shows \"Privacy\"")
        privacy.tap()
        assertScreen("Privacy notice")
        tapARouteReminder(category: "plannedMeal", userInfo: routeTapPlannedMealUserInfo, "(4) a planned meal reminder on the privacy notice")
        assertOnlyTodayShowsAfterTheRoute("(4) a planned meal reminder on the privacy notice")
    }

    /// Ruling r20-01 (mm-t45.12), the other screens that the ruling names:
    /// seeded store `review` (stage 2 open, the review of week 1 due). Each
    /// tap starts on "Programme" or on "Reviews". (1) The weekly review
    /// reminder opens the review, and Back goes to Today. (2) The morning
    /// plan reminder opens "Today's plan" over Today; Cancel shows only
    /// Today. (3) The close-the-day reminder opens the close-the-day screen
    /// over Today; Done shows only Today. (4) The midday reminder opens the
    /// new-entry screen over Today; Cancel shows only Today.
    func testReminderTapFromAnotherScreenOpensItsScreenOnToday() throws {
        try launchOnToday("review")
        allowNotificationsFromToday()
        // (1)
        openFromTheToolbar("Reviews")
        tapARouteReminder(userInfo: routeTapUserInfo("weeklyReview"), "(1) the weekly review reminder on \"Reviews\"")
        assertTheRouteOpensOnToday("Weekly review", before: "Reviews", "(1) the weekly review reminder on \"Reviews\"")
        // (2)
        openFromTheToolbar("Programme")
        tapARouteReminder(userInfo: routeTapUserInfo("morningPlan"), "(2) the morning plan reminder on \"Programme\"")
        XCTAssertTrue(app.navigationBars["Today's plan"].waitForExistence(timeout: 20), "(2) \"Today's plan\" opens")
        app.navigationBars["Today's plan"].buttons["Cancel"].tap()
        assertOnlyTodayShowsAfterTheRoute("(2) after Cancel on \"Today's plan\"")
        // (3)
        openFromTheToolbar("Programme")
        tapARouteReminder(userInfo: routeTapUserInfo("closeTheDay"), "(3) the close-the-day reminder on \"Programme\"")
        XCTAssertTrue(app.navigationBars["Close the day"].waitForExistence(timeout: 20), "(3) the close-the-day screen opens")
        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5), "(3) the close-the-day screen shows \"Done\"")
        done.tap()
        assertOnlyTodayShowsAfterTheRoute("(3) after Done on the close-the-day screen")
        // (4)
        openFromTheToolbar("Programme")
        tapARouteReminder(userInfo: routeTapUserInfo("midday"), "(4) the midday reminder on \"Programme\"")
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 20), "(4) the new-entry screen opens")
        dismissKeyboardTip()
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        assertOnlyTodayShowsAfterTheRoute("(4) after Cancel on the new-entry screen")
    }

    // MARK: mm-t45.12: a tap while the new-entry sheet holds a draft

    /// Ruling r20-01 (mm-t45.12): "An open new-entry sheet with a draft
    /// stays, and the route waits until that sheet closes." Seeded store
    /// `week1`. (1) With "Soup" in What, tap the weigh-in day reminder: the
    /// sheet stays with "Soup", and the weigh-in screen does not open
    /// under it. Cancel: the weigh-in screen opens on Today, and Back goes
    /// to Today. (2) With "Bread" in What, tap a planned meal reminder: the
    /// sheet stays with "Bread". Save: Today shows the entry "Bread", and
    /// only Today shows.
    func testReminderTapWaitsForTheNewEntrySheetWithADraft() throws {
        try launchOnToday("week1")
        allowNotificationsFromToday()
        // (1)
        let soup = openANewEntryDraft("Soup")
        tapARouteReminder(userInfo: routeTapUserInfo("weighInDay"), "(1) the weigh-in day reminder over the draft \"Soup\"")
        assertTheDraftStays(soup, holds: "Soup", waiting: "Weigh-in", "(1) the weigh-in day reminder over the draft \"Soup\"")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 8), "(1) Cancel closes the new-entry sheet")
        XCTAssertTrue(app.textFields["Weight"].firstMatch.waitForExistence(timeout: 15), "(1) after the sheet closes, the weigh-in screen opens with the weight input")
        assertTheRouteOpensOnToday("Weigh-in", before: nil, "(1) the route after the sheet closes")
        XCTAssertEqual(todayRows(what: "Soup"), 0, "(1) Cancel saves no entry")
        // (2)
        let bread = openANewEntryDraft("Bread")
        tapARouteReminder(category: "plannedMeal", userInfo: routeTapPlannedMealUserInfo, "(2) a planned meal reminder over the draft \"Bread\"")
        assertTheDraftStays(bread, holds: "Bread", waiting: nil, "(2) a planned meal reminder over the draft \"Bread\"")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 8), "(2) Save closes the new-entry sheet")
        assertOnlyTodayShowsAfterTheRoute("(2) the route after the sheet closes")
        XCTAssertEqual(todayRows(what: "Bread"), 1, "(2) Today shows the saved entry \"Bread\"")
    }
}
