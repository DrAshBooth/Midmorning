import XCTest
import SQLite3
import PDFKit

/// Rulings r13-19 and r16-01 (epic mm-t45, mm-t43.32): the checks of the
/// device-check beads mm-t24.22 (reminders), mm-t41.15 (local delete-all)
/// and mm-t42.14 (export) that the simulator can prove. Each test names its
/// bead and the check that it replaces. A real delivered notification, the
/// lock control, VoiceOver and the largest text size stay device checks.
///
/// The seeder scenarios are in `seeder/Sources/Seeder/RemindersExportScenarios.swift`.
/// `stage1Morning`, `stage1Evening`, `stage1Paused`, `stage2Evening` and
/// `stage2Morning` are seeded in a fixed-offset zone; a test launches the
/// app with `TZ` set to that zone, so the app's own time of day does not
/// depend on the hour of the run.
///
/// The notification daemon is different: the app gives each reminder a
/// floating time (year, month, day, hour and minute, with no zone), and the
/// daemon reads that time in the simulator's zone, which is the Mac's zone.
/// So a test that reads the pending requests first makes sure that the
/// seeded day's reminder time is still ahead in the Mac's zone
/// (`requireTheSeededDaysTimeIsAheadForTheDaemon`). The seeder chooses the
/// zones of `stage1Morning`, `stage1Paused` and `stage2Morning` so that the
/// seeded day's 21:30 and 21:45 are more than 4 hours ahead in the Mac's
/// zone (in the UK, at any hour of a run; `zoneForTheReminderCounts`).
///
/// The tests that read the pending requests read their number from
/// Diagnostics ("Pending reminders"), and their identifiers from the
/// simulator's own store of pending requests (`pendingRequestIdentifiers`).
/// The identifier names the reminder: "closeTheDay.<day>.-" or
/// "plannedMeal.<day>.<slot>". So a test can show which request went.
///
/// The notification permission: `automated-checks.sh` installs the app new
/// for each run, so a run starts with the permission "not determined". An
/// answer to the system request stays until the next install, and tests in
/// other files also answer it. So the script runs
/// `testZFreshInstallAsksForNotificationsOnToday`, which needs "not
/// determined", in a first pass of its own, before every other test
/// (`FRESH_PERMISSION_TESTS` in the script), and then installs the app new
/// again. The other "testZ" tests read the pending requests, which needs
/// the permission "allowed"; each allows notifications itself when Today
/// asks, so their order does not matter. Their names start with "testZ" so
/// that they run last in the second pass: after the permission is
/// "allowed", the app schedules real reminders, and a reminder banner can
/// cover the navigation bar in a later test.
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

    /// The seeded day's `hour`:`minute` of `scenario`, as the notification
    /// daemon reads it: the app's floating reminder time, in the
    /// simulator's zone (the Mac's zone). Fails when it is less than 5
    /// minutes ahead: the daemon then holds no request for it, and a count
    /// of "Pending reminders" cannot show the change. Not a fault of the
    /// app; run the checks earlier in the day.
    private func requireTheSeededDaysTimeIsAheadForTheDaemon(_ scenario: String, hour: Int, minute: Int, file: StaticString = #filePath, line: UInt = #line) throws {
        var seeded = Calendar(identifier: .gregorian)
        seeded.timeZone = try seededZone(scenario)
        var components = seeded.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        var mac = Calendar(identifier: .gregorian)
        mac.timeZone = .current
        let moment = try XCTUnwrap(mac.date(from: components), file: file, line: line)
        let time = String(format: "%02d:%02d", hour, minute)
        XCTAssertGreaterThan(moment.timeIntervalSinceNow, 5 * 60,
                             "the seeded day's \(time) is more than 5 minutes ahead in the Mac's zone (\(mac.timeZone.identifier)), where the notification daemon reads the app's floating reminder times. This check must run before \(time) minus 5 minutes in the Mac's zone; run the checks again earlier in the day.",
                             file: file, line: line)
    }

    /// The local time of the seeded zone of `scenario` now, in minutes
    /// after midnight.
    private func seededLocalMinutes(_ scenario: String) throws -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try seededZone(scenario)
        let now = calendar.dateComponents([.hour, .minute], from: Date())
        return (now.hour ?? 0) * 60 + (now.minute ?? 0)
    }

    /// The current record day of `scenario` ("yyyy-MM-dd"), in its seeded
    /// zone. The record day starts at 04:00.
    private func seededDayKey(_ scenario: String) throws -> String {
        let zone = try seededZone(scenario)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = zone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date().addingTimeInterval(-4 * 3600))
    }

    /// The identifiers of the app's pending notification requests, from the
    /// simulator's own store: `data/Library/UserNotifications/Library.plist`
    /// gives the app's folder, and its `PendingNotifications.plist` is a
    /// keyed archive with one dictionary for each pending request (key
    /// "AppNotificationIdentifier"). `nil` when the store cannot be read.
    private func pendingRequestIdentifiers() -> Set<String>? {
        // APP_DATA is data/Containers/Data/Application/<id>.
        let notifications = URL(fileURLWithPath: runEnvironment["APP_DATA"]!)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Library/UserNotifications")
        func unarchive(_ url: URL) -> Any? {
            guard let bytes = try? Data(contentsOf: url), let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: bytes) else { return nil }
            unarchiver.requiresSecureCoding = false
            defer { unarchiver.finishDecoding() }
            return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        }
        guard let library = unarchive(notifications.appendingPathComponent("Library.plist")) as? [String: Any],
              let folder = library["uk.midmorning.app"] as? String,
              let requests = unarchive(notifications.appendingPathComponent(folder).appendingPathComponent("PendingNotifications.plist")) as? [[String: Any]]
        else { return nil }
        return Set(requests.compactMap { $0["AppNotificationIdentifier"] as? String })
    }

    /// Reads the pending request identifiers until `condition` holds, for
    /// 10 seconds at most: the simulator writes its store a moment after a
    /// change. Answers the last read.
    private func pendingIdentifiers(where condition: (Set<String>) -> Bool, file: StaticString = #filePath, line: UInt = #line) -> Set<String> {
        var identifiers: Set<String>?
        for _ in 0..<20 {
            identifiers = pendingRequestIdentifiers()
            if let identifiers, condition(identifiers) { return identifiers }
            usleep(500_000)
        }
        XCTAssertNotNil(identifiers, "the test reads the simulator's store of pending notification requests", file: file, line: line)
        return identifiers ?? []
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
        completeScreen2(file: file, line: line)
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
    /// is in stage 1 between 06:00 and 16:59 local time (10:xx when the
    /// Mac's zone allows it), with the reminders paused. Paused:
    /// 0 pending. "Turn reminders on": more than 0 (P). "Close the day" off:
    /// fewer (S). On again: P. "Close the day time" 22:30, inside quiet
    /// hours: S again, because quiet hours drop every close-the-day
    /// reminder. Quiet hours off: P again. (A new schedule on app activation
    /// gives the same count, so the count cannot show it; that part stays a
    /// device check.)
    func testZRemindersScreenChangesComputeTheScheduleAgain() throws {
        try launchOnTodayInTheSeededZone("stage1Paused")
        try requireTheSeededDaysTimeIsAheadForTheDaemon("stage1Paused", hour: 21, minute: 45)
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
    /// The two stores are seeded in zones where the local time is between
    /// 06:00 and 16:59 (10:xx when the Mac's zone allows it) and 19:xx.
    /// While the menu is open, the test counts each "Close the day" except
    /// Today's own control, which it finds by its frame before the menu
    /// opens. (From stage 2, "after the last planned meal's time" is
    /// testCloseTheDayShowsAfterTheLastPlannedMealInStage2.)
    func testCloseTheDayShowsBesidePauseOnlyAfter17InStage1() throws {
        /// `todaysControl`: the frame of Today's own "Close the day", or
        /// `nil` when Today shows none.
        func assertTheDayMenuHasNoCloseTheDay(todaysControl: CGRect?) {
            let menu = app.buttons["Day options"].firstMatch
            XCTAssertTrue(menu.waitForExistence(timeout: 5), "the current day heading shows its menu")
            menu.tap()
            XCTAssertTrue(app.buttons["Fasting today"].firstMatch.waitForExistence(timeout: 5), "the day menu opens")
            let matches = app.buttons.matching(NSPredicate(format: "label == %@", "Close the day")).allElementsBoundByIndex
            let notTodaysControl = matches.filter { match in
                guard let control = todaysControl else { return true }
                let frame = match.frame
                return abs(frame.minX - control.minX) > 2 || abs(frame.minY - control.minY) > 2
                    || abs(frame.width - control.width) > 2 || abs(frame.height - control.height) > 2
            }
            XCTAssertEqual(notTodaysControl.count, 0, "the day heading menu has no \"Close the day\": \(notTodaysControl.map(\.frame))")
            app.navigationBars["Today"].staticTexts.firstMatch.tap()
            XCTAssertTrue(app.buttons["Fasting today"].firstMatch.waitForNonExistence(timeout: 5), "the day menu closes")
        }
        let morning = try launchOnTodayInTheSeededZone("stage1Morning")
        XCTAssertTrue((5..<17).contains(morning), "the stage1Morning zone is before 17:00 (local hour \(morning))")
        XCTAssertTrue(app.buttons["Getting started"].firstMatch.exists, "the seeded store is in stage 1")
        let pause = app.buttons["Pause for today"].firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Today shows \"Pause for today\"")
        XCTAssertFalse(app.buttons["Close the day"].exists, "before 17:00 in stage 1, Today shows only \"Pause for today\"")
        assertTheDayMenuHasNoCloseTheDay(todaysControl: nil)

        let evening = try launchOnTodayInTheSeededZone("stage1Evening")
        XCTAssertTrue(evening >= 17 || evening < 4, "the stage1Evening zone is after 17:00 (local hour \(evening))")
        XCTAssertTrue(app.buttons["Getting started"].firstMatch.exists, "the seeded store is in stage 1")
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "Today shows \"Pause for today\"")
        let closeTheDay = app.buttons["Close the day"].firstMatch
        XCTAssertTrue(closeTheDay.waitForExistence(timeout: 5), "after 17:00 in stage 1, Today shows \"Close the day\"")
        XCTAssertEqual(closeTheDay.frame.midY, pause.frame.midY, accuracy: 4, "\"Close the day\" shows beside \"Pause for today\"")
        XCTAssertGreaterThan(closeTheDay.frame.minX, pause.frame.maxX, "\"Close the day\" shows beside \"Pause for today\"")
        assertTheDayMenuHasNoCloseTheDay(todaysControl: closeTheDay.frame)
    }

    /// mm-t24.22, comment of mm-t24.33 (r13-19, r16-01): "Pending
    /// reminders" drops after "Pause for today". The store is in stage 1,
    /// between 06:00 and 16:59 local time (10:xx when the Mac's zone allows
    /// it), with an entry at 05:00: today's only reminder still to come is
    /// close the day at 21:45. After "Pause for today" the count is one
    /// less, and the pending requests are the same as before without
    /// today's close-the-day request: every request of the other days
    /// stays. A second tap ("Paused for today") gives the same requests as
    /// before. Comment of mm-t24.23: the same check as "Tap 'Pause for
    /// today' ... no reminder fires", by the pending requests only; the real
    /// reminders that do not fire stay a device check.
    func testZPauseForTodayCancelsOnlyTodaysReminders() throws {
        try launchOnTodayInTheSeededZone("stage1Morning")
        try requireTheSeededDaysTimeIsAheadForTheDaemon("stage1Morning", hour: 21, minute: 45)
        let today = try seededDayKey("stage1Morning")
        let closeTheDay = "closeTheDay.\(today).-"
        allowNotificationsFromTodayIfAsked()
        guard let before = pendingReminders(where: { $0 > 1 }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertGreaterThan(before, 1, "before the pause, reminders are pending for today and the next days")
        let requestsBefore = pendingIdentifiers(where: { $0.count == before })
        XCTAssertEqual(requestsBefore.count, before, "the simulator's store holds the requests that Diagnostics counts: \(requestsBefore.sorted())")
        XCTAssertEqual(requestsBefore.filter { $0.contains(".\(today).") }, [closeTheDay],
                       "before the pause, today's one pending request is close the day: \(requestsBefore.sorted())")
        app.buttons["Pause for today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Paused for today"].firstMatch.waitForExistence(timeout: 5))
        let paused = pendingReminders(where: { $0 == before - 1 })
        XCTAssertEqual(paused, before - 1, "after \"Pause for today\", one request less is pending")
        let withoutToday = requestsBefore.subtracting([closeTheDay])
        let requestsPaused = pendingIdentifiers(where: { $0 == withoutToday })
        XCTAssertEqual(requestsPaused, withoutToday,
                       "\"Pause for today\" cancels today's close-the-day request (\(closeTheDay)) and keeps every request of the other days")
        app.buttons["Paused for today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Pause for today"].firstMatch.waitForExistence(timeout: 5))
        let resumed = pendingReminders(where: { $0 == before })
        XCTAssertEqual(resumed, before, "after the pause is off, the count is the same as before the pause")
        let requestsResumed = pendingIdentifiers(where: { $0 == requestsBefore })
        XCTAssertEqual(requestsResumed, requestsBefore, "after the pause is off, today's close-the-day request is pending again, with the same requests as before")
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
    /// store is in stage 2 at 17:xx local time, with today's last planned
    /// meal at 21:30: after 17:00, Today still shows only "Pause for
    /// today". After the Evening meal leaves today's plan, the last planned
    /// meal is Mid-afternoon at 16:00, and "Close the day" shows beside
    /// "Pause for today".
    func testCloseTheDayShowsAfterTheLastPlannedMealInStage2() throws {
        try launchOnTodayInTheSeededZone("stage2Evening")
        let local = try seededLocalMinutes("stage2Evening")
        XCTAssertTrue((17 * 60)..<(21 * 60 + 25) ~= local,
                      "the local time is after 17:00 and more than 5 minutes before 21:30 (now \(local / 60):\(local % 60)); seed the stores again")
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
    /// change cancels the right reminders") (r13-19, r16-01). The store is
    /// in stage 2, between 06:00 and 16:59 local time (10:xx when the Mac's
    /// zone allows it), with no entry today: today's reminders still to
    /// come include the Evening meal at 21:30 (slot 4) and close the day at
    /// 21:45. After the Evening meal leaves today's plan, "Pending
    /// reminders" is one less, and the pending requests are the same as
    /// before without the Evening meal's request: close the day stays,
    /// because the other planned meals have no entry, and every other
    /// request stays. (That the reminder does not fire at 21:30 needs a
    /// real notification; it stays a device check.)
    func testZRemovingAPlannedMealCancelsOnlyItsReminder() throws {
        try launchOnTodayInTheSeededZone("stage2Morning")
        try requireTheSeededDaysTimeIsAheadForTheDaemon("stage2Morning", hour: 21, minute: 30)
        let today = try seededDayKey("stage2Morning")
        let eveningMeal = "plannedMeal.\(today).4"
        let closeTheDay = "closeTheDay.\(today).-"
        allowNotificationsFromTodayIfAsked()
        guard let before = pendingReminders(where: { $0 > 2 }) else { return XCTFail("Diagnostics shows \"Pending reminders\"") }
        XCTAssertGreaterThan(before, 2, "before the change, reminders are pending for today and the next days")
        let requestsBefore = pendingIdentifiers(where: { $0.count == before })
        XCTAssertEqual(requestsBefore.count, before, "the simulator's store holds the requests that Diagnostics counts: \(requestsBefore.sorted())")
        XCTAssertTrue(requestsBefore.isSuperset(of: [eveningMeal, closeTheDay]),
                      "before the change, the Evening meal (21:30) and close the day (21:45) are pending: \(requestsBefore.sorted())")
        removeFromTodaysPlan("Evening meal")
        let after = pendingReminders(where: { $0 == before - 1 })
        XCTAssertEqual(after, before - 1, "after the Evening meal leaves today's plan, one request less is pending")
        let withoutEveningMeal = requestsBefore.subtracting([eveningMeal])
        let requestsAfter = pendingIdentifiers(where: { $0 == withoutEveningMeal })
        XCTAssertEqual(requestsAfter, withoutEveningMeal,
                       "removing the Evening meal cancels its own request (\(eveningMeal)) only; close the day (\(closeTheDay)) and every other request stay")
    }

    /// The app's App Group container (`group.uk.midmorning`) on the
    /// simulator, found by its container metadata beside the data container.
    private func appGroupDirectory() -> URL? {
        sharedGroupDirectory("group.uk.midmorning")
    }

    /// The simulator's shared group container `identifier`, found by its
    /// container metadata beside the data container.
    private func sharedGroupDirectory(_ identifier: String) -> URL? {
        let shared = URL(fileURLWithPath: runEnvironment["APP_DATA"]!)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Shared/AppGroup")
        let directories = (try? FileManager.default.contentsOfDirectory(at: shared, includingPropertiesForKeys: nil)) ?? []
        return directories.first { directory in
            let metadata = directory.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let data = try? Data(contentsOf: metadata),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return false }
            return plist["MCMMetadataIdentifier"] as? String == identifier
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
        try launchOnTodayInTheSeededZone("stage2Evening")
        // A skipped planned meal's row reads exactly "Lunch, 13:00,
        // Skipped" (`PlannedMealAccessibility`). Before 17:30 local time the
        // missed planned meal prompt is on Lunch, and that row reads
        // "Lunch, 13:00, Skipped, or not recorded yet?", so the test
        // compares the whole label.
        let skippedLabel = "Lunch, 13:00, Skipped"
        let lunch = element(labelBeginningWith: "Lunch, 13:00")
        XCTAssertTrue(scrollTo(lunch), "Today shows the Lunch row")
        XCTAssertNotEqual(lunch.label, skippedLabel, "before the queue, Lunch is not skipped")
        XCTAssertFalse(element(labelled: skippedLabel).exists, "before the queue, no row reads \"\(skippedLabel)\"")
        app.terminate()
        // The queue file, as the notification handler writes it.
        let dayKey = try seededDayKey("stage2Evening")
        let moment = ISO8601DateFormatter().string(from: Date())
        let queue = #"{"formatVersion":1,"actions":[{"kind":"skipped","dayKey":"\#(dayKey)","slotIndex":2,"plannedTime":"13:00","snoozeCount":0,"moment":"\#(moment)"}]}"#
        let group = try XCTUnwrap(appGroupDirectory(), "the simulator holds the App Group container of the app")
        let queueURL = group.appendingPathComponent("queue.json")
        try Data(queue.utf8).write(to: queueURL)
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        let skipped = element(labelled: skippedLabel)
        XCTAssertTrue(skipped.waitForExistence(timeout: 8) || scrollTo(skipped), "after the app opens, Today shows Lunch skipped (\"\(skippedLabel)\")")
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

    /// mm-t41.15, comment of mm-t41.17 and mm-t41.21, the "Try again" part
    /// (r13-19, r16-01): "Tap 'Try again' on the store-failure page twice
    /// in one launch: the launch failure count rises by one at most." The
    /// launch finds an uncleared marker ("0": one launch before this one
    /// ended before Today) and a store that cannot open.
    /// The first "Try again" fails too. The test then puts a good store
    /// (`week1`, count 0) in place, and the second "Try again" opens it.
    /// The ordinary Today shows, not safe mode (the streak rose once, to 1;
    /// a streak of 2 opens safe mode), and Diagnostics shows 1 launch
    /// failure. (A crash in Today's
    /// first load needs a special build, and the protection class of the
    /// marker needs a device; both stay device checks.)
    func testTryAgainCountsTheLaunchFailureOnce() throws {
        try launch("corrupt", launchMarker: "0")
        let page = element(labelled: "Midmorning cannot open your record on this device.")
        XCTAssertTrue(page.waitForExistence(timeout: 20), "the store-open fault screen shows")
        let tryAgain = app.buttons["Try again"].firstMatch
        XCTAssertTrue(tryAgain.exists, "the page shows \"Try again\"")
        tryAgain.tap()
        sleep(1)
        XCTAssertTrue(page.exists, "the first \"Try again\" fails: the store still cannot open")
        // Put a good store in place of the one that cannot open.
        let fileManager = FileManager.default
        for file in try fileManager.contentsOfDirectory(at: recordDirectory, includingPropertiesForKeys: nil) {
            try fileManager.removeItem(at: file)
        }
        let seeded = URL(fileURLWithPath: runEnvironment["STORES"]!).appendingPathComponent("week1")
        for file in try fileManager.contentsOfDirectory(at: seeded, includingPropertiesForKeys: nil) {
            try fileManager.copyItem(at: file, to: recordDirectory.appendingPathComponent(file.lastPathComponent))
        }
        tryAgain.tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10), "the second \"Try again\" opens the store")
        XCTAssertTrue(app.buttons["Add an entry"].firstMatch.waitForExistence(timeout: 5), "the ordinary Today shows, not safe mode")
        XCTAssertEqual(diagnosticsCount("Launch failures"), 1, "the launch failure count rose by one, not once for each \"Try again\"")
    }

    /// mm-t41.15, "Share App Analytics with Apple row opens the iOS
    /// Settings app" (data-and-privacy spec, "The app holds no analytics of
    /// its own"; ruling r12-01) (r13-19): one tap on the row in the Privacy
    /// group opens the iOS Settings app. (The spec scenario says "at the
    /// app's own page". On the iOS 27.0 simulator the app opens the Settings
    /// app at its first page, so that part stays a device check.)
    func testShareAppAnalyticsOpensTheIOSSettingsApp() throws {
        try launchOnToday("week1")
        tapToolbar("Settings")
        assertScreen("Settings")
        let row = app.buttons["Share App Analytics with Apple"].firstMatch
        XCTAssertTrue(scrollTo(row), "the Privacy group shows \"Share App Analytics with Apple\"")
        row.tap()
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settingsApp.wait(for: .runningForeground, timeout: 15), "the row opens the iOS Settings app")
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5), "Midmorning goes to the background")
        settingsApp.terminate()
    }

    // MARK: mm-t42.14 (export)

    /// Opens the export screen from Today through Settings and taps "Make
    /// PDF"; waits for the share sheet.
    private func makeAPDFFromSettings(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        tapToolbar("Settings")
        assertScreen("Settings", file: file, line: line)
        let export = app.buttons["Export"].firstMatch
        XCTAssertTrue(scrollTo(export), "Settings shows \"Export\"", file: file, line: line)
        export.tap()
        assertScreen("Export", file: file, line: line)
        let makePDF = app.buttons["Make PDF"].firstMatch
        XCTAssertTrue(scrollTo(makePDF), "the export screen shows \"Make PDF\"", file: file, line: line)
        makePDF.tap()
        let sheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 15), "\"Make PDF\" shows the system share sheet", file: file, line: line)
        return sheet
    }

    /// The text of the one PDF under `tmp/Export`.
    private func exportedPDFText() -> String? {
        let folder = URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("tmp/Export")
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return files.first { $0.pathExtension == "pdf" }.flatMap { PDFDocument(url: $0)?.string }
    }

    /// mm-t42.14, comment of mm-t42.24, part 1 (r13-19, r16-01): make a
    /// PDF, and while the share sheet shows, force-quit the app; open the
    /// app again: the app's containers hold no PDF. (Part 2, "Delete
    /// everything" straight from the cover, needs the app lock; it stays
    /// with the app-lock checks.)
    func testTheNextLaunchRemovesAPDFLeftByAForceQuit() throws {
        try launchOnToday("week1")
        _ = makeAPDFFromSettings()
        assertTheOnePDFIsInTmpExport("while the share sheet shows")
        app.terminate()
        assertTheOnePDFIsInTmpExport("after the force-quit")
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        XCTAssertEqual(pdfFilesInTheAppContainers(), [], "after the next launch, the app's data container and App Group container hold no PDF")
    }

    /// mm-t41.15, comment of r13-13 and r13-05, part (2) (r13-19, r16-01):
    /// in safe mode, make a PDF export; it holds the entries. The store is
    /// `review`, with entries on nine record days, all in the default
    /// range of 28 days. The test reads the text of the PDF in tmp/Export
    /// while the share sheet shows: it holds "Porridge" eight times (one
    /// entry on each of the eight earlier days), "Soup" and "Pasta" (the
    /// previous day), and "Toast and tea" and "Rice and beans" (today).
    /// (How the PDF looks stays with the person who checks the export.)
    func testTheSafeModeExportHoldsTheEntries() throws {
        try launch("review", launchMarker: "2")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "safe mode's Today shows")
        XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
        app.buttons["Export"].firstMatch.tap()
        assertScreen("Export")
        let makePDF = app.buttons["Make PDF"].firstMatch
        XCTAssertTrue(scrollTo(makePDF), "the export screen shows \"Make PDF\"")
        makePDF.tap()
        let sheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 15), "in safe mode, \"Make PDF\" shows the system share sheet")
        let text = exportedPDFText() ?? ""
        XCTAssertEqual(text.components(separatedBy: "Porridge").count - 1, 8,
                       "the safe mode PDF holds the entry \"Porridge\" of each of the eight earlier days: \(text.prefix(600))")
        for entry in ["Soup", "Pasta", "Toast and tea", "Rice and beans"] {
            XCTAssertTrue(text.contains(entry), "the safe mode PDF holds the entry \"\(entry)\": \(text.prefix(600))")
        }
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the share sheet closes")
    }

    /// Every PDF file in the app's data container (tmp, Library and
    /// Documents included) and in its App Group container, as a path from
    /// the top of its container.
    private func pdfFilesInTheAppContainers() -> [String] {
        let roots = [URL(fileURLWithPath: runEnvironment["APP_DATA"]!), appGroupDirectory()].compactMap { $0 }
        return roots.flatMap { root -> [String] in
            let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            let prefix = root.resolvingSymlinksInPath().path + "/"
            return files.filter { $0.pathExtension.lowercased() == "pdf" }.map { file in
                let path = file.resolvingSymlinksInPath().path
                return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
            }
        }.sorted()
    }

    /// The app's containers hold one PDF, and it is in `tmp/Export`.
    private func assertTheOnePDFIsInTmpExport(_ moment: String, file: StaticString = #filePath, line: UInt = #line) {
        let pdfs = pdfFilesInTheAppContainers()
        XCTAssertEqual(pdfs.count, 1, "\(moment), the app's containers hold one PDF: \(pdfs)", file: file, line: line)
        XCTAssertTrue(pdfs.allSatisfy { $0.hasPrefix("tmp/Export/") }, "\(moment), the PDF is in tmp/Export: \(pdfs)", file: file, line: line)
    }

    /// The labels of the share sheet's actions, after a swipe up that shows
    /// the whole list.
    private func shareSheetActionLabels(_ sheet: XCUIElement) -> Set<String> {
        let actions = sheet.cells.matching(identifier: "actionGroupCell")
        var labels = Set(actions.allElementsBoundByIndex.map(\.label))
        for _ in 0..<3 where !(labels.contains("Markup") && labels.contains("Print")) {
            sheet.swipeUp()
            labels.formUnion(actions.allElementsBoundByIndex.map(\.label))
        }
        return labels
    }

    /// mm-t42.14, comment of r13-14 (mm-t42.27) (r13-19): on the export
    /// screen, "Make PDF" shows the share sheet with its actions, "Save to
    /// Files", "Markup" and "Print" among them, and no "Copy". Comment of
    /// mm-t41.24, the part that the simulator can prove (r13-19, r16-01): a
    /// close of the share sheet with no destination shows the export screen
    /// with no message, and no PDF file stays in the app's data container
    /// (tmp, Library and Documents) or its App Group container. (AirDrop is
    /// not on the simulator, and the network watch needs a device or a
    /// proxy; both stay device checks.)
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
        let labels = shareSheetActionLabels(sheet)
        for action in ["Save to Files", "Markup", "Print"] {
            XCTAssertTrue(labels.contains(action), "the share sheet offers \"\(action)\": \(labels.sorted())")
        }
        XCTAssertFalse(labels.contains("Copy"), "the share sheet offers no \"Copy\": \(labels.sorted())")
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Copy")).firstMatch
        XCTAssertFalse(copy.exists, "the share sheet shows no \"Copy\"")
        assertTheOnePDFIsInTmpExport("while the share sheet shows")
        // Close the share sheet with no destination.
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the share sheet closes")
        assertScreen("Export")
        XCTAssertTrue(makePDF.isHittable, "the export screen shows again")
        XCTAssertEqual(app.alerts.count, 0, "the close shows no message")
        XCTAssertFalse(element(labelled: "The PDF could not be made. Try again.").exists, "the close shows no message")
        var left = pdfFilesInTheAppContainers()
        for _ in 0..<10 where !left.isEmpty {
            usleep(300_000)
            left = pdfFilesInTheAppContainers()
        }
        XCTAssertEqual(left, [], "after the close, no PDF file stays in the app's data container or its App Group container")
    }

    /// Taps "Save to Files" in the share sheet and waits for the Files
    /// picker. Answers the picker's navigation bar.
    private func openSaveToFiles(_ sheet: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let saveToFiles = sheet.cells.matching(identifier: "actionGroupCell").matching(NSPredicate(format: "label == %@", "Save to Files")).firstMatch
        XCTAssertTrue(saveToFiles.waitForExistence(timeout: 10), "the share sheet offers \"Save to Files\"", file: file, line: line)
        if !saveToFiles.isHittable { sheet.swipeUp() }
        saveToFiles.tap()
        let pickerBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"].firstMatch
        XCTAssertTrue(pickerBar.waitForExistence(timeout: 10), "\"Save to Files\" shows the Files picker", file: file, line: line)
        return pickerBar
    }

    /// mm-t42.14, review of mm-t45.1 (r13-19, r16-01): a cancel in a
    /// destination does not close the share sheet, so the PDF must stay.
    /// "Make PDF", then "Save to Files", then "Cancel" in the Files picker:
    /// the share sheet shows again, and the one PDF stays in tmp/Export.
    /// Then "Save to Files" again and "Save" in "On My iPhone": the share
    /// sheet closes, "On My iPhone" holds a file with the same bytes as the
    /// PDF, and no PDF stays in the app's containers.
    ///
    /// On the iOS 27.0 simulator, "Cancel" in the Files picker does not run
    /// the share sheet's completion handler, so this test also passed on
    /// the code before the fix (7 October 2026). It does not show the case
    /// of the review, where the handler runs while the share sheet stays.
    /// Mail gives that case, and Mail needs a mail account, which the
    /// simulator does not have: "Mail, Cancel, then Save to Files" stays a
    /// device check.
    func testACancelledDestinationKeepsThePDFForTheNextOne() throws {
        // "On My iPhone" keeps the PDFs of earlier runs; the save must not
        // meet a file of the same name.
        let storage = try XCTUnwrap(sharedGroupDirectory("group.com.apple.FileProvider.LocalStorage"), "the simulator has the \"On My iPhone\" storage")
            .appendingPathComponent("File Provider Storage")
        for file in (try? FileManager.default.contentsOfDirectory(at: storage, includingPropertiesForKeys: nil)) ?? [] where file.pathExtension == "pdf" {
            try FileManager.default.removeItem(at: file)
        }
        try launchOnToday("week1")
        let sheet = makeAPDFFromSettings()
        assertTheOnePDFIsInTmpExport("while the share sheet shows")
        let folder = URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("tmp/Export")
        let made = (FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? [])
            .first { $0.pathExtension == "pdf" }
        let pdf = try Data(contentsOf: try XCTUnwrap(made, "tmp/Export holds the PDF"))

        // Save to Files, then Cancel. In the picker, "Cancel" is on the
        // Browse level, one step back from "On My iPhone".
        var pickerBar = openSaveToFiles(sheet)
        let cancel = pickerBar.buttons["Cancel"]
        for _ in 0..<3 where !cancel.exists {
            pickerBar.buttons["BackButton"].firstMatch.tap()
            _ = cancel.waitForExistence(timeout: 3)
        }
        XCTAssertTrue(cancel.exists, "the Files picker shows \"Cancel\"")
        cancel.tap()
        XCTAssertTrue(pickerBar.waitForNonExistence(timeout: 10), "\"Cancel\" closes the Files picker")
        XCTAssertTrue(sheet.exists, "after \"Cancel\" in the Files picker, the share sheet still shows")
        for second in 0..<3 {
            sleep(1)
            assertTheOnePDFIsInTmpExport("\(second + 1) s after \"Cancel\" in the Files picker, while the share sheet shows")
        }

        // Save to Files again, then Save in On My iPhone.
        pickerBar = openSaveToFiles(sheet)
        let save = app.buttons["DOCPicker.actionButton"].firstMatch
        if !save.waitForExistence(timeout: 3) {
            let onMyIPhone = app.cells.containing(NSPredicate(format: "label == %@", "On My iPhone")).firstMatch
            XCTAssertTrue(onMyIPhone.waitForExistence(timeout: 5), "the Files picker shows \"On My iPhone\"")
            onMyIPhone.tap()
        }
        XCTAssertTrue(save.waitForExistence(timeout: 5), "the Files picker shows \"Save\"")
        save.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 15), "after \"Save\", the share sheet closes")
        assertScreen("Export")
        var saved = false
        for _ in 0..<20 where !saved {
            let files = FileManager.default.enumerator(at: storage, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            saved = files.contains { $0.pathExtension == "pdf" && (try? Data(contentsOf: $0)) == pdf }
            if !saved { usleep(500_000) }
        }
        XCTAssertTrue(saved, "\"On My iPhone\" holds the saved PDF, with the same bytes as the PDF that the app made")
        var left = pdfFilesInTheAppContainers()
        for _ in 0..<10 where !left.isEmpty {
            usleep(300_000)
            left = pdfFilesInTheAppContainers()
        }
        XCTAssertEqual(left, [], "after the share sheet closes, no PDF file stays in the app's data container or its App Group container")
    }

    /// mm-t42.14, review of mm-t45.1 (r13-19, r16-01): Print removes the
    /// share sheet before it shows its options, and it needs the PDF until
    /// they close. "Make PDF", then "Print": while the print options show,
    /// the PDF stays in tmp/Export. "Cancel": the export screen shows, and
    /// no PDF stays in the app's containers. (A first version of the fix
    /// deleted the PDF when the share sheet went, and Print then showed
    /// "Protected PDF files can only be printed separately.". A real
    /// printer stays a device check.)
    ///
    /// While the print options show, iOS keeps its own copy of the PDF in
    /// `tmp/<UUID>/`, and removes it when they close. When the app ends
    /// first, that copy stays until the next launch removes it (bug
    /// mm-t45.11; `testTheNextLaunchRemovesThePrintCopyLeftByAForceQuit`
    /// in `AutomatedChecks+PrintTmp.swift`). When this test fails before
    /// "Cancel", it removes that copy, so that the export tests after it do
    /// not fail because of it.
    func testPrintKeepsThePDFUntilItsOptionsClose() throws {
        addTeardownBlock { [self] in
            app.terminate()
            let temporary = URL(fileURLWithPath: runEnvironment["APP_DATA"]!).appendingPathComponent("tmp")
            for path in pdfFilesInTheAppContainers() where path.hasPrefix("tmp/") && !path.hasPrefix("tmp/Export/") {
                try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent().appendingPathComponent(path).deletingLastPathComponent())
            }
        }
        try launchOnToday("week1")
        let sheet = makeAPDFFromSettings()
        let print = sheet.cells.matching(identifier: "actionGroupCell").matching(NSPredicate(format: "label == %@", "Print")).firstMatch
        XCTAssertTrue(print.waitForExistence(timeout: 10), "the share sheet offers \"Print\"")
        print.tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10), "\"Print\" shows the print options with \"Cancel\"")
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5), "while the print options show, the share sheet is gone")
        XCTAssertEqual(app.alerts.count, 0, "Print shows no message: \(app.alerts.firstMatch.label)")
        for second in 0..<3 {
            sleep(1)
            let pdfs = pdfFilesInTheAppContainers()
            XCTAssertEqual(pdfs.filter { $0.hasPrefix("tmp/Export/") }.count, 1,
                           "\(second + 1) s after \"Print\", while the print options show, tmp/Export holds the PDF: \(pdfs)")
        }
        cancel.tap()
        XCTAssertTrue(cancel.waitForNonExistence(timeout: 10), "\"Cancel\" closes the print options")
        assertScreen("Export")
        var left = pdfFilesInTheAppContainers()
        for _ in 0..<10 where !left.isEmpty {
            usleep(300_000)
            left = pdfFilesInTheAppContainers()
        }
        XCTAssertEqual(left, [], "after the print options close, no PDF file stays in the app's data container or its App Group container")
    }
}
