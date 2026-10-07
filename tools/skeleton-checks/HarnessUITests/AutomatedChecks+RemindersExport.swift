import XCTest
import SQLite3

/// Rulings r13-19 and r16-01 (epic mm-t45, mm-t43.32): the checks of the
/// device-check beads mm-t24.22 (reminders), mm-t41.15 (local delete-all)
/// and mm-t42.14 (export) that the simulator can prove. Each test names its
/// bead and the check that it replaces. A real delivered notification, the
/// lock control, VoiceOver and the largest text size stay device checks.
///
/// The seeder scenarios are in `seeder/Sources/Seeder/RemindersExportScenarios.swift`.
/// `stage1Morning` and `stage1Evening` are seeded in a fixed-offset zone; a
/// test launches the app with `TZ` set to that zone, so a check of the time
/// of day does not depend on the hour of the run.
///
/// The notification permission: `automated-checks.sh` installs the app new
/// for each run, so a run starts with the permission "not determined", and
/// Today shows "Allow notifications to get reminders." in every test. An
/// answer to the system request stays for the rest of the run. So the two
/// tests that answer it have names that begin with "testZ": XCTest runs the
/// tests of a class in name order, and every other test then runs before
/// them, with the permission line that it was written with.
/// `testZFreshInstallAsksForNotificationsOnToday` needs the permission "not
/// determined" and allows notifications; `testZPauseForTodayCancelsOnlyTodaysReminders`
/// reads "Pending reminders", which needs that permission, and allows
/// notifications itself when it runs alone.
extension AutomatedChecks {
    private var runEnvironment: [String: String] { ProcessInfo.processInfo.environment }

    // MARK: Helpers (private to this file)

    /// The zone that the seeder chose for `scenario` (`<stores>/<scenario>.timezone`).
    private func seededZone(_ scenario: String) throws -> TimeZone {
        let url = URL(fileURLWithPath: runEnvironment["STORES"]!).appendingPathComponent("\(scenario).timezone")
        let identifier = try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        return try XCTUnwrap(TimeZone(identifier: identifier), "the seeder wrote a zone for \(scenario)")
    }

    /// Launches with the seeded store `scenario` in its seeded zone and
    /// waits for Today. Answers the local hour in that zone.
    @discardableResult
    private func launchOnTodayInTheSeededZone(_ scenario: String) throws -> Int {
        let zone = try seededZone(scenario)
        app.launchEnvironment["TZ"] = zone.identifier
        try launchOnToday(scenario)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.component(.hour, from: Date())
    }

    /// The Record directory in the app's data container.
    private var recordDirectory: URL {
        URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("Library/Application Support/Record")
    }

    private var launchMarkerURL: URL {
        URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("Library/Application Support/LaunchMarker")
    }

    /// Opens Settings, then Diagnostics, from Today, reads the number in the
    /// row `label`, and goes back to Today. With `fromSettings`, it starts
    /// and ends on the settings screen.
    private func diagnosticsCount(_ label: String, fromSettings: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> Int? {
        if !fromSettings { tapToolbar("Settings") }
        assertScreen("Settings", file: file, line: line)
        let diagnostics = app.buttons["Diagnostics"].firstMatch
        XCTAssertTrue(scrollTo(diagnostics), "Settings shows \"Diagnostics\"", file: file, line: line)
        diagnostics.tap()
        assertScreen("Diagnostics", file: file, line: line)
        let row = element(labelBeginningWith: label)
        XCTAssertTrue(scrollTo(row), "Diagnostics shows \"\(label)\"", file: file, line: line)
        let text = "\(row.label) \(row.value as? String ?? "")".dropFirst(label.count)
        let number = text.split(whereSeparator: { !$0.isNumber }).first.flatMap { Int($0) }
        goBack()
        assertScreen("Settings", file: file, line: line)
        if !fromSettings {
            goBack()
            assertScreen("Today", file: file, line: line)
        }
        return number
    }

    /// Reads "Pending reminders" until `condition` holds, at most four
    /// times: the scheduler applies a change a moment after the store write
    /// (`ReminderCoordinator.scheduleRecompute`).
    private func pendingReminders(fromSettings: Bool = false, where condition: (Int) -> Bool) -> Int? {
        var count: Int?
        for _ in 0..<4 {
            count = diagnosticsCount("Pending reminders", fromSettings: fromSettings)
            if let count, condition(count) { return count }
            sleep(1)
        }
        return count
    }

    /// The system's notification permission alert, which SpringBoard shows.
    private var notificationPermissionAlert: XCUIElement {
        XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
    }

    /// Allows notifications from Today's line "Allow notifications to get
    /// reminders." when the permission is not determined. Fails when Today
    /// shows "Notifications are off in iOS Settings.": only a new install
    /// gives the question back.
    private func allowNotificationsFromTodayIfAsked(file: StaticString = #filePath, line: UInt = #line) {
        let ask = app.buttons["Allow notifications to get reminders."].firstMatch
        let denied = app.buttons["Notifications are off in iOS Settings."].firstMatch
        _ = ask.waitForExistence(timeout: 3)
        XCTAssertFalse(denied.exists, "notifications are not denied on this simulator (install the app again)", file: file, line: line)
        guard ask.exists else { return }
        ask.tap()
        let alert = notificationPermissionAlert
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "a tap on the line shows the system request", file: file, line: line)
        alert.buttons["Allow"].tap()
        XCTAssertTrue(ask.waitForNonExistence(timeout: 10), "after \"Allow\", the line goes", file: file, line: line)
    }

