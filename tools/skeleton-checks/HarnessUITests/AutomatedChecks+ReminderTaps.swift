import XCTest

/// Rulings r13-19 and r16-01 (epic mm-t45, mm-t45.9): the reminder taps of
/// the device-check beads mm-t22.16 (mm-t22.22), mm-t32.17 (mm-t32.21) and
/// mm-t24.22 (mm-t24.29), with the app lock off, as UI tests on the
/// simulator. Each test names its bead and the check that it replaces. The
/// taps with the app lock on are in `AutomatedChecks+AppLock.swift`.
///
/// The reminders are simulated notifications. A UI test cannot run `xcrun
/// simctl`, so it writes the payload into `$OUT/push` (`OUT_DIR` +
/// "/push"), and `tools/skeleton-checks/push-relay.sh`, which
/// `automated-checks.sh` starts before the checks, sends it with `xcrun
/// simctl push`. Each payload has the category and the userInfo that the
/// app's scheduler gives the real reminder of that kind
/// (`Scheduler.requests`): "dayKey" and "kind" for each kind but a planned
/// meal, and the seven keys of `ReminderUserInfo` (and no "kind") for a
/// planned meal. The app's notification delegate reads the same keys from
/// a simulated notification as from a real one, so a tap takes the same
/// route (`ReminderTapRoute`, `ReminderRouteOpening`). These parts stay
/// device checks: that the app schedules the reminder and that the system
/// delivers it at its real time, a tap on a real banner or on a Lock
/// Screen item, and a tap on the far reminder. The app finds the far
/// reminder by its request identifier "far.<day key>", and `xcrun simctl
/// push` cannot set that identifier: on 7 October 2026 the simulator gave a
/// new UUID as the identifier of a simulated notification, also with
/// "apns-collapse-id" in the payload. The package test
/// `ReminderTapRouteTests` gives the far reminder's route, Today.
///
/// Each test starts the taps on Today. A tap while another screen is on
/// Today's stack (for example "Programme") is bug mm-t45.12.
///
/// "From the background": the test launches the app, goes to the Home
/// Screen and taps the banner there. "From a cold launch": the test stops
/// the app, as a force-quit does, and taps the banner; the system starts
/// the app. An app that a tap starts has no launch environment: no locale
/// arguments, no `TZ` and no app-lock test seam. So the tests that do a
/// cold launch use stores that are seeded in the Mac's zone (the
/// simulator's zone), with the app lock off, and their checks do not
/// depend on the locale.
///
/// Each banner has its own body text ("Reminder check <code>"), and the
/// test taps the banner with that text. So a real reminder that the app
/// scheduled cannot take the tap. The route does not read the title or
/// the body; the discreet text of the real reminders stays a device check.
///
/// The notification permission: `automated-checks.sh` installs the app
/// new for each run. Each test allows notifications from Today's line when
/// Today asks (`allowNotificationsFromToday`); the system shows no banner
/// without the permission. Tests in other files also allow them, so the
/// order of the tests does not change a result here.
extension AutomatedChecks {
    // MARK: Helpers (private to this file)

    private var reminderTapEnvironment: [String: String] { ProcessInfo.processInfo.environment }

    /// The launch marker in the app's container (`StoreLayout`). `launch`
    /// removes it before each launch; a cold launch does the same.
    private var reminderTapLaunchMarker: URL {
        URL(fileURLWithPath: reminderTapEnvironment["APP_DATA"]!).appendingPathComponent("Library/Application Support/LaunchMarker")
    }

    /// The record day key ("yyyy-MM-dd") `offset` record days from the
    /// current one, in `zone` (the Mac's zone unless given). The seeded
    /// stores keep the default day start, 04:00.
    private func reminderTapDayKey(_ offset: Int = 0, in zone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let day = calendar.date(byAdding: .day, value: offset, to: Date().addingTimeInterval(-4 * 3600))!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = zone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }

    /// The day heading of the record day `dayKey` ("Tuesday 6 October"), as
    /// the app writes it in each locale (`DayKeyText.weekdayAndDate`).
    private func reminderTapHeading(forDayKey dayKey: String, in zone: TimeZone = .current) -> String {
        let parse = DateFormatter()
        parse.locale = Locale(identifier: "en_US_POSIX")
        parse.timeZone = zone
        parse.dateFormat = "yyyy-MM-dd HH:mm"
        let noon = parse.date(from: "\(dayKey) 12:00")!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = zone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: noon)
    }

    /// The userInfo of the app's own reminder of `kind` (not a planned
    /// meal) on the record day `dayKey` (`Scheduler.requests`).
    private func reminderTapUserInfo(_ kind: String, dayKey: String) -> [String: String] {
        ["dayKey": dayKey, "kind": kind]
    }

    /// The userInfo of the app's own planned meal reminder
    /// (`ReminderUserInfo.dictionary`): Lunch (slot 2) at 13:00 on the
    /// record day `dayKey`, Mid-afternoon next at 16:00, no snooze yet, the
    /// default quiet hours and "Remind me again in" 15 minutes. It holds no
    /// "kind" and no label.
    private func reminderTapPlannedMealUserInfo(dayKey: String) -> [String: String] {
        ["dayKey": dayKey, "slotIndex": "2", "plannedTime": "13:00", "nextPlannedTime": "16:00",
         "snoozeCount": "0", "quietHours": "22:00-07:00", "snoozeMinutes": "15"]
    }

    /// Sends a simulated reminder with `category` and `userInfo` through
    /// `push-relay.sh`. Returns the body text of its banner.
    private func sendASimulatedReminder(category: String, userInfo: [String: String], file: StaticString = #filePath, line: UInt = #line) -> String {
        let folder = URL(fileURLWithPath: reminderTapEnvironment["OUT_DIR"]!).appendingPathComponent("push")
        let name = UUID().uuidString
        let marker = "Reminder check \(name.prefix(6))"
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
            XCTFail("cannot write the reminder payload: \(error)", file: file, line: line)
            return marker
        }
        let sent = folder.appendingPathComponent("\(name).sent")
        let deadline = Date().addingTimeInterval(20)
        while !FileManager.default.fileExists(atPath: sent.path), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.3)
        }
        let output = (try? String(contentsOf: folder.appendingPathComponent("\(name).out"), encoding: .utf8)) ?? "no output; is push-relay.sh running?"
        XCTAssertTrue(FileManager.default.fileExists(atPath: sent.path), "push-relay.sh sends the reminder: \(output)", file: file, line: line)
        return marker
    }

    /// The banner of the simulated reminder whose body is `marker`.
    private func reminderTapBanner(_ marker: String) -> XCUIElement {
        springboard.descendants(matching: .any).matching(identifier: "NotificationShortLookView")
            .matching(NSPredicate(format: "label CONTAINS %@", marker)).firstMatch
    }

    /// Sends a simulated reminder and taps its banner.
    private func tapASimulatedReminder(category: String = "openOnly", userInfo: [String: String], file: StaticString = #filePath, line: UInt = #line) {
        let marker = sendASimulatedReminder(category: category, userInfo: userInfo, file: file, line: line)
        let banner = reminderTapBanner(marker)
        XCTAssertTrue(banner.waitForExistence(timeout: 15), "the reminder \"\(marker)\" shows its banner", file: file, line: line)
        banner.tap()
    }

    /// Sends a simulated planned meal reminder, opens its actions with a
    /// long press on the banner, and taps "Add".
    private func tapAddOnASimulatedPlannedMealReminder(dayKey: String, file: StaticString = #filePath, line: UInt = #line) {
        let marker = sendASimulatedReminder(category: "plannedMeal", userInfo: reminderTapPlannedMealUserInfo(dayKey: dayKey), file: file, line: line)
        let banner = reminderTapBanner(marker)
        XCTAssertTrue(banner.waitForExistence(timeout: 15), "the planned meal reminder \"\(marker)\" shows its banner", file: file, line: line)
        banner.press(forDuration: 1.2)
        let add = springboard.buttons["Add"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), "the planned meal reminder offers \"Add\"", file: file, line: line)
        add.tap()
    }

    /// Goes to the Home Screen. The app stays in the background. (The
    /// app's `state` can still read "running in the foreground" for some
    /// seconds, so the check is that the Home Screen shows the app's icon.)
    private func putTheAppInTheBackground(file: StaticString = #filePath, line: UInt = #line) {
        XCUIDevice.shared.press(.home)
        let icon = springboard.icons["Midmorning"].firstMatch
        XCTAssertTrue(icon.waitForExistence(timeout: 10), "the Home Screen shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(icon.isHittable, "the Home Screen shows, and the app is in the background", file: file, line: line)
    }

    /// Stops the app, as a force-quit does. The next tap on a reminder
    /// starts it again with no launch environment.
    private func forceQuitTheApp(file: StaticString = #filePath, line: UInt = #line) {
        app.terminate()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "the app stops", file: file, line: line)
        try? FileManager.default.removeItem(at: reminderTapLaunchMarker)
    }

    /// After a tap on a banner: the app is in front.
    private func assertTheAppIsInFront(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20), "\(message): the app comes to the front", file: file, line: line)
    }

    /// Today shows, and no other screen: one navigation bar, and no
    /// new-entry screen.
    private func assertOnlyTodayShows(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 15), "\(message): Today shows", file: file, line: line)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(app.navigationBars.count, 1, "\(message): only Today shows: \(app.navigationBars.allElementsBoundByIndex.map(\.identifier))", file: file, line: line)
        XCTAssertFalse(app.switches["felt like a binge"].exists, "\(message): no new-entry screen opens", file: file, line: line)
    }

    /// The screen `title` is on Today's own navigation stack: its
    /// navigation bar has a Back control, and a tap on it shows Today.
    private func assertBackToToday(from title: String, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let bar = app.navigationBars[title]
        XCTAssertTrue(bar.waitForExistence(timeout: 15), "\(message): \"\(title)\" shows", file: file, line: line)
        let back = bar.buttons.element(boundBy: 0)
        XCTAssertTrue(back.exists, "\(message): \"\(title)\" has a Back control", file: file, line: line)
        XCTAssertTrue(["Today", "Back"].contains(back.label), "\(message): the Back control of \"\(title)\" goes back to Today: \"\(back.label)\"", file: file, line: line)
        back.tap()
        XCTAssertTrue(bar.waitForNonExistence(timeout: 8), "\(message): Back closes \"\(title)\"", file: file, line: line)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 8), "\(message): after Back, Today shows", file: file, line: line)
    }

    /// The new-entry screen that "Add" opens: empty, with the keyboard in
    /// What, at the current time (reminders spec, "Add").
    private func assertTheAddScreenAtTheCurrentTime(opened: Date, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 15), "\(message): the new-entry screen shows", file: file, line: line)
        dismissKeyboardTip()
        let what = app.textViews["What"].firstMatch
        XCTAssertEqual((what.value as? String) ?? "", "", "\(message): the new-entry screen is empty", file: file, line: line)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "\(message): the keyboard shows", file: file, line: line)
        XCTAssertEqual(what.value(forKey: "hasKeyboardFocus") as? Bool, true, "\(message): the keyboard is in What", file: file, line: line)
        let clock = DateFormatter()
        clock.locale = Locale(identifier: "en_GB")
        clock.dateFormat = "HH:mm"
        let nearNow = (-1...2).map { clock.string(from: opened.addingTimeInterval(Double($0) * 60)) }
        let value = app.otherElements["Time"].firstMatch.value as? String ?? ""
        XCTAssertTrue(nearNow.contains { value.hasSuffix(", \($0)") }, "\(message): the new-entry screen opens at the current time, not at the planned time 13:00: \(value)", file: file, line: line)
    }

    /// The close-the-day screen for the record day `dayKey`: its column
    /// has the heading of that day.
    private func assertTheCloseTheDayScreen(forDayKey dayKey: String, in zone: TimeZone = .current, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.navigationBars["Close the day"].waitForExistence(timeout: 15), "\(message): the close-the-day screen opens", file: file, line: line)
        let heading = reminderTapHeading(forDayKey: dayKey, in: zone)
        let shown = app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", heading)).firstMatch
        XCTAssertTrue(shown.waitForExistence(timeout: 5), "\(message): the close-the-day screen is for the record day \(dayKey) (\"\(heading)\")", file: file, line: line)
    }

    /// Closes the close-the-day screen with "Done".
    private func closeTheCloseTheDayScreen(file: StaticString = #filePath, line: UInt = #line) {
        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5), "the close-the-day screen shows \"Done\"", file: file, line: line)
        done.tap()
        XCTAssertTrue(app.navigationBars["Close the day"].waitForNonExistence(timeout: 8), "\"Done\" closes the close-the-day screen", file: file, line: line)
    }

    // MARK: mm-t22.16, mm-t22.22: the weigh-in day reminder

    /// mm-t22.16, comment of 15:27 (mm-t22.22), the weigh-in part, with the
    /// app lock off: "on the weigh-in day, tap the weigh-in day reminder.
    /// The weigh-in screen opens on Today's stack with a Back control. Tap
    /// Back: Today shows." The seeded store `week1` has the weigh-in day on
    /// the current record day's weekday. From the background, and from a
    /// cold launch. Reminders spec, "The weigh-in day reminder": "A tap
    /// MUST open the weigh-in screen."
    func testReminderTapOpensTheWeighInScreenOnTodaysStack() throws {
        let weighIn = reminderTapUserInfo("weighInDay", dayKey: reminderTapDayKey())
        try launchOnToday("week1")
        allowNotificationsFromToday()
        // From the background.
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weighIn)
        assertTheAppIsInFront("a tap on the weigh-in day reminder from the background")
        XCTAssertTrue(app.navigationBars["Weigh-in"].waitForExistence(timeout: 15), "from the background, the weigh-in day reminder opens the weigh-in screen")
        XCTAssertTrue(app.textFields["Weight"].firstMatch.waitForExistence(timeout: 5), "the weigh-in screen shows the weight input on the weigh-in day")
        assertBackToToday(from: "Weigh-in", "from the background")
        // From a cold launch.
        forceQuitTheApp()
        tapASimulatedReminder(userInfo: weighIn)
        assertTheAppIsInFront("a tap on the weigh-in day reminder after a force-quit")
        XCTAssertTrue(app.navigationBars["Weigh-in"].waitForExistence(timeout: 20), "from a cold launch, the weigh-in day reminder opens the weigh-in screen")
        XCTAssertTrue(app.textFields["Weight"].firstMatch.waitForExistence(timeout: 5), "the weigh-in screen shows the weight input on the weigh-in day")
        assertBackToToday(from: "Weigh-in", "from a cold launch")
    }

    // MARK: mm-t22.16, mm-t22.22: the weekly review reminder

    /// mm-t22.16, comment of 15:27 (mm-t22.22), the weekly review part,
    /// with the app lock off: "tap the weekly review reminder while a
    /// review is due. The review of that week opens with a Back control.
    /// Finish the review, then tap the same delivered reminder again: the
    /// finished review of the same week opens, not week 1." The seeded
    /// store `or-pinned` is in week 3: the review of week 1 is finished
    /// ("Week one harder" under "What made things harder?"), and the review
    /// of week 2 is due since the previous record day. So "not week 1" can
    /// show: the review of week 2 asks no week-1 question, and it shows its
    /// own answer. The reminder's userInfo names the due day of week 2. Each
    /// tap from the background and from a cold launch. Reminders spec, "The
    /// weekly review reminder": "A tap MUST open the weekly review."
    /// (A simulated reminder is a new notification each time; that a real
    /// delivered reminder stays in Notification Centre for a second tap
    /// stays a device check.)
    func testReminderTapOpensTheDueReviewAndThenTheFinishedReview() throws {
        let weeklyReview = reminderTapUserInfo("weeklyReview", dayKey: reminderTapDayKey(-1))
        let harder = "What made things harder?"
        let answer = "Week two answer"
        try launchOnToday("or-pinned")
        allowNotificationsFromToday()
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForExistence(timeout: 5), "Today shows that the review of week 2 is due")
        /// The review of week 2 shows: no week-1 question, and `expected`
        /// under "What made things harder?" (not week 1's "Week one harder").
        func assertTheReviewOfWeek2(holds expected: String, _ message: String) {
            XCTAssertTrue(app.navigationBars["Weekly review"].waitForExistence(timeout: 20), "\(message): the weekly review opens")
            XCTAssertFalse(app.textFields["What is hardest at the moment?"].exists, "\(message): the review asks no week-1 question, so it is not the review of week 1")
            let field = reveal(bar: "Done", self.field(harder))
            XCTAssertNotNil(field, "\(message): the review shows \"\(harder)\"")
            XCTAssertEqual(field?.value ?? "", expected, "\(message): the review of week 2 shows its own answer, not the answer of week 1")
        }

        // The due review, from a cold launch.
        forceQuitTheApp()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder after a force-quit")
        assertTheReviewOfWeek2(holds: "", "the due review from a cold launch")
        assertBackToToday(from: "Weekly review", "the due review from a cold launch")
        // The due review, from the background.
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder from the background")
        assertTheReviewOfWeek2(holds: "", "the due review from the background")
        // Finish the review.
        fill(harder, answer, bar: "Done")
        tapConfirm("Done")
        assertScreen("Today")
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForNonExistence(timeout: 5), "\"Done\" finishes the review of week 2")
        // The same reminder after the finish, from the background.
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder after the finish, from the background")
        assertTheReviewOfWeek2(holds: answer, "the finished review from the background")
        assertBackToToday(from: "Weekly review", "the finished review from the background")
        // The same reminder after the finish, from a cold launch.
        forceQuitTheApp()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder after the finish and a force-quit")
        assertTheReviewOfWeek2(holds: answer, "the finished review from a cold launch")
        assertBackToToday(from: "Weekly review", "the finished review from a cold launch")
    }

    // MARK: mm-t32.17, mm-t32.21: the GP page and the weekly review reminder

    /// mm-t32.17, comment of 15:27, item 3 (mm-t32.21), the part "from the
    /// reminder": with frozen starred counts 2, 3, 4 and 5 for weeks 2 to 5,
    /// the review of week 5 shows the GP page once. The seeded store
    /// `or-deterioration` is in week 6, and the review of week 5 is due. The
    /// first open is from the weekly review reminder: the GP page shows.
    /// After "Done" on the page and Back, each later open from the reminder
    /// (from the background and from a cold launch) and from Today shows no
    /// GP page, before and after "Done" on the review. Each open shows the
    /// review of week 5 ("Starred entries: 5 this week, 4 last week.").
    /// (`testTheDeteriorationPageShowsOnce` does the opens from Today and
    /// from the "Reviews" list.)
    func testReminderTapDoesNotShowTheGPPageAgain() throws {
        let heading = "It might help to see your GP"
        let weeklyReview = reminderTapUserInfo("weeklyReview", dayKey: reminderTapDayKey(-1))
        try launchOnToday("or-deterioration")
        allowNotificationsFromToday()
        /// The review of week 5 shows with no GP page.
        func assertTheReviewOfWeek5WithNoGPPage(_ message: String) {
            XCTAssertTrue(app.navigationBars["Weekly review"].waitForExistence(timeout: 20), "\(message): the weekly review opens")
            XCTAssertFalse(element(labelled: heading).waitForExistence(timeout: 3), "\(message): the GP page does not show again")
            XCTAssertNotNil(reveal(bar: "Done", { self.first(.staticText, "Starred entries: 5 this week, 4 last week.", in: $0) }), "\(message): the review of week 5 shows")
        }

        // The first open, from the reminder: the GP page shows.
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("the first tap on the weekly review reminder")
        XCTAssertTrue(element(labelled: heading).waitForExistence(timeout: 20), "the first open, from the reminder, shows the GP page")
        XCTAssertTrue(text("Your starred entries have gone up each week lately.").exists, "the page gives the deterioration reason")
        tapDoneOnThePage(heading)
        assertBackToToday(from: "Weekly review", "after the GP page")
        // From the reminder again, from the background.
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a second tap on the weekly review reminder")
        assertTheReviewOfWeek5WithNoGPPage("the reminder again, from the background")
        assertBackToToday(from: "Weekly review", "the reminder again, from the background")
        // From Today.
        openTheDueReview()
        assertTheReviewOfWeek5WithNoGPPage("an open from Today")
        assertBackToToday(from: "Weekly review", "an open from Today")
        // From the reminder again, from a cold launch.
        forceQuitTheApp()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder after a force-quit")
        assertTheReviewOfWeek5WithNoGPPage("the reminder again, from a cold launch")
        // After "Done" on the review, from the reminder.
        tapConfirm("Done")
        assertScreen("Today")
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForNonExistence(timeout: 5), "\"Done\" finishes the review of week 5")
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: weeklyReview)
        assertTheAppIsInFront("a tap on the weekly review reminder after the finish")
        assertTheReviewOfWeek5WithNoGPPage("the finished review, from the reminder")
    }

    // MARK: mm-t24.22, mm-t24.29: the other reminder taps

    /// One reminder of mm-t24.29 and the screen that its tap opens.
    private struct ReminderTapCase {
        let name: String
        let tap: () -> Void
        let check: (String) -> Void
        let close: () -> Void
    }

    /// The reminders of mm-t24.29 with the app lock off, on the seeded store
    /// `review` (stage 2 open, Mac zone), each with its check of the screen
    /// that the reminders spec names, and the way back to Today.
    private func mmT2429Cases() -> [ReminderTapCase] {
        let today = reminderTapDayKey()
        return [
            // Reminders spec, "The midday reminder": "A tap on the reminder
            // MUST open the new-entry screen."
            ReminderTapCase(name: "the midday reminder", tap: {
                self.tapASimulatedReminder(userInfo: self.reminderTapUserInfo("midday", dayKey: today))
            }, check: { message in
                XCTAssertTrue(self.app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 20), "\(message): the new-entry screen opens")
                self.dismissKeyboardTip()
            }, close: {
                self.app.navigationBars.buttons["Cancel"].firstMatch.tap()
            }),
            // Reminders spec, "Close the day": "A tap on the reminder MUST
            // open the close-the-day screen." The reminder names the
            // current record day.
            ReminderTapCase(name: "the close-the-day reminder", tap: {
                self.tapASimulatedReminder(userInfo: self.reminderTapUserInfo("closeTheDay", dayKey: today))
            }, check: { message in
                self.assertTheCloseTheDayScreen(forDayKey: today, message)
            }, close: {
                self.closeTheCloseTheDayScreen()
            }),
            // Reminders spec, "The morning plan reminder while the plan
            // needs setting": "A tap on the reminder MUST open 'Today's
            // plan'." Stage 2 is open in `review`.
            ReminderTapCase(name: "the morning plan reminder", tap: {
                self.tapASimulatedReminder(userInfo: self.reminderTapUserInfo("morningPlan", dayKey: today))
            }, check: { message in
                XCTAssertTrue(self.app.navigationBars["Today's plan"].waitForExistence(timeout: 20), "\(message): \"Today's plan\" opens")
            }, close: {
                self.app.navigationBars["Today's plan"].buttons["Cancel"].tap()
            }),
            // Reminders spec, "Actions on a planned meal reminder": "A tap
            // on the reminder itself MUST open Today."
            ReminderTapCase(name: "the planned meal reminder", tap: {
                self.tapASimulatedReminder(category: "plannedMeal", userInfo: self.reminderTapPlannedMealUserInfo(dayKey: today))
            }, check: { message in
                self.assertOnlyTodayShows(message)
            }, close: {}),
        ]
    }

    /// mm-t24.22, comment of 15:27 (mm-t24.29), with the app lock off, from
    /// the background: "tap the midday reminder; the new-entry screen
    /// opens. Tap the close-the-day reminder [...]; the close-the-day
    /// screen opens for that record day. In stage 2, tap the morning plan
    /// reminder; Today's plan opens. Tap a planned meal reminder [...];
    /// Today shows." Also "Add" on a planned meal reminder: the empty
    /// new-entry screen opens with the keyboard in What, at the current
    /// time (reminders spec, "Add"). The seeded store `review` has stage 2
    /// open. (The far reminder stays a device check: see the comment at the
    /// top of this file. The close-the-day tap before 04:00 is
    /// `testReminderTapOnCloseTheDayBefore0400`.)
    func testReminderTapsFromTheBackgroundWithTheAppLockOff() throws {
        try launchOnToday("review")
        allowNotificationsFromToday()
        for reminder in mmT2429Cases() {
            putTheAppInTheBackground()
            reminder.tap()
            let message = "a tap on \(reminder.name) from the background"
            assertTheAppIsInFront(message)
            reminder.check(message)
            reminder.close()
            assertScreen("Today")
        }
        putTheAppInTheBackground()
        let opened = Date()
        tapAddOnASimulatedPlannedMealReminder(dayKey: reminderTapDayKey())
        assertTheAppIsInFront("\"Add\" on a planned meal reminder from the background")
        assertTheAddScreenAtTheCurrentTime(opened: opened, "\"Add\" from the background")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        assertScreen("Today")
    }

    /// mm-t24.22, comment of 15:27 (mm-t24.29), with the app lock off:
    /// "Cold launch: force-quit the app, then tap each reminder and 'Add'
    /// on a planned meal reminder; each opens its own screen." The midday,
    /// close-the-day, morning plan and planned meal reminders, and "Add",
    /// each after a force-quit. The seeded store `review` has stage 2 open.
    /// (The weigh-in day and the weekly review reminders after a force-quit
    /// are in `testReminderTapOpensTheWeighInScreenOnTodaysStack` and
    /// `testReminderTapOpensTheDueReviewAndThenTheFinishedReview`.)
    func testReminderTapsFromAColdLaunchWithTheAppLockOff() throws {
        try launchOnToday("review")
        allowNotificationsFromToday()
        for reminder in mmT2429Cases() {
            forceQuitTheApp()
            reminder.tap()
            let message = "a tap on \(reminder.name) after a force-quit"
            assertTheAppIsInFront(message)
            reminder.check(message)
            reminder.close()
            assertScreen("Today")
        }
        forceQuitTheApp()
        let opened = Date()
        tapAddOnASimulatedPlannedMealReminder(dayKey: reminderTapDayKey())
        assertTheAppIsInFront("\"Add\" on a planned meal reminder after a force-quit")
        assertTheAddScreenAtTheCurrentTime(opened: opened, "\"Add\" from a cold launch")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        assertScreen("Today")
    }

    // MARK: mm-t24.22, mm-t24.29: close the day before 04:00

    /// mm-t24.22, comment of 15:27 (mm-t24.29): "Tap the close-the-day
    /// reminder before 04:00; the close-the-day screen opens for that
    /// record day." The seeded store `tap-night` is seeded in a
    /// fixed-offset zone where the local time is 00:xx, and the app runs in
    /// that zone (`TZ`). The current record day started at 04:00 on the
    /// previous calendar date and holds "Soup" at 13:00. Its close-the-day
    /// reminder names that record day. A tap from the background opens the
    /// close-the-day screen with the heading of that record day (not of
    /// the calendar date) and its entry "Soup". (From a cold launch the
    /// app has no `TZ`, so this part runs from the background only; a cold
    /// launch before 04:00 in the Mac's zone stays a device check.)
    func testReminderTapOnCloseTheDayBefore0400() throws {
        let url = URL(fileURLWithPath: reminderTapEnvironment["STORES"]!).appendingPathComponent("tap-night.timezone")
        let identifier = try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let zone = try XCTUnwrap(TimeZone(identifier: identifier), "the seeder wrote a zone for tap-night")
        var local = Calendar(identifier: .gregorian)
        local.timeZone = zone
        let hour = local.component(.hour, from: Date())
        XCTAssertLessThan(hour, 4, "the local time in \(identifier) is before 04:00. If not, the seeded store tap-night is more than 3 hours old: run the script again. This is not a fault of the app.")
        let recordDay = reminderTapDayKey(in: zone)
        let calendarDay = reminderTapDayKey(1, in: zone)
        app.launchEnvironment["TZ"] = identifier
        try launchOnToday("tap-night")
        allowNotificationsFromToday()
        putTheAppInTheBackground()
        tapASimulatedReminder(userInfo: reminderTapUserInfo("closeTheDay", dayKey: recordDay))
        assertTheAppIsInFront("a tap on the close-the-day reminder before 04:00")
        assertTheCloseTheDayScreen(forDayKey: recordDay, in: zone, "a tap before 04:00")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", reminderTapHeading(forDayKey: calendarDay, in: zone))).firstMatch.exists,
                       "the close-the-day screen is not for the calendar date \(calendarDay)")
        XCTAssertTrue(element(labelContaining: "Soup").exists, "the close-the-day screen shows the record day's entry \"Soup\"")
        closeTheCloseTheDayScreen()
        assertScreen("Today")
    }
}
