import XCTest
import notify

/// Rulings r13-19 and r16-01 (epic mm-t45): the app-lock flow checks of the
/// device-check beads mm-t15.14, mm-t14.28, mm-t41.15, mm-t42.14 and
/// mm-t24.22, as UI tests on the simulator. Each test names its bead and the
/// check that it replaces.
///
/// The app-lock test seam (`App/Midmorning/AppLock/AppLockTestSeam.swift`,
/// Debug builds only) answers each system authentication request with the
/// next result of a script file, and gives the enrolment state hash from
/// the same file. The test writes the file, and the app writes one log line
/// for each request. So a test can make a request succeed, fail or cancel,
/// count the requests and read the policy of each one. The real Face ID
/// prompt, the passcode entry, a real enrolment change and the App Switcher
/// stay device checks.
///
/// The device's `Biometry` stays real. On the iOS simulator with no Face ID
/// enrolled, LocalAuthentication gives "passcode only". A test that needs
/// Face ID enrols it with the simulator's own notification
/// (`setSimulatedFaceID`), and its teardown takes the enrolment off again.
extension AutomatedChecks {
    // MARK: The app-lock test seam

    private var appData: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"]!)
    }

    /// The seam's script file, in the app's own data container. The app sees
    /// the container at the same path.
    var appLockScript: URL {
        appData.appendingPathComponent("Library/AppLockTestScript.json")
    }

    /// The seam's log: one line for each request, "<policy> <reason key>
    /// <result>".
    var appLockLog: URL {
        appLockScript.deletingPathExtension().appendingPathExtension("log")
    }

    /// Writes the results of the next system authentication requests
    /// ("succeed", "fail", "cancel" or "noPasscode"), first to last, and the
    /// enrolment state hash that the seam gives (`nil`: no hash).
    func scriptAppLock(_ results: [String], enrolmentHash: String? = "A", file: StaticString = #filePath, line: UInt = #line) {
        var script: [String: Any] = ["results": results]
        if let enrolmentHash { script["enrolmentHash"] = enrolmentHash }
        do {
            let data = try JSONSerialization.data(withJSONObject: script)
            try data.write(to: appLockScript, options: .atomic)
        } catch {
            XCTFail("cannot write the app-lock script: \(error)", file: file, line: line)
        }
    }

    /// The requests that the app made, one log line each.
    func appLockRequests() -> [String] {
        guard let text = try? String(contentsOf: appLockLog, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").map(String.init)
    }

    /// Waits until the app made `count` requests, then waits 2 seconds more
    /// and requires that no other request starts. Returns the log lines.
    @discardableResult
    func assertAppLockRequests(_ count: Int, _ message: String, file: StaticString = #filePath, line: UInt = #line) -> [String] {
        let deadline = Date().addingTimeInterval(8)
        while appLockRequests().count < count, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
        }
        Thread.sleep(forTimeInterval: 2)
        let requests = appLockRequests()
        XCTAssertEqual(requests.count, count, "\(message): \(requests)", file: file, line: line)
        return requests
    }

    /// Launches with the seam on: the scenario's store (or no store), a new
    /// log and the script `results`.
    func launchWithTheSeam(_ scenario: String?, results: [String], enrolmentHash: String? = "A", launchMarker: String? = nil) throws {
        app.terminate()
        removeDeletionFault()
        try? FileManager.default.removeItem(at: appLockLog)
        try FileManager.default.createDirectory(at: appLockScript.deletingLastPathComponent(), withIntermediateDirectories: true)
        scriptAppLock(results, enrolmentHash: enrolmentHash)
        app.launchEnvironment["MIDMORNING_APP_LOCK_SCRIPT"] = appLockScript.path
        try launch(scenario, launchMarker: launchMarker)
    }

    // MARK: Simulated Face ID

    /// Enrols Face ID on the simulator, or takes the enrolment off, with
    /// the notification that the simulator's Features menu sends. With Face
    /// ID enrolled, LocalAuthentication gives `.faceID`; with none, it gives
    /// "passcode only". The teardown takes the enrolment off, so that the
    /// next test starts as on a new simulator.
    func setSimulatedFaceID(enrolled: Bool) {
        let name = "com.apple.BiometricKit.enrollmentChanged"
        var token: Int32 = 0
        notify_register_check(name, &token)
        notify_set_state(token, enrolled ? 1 : 0)
        notify_post(name)
        notify_cancel(token)
        Thread.sleep(forTimeInterval: 1)
        if enrolled {
            addTeardownBlock { [weak self] in self?.setSimulatedFaceID(enrolled: false) }
        }
    }

    // MARK: A deletion that fails

    private var deletionFault: URL {
        appData.appendingPathComponent("Library/Application Support/Record/AppLockFault")
    }

    /// Makes the next deletion fail: a folder in the store directory that
    /// holds a file and that the app cannot write, so the app cannot remove
    /// the file (the device check's "make one file impossible to remove").
    func makeTheDeletionFail(file: StaticString = #filePath, line: UInt = #line) {
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: deletionFault, withIntermediateDirectories: true)
            try Data("fault".utf8).write(to: deletionFault.appendingPathComponent("keep"))
            try manager.setAttributes([.posixPermissions: 0o500], ofItemAtPath: deletionFault.path)
        } catch {
            XCTFail("cannot make the deletion fail: \(error)", file: file, line: line)
        }
        addTeardownBlock { [weak self] in self?.removeDeletionFault() }
    }

    /// Makes the deletion work again.
    func removeDeletionFault() {
        let manager = FileManager.default
        guard manager.fileExists(atPath: deletionFault.path) else { return }
        try? manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: deletionFault.path)
        try? manager.removeItem(at: deletionFault)
    }

    // MARK: The cover

    var unlockButton: XCUIElement { app.buttons["Unlock"].firstMatch }
    var deleteEverythingButton: XCUIElement { app.buttons["Delete everything"].firstMatch }
    var deleteFromThisDeviceButton: XCUIElement { app.buttons["Delete from this device"].firstMatch }

    /// The locked cover shows: "Midmorning", "Unlock" (or "Delete from this
    /// device" after an enrolment change) and "Delete everything", and no
    /// part of the screen under it: no navigation bar, no "Get support" and
    /// no entry.
    func assertTheLockedCover(afterAnEnrolmentChange: Bool = false, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let first = afterAnEnrolmentChange ? deleteFromThisDeviceButton : unlockButton
        XCTAssertTrue(first.waitForExistence(timeout: 20), "\(message): the cover shows \"\(first.label.isEmpty ? (afterAnEnrolmentChange ? "Delete from this device" : "Unlock") : first.label)\"", file: file, line: line)
        XCTAssertTrue(app.staticTexts["Midmorning"].exists, "\(message): the cover shows \"Midmorning\"", file: file, line: line)
        XCTAssertTrue(deleteEverythingButton.exists, "\(message): the cover shows \"Delete everything\"", file: file, line: line)
        if afterAnEnrolmentChange {
            XCTAssertFalse(unlockButton.exists, "\(message): after an enrolment change the cover shows no \"Unlock\"", file: file, line: line)
        } else {
            XCTAssertFalse(deleteFromThisDeviceButton.exists, "\(message): the cover shows no \"Delete from this device\"", file: file, line: line)
        }
        XCTAssertEqual(app.navigationBars.count, 0, "\(message): no screen shows under the cover", file: file, line: line)
        XCTAssertFalse(app.buttons["Get support"].exists, "\(message): the cover shows no \"Get support\"", file: file, line: line)
        XCTAssertFalse(element(labelContaining: "Toast and tea").exists, "\(message): the cover shows no entry", file: file, line: line)
    }

    /// No cover shows, and the screen `title` shows.
    func assertNoCover(on title: String, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10), "\(message): \"\(title)\" shows", file: file, line: line)
        XCTAssertFalse(unlockButton.exists, "\(message): no cover shows", file: file, line: line)
        XCTAssertFalse(app.staticTexts["Midmorning"].exists, "\(message): no cover shows", file: file, line: line)
    }

    /// Leaves the app for `seconds` (the Home Screen), then returns to it.
    func leaveTheApp(for seconds: TimeInterval) {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: seconds)
        app.activate()
    }

    /// Taps the lock control in Today's navigation bar.
    func tapTheLockControl(file: StaticString = #filePath, line: UInt = #line) {
        let lock = app.navigationBars["Today"].buttons["Lock"]
        XCTAssertTrue(lock.waitForExistence(timeout: 8), "Today shows the lock control", file: file, line: line)
        lock.tap()
    }

    // MARK: mm-t15.14 (app lock): when the app asks

    /// mm-t15.14, comment of mm-t15.17 (commit 1f42d63): "open the app from
    /// the Home Screen. The cover and the Face ID request show with no tap.
    /// Cancel the request: the cover stays with 'Unlock', no second request
    /// starts". Then "Unlock" makes the request, and after a success Today
    /// shows. The comment of 25 September, item (2) "The cover", "Unlock
    /// control": the cover shows "Midmorning", "Unlock" and "Delete
    /// everything", and nothing of Today. (VoiceOver focus on "Unlock" after
    /// the cancel stays a device check: a UI test cannot read the VoiceOver
    /// focus.)
    func testTheAppLockAsksAtLaunch() throws {
        try launchWithTheSeam("lock-week1", results: ["cancel"])
        assertTheLockedCover("at launch")
        let requests = assertAppLockRequests(1, "the launch makes one request with no tap, and no second request starts after the cancel")
        XCTAssertEqual(requests.first, "biometricsAndPasscode applock.unlockReason cancel", "the request asks for Face ID or the passcode")
        assertTheLockedCover("after the cancel")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\" and a success")
        assertAppLockRequests(2, "\"Unlock\" makes one request")
        XCTAssertTrue(element(labelContaining: "Toast and tea").exists, "Today shows its entry after Unlock")
    }

    /// mm-t15.14, comment of mm-t15.17: "Leave for 45 seconds and return:
    /// the request shows again with no tap. Return within 20 seconds: no
    /// request." With "Lock after" "30 seconds" (the comment's set-up). The
    /// comment of 25 September, item (1), the timing against the real
    /// clock, and item (7) "Unsaved text survives the lock", "Return to a
    /// draft": New entry with "Toast and" in What shows the cover after the
    /// grace period, and after "Unlock" the same screen shows "Toast and".
    func testTheCoverAfterTheGracePeriod() throws {
        try launchWithTheSeam("lock-week1-30s", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        assertAppLockRequests(1, "the launch makes one request")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Toast and")
        // Return within 20 seconds: no cover and no request.
        leaveTheApp(for: 12)
        XCTAssertTrue(what.waitForExistence(timeout: 10), "a return within the grace period shows the new-entry screen")
        XCTAssertFalse(unlockButton.exists, "a return within the grace period shows no cover")
        assertAppLockRequests(1, "a return within the grace period makes no request")
        XCTAssertEqual(what.value as? String, "Toast and", "the new-entry screen keeps \"Toast and\"")
        // Return after 45 seconds: the cover and the request, with no tap.
        scriptAppLock(["cancel"])
        leaveTheApp(for: 45)
        assertTheLockedCover("a return after 45 seconds")
        XCTAssertEqual(assertAppLockRequests(2, "a return after the grace period makes one request with no tap").last,
                       "biometricsAndPasscode applock.unlockReason cancel")
        XCTAssertFalse(element(labelContaining: "Toast and").exists, "the cover shows no typed text")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        XCTAssertTrue(unlockButton.waitForNonExistence(timeout: 8), "\"Unlock\" and a success take the cover off")
        XCTAssertTrue(what.waitForExistence(timeout: 8), "after Unlock the new-entry screen shows again")
        XCTAssertEqual(what.value as? String, "Toast and", "after Unlock the new-entry screen shows \"Toast and\"")
    }

    // MARK: mm-t24.22 item 3 and mm-t15.14: the lock control on Today

    /// mm-t24.22, item 3 of the first list: the Today lock control's real
    /// cover. "Lock at once": with the app lock on, one tap on the lock
    /// control shows the cover at once. mm-t15.14, comment of mm-t15.17:
    /// "Tap the lock control on Today: the cover shows, and no request
    /// starts until you tap 'Unlock'." "Lock control with the app lock off":
    /// the cover shows "Midmorning" only, and a tap takes it off with no
    /// request.
    func testTheLockControlShowsTheCover() throws {
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        assertAppLockRequests(1, "the launch makes one request")
        tapTheLockControl()
        assertTheLockedCover("after the lock control")
        assertAppLockRequests(1, "the lock control starts no request")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\" and a success")
        assertAppLockRequests(2, "\"Unlock\" makes the request")

        // The app lock off.
        try launchWithTheSeam("week1", results: [])
        assertNoCover(on: "Today", "with the app lock off, the launch")
        tapTheLockControl()
        let title = app.staticTexts["Midmorning"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "with the app lock off, the lock control shows the cover")
        XCTAssertFalse(unlockButton.exists, "with the app lock off, the cover shows no \"Unlock\"")
        XCTAssertFalse(deleteEverythingButton.exists, "with the app lock off, the cover shows no \"Delete everything\"")
        XCTAssertEqual(app.navigationBars.count, 0, "with the app lock off, the cover hides Today")
        title.tap()
        assertNoCover(on: "Today", "with the app lock off, a tap on the cover")
        assertAppLockRequests(0, "with the app lock off, the cover makes no request")
    }

    // MARK: mm-t15.14 item (3): Delete everything from the cover

    /// mm-t15.14, comment of 25 September, item (3), "Delete everything
    /// from the cover": "Delete everything" makes the request first. After
    /// a cancel the cover stays and nothing is deleted. After a success,
    /// "Delete everything?" shows with "Cancel"; "Cancel" keeps the cover.
    /// The confirmation shows "Everything is deleted.", and the next launch
    /// shows onboarding, because the record is gone. (The real system
    /// request stays a device check.)
    func testDeleteEverythingFromTheCover() throws {
        try launchWithTheSeam("lock-week1", results: ["cancel"])
        assertTheLockedCover("at launch")
        assertAppLockRequests(1, "the launch makes one request")
        scriptAppLock(["cancel"])
        deleteEverythingButton.tap()
        assertAppLockRequests(2, "\"Delete everything\" makes the request")
        XCTAssertFalse(app.alerts.firstMatch.exists, "after a cancel, no \"Delete everything?\" shows")
        assertTheLockedCover("after a cancel of the request")
        scriptAppLock(["succeed"])
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8), "after a success, \"Delete everything?\" shows")
        tapDialogButton("Cancel")
        assertTheLockedCover("after \"Cancel\" in \"Delete everything?\"")
        scriptAppLock(["succeed"])
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8))
        tapDialogButton("Delete everything")
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "the deleted screen shows")
        assertAppLockRequests(4, "each \"Delete everything\" makes one request")
        // The record is gone: the next launch shows onboarding.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Continue"].firstMatch.waitForExistence(timeout: 20), "after the deletion, the app opens on onboarding")
    }

    // MARK: mm-t15.14 and mm-t41.15: after an enrolment change

    /// mm-t41.15, ruling r17-04 (mm-t41.27, commit f1d80bf): with "Face ID
    /// only" on and an enrolment change, the cover shows "Delete from this
    /// device" and no "Unlock". With a deletion that fails, "Delete from
    /// this device" and its confirmation keep the cover, which shows "Could
    /// not delete. Try again." under its controls, and no deleted screen.
    /// With the deletion fixed, a second tap removes the line and shows the
    /// deleted screen. mm-t15.14, comment of 25 September, item (5),
    /// "Enrolment changed" and "Delete everything after an enrolment
    /// change": no request starts, and "Delete everything" shows its
    /// confirmation on one tap. Comment of ruling r13-06: the cover shows
    /// "Delete from this device" and "Delete everything", and no "Unlock".
    /// (The test seam gives the changed enrolment hash; a real change of
    /// the enrolled faces stays a device check.)
    func testDeleteFromThisDeviceAfterAnEnrolmentChange() throws {
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-face-only", results: [], enrolmentHash: "B")
        assertTheLockedCover(afterAnEnrolmentChange: true, "after an enrolment change")
        assertAppLockRequests(0, "after an enrolment change the app makes no request")
        // "Delete everything" after an enrolment change: the confirmation on one tap.
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8), "\"Delete everything\" shows its confirmation on one tap")
        assertAppLockRequests(0, "\"Delete everything\" makes no request after an enrolment change")
        tapDialogButton("Cancel")
        // Ruling r17-04: a deletion that fails.
        makeTheDeletionFail()
        deleteFromThisDeviceButton.tap()
        XCTAssertTrue(app.alerts["Delete from this device?"].waitForExistence(timeout: 8), "\"Delete from this device?\" shows")
        tapDialogButton("Delete from this device")
        let failure = element(labelled: "Could not delete. Try again.")
        XCTAssertTrue(failure.waitForExistence(timeout: 10), "after a failed deletion the cover shows \"Could not delete. Try again.\"")
        assertTheLockedCover(afterAnEnrolmentChange: true, "after a failed deletion")
        XCTAssertGreaterThan(failure.frame.minY, deleteEverythingButton.frame.maxY, "the line shows under the cover's controls")
        XCTAssertGreaterThan(failure.frame.minY, deleteFromThisDeviceButton.frame.maxY, "the line shows under the cover's controls")
        XCTAssertFalse(element(labelBeginningWith: "This device").exists, "after a failed deletion no deleted screen shows")
        // The deletion works again.
        removeDeletionFault()
        deleteFromThisDeviceButton.tap()
        XCTAssertTrue(app.alerts["Delete from this device?"].waitForExistence(timeout: 8))
        tapDialogButton("Delete from this device")
        XCTAssertTrue(element(labelBeginningWith: "This device").waitForExistence(timeout: 10), "the deleted screen shows")
        XCTAssertFalse(failure.exists, "the line goes")
        assertAppLockRequests(0, "\"Delete from this device\" makes no request")
    }

    // MARK: mm-t15.14: "Face ID only" (rulings r15-03 and r13-06)

    /// Opens Settings from Today and scrolls to the switch `label` of the
    /// Privacy group.
    @discardableResult
    func openSettingsAt(_ label: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        tapToolbar("Settings")
        assertScreen("Settings", file: file, line: line)
        let toggle = app.switches[label].firstMatch
        XCTAssertTrue(scrollTo(toggle), "Settings shows \"\(label)\"", file: file, line: line)
        return toggle
    }

    /// "Face ID only": a tap on the switch, "Turn on" in the warning, and
    /// the scripted request.
    func turnOnFaceIDOnly(_ result: String, enrolmentHash: String, file: StaticString = #filePath, line: UInt = #line) {
        scriptAppLock([result], enrolmentHash: enrolmentHash)
        flipSwitch("Face ID only", file: file, line: line)
        XCTAssertTrue(app.alerts["Face ID only"].waitForExistence(timeout: 8), "the warning \"Face ID only\" shows", file: file, line: line)
        tapDialogButton("Turn on", file: file, line: line)
    }

    /// The value of the switch `label`: "1" on, "0" off.
    func switchValue(_ label: String) -> String? {
        let toggle = app.switches[label].firstMatch
        _ = toggle.waitForExistence(timeout: 5)
        return toggle.value as? String
    }

    /// mm-t15.14, comment of ruling r15-03 (mm-t15.21, commit 4e844d7), on
    /// a simulator with Face ID enrolled and the app lock on:
    /// (1) "Turn on" makes a Face ID request (the biometrics-only policy)
    /// before the switch turns on; after a success the switch is on.
    /// (2) Off needs a request. On again with a cancel: the switch stays
    /// off. Then the lock control and "Unlock" ask with the policy that
    /// offers the device passcode, because the setting is off.
    /// (3) A failed request (as at a biometry lockout): the switch stays
    /// off. Then a face is added (a new enrolment hash), the setting turns
    /// on, and the cover after the lock shows "Unlock", not "Delete from
    /// this device".
    /// Comment of ruling r13-06 (mm-t15.20, commit 965e92b): the lock
    /// control and Face ID unlock the app; an enrolment change while the
    /// setting stays on shows "Delete from this device" and "Delete
    /// everything", and no "Unlock".
    /// The real Face ID prompt ("offers no 'Enter Passcode'"), the real
    /// passcode entry, a real lockout and a real change of the enrolled
    /// faces stay device checks; the seam gives the results and the hash.
    func testFaceIDOnlyTurnOn() throws {
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-week1", results: ["succeed"], enrolmentHash: "A")
        assertNoCover(on: "Today", "after the request at launch succeeds")
        let faceIDOnly = openSettingsAt("Face ID only")
        XCTAssertTrue(faceIDOnly.isEnabled, "\"Face ID only\" is enabled with Face ID enrolled and the app lock on")
        XCTAssertEqual(switchValue("Face ID only"), "0")
        // (1) Turn on, with a success.
        turnOnFaceIDOnly("succeed", enrolmentHash: "A")
        XCTAssertEqual(assertAppLockRequests(2, "\"Turn on\" makes one request").last,
                       "biometricsOnly applock.unlockReason succeed", "\"Turn on\" asks for Face ID only, with no passcode")
        XCTAssertEqual(switchValue("Face ID only"), "1", "after a success the switch is on")
        // (2) Off needs a request; on again with a cancel stays off.
        scriptAppLock(["succeed"], enrolmentHash: "A")
        flipSwitch("Face ID only")
        XCTAssertEqual(assertAppLockRequests(3, "off makes one request").last, "biometricsOnly applock.unlockReason succeed")
        XCTAssertEqual(switchValue("Face ID only"), "0", "after the request the switch is off")
        turnOnFaceIDOnly("cancel", enrolmentHash: "A")
        assertAppLockRequests(4, "\"Turn on\" makes one request")
        XCTAssertEqual(switchValue("Face ID only"), "0", "after a cancel the switch stays off")
        goBack()
        assertScreen("Today")
        tapTheLockControl()
        assertTheLockedCover("after the lock control")
        scriptAppLock(["succeed"], enrolmentHash: "A")
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\"")
        XCTAssertEqual(assertAppLockRequests(5, "\"Unlock\" makes one request").last,
                       "biometricsAndPasscode applock.unlockReason succeed", "with the setting off, \"Unlock\" offers the device passcode")
        // (3) A failed request keeps the switch off.
        openSettingsAt("Face ID only")
        turnOnFaceIDOnly("fail", enrolmentHash: "A")
        assertAppLockRequests(6, "\"Turn on\" makes one request")
        XCTAssertEqual(switchValue("Face ID only"), "0", "after a failed request the switch stays off")
        // A face is added while the setting is off: the app returns locked
        // ("Lock after" is "At once") and asks again.
        scriptAppLock(["succeed"], enrolmentHash: "B")
        leaveTheApp(for: 3)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "after the return and Face ID, Settings shows again")
        XCTAssertEqual(assertAppLockRequests(7, "the return makes one request with no tap").last,
                       "biometricsAndPasscode applock.unlockReason succeed")
        turnOnFaceIDOnly("succeed", enrolmentHash: "B")
        assertAppLockRequests(8, "\"Turn on\" makes one request")
        XCTAssertEqual(switchValue("Face ID only"), "1", "after a success the switch is on")
        goBack()
        assertScreen("Today")
        // Ruling r13-06: the lock control, then Face ID unlocks the app.
        tapTheLockControl()
        assertTheLockedCover("after the lock control, with the hash kept at the turn-on")
        scriptAppLock(["succeed"], enrolmentHash: "B")
        unlockButton.tap()
        assertNoCover(on: "Today", "Face ID unlocks the app")
        XCTAssertEqual(assertAppLockRequests(9, "\"Unlock\" makes one request").last,
                       "biometricsOnly applock.unlockReason succeed", "with the setting on, \"Unlock\" asks for Face ID only")
        // A return with the same enrolment: "Unlock", and the request.
        scriptAppLock(["cancel"], enrolmentHash: "B")
        leaveTheApp(for: 3)
        assertTheLockedCover("a return with no enrolment change")
        assertAppLockRequests(10, "the return makes one request with no tap")
        scriptAppLock(["succeed"], enrolmentHash: "B")
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\"")
        // An appearance is added while the setting stays on.
        scriptAppLock([], enrolmentHash: "C")
        leaveTheApp(for: 3)
        assertTheLockedCover(afterAnEnrolmentChange: true, "after an enrolment change with the setting on")
        assertAppLockRequests(11, "after an enrolment change the app makes no request")
    }

    /// mm-t15.14, comment of mm-8jr (commit d3f809a) with its correction:
    /// turn "Face ID only" on, set "Lock after" to "2 minutes", then turn
    /// the app lock off. Quit the app and open it again. The switch is off,
    /// "Lock after" reads "2 minutes", and the app opens with no request.
    /// Turn the app lock on again: "Face ID only" is still on.
    func testTheAppLockSettingsStayAfterAQuit() throws {
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-week1", results: ["succeed"], enrolmentHash: "A")
        assertNoCover(on: "Today", "after the request at launch succeeds")
        openSettingsAt("Face ID only")
        turnOnFaceIDOnly("succeed", enrolmentHash: "A")
        XCTAssertEqual(switchValue("Face ID only"), "1")
        let lockAfter = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Lock after")).firstMatch
        XCTAssertTrue(scrollTo(lockAfter), "the Privacy group shows \"Lock after\"")
        lockAfter.tap()
        let twoMinutes = app.buttons["2 minutes"].firstMatch
        XCTAssertTrue(twoMinutes.waitForExistence(timeout: 5), "\"Lock after\" offers \"2 minutes\"")
        twoMinutes.tap()
        scriptAppLock(["succeed"], enrolmentHash: "A")
        flipSwitch("Lock with Face ID")
        assertAppLockRequests(3, "the app lock off makes one request")
        XCTAssertEqual(switchValue("Lock with Face ID"), "0", "the app lock is off")
        // Quit and open again, with the same store.
        app.terminate()
        app.launch()
        assertNoCover(on: "Today", "the app opens with the app lock off")
        assertAppLockRequests(3, "the app opens with no request")
        openSettingsAt("Lock with Face ID")
        XCTAssertEqual(switchValue("Lock with Face ID"), "0", "after the quit, the app lock switch is off")
        XCTAssertTrue(scrollTo(lockAfter))
        XCTAssertTrue(lockAfter.label.contains("2 minutes") || lockAfter.staticTexts["2 minutes"].exists, "after the quit, \"Lock after\" reads \"2 minutes\": \(lockAfter.label)")
        // The switch on locks the app at once
        // (`AppLockSharedStateIntegrationTests`): the cover, and "Unlock"
        // asks for Face ID only, because the setting is still on.
        scriptAppLock(["succeed"], enrolmentHash: "A")
        flipSwitch("Lock with Face ID")
        assertTheLockedCover("the app lock on again locks the app")
        unlockButton.tap()
        XCTAssertEqual(assertAppLockRequests(4, "\"Unlock\" makes one request").last,
                       "biometricsOnly applock.unlockReason succeed", "\"Unlock\" asks for Face ID only")
        assertNoCover(on: "Settings", "after \"Unlock\"")
        XCTAssertEqual(switchValue("Lock with Face ID"), "1", "the app lock is on again")
        XCTAssertEqual(switchValue("Face ID only"), "1", "\"Face ID only\" is still on")
        XCTAssertTrue(app.switches["Face ID only"].firstMatch.isEnabled, "\"Face ID only\" is enabled again")
    }

    // MARK: mm-t14.28: onboarding screen 4

    /// Goes from onboarding screen 1 to screen 4 ("Permissions") on a new
    /// install: "No" to the three questions of screen 2 with an age, a
    /// height and a weight that exclude nothing (as in
    /// `testOnboardingScreen3`), then "I won't be weighing" on screen 3.
    func passOnboardingToScreen4(file: StaticString = #filePath, line: UInt = #line) {
        let firstContinue = app.buttons["Continue"].firstMatch
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows", file: file, line: line)
        XCTAssertTrue(scrollTo(firstContinue), file: file, line: line)
        firstContinue.tap()
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
        // The keyboard tip of a new simulator can take the first tap.
        if !app.navigationBars["Your start"].waitForExistence(timeout: 3),
           app.navigationBars["A few questions first"].exists {
            app.buttons["Continue"].firstMatch.tap()
        }
        assertScreen("Your start", file: file, line: line)
        let wontBeWeighing = app.buttons["I won't be weighing"].firstMatch
        XCTAssertTrue(dragTo(wontBeWeighing, above: continueButton.frame.minY - 8), "screen 3 shows \"I won't be weighing\"", file: file, line: line)
        wontBeWeighing.tap()
        continueButton.tap()
        assertScreen("Permissions", file: file, line: line)
    }

    /// On screen 4: the app-lock switch `label` and the sentence under it.
    func assertScreen4Lock(_ label: String, sentence: String, file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[label].firstMatch
        XCTAssertTrue(scrollTo(toggle), "screen 4 shows the switch \"\(label)\"", file: file, line: line)
        let text = element(labelled: sentence)
        XCTAssertTrue(text.waitForExistence(timeout: 5), "screen 4 shows \"\(sentence)\"", file: file, line: line)
        XCTAssertGreaterThanOrEqual(text.frame.minY, toggle.frame.maxY - 1, "the sentence shows under the switch", file: file, line: line)
    }

    /// mm-t14.28, comment of mm-t14.32 (commit d3f809a): turn the switch
    /// off on screen 4 and tap Start. Today opens with no cover. Leave the
    /// app for 45 seconds and return: no cover. The Privacy group shows the
    /// switch off. Do onboarding again with the switch on: Today opens with
    /// no cover after Start, and a return after the grace period shows the
    /// cover and the authentication request.
    /// Comment of mm-t14.31, the parts that the simulator has: with Face ID
    /// enrolled, screen 4 shows "Lock with Face ID" and "Midmorning asks for
    /// Face ID or your passcode when it opens."; with a passcode and no
    /// biometric, "Lock with passcode" and "Midmorning asks for your
    /// passcode when it opens."; the sentence shows under the switch when
    /// the switch is on or off. (Touch ID and a device with no passcode stay
    /// device checks: the simulator has neither.)
    func testOnboardingScreen4WithTheAppLockOffAndOn() throws {
        // The simulator with no biometric enrolled: "passcode only".
        try launchWithTheSeam(nil, results: [])
        passOnboardingToScreen4()
        let passcodeSentence = "Midmorning asks for your passcode when it opens."
        assertScreen4Lock("Lock with passcode", sentence: passcodeSentence)
        XCTAssertEqual(switchValue("Lock with passcode"), "1", "the switch is on by default")
        flipSwitch("Lock with passcode")
        XCTAssertEqual(switchValue("Lock with passcode"), "0", "the switch is off")
        assertScreen4Lock("Lock with passcode", sentence: passcodeSentence)
        app.buttons["Start"].firstMatch.tap()
        assertNoCover(on: "Today", "with the switch off, after Start")
        leaveTheApp(for: 45)
        assertNoCover(on: "Today", "with the switch off, a return after 45 seconds")
        assertAppLockRequests(0, "with the switch off, the app makes no request")
        openSettingsAt("Lock with passcode")
        XCTAssertEqual(switchValue("Lock with passcode"), "0", "the Privacy group shows the switch off")

        // Onboarding again, with Face ID enrolled and the switch on.
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam(nil, results: ["cancel"])
        passOnboardingToScreen4()
        assertScreen4Lock("Lock with Face ID", sentence: "Midmorning asks for Face ID or your passcode when it opens.")
        XCTAssertEqual(switchValue("Lock with Face ID"), "1", "the switch is on by default")
        app.buttons["Start"].firstMatch.tap()
        assertNoCover(on: "Today", "with the switch on, after Start")
        assertAppLockRequests(0, "Start makes no request")
        // "Lock after" is "At once", so each return is after the grace period.
        leaveTheApp(for: 3)
        assertTheLockedCover("with the switch on, a return after the grace period")
        assertAppLockRequests(1, "the return makes the request with no tap")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\"")
    }

    // MARK: mm-t42.14: safe mode with the app lock on

    /// mm-t42.14, comment of mm-t42.21 (commit 1f42d63): start safe mode
    /// with the app lock on (the third launch after two that stopped before
    /// Today). The cover and the request show before the safe-mode screen.
    /// Cancel: the cover stays. Unlock: Export and Get support show. Open
    /// Export, leave the app for 45 seconds ("Lock after" "30 seconds") and
    /// return: the cover shows over Export. With the app lock off, safe mode
    /// opens with no cover. (The App Switcher snapshot stays a device check.)
    func testSafeModeWithTheAppLockOn() throws {
        try launchWithTheSeam("lock-week1-30s", results: ["cancel"], launchMarker: "2")
        assertTheLockedCover("safe mode with the app lock on")
        XCTAssertFalse(app.buttons["Export"].exists, "the cover hides the safe-mode screen")
        assertAppLockRequests(1, "safe mode makes one request with no tap, and no second request after the cancel")
        assertTheLockedCover("after the cancel")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        assertNoCover(on: "Today", "after \"Unlock\"")
        XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
        XCTAssertTrue(getSupport(on: "Today").exists, "safe mode shows \"Get support\"")
        let export = app.buttons["Export"].firstMatch
        XCTAssertTrue(export.exists, "safe mode shows \"Export\"")
        export.tap()
        assertScreen("Export")
        scriptAppLock(["cancel"])
        leaveTheApp(for: 45)
        assertTheLockedCover("a return to Export after 45 seconds")
        assertAppLockRequests(3, "the return makes one request with no tap")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        assertNoCover(on: "Export", "after \"Unlock\" Export shows again")
        // The app lock off.
        try launchWithTheSeam("week1", results: [], launchMarker: "2")
        assertNoCover(on: "Today", "safe mode with the app lock off")
        XCTAssertTrue(app.buttons["Export"].firstMatch.exists, "safe mode shows \"Export\"")
        assertAppLockRequests(0, "safe mode with the app lock off makes no request")
    }
}