    /// Sets the compact time picker `picker` to `hour`:`minute` with the
    /// hour and the minute wheels, then closes the wheels with a tap on the
    /// navigation bar.
    private func turnTheWheels(of picker: XCUIElement, toHour hour: String, minute: String, file: StaticString = #filePath, line: UInt = #line) {
        picker.tap()
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 5), "the time picker shows its wheels", file: file, line: line)
        let ordered = wheels.allElementsBoundByIndex.sorted { $0.frame.minX < $1.frame.minX }
        XCTAssertGreaterThanOrEqual(ordered.count, 2, "the time picker shows an hour and a minute wheel", file: file, line: line)
        guard ordered.count >= 2 else { return }
        ordered[0].adjust(toPickerWheelValue: hour)
        ordered[1].adjust(toPickerWheelValue: minute)
        app.navigationBars.firstMatch.tap()
        XCTAssertTrue(wheels.firstMatch.waitForNonExistence(timeout: 5), "the wheels close", file: file, line: line)
    }

    /// The compact time pickers on the screen, top to bottom.
    private func timePickers() -> [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "label == %@", "Time Picker")).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    /// Swipes up until a compact time picker shows `value`, and answers it.
    private func timePicker(showing value: String) -> XCUIElement? {
        for _ in 0..<6 {
            if let picker = timePickers().first(where: { $0.value as? String == value && $0.isHittable }) { return picker }
            app.swipeUp()
        }
        return nil
    }

    /// Taps the first hittable element with the label `label`
    /// that sits above `limit` (the top of the bottom "Continue" bar),
    /// with up to eight swipes.
    private func tapAbove(_ limit: () -> CGFloat, label: String, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<8 {
            let matches = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
                .filter { $0.isHittable && $0.frame.maxY < limit() - 8 }
            if let first = matches.first {
                first.tap()
                return
            }
            app.swipeUp()
        }
        XCTFail("the screen shows \"\(label)\"", file: file, line: line)
    }

    /// Walks onboarding from screen 1 to Today. Screen 2: "No" to the
    /// three questions, then an age, a height and a weight that exclude
    /// nothing. Screen 3: the start day stays "Today", "I won't be
    /// weighing", then `onScreen3` runs before "Continue". Screen 4: no tap
    /// on "Allow notifications", the app lock switch off when it can be
    /// on, then "Start".
    private func finishOnboarding(onScreen3: () -> Void = {}, file: StaticString = #filePath, line: UInt = #line) {
        let firstContinue = app.buttons["Continue"].firstMatch
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows", file: file, line: line)
        XCTAssertTrue(scrollTo(firstContinue), file: file, line: line)
        firstContinue.tap()
        // Screen 2 (the same steps as testOnboardingScreen3).
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
            XCTAssertTrue(answered, "screen 2 shows question \(question) with \"No\"", file: file, line: line)
        }
        for (label, value) in [("Weight in kilograms", "65"), ("Height in centimetres", "170"), ("How old are you?", "30")] {
            let field = app.textFields[label].firstMatch
            for _ in 0..<8 where !(field.exists && field.isHittable) { app.swipeDown() }
            XCTAssertTrue(field.isHittable, "screen 2 shows \"\(label)\"", file: file, line: line)
            field.tap()
            field.typeText(value)
        }
        app.buttons["Continue"].firstMatch.tap()
        if !app.navigationBars["Your start"].waitForExistence(timeout: 3),
           app.navigationBars["A few questions first"].exists {
            app.buttons["Continue"].firstMatch.tap()
        }
        assertScreen("Your start", file: file, line: line)
        // Screen 3.
        tapAbove({ app.buttons["Continue"].firstMatch.frame.minY }, label: "I won't be weighing", file: file, line: line)
        onScreen3()
        app.buttons["Continue"].firstMatch.tap()
        // Screen 4.
        assertScreen("Permissions", file: file, line: line)
        XCTAssertTrue(app.buttons["Allow notifications"].firstMatch.exists, "screen 4 shows \"Allow notifications\"", file: file, line: line)
        let lock = app.switches.firstMatch
        if lock.exists, lock.isEnabled, lock.value as? String == "1" {
            let knob = lock.switches.firstMatch
            (knob.exists ? knob : lock).tap()
        }
        app.buttons["Start"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10), "\"Start\" opens Today", file: file, line: line)
    }

    /// The bytes of the two store files and their write-ahead logs. A write
    /// goes to the `-wal` file first, so the check reads it too. The
    /// `-shm` file is a shared-memory index that a reader also writes, so
    /// the check leaves it out.
    private func storeFileBytes() throws -> [String: Data] {
        var result: [String: Data] = [:]
        for name in ["Record.store", "Record.store-wal", "Local.store", "Local.store-wal"] {
            let url = recordDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                result[name] = try Data(contentsOf: url)
            }
        }
        return result
    }

    /// The rows of one SQL query on a store file, each row as one string,
    /// read-only, while the app keeps the file open.
    private func rows(of fileName: String, _ sql: String, file: StaticString = #filePath, line: UInt = #line) -> [String] {
        var database: OpaquePointer?
        let path = recordDirectory.appendingPathComponent(fileName).path
        guard sqlite3_open_v2(path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            XCTFail("\(fileName) opens read-only", file: file, line: line)
            return []
        }
        defer { sqlite3_close(database) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            XCTFail("the query runs on \(fileName): \(String(cString: sqlite3_errmsg(database)))", file: file, line: line)
            return []
        }
        defer { sqlite3_finalize(statement) }
        var result: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let columns = (0..<sqlite3_column_count(statement)).map { index -> String in
                sqlite3_column_text(statement, index).map { String(cString: $0) } ?? "NULL"
            }
            result.append(columns.joined(separator: "|"))
        }
        return result
    }

    /// Every synced `Settings` row (Record.store), and every device setting
    /// that the Reminders screen writes (Local.store), with Core Data's row
    /// version `Z_OPT`, which rises with each save of the row.
    private func reminderSettingsRows() -> [String] {
        rows(of: "Record.store", "SELECT Z_PK, Z_OPT, ZKEY, ZVALUE, ZCHANGEDAT FROM ZSETTINGS ORDER BY Z_PK")
            + rows(of: "Local.store", """
                SELECT Z_PK, Z_OPT, ZKEY, ZVALUE FROM ZLOCALSETTING
                WHERE ZKEY LIKE 'reminder.%' AND ZKEY NOT LIKE 'reminder.stops.%' AND ZKEY NOT LIKE 'reminder.snoozeAt.%'
                ORDER BY Z_PK
                """).map { "local|\($0)" }
    }

    // MARK: mm-t24.22 (reminders)

    /// mm-t24.22, comment of mm-t24.25 (r13-19, r16-01): install fresh and
    /// do not answer the permission request on screen 4. Today shows
    /// "Allow notifications to get reminders.". A tap shows the system
    /// request. "Allow": the line goes, and Diagnostics "Pending reminders"
    /// is more than 0. Item 1 of the first comment, the effect on the
    /// Reminders group: before the answer it shows "Reminders need
    /// notification permission." and "Allow notifications"; after "Allow"
    /// it shows neither, and no denied line. (The "Deny" path and the badge
    /// in the iOS Settings app stay device checks: the permission comes
    /// back only with a new install.)
    func testZFreshInstallAsksForNotificationsOnToday() throws {
        func openReminders() {
            tapToolbar("Settings")
            assertScreen("Settings")
            app.buttons["Reminders"].firstMatch.tap()
            assertScreen("Reminders")
        }
        func backToToday() {
            goBack()
            assertScreen("Settings")
            goBack()
            assertScreen("Today")
        }
        try launch(nil)
        finishOnboarding()
        let line = app.buttons["Allow notifications to get reminders."].firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 8),
                      "on a fresh install, Today shows \"Allow notifications to get reminders.\" (a test that answers the system request must run after this one: automated-checks.sh installs the app new for each run)")
        openReminders()
        let needsPermission = element(labelled: "Reminders need notification permission.")
        XCTAssertTrue(needsPermission.waitForExistence(timeout: 5), "before the answer, the Reminders group shows \"Reminders need notification permission.\"")
        XCTAssertTrue(app.buttons["Allow notifications"].firstMatch.exists, "before the answer, the Reminders group shows \"Allow notifications\"")
        backToToday()
        line.tap()
        let alert = notificationPermissionAlert
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "a tap on the line shows the system request")
        alert.buttons["Allow"].tap()
        XCTAssertTrue(line.waitForNonExistence(timeout: 10), "after \"Allow\", the line goes")
        XCTAssertFalse(app.buttons["Notifications are off in iOS Settings."].exists, "after \"Allow\", Today shows no denied line")
        let pending = pendingReminders(where: { $0 > 0 })
        XCTAssertGreaterThan(pending ?? 0, 0, "after \"Allow\", Diagnostics \"Pending reminders\" is more than 0")
        openReminders()
        XCTAssertTrue(app.switches["Planned meals"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(needsPermission.exists, "after \"Allow\", the Reminders group shows no permission line")
        XCTAssertFalse(app.buttons["Allow notifications"].exists, "after \"Allow\", the Reminders group shows no \"Allow notifications\"")
        XCTAssertFalse(element(labelBeginningWith: "Notifications are off in iOS Settings.").exists, "after \"Allow\", the Reminders group shows no denied line")
    }

    /// mm-t24.22, item 2 of the first comment (r13-19, r16-01): the
    /// schedule computes again after "Turn reminders on", a switch, a time
    /// change and a quiet hours change, by the Diagnostics count. The store
    /// is in stage 1 at 10:xx local time, with the reminders paused. Paused:
    /// 0 pending. "Turn reminders on": more than 0 (P). "Close the day" off:
    /// fewer (S). On again: P. "Close the day time" 22:30, inside quiet
    /// hours: S again, because quiet hours drop every close-the-day
    /// reminder. Quiet hours off: P again. (A new schedule on app activation
    /// gives the same count, so the count cannot show it; that part stays a
    /// device check.)
    func testZRemindersScreenChangesComputeTheScheduleAgain() throws {
        try launchOnTodayInTheSeededZone("stage1Paused")
        allowNotificationsFromTodayIfAsked()
        XCTAssertEqual(pendingReminders(where: { $0 == 0 }), 0, "while the reminders are paused, nothing is pending")
        tapToolbar("Settings")
        assertScreen("Settings")
        func inReminders(_ change: () -> Void) {
            // Diagnostics is at the bottom of Settings; Reminders is at the top.
            let reminders = app.buttons["Reminders"].firstMatch
            for _ in 0..<6 where !(reminders.exists && reminders.isHittable) { app.swipeDown() }
            reminders.tap()
            assertScreen("Reminders")
            change()
            goBack()
            assertScreen("Settings")
        }
        inReminders {
            XCTAssertTrue(element(labelled: "Reminders are paused.").waitForExistence(timeout: 5), "the Reminders group shows \"Reminders are paused.\"")
            app.buttons["Turn reminders on"].firstMatch.tap()
            XCTAssertTrue(element(labelled: "Reminders are paused.").waitForNonExistence(timeout: 5), "\"Turn reminders on\" removes the line")
        }
        guard let all = pendingReminders(fromSettings: true, where: { $0 > 0 }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertGreaterThan(all, 0, "after \"Turn reminders on\", reminders are pending")
        inReminders { flipSwitch("Close the day") }
        guard let withoutCloseTheDay = pendingReminders(fromSettings: true, where: { $0 < all }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertLessThan(withoutCloseTheDay, all, "\"Close the day\" off cancels the close-the-day reminders")
        inReminders { flipSwitch("Close the day") }
        XCTAssertEqual(pendingReminders(fromSettings: true, where: { $0 == all }), all, "\"Close the day\" on schedules them again")
        inReminders {
            guard let time = timePicker(showing: "21:45") else { return XCTFail("the Reminders group shows \"Close the day time\" 21:45") }
            turnTheWheels(of: time, toHour: "22", minute: "30")
            XCTAssertNotNil(timePicker(showing: "22:30"), "\"Close the day time\" shows 22:30")
        }
        XCTAssertEqual(pendingReminders(fromSettings: true, where: { $0 == withoutCloseTheDay }), withoutCloseTheDay,
                       "a close-the-day time inside quiet hours (22:00 to 07:00) drops every close-the-day reminder")
        inReminders { flipSwitch("Quiet hours") }
        XCTAssertEqual(pendingReminders(fromSettings: true, where: { $0 == all }), all, "with quiet hours off, the close-the-day reminders at 22:30 are pending again")
    }

    /// mm-t24.22, comment of mm-t24.37, item 3 (r13-19, r16-01): on
    /// onboarding screen 3, a new quiet hours time keeps its hour and
    /// minute. The test turns the wheels to 21:35 and 06:50, finishes
    /// onboarding, and Settings, Reminders, shows quiet hours from 21:35 to
    /// 06:50. (testOnboardingScreen3 checks the defaults, 22:00 and 07:00.)
    func testANewQuietHoursTimeKeepsItsHourAndMinute() throws {
        try launch(nil)
        finishOnboarding(onScreen3: {
            // "Continue" sits over the bottom of the form; a picker under it
            // takes no tap.
            let continueTop = app.buttons["Continue"].firstMatch.frame.minY
            for _ in 0..<8 {
                let pickers = timePickers()
                if pickers.count == 2, pickers.allSatisfy({ $0.isHittable && $0.frame.maxY < continueTop - 8 }) { break }
                app.swipeUp()
            }
            var quiet = timePickers()
            XCTAssertEqual(quiet.map { $0.value as? String }, ["22:00", "07:00"], "screen 3 shows the default quiet hours")
            guard quiet.count == 2 else { return }
            turnTheWheels(of: quiet[0], toHour: "21", minute: "35")
            quiet = timePickers()
            turnTheWheels(of: quiet[1], toHour: "06", minute: "50")
            XCTAssertEqual(timePickers().map { $0.value as? String }, ["21:35", "06:50"], "screen 3 shows the new quiet hours")
        })
        tapToolbar("Settings")
        assertScreen("Settings")
        app.buttons["Reminders"].firstMatch.tap()
        assertScreen("Reminders")
        let quietHours = app.switches["Quiet hours"].firstMatch
        XCTAssertTrue(scrollTo(quietHours))
        for _ in 0..<4 { app.swipeUp() }
        XCTAssertEqual(timePickers().suffix(2).map { $0.value as? String }, ["21:35", "06:50"],
                       "Settings, Reminders, shows the quiet hours set on screen 3, with the same hour and minute")
    }

    /// mm-t24.22, comment of mm-t24.34 (r13-19, r16-01): in stage 1 before
    /// 17:00, Today shows only "Pause for today". After 17:00, "Close the
    /// day" shows beside it. The day heading menu has no "Close the day".
    /// The two stores are seeded in zones where the local time is 10:xx and
    /// 19:xx. (From stage 2, "after the last planned meal's time" needs a
    /// seeded plan; it stays a device check.)
    func testCloseTheDayShowsBesidePauseOnlyAfter17InStage1() throws {
        func assertTheDayMenuHasNoCloseTheDay(besidePause: Int) {
            let menu = app.buttons["Day options"].firstMatch
            XCTAssertTrue(menu.waitForExistence(timeout: 5), "the current day heading shows its menu")
            menu.tap()
            XCTAssertTrue(app.buttons["Fasting today"].firstMatch.waitForExistence(timeout: 5), "the day menu opens")
            let closeTheDay = app.buttons.matching(NSPredicate(format: "label == %@", "Close the day")).count
            XCTAssertEqual(closeTheDay, besidePause, "the day heading menu has no \"Close the day\"")
            app.navigationBars["Today"].staticTexts.firstMatch.tap()
            XCTAssertTrue(app.buttons["Fasting today"].firstMatch.waitForNonExistence(timeout: 5), "the day menu closes")
        }
        let morning = try launchOnTodayInTheSeededZone("stage1Morning")
        XCTAssertTrue((5..<17).contains(morning), "the stage1Morning zone is before 17:00 (local hour \(morning))")
        XCTAssertTrue(app.buttons["Getting started"].firstMatch.exists, "the seeded store is in stage 1")
        let pause = app.buttons["Pause for today"].firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Today shows \"Pause for today\"")
        XCTAssertFalse(app.buttons["Close the day"].exists, "before 17:00 in stage 1, Today shows only \"Pause for today\"")
        assertTheDayMenuHasNoCloseTheDay(besidePause: 0)

        let evening = try launchOnTodayInTheSeededZone("stage1Evening")
        XCTAssertTrue(evening >= 17 || evening < 4, "the stage1Evening zone is after 17:00 (local hour \(evening))")
        XCTAssertTrue(app.buttons["Getting started"].firstMatch.exists, "the seeded store is in stage 1")
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Today shows \"Pause for today\"")
        let closeTheDay = app.buttons["Close the day"].firstMatch
        XCTAssertTrue(closeTheDay.waitForExistence(timeout: 5), "after 17:00 in stage 1, Today shows \"Close the day\"")
        XCTAssertEqual(closeTheDay.frame.midY, pause.frame.midY, accuracy: 4, "\"Close the day\" shows beside \"Pause for today\"")
        XCTAssertGreaterThan(closeTheDay.frame.minX, pause.frame.maxX, "\"Close the day\" shows beside \"Pause for today\"")
        assertTheDayMenuHasNoCloseTheDay(besidePause: 1)
    }

    /// mm-t24.22, comment of mm-t24.33 (r13-19, r16-01): "Pending
    /// reminders" drops after "Pause for today". The store is in stage 1,
    /// at 10:xx local time, with an entry at 05:00: today's only reminder
    /// still to come is close the day at 21:45, so the count drops by one,
    /// and the other days keep theirs. A second tap ("Paused for today")
    /// gives the reminder back. Comment of mm-t24.23: the same check as
    /// "Tap 'Pause for today' ... no reminder fires", by the count only;
    /// the real reminders that do not fire stay a device check.
    func testZPauseForTodayCancelsOnlyTodaysReminders() throws {
        try launchOnTodayInTheSeededZone("stage1Morning")
        allowNotificationsFromTodayIfAsked()
        guard let before = pendingReminders(where: { $0 > 1 }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertGreaterThan(before, 1, "before the pause, reminders are pending for today and the next days")
        app.buttons["Pause for today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Paused for today"].firstMatch.waitForExistence(timeout: 5))
        let paused = pendingReminders(where: { $0 == before - 1 })
        XCTAssertEqual(paused, before - 1, "\"Pause for today\" cancels today's one reminder (close the day) and keeps the other days' reminders")
        app.buttons["Paused for today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Pause for today"].firstMatch.waitForExistence(timeout: 5))
        let resumed = pendingReminders(where: { $0 == before })
        XCTAssertEqual(resumed, before, "after the pause is off, today's reminder is pending again")
    }

    /// mm-t24.22, comment of mm-t24.38 (r13-19, r16-01): with reminder
    /// times, quiet hours and device settings that are not the defaults,
    /// open Settings, then Reminders, close it and open it again: the store
    /// file holds no new or changed Settings row (and no changed device
    /// setting of the Reminders screen). Then change "Close the day time"
    /// from 21:15 to 21:20: one row changes, the row of that time only.
    /// (Whether the open computes a new pending set is not visible from
    /// the screen or the store file; it stays a device check.)
    func testOpeningRemindersTwiceWritesNoSettingsRow() throws {
        try launchOnToday("reminderSettings")
        tapToolbar("Settings")
        assertScreen("Settings")
        let before = reminderSettingsRows()
        XCTAssertTrue(before.contains { $0.contains("|reminder.closeTheDay.time|21:15|") }, "the seeded store holds \"Close the day time\" 21:15: \(before)")
        for _ in 1...2 {
            app.buttons["Reminders"].firstMatch.tap()
            assertScreen("Reminders")
            XCTAssertNotNil(timePicker(showing: "21:15"), "the Reminders screen shows the seeded \"Close the day time\" 21:15")
            goBack()
            assertScreen("Settings")
        }
        sleep(1)
        let afterOpens = reminderSettingsRows()
        XCTAssertEqual(afterOpens, before, "opening the Reminders screen twice writes no Settings row")
        app.buttons["Reminders"].firstMatch.tap()
        assertScreen("Reminders")
        guard let closeTheDayTime = timePicker(showing: "21:15") else {
            return XCTFail("the Reminders screen shows \"Close the day time\" 21:15")
        }
        turnTheWheels(of: closeTheDayTime, toHour: "21", minute: "20")
        goBack()
        assertScreen("Settings")
        sleep(1)
        let afterChange = reminderSettingsRows()
        let changed = afterChange.filter { !before.contains($0) }
        let gone = before.filter { !afterChange.contains($0) }
        XCTAssertEqual(changed.count, 1, "one time change writes one row: \(changed)")
        XCTAssertTrue(changed.first?.contains("|reminder.closeTheDay.time|21:20|") ?? false, "the row is \"Close the day time\" 21:20: \(changed)")
        XCTAssertTrue(gone.allSatisfy { $0.contains("|reminder.closeTheDay.time|21:15|") }, "no other row changes: \(gone)")
    }

    /// Opens "Today's plan" from the day menu, removes the planned meal
    /// `slotLabel`, and saves ("Save anyway" when the soft rules ask).
    private func removeFromTodaysPlan(_ slotLabel: String, file: StaticString = #filePath, line: UInt = #line) {
        tapDayMenu("Today's plan")
        assertScreen("Today's plan", file: file, line: line)
        let remove = app.buttons["Remove \(slotLabel)"].firstMatch
        XCTAssertTrue(scrollTo(remove), "the plan builder shows \"Remove \(slotLabel)\"", file: file, line: line)
        remove.tap()
        XCTAssertTrue(remove.waitForNonExistence(timeout: 5), "\(slotLabel) leaves the plan", file: file, line: line)
        let save = app.buttons["Save"].firstMatch
        XCTAssertTrue(scrollTo(save), "the plan builder shows \"Save\"", file: file, line: line)
        save.tap()
        let saveAnyway = app.alerts.buttons["Save anyway"].firstMatch
        if saveAnyway.waitForExistence(timeout: 3) { saveAnyway.tap() }
        XCTAssertTrue(app.navigationBars["Today's plan"].waitForNonExistence(timeout: 8), "\"Save\" closes the plan builder", file: file, line: line)
        assertScreen("Today", file: file, line: line)
    }

    /// mm-t24.22, comment of mm-t24.34, the stage 2 part (r13-19, r16-01):
    /// "From stage 2, it shows after the last planned meal's time." The
    /// store is in stage 2 at 19:xx local time, with today's last planned
    /// meal at 21:30: after 17:00, Today still shows only "Pause for
    /// today". After the Evening meal leaves today's plan, the last planned
    /// meal is Mid-afternoon at 16:00, and "Close the day" shows beside
    /// "Pause for today".
    func testCloseTheDayShowsAfterTheLastPlannedMealInStage2() throws {
        let hour = try launchOnTodayInTheSeededZone("stage2Evening")
        XCTAssertTrue((17..<21).contains(hour), "the stage2Evening zone is after 17:00 and before 21:30 (local hour \(hour))")
        XCTAssertFalse(app.buttons["Getting started"].exists, "the seeded store is in stage 2")
        let pause = app.buttons["Pause for today"].firstMatch
        XCTAssertTrue(scrollTo(pause), "Today shows \"Pause for today\"")
        XCTAssertFalse(app.buttons["Close the day"].exists, "before the last planned meal's time (21:30), Today shows only \"Pause for today\", also after 17:00")
        app.swipeDown(); app.swipeDown()
        removeFromTodaysPlan("Evening meal")
        XCTAssertTrue(scrollTo(pause), "Today shows \"Pause for today\"")
        let closeTheDay = app.buttons["Close the day"].firstMatch
        XCTAssertTrue(closeTheDay.waitForExistence(timeout: 5), "after the last planned meal's time (now 16:00), Today shows \"Close the day\"")
        XCTAssertEqual(closeTheDay.frame.midY, pause.frame.midY, accuracy: 4, "\"Close the day\" shows beside \"Pause for today\"")
        XCTAssertGreaterThan(closeTheDay.frame.minX, pause.frame.maxX, "\"Close the day\" shows beside \"Pause for today\"")
    }

    /// mm-t24.22, comment of mm-t24.23 and the lead's request ("a plan
    /// change cancels the right reminders"), by the Diagnostics count
    /// (r13-19, r16-01). The store is in stage 2 at 19:xx local time, with
    /// no entry today: today's reminders still to come are the Evening
    /// meal at 21:30 and close the day at 21:45. After the Evening meal
    /// leaves today's plan, "Pending reminders" is one less: close the day
    /// stays, because Mid-afternoon (16:00) has no entry, and the other
    /// days keep theirs. (That the reminder does not fire at 21:30 needs a
    /// real notification; it stays a device check.)
    func testZRemovingAPlannedMealCancelsOnlyItsReminder() throws {
        let hour = try launchOnTodayInTheSeededZone("stage2Evening")
        XCTAssertTrue((17..<21).contains(hour), "the stage2Evening zone is before 21:30 (local hour \(hour))")
        allowNotificationsFromTodayIfAsked()
        guard let before = pendingReminders(where: { $0 > 2 }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertGreaterThan(before, 2, "before the change, reminders are pending for today and the next days")
        removeFromTodaysPlan("Evening meal")
        let after = pendingReminders(where: { $0 == before - 1 })
        XCTAssertEqual(after, before - 1, "removing the Evening meal cancels its reminder only; close the day and the other days keep theirs")
    }

    /// The app's App Group container (`group.uk.midmorning`) on the
    /// simulator, found by its container metadata beside the data container.
    private func appGroupDirectory() -> URL? {
        let shared = URL(fileURLWithPath: runEnvironment["APP_DATA"]!)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Shared/AppGroup")
        let directories = (try? FileManager.default.contentsOfDirectory(at: shared, includingPropertiesForKeys: nil)) ?? []
        return directories.first { directory in
            let metadata = directory.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let data = try? Data(contentsOf: metadata),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return false }
            return plist["MCMMetadataIdentifier"] as? String == "group.uk.midmorning"
        }
    }

    /// mm-t24.22, comment of mm-t24.24, the part after the tap (r13-19,
    /// r16-01): with the app closed, the notification handler wrote
    /// "Skipped" for Lunch to the action queue; the app opens, Today shows
    /// Lunch skipped, and Diagnostics "Queue length" reads 0. The test
    /// writes the queue file as the handler does (`queue.json` in the App
    /// Group, format version 1). (The tap on "Skipped" on a real reminder,
    /// with the app closed or open, and the next-planned-meal line, which
    /// the row does not give to accessibility, stay device checks.)
    func testAQueuedSkippedAppliesWhenTheAppOpens() throws {
        let zone = try seededZone("stage2Evening")
        try launchOnTodayInTheSeededZone("stage2Evening")
        let lunch = element(labelBeginningWith: "Lunch, 13:00")
        XCTAssertTrue(scrollTo(lunch), "Today shows the Lunch row")
        XCTAssertFalse(lunch.label.contains("Skipped"), "before the queue, Lunch is not skipped: \(lunch.label)")
        app.terminate()
        // The queue file, as the notification handler writes it.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = zone
        formatter.dateFormat = "yyyy-MM-dd"
        let dayKey = formatter.string(from: Date().addingTimeInterval(-4 * 3600))
        let moment = ISO8601DateFormatter().string(from: Date())
        let queue = #"{"formatVersion":1,"actions":[{"kind":"skipped","dayKey":"\#(dayKey)","slotIndex":2,"plannedTime":"13:00","snoozeCount":0,"moment":"\#(moment)"}]}"#
        let group = try XCTUnwrap(appGroupDirectory(), "the simulator holds the App Group container of the app")
        let queueURL = group.appendingPathComponent("queue.json")
        try Data(queue.utf8).write(to: queueURL)
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        let skipped = element(labelBeginningWith: "Lunch, 13:00, Skipped")
        XCTAssertTrue(skipped.waitForExistence(timeout: 8) || scrollTo(skipped), "after the app opens, Today shows Lunch skipped")
        app.swipeDown(); app.swipeDown()
        XCTAssertEqual(diagnosticsCount("Queue length"), 0, "Diagnostics \"Queue length\" reads 0")
        let left = (try? Data(contentsOf: queueURL)).map { String(decoding: $0, as: UTF8.self) } ?? ""
        XCTAssertFalse(left.contains("\"skipped\""), "the app emptied the queue file: \(left)")
    }

    // MARK: mm-t41.15 and mm-t42.14 (safe mode, rulings r13-13 and r13-05)

    /// mm-t41.15, comments of r13-13 and r13-05, parts (3) and (4)
    /// (r13-19, r16-01). The store starts with a launch failure count of 3,
    /// and onboarding is not done, so a launch ends before Today. Two
    /// launches end before Today (onboarding shows; the test stops the
    /// app). The third launch opens safe mode's Today. (3) Safe mode
    /// changes neither Record.store nor Local.store (and neither write-ahead
    /// log). (4) The next launch is an ordinary launch (onboarding again,
    /// then Today), and Diagnostics shows 5, two more than before the first
    /// launch. (The PDF content of the safe mode export (part 2) needs a
    /// person; the MetricKit and migration parts (5) and (6) need a device
    /// or a second schema version.)
    func testSafeModeChangesNoStoreFileAndCountsBothFailures() throws {
        let screen1 = app.buttons["Continue"].firstMatch
        // Launch 1 and launch 2: each ends before Today.
        try launch("unfinishedOnboarding")
        XCTAssertTrue(screen1.waitForExistence(timeout: 20), "launch 1 shows onboarding, not Today")
        app.terminate()
        app.launch()
        XCTAssertTrue(screen1.waitForExistence(timeout: 20), "launch 2 shows onboarding, not Today")
        XCTAssertFalse(app.buttons["Export"].exists, "launch 2 is not safe mode")
        app.terminate()
        let before = try storeFileBytes()
        XCTAssertNotNil(before["Record.store"])
        XCTAssertNotNil(before["Local.store"])
        // Launch 3: safe mode.
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "launch 3 shows safe mode's Today")
        XCTAssertTrue(app.buttons["Export"].firstMatch.waitForExistence(timeout: 5), "safe mode's Today shows \"Export\"")
        XCTAssertTrue(getSupport(on: "Today").exists, "safe mode's Today shows \"Get support\"")
        XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
        // Safe mode's Today clears the streak in the marker and keeps its
        // own launch failure for the next launch ("- 1").
        var marker = ""
        for _ in 0..<10 {
            marker = (try? String(contentsOf: launchMarkerURL, encoding: .utf8)) ?? ""
            if marker.hasPrefix("-") { break }
            usleep(500_000)
        }
        XCTAssertEqual(marker, "- 1", "safe mode's Today clears the streak and keeps one launch failure for the next launch")
        app.terminate()
        let after = try storeFileBytes()
        XCTAssertEqual(Set(after.keys), Set(before.keys), "safe mode adds or removes no store file")
        for (name, data) in before {
            XCTAssertEqual(after[name], data, "safe mode does not change \(name)")
        }
        // Launch 4: an ordinary launch.
        app.launch()
        XCTAssertTrue(screen1.waitForExistence(timeout: 20), "launch 4 is an ordinary launch: onboarding shows, not safe mode")
        finishOnboarding()
        XCTAssertTrue(app.buttons["Add an entry"].firstMatch.waitForExistence(timeout: 5), "the ordinary Today shows")
        XCTAssertEqual(diagnosticsCount("Launch failures"), 5, "Diagnostics shows a launch failure count two more than before launch 1 (3)")
    }

    // MARK: mm-t42.14 (export)

    /// The PDF files under the app's `tmp/Export` folder.
    private func exportedPDFs() -> [String] {
        let folder = URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("tmp/Export")
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return files.filter { $0.pathExtension == "pdf" }.map(\.lastPathComponent)
    }

    /// mm-t42.14, comment of r13-14 (mm-t42.27) (r13-19): on the export
    /// screen, "Make PDF" shows the share sheet with its actions, "Save to
    /// Files" among them, and no "Copy". Comment of mm-t41.24, the part
    /// that the simulator can prove (r13-19, r16-01): a close of the share
    /// sheet with no destination shows the export screen with no message,
    /// and no PDF file stays in the app's container. (AirDrop is not on the
    /// simulator, and the network watch needs a device or a proxy; both
    /// stay device checks.)
    func testTheExportShareSheetShowsNoCopy() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let export = app.buttons["Export"].firstMatch
        XCTAssertTrue(scrollTo(export), "Settings shows \"Export\"")
        export.tap()
        assertScreen("Export")
        let makePDF = app.buttons["Make PDF"].firstMatch
        XCTAssertTrue(scrollTo(makePDF), "the export screen shows \"Make PDF\"")
        makePDF.tap()
        let sheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 15), "\"Make PDF\" shows the system share sheet")
        let actions = sheet.cells.matching(identifier: "actionGroupCell")
        XCTAssertTrue(actions.firstMatch.waitForExistence(timeout: 10), "the share sheet shows its actions")
        let labels = actions.allElementsBoundByIndex.map(\.label)
        XCTAssertTrue(labels.contains("Save to Files"), "the share sheet offers \"Save to Files\": \(labels)")
        XCTAssertFalse(labels.contains("Copy"), "the share sheet offers no \"Copy\": \(labels)")
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Copy")).firstMatch
        XCTAssertFalse(copy.exists, "the share sheet shows no \"Copy\"")
        XCTAssertEqual(exportedPDFs().count, 1, "while the share sheet shows, tmp/Export holds the one PDF")
        // Close the share sheet with no destination.
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the share sheet closes")
        assertScreen("Export")
        XCTAssertTrue(makePDF.isHittable, "the export screen shows again")
        XCTAssertEqual(app.alerts.count, 0, "the close shows no message")
        XCTAssertFalse(element(labelled: "The PDF could not be made. Try again.").exists, "the close shows no message")
        var left = exportedPDFs()
        for _ in 0..<10 where !left.isEmpty {
            usleep(300_000)
            left = exportedPDFs()
        }
        XCTAssertEqual(left, [], "after the close, no PDF file stays in the app's container")
    }
}
