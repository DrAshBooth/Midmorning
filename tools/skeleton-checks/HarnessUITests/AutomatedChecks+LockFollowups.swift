import XCTest

/// Rulings r13-19 and r16-01 (epic mm-t45): the follow-up checks of the app
/// lock and of the deletion, from the device-check beads mm-t15.14 (app
/// lock), mm-t41.15 (local delete-all), mm-t12b.1 (ruling r16-03) and
/// mm-t42.14 (export), and the test bead mm-t45.8. Each test names its bead
/// and the check that it replaces.
///
/// The tests use the app-lock test seam and the helpers of
/// `AutomatedChecks+AppLock.swift`: `launchWithTheSeam`, `scriptAppLock`,
/// the cover helpers, and `makeTheDeletionFail`, which puts a folder that
/// the app cannot remove into the store directory. The seeded stores are
/// `week1`, `corrupt`, `lock-week1` and `lock-face-only`
/// (`seeder/Sources/Seeder/AutomatedScenarios.swift` and
/// `AppLockScenarios.swift`).
///
/// Ruling r16-03 (mm-t12b.28): each confirmation is an alert in the centre
/// of the screen with both buttons, and its cancel button closes it and
/// changes nothing. `recordPlanAssertAlert` (in
/// `AutomatedChecks+RecordPlan.swift`) checks the alert, its two buttons and
/// its place in the centre of the screen.
extension AutomatedChecks {
    // MARK: Helpers (private to this file)

    private var lockFollowupsAppData: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"]!)
    }

    /// The store directory in the app's data container (`StoreLayout`).
    private var lockFollowupsStoreDirectory: URL {
        lockFollowupsAppData.appendingPathComponent("Library/Application Support/Record", isDirectory: true)
    }

    /// The bytes of each file in the store directory, at any depth, by its
    /// path in that directory.
    private func lockFollowupsStoreBytes() -> [String: Data] {
        let root = lockFollowupsStoreDirectory.resolvingSymlinksInPath().path
        let files = FileManager.default.enumerator(at: lockFollowupsStoreDirectory, includingPropertiesForKeys: [.isRegularFileKey])?.allObjects as? [URL] ?? []
        var bytes: [String: Data] = [:]
        for url in files where (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
            let path = url.resolvingSymlinksInPath().path
            let key = path.hasPrefix(root + "/") ? String(path.dropFirst(root.count + 1)) : path
            bytes[key] = (try? Data(contentsOf: url)) ?? Data()
        }
        return bytes
    }

    /// The app's App Group container (`group.uk.midmorning`) on the
    /// simulator, found by its container metadata.
    private func lockFollowupsAppGroupDirectory() -> URL? {
        let shared = lockFollowupsAppData
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

    /// Every PDF file in the app's data container (tmp, Library and
    /// Documents included) and in its App Group container, as a path from
    /// the top of its container.
    private func lockFollowupsPDFFiles() -> [String] {
        let roots = [lockFollowupsAppData, lockFollowupsAppGroupDirectory()].compactMap { $0 }
        return roots.flatMap { root -> [String] in
            let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            let prefix = root.resolvingSymlinksInPath().path + "/"
            return files.filter { $0.pathExtension.lowercased() == "pdf" }.map { file in
                let path = file.resolvingSymlinksInPath().path
                return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
            }
        }.sorted()
    }

    /// The app's containers hold one PDF, and it is in `tmp/Export`. The
    /// share sheet deletes that file when it closes, so while the file is
    /// there, the share sheet did not close.
    private func lockFollowupsAssertOnePDFInTmpExport(_ moment: String, file: StaticString = #filePath, line: UInt = #line) {
        let pdfs = lockFollowupsPDFFiles()
        XCTAssertEqual(pdfs.count, 1, "\(moment): the app's containers hold one PDF: \(pdfs)", file: file, line: line)
        XCTAssertTrue(pdfs.allSatisfy { $0.hasPrefix("tmp/Export/") }, "\(moment): the PDF is in tmp/Export: \(pdfs)", file: file, line: line)
    }

    /// The app's data container and its App Group container hold no PDF.
    private func lockFollowupsAssertNoPDF(_ moment: String, file: StaticString = #filePath, line: UInt = #line) {
        var left = lockFollowupsPDFFiles()
        for _ in 0..<10 where !left.isEmpty {
            usleep(300_000)
            left = lockFollowupsPDFFiles()
        }
        XCTAssertEqual(left, [], "\(moment): the app's data container and its App Group container hold no PDF", file: file, line: line)
    }

    /// Opens the export screen through Settings and taps "Make PDF". Waits
    /// for the system share sheet.
    private func lockFollowupsMakeAPDF(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
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

    /// Waits for the deleted screen (its message begins with `message`), and
    /// at once requires that the share sheet does not show, that no
    /// navigation bar shows, and that no element has a label that is not a
    /// part of the deleted screen ("Done", "Get support", the message, and
    /// "Midmorning", the label of the app element). The checks use queries
    /// (see `assertTheTreeHoldsOnlyTheCover`).
    private func lockFollowupsAssertOnlyTheDeletedScreen(beginningWith message: String, _ moment: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element(labelBeginningWith: message).waitForExistence(timeout: 15), "\(moment): the deleted screen shows \"\(message) ...\"", file: file, line: line)
        XCTAssertFalse(app.otherElements["ActivityListView"].exists, "\(moment): the share sheet closes at once: when the deleted screen shows, the share sheet does not show", file: file, line: line)
        XCTAssertEqual(app.navigationBars.count, 0, "\(moment): no other screen shows", file: file, line: line)
        let others = app.descendants(matching: .any).matching(NSPredicate(format: "label != '' AND NOT (label BEGINSWITH %@) AND NOT (label IN %@)", message, ["Midmorning", "Done", "Get support"]))
        XCTAssertEqual(others.allElementsBoundByIndex.map { "\($0.elementType.rawValue) \"\($0.identifier)\" \"\($0.label)\"" }, [],
                       "\(moment): only the deleted screen shows, with no share sheet and no PDF preview", file: file, line: line)
    }

    /// Taps the cancel button of the alert that shows, and waits until the
    /// alert closes.
    private func lockFollowupsCancelTheAlert(_ cancel: String = "Cancel", file: StaticString = #filePath, line: UInt = #line) {
        let alert = app.alerts.firstMatch
        alert.buttons[cancel].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "\"\(cancel)\" closes the alert", file: file, line: line)
    }

    // MARK: mm-t45.8 and mm-t42.14: a deletion from the cover closes the share sheet

    /// mm-t45.8 (export spec, "Share sheet only"; mm-t42.14, the device
    /// check of 7 October 2026 at 12:36 for commit e447168): with the app
    /// lock on, open Export and tap "Make PDF". While the share sheet shows,
    /// leave the app and return after the grace period ("Lock after" "At
    /// once"): the cover shows, and the share sheet stays under it (the PDF
    /// stays in tmp/Export, and the share sheet deletes it when it closes).
    /// (1) "Delete everything" on the cover, the request and the
    /// confirmation: the share sheet closes at once, only the deleted screen
    /// shows, with no PDF preview, and the app's data container and App
    /// Group container hold no PDF. (2) The same with "Delete from this
    /// device" after an enrolment change. "At once": when the deleted
    /// screen shows, the share sheet does not show. (The real Face ID
    /// prompt and a real enrolment change stay device checks; the test seam
    /// gives the result and the enrolment hash.)
    func testDeleteEverythingFromTheCoverClosesTheShareSheet() throws {
        // (1) "Delete everything".
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        _ = lockFollowupsMakeAPDF()
        lockFollowupsAssertOnePDFInTmpExport("while the share sheet shows")
        scriptAppLock(["cancel"])
        leaveTheApp(for: 3)
        assertTheLockedCover("a return to the share sheet after the grace period")
        lockFollowupsAssertOnePDFInTmpExport("under the cover, the share sheet stays")
        scriptAppLock(["succeed"])
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8), "after a success, \"Delete everything?\" shows")
        tapDialogButton("Delete everything")
        lockFollowupsAssertOnlyTheDeletedScreen(beginningWith: "Everything is deleted.", "after \"Delete everything\" from the cover")
        lockFollowupsAssertNoPDF("after \"Delete everything\" from the cover")
        assertAppLockRequests(3, "the launch, the return and \"Delete everything\" make one request each")

        // (2) "Delete from this device" after an enrolment change.
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-face-only", results: ["succeed"], enrolmentHash: "A")
        assertNoCover(on: "Today", "with \"Face ID only\" on, after the request at launch succeeds")
        _ = lockFollowupsMakeAPDF()
        lockFollowupsAssertOnePDFInTmpExport("while the share sheet shows")
        scriptAppLock([], enrolmentHash: "B")
        leaveTheApp(for: 3)
        assertTheLockedCover(afterAnEnrolmentChange: true, "a return to the share sheet after an enrolment change")
        lockFollowupsAssertOnePDFInTmpExport("under the cover after an enrolment change, the share sheet stays")
        deleteFromThisDeviceButton.tap()
        XCTAssertTrue(app.alerts["Delete from this device?"].waitForExistence(timeout: 8), "\"Delete from this device?\" shows")
        tapDialogButton("Delete from this device")
        lockFollowupsAssertOnlyTheDeletedScreen(beginningWith: "This device", "after \"Delete from this device\"")
        lockFollowupsAssertNoPDF("after \"Delete from this device\"")
        assertAppLockRequests(1, "after the enrolment change, the app makes no request")
    }

    /// mm-t15.14, comment of 26 September 2026 at 15:44, check (1)
    /// (mm-t15.15, commit 6391c41), the export share sheet: open the screen,
    /// leave the app, and return after the grace period ("Lock after" "At
    /// once", so 3 seconds are after it). The cover shows over the share
    /// sheet: "Midmorning", "Unlock" and "Delete everything", and no part of
    /// the share sheet or the export screen. The share sheet stays under
    /// the cover (the PDF stays in tmp/Export). After "Unlock" the same
    /// screen shows: the share sheet with the PDF. Then a close of the share
    /// sheet shows the export screen, and no PDF stays. (Before mm-t45.1 the
    /// share sheet showed blank on the iOS 27.0 simulator, so this part
    /// stayed a device check. The App Switcher snapshot stays a device
    /// check.)
    func testTheCoverShowsOverTheExportShareSheet() throws {
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        let sheet = lockFollowupsMakeAPDF()
        lockFollowupsAssertOnePDFInTmpExport("while the share sheet shows")
        scriptAppLock(["cancel"])
        leaveTheApp(for: 3)
        assertTheLockedCover("a return to the share sheet after the grace period")
        XCTAssertFalse(sheet.exists, "the cover hides the share sheet")
        XCTAssertFalse(app.buttons["Make PDF"].exists, "the cover hides the export screen")
        assertAppLockRequests(2, "the return makes one request with no tap")
        lockFollowupsAssertOnePDFInTmpExport("under the cover, the share sheet stays")
        scriptAppLock(["succeed"])
        unlockButton.tap()
        XCTAssertTrue(unlockButton.waitForNonExistence(timeout: 8), "\"Unlock\" and a success take the cover off")
        XCTAssertTrue(sheet.waitForExistence(timeout: 8), "after \"Unlock\" the share sheet shows again")
        lockFollowupsAssertOnePDFInTmpExport("after \"Unlock\"")
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the share sheet closes")
        assertScreen("Export")
        lockFollowupsAssertNoPDF("after the share sheet closes")
    }

    // MARK: mm-t41.15 (r14-01) and mm-t12b.1 (r16-03): the settings screen

    /// mm-t12b.1, ruling r16-03 (mm-t12b.28), the comment of 7 October 2026
    /// at 08:20: each confirmation "shows as an alert in the centre of the
    /// screen with both buttons", and "the cancel button closes it and
    /// changes nothing". Item (7), "Face ID only" in Settings: "Turn on" and
    /// "Cancel"; "Cancel" leaves the switch off and the app lock on, and
    /// makes no request. Item (5), "Delete everything" in Settings: "Delete
    /// everything" and "Cancel"; "Cancel" keeps the settings screen with no
    /// line and no deleted screen, the store directory holds the same
    /// files, and Record.store (with its write-ahead log) holds the same
    /// bytes.
    /// mm-t41.15, ruling r14-01 (mm-t41.26, commit 56bcf48), part (1), and
    /// the comment of mm-t41.20 (commit da168bb) for the settings screen:
    /// with a deletion that fails, "Delete everything" and its confirmation
    /// keep the settings screen, which shows "Could not delete. Try again."
    /// under the Privacy controls, and no deleted screen and no other
    /// message. Part (4) for the settings screen: with the deletion fixed,
    /// "Delete everything" again shows the deleted screen, the line goes,
    /// and the store directory holds no file.
    func testTheSettingsConfirmationsAndAFailedDeletion() throws {
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        assertAppLockRequests(1, "the launch makes one request")
        // r16-03 (7): "Face ID only".
        openSettingsAt("Face ID only")
        XCTAssertEqual(switchValue("Face ID only"), "0", "\"Face ID only\" is off")
        flipSwitch("Face ID only")
        recordPlanAssertAlert(title: "Face ID only", buttons: ["Turn on", "Cancel"])
        lockFollowupsCancelTheAlert()
        assertScreen("Settings")
        XCTAssertEqual(switchValue("Face ID only"), "0", "\"Cancel\" leaves \"Face ID only\" off")
        XCTAssertEqual(switchValue("Lock with Face ID"), "1", "\"Cancel\" leaves the app lock on")
        assertAppLockRequests(1, "\"Cancel\" in the warning makes no request")
        // r16-03 (5): "Delete everything" in Settings.
        let delete = app.buttons["Delete everything"].firstMatch
        XCTAssertTrue(scrollTo(delete), "the Privacy group shows \"Delete everything\"")
        let before = storeContents()
        XCTAssertNotNil(before.record, "before \"Delete everything\", Record.store can be read")
        delete.tap()
        recordPlanAssertAlert(title: "Delete everything?", buttons: ["Delete everything", "Cancel"])
        lockFollowupsCancelTheAlert()
        assertScreen("Settings")
        let failure = element(labelled: "Could not delete. Try again.")
        XCTAssertFalse(failure.exists, "\"Cancel\" shows no line")
        XCTAssertFalse(element(labelBeginningWith: "Everything is deleted.").exists, "\"Cancel\" shows no deleted screen")
        assertNothingIsDeleted(since: before, "after \"Cancel\" in \"Delete everything?\" in Settings")
        // r14-01 (1): a deletion that fails keeps the settings screen, with the line.
        makeTheDeletionFail()
        delete.tap()
        tapDialogButton("Delete everything")
        XCTAssertTrue(failure.waitForExistence(timeout: 10), "after a failed deletion the settings screen shows \"Could not delete. Try again.\"")
        assertScreen("Settings")
        XCTAssertTrue(delete.exists, "the settings screen stays, with \"Delete everything\"")
        XCTAssertGreaterThanOrEqual(failure.frame.minY, delete.frame.maxY - 1, "the line shows under the Privacy controls")
        XCTAssertFalse(element(labelBeginningWith: "Everything is deleted.").exists, "after a failed deletion no deleted screen shows")
        XCTAssertEqual(app.alerts.count, 0, "the app shows no other message about the failure")
        // r14-01 (4): the deletion works again.
        removeDeletionFault()
        delete.tap()
        tapDialogButton("Delete everything")
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "with the deletion fixed, the deleted screen shows")
        XCTAssertFalse(failure.exists, "the line goes")
        XCTAssertEqual(filesInTheStoreDirectory(), [], "after \"Delete everything\" the store directory holds no file")
    }

    // MARK: mm-t41.15 (r14-01) and mm-t12b.1 (r16-03): the store-failure page

    /// mm-t12b.1, ruling r16-03 (mm-t12b.28), item (5), the page
    /// "Midmorning cannot open your record on this device.": "Delete
    /// everything" shows an alert in the centre of the screen with "Delete
    /// everything" and "Cancel". "Cancel" closes it and keeps the page, and
    /// each file in the store directory keeps its bytes.
    /// mm-t41.15, ruling r14-01 (mm-t41.26, commit 56bcf48), part (3), and
    /// the comment of mm-t41.20 (commit da168bb) for this page: with a
    /// deletion that fails, the confirmation keeps the page, which shows
    /// "Could not delete. Try again." under its controls, and no deleted
    /// screen and no other message. Part (4) for this page: with the
    /// deletion fixed, "Delete everything" again shows the deleted screen,
    /// the line goes, and the store directory holds no file.
    func testTheStoreFailurePageConfirmationAndAFailedDeletion() throws {
        try launch("corrupt")
        let page = element(labelled: "Midmorning cannot open your record on this device.")
        XCTAssertTrue(page.waitForExistence(timeout: 20), "the store-failure page shows")
        let delete = app.buttons["Delete everything"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "the page shows \"Delete everything\"")
        let before = lockFollowupsStoreBytes()
        XCTAssertNotNil(before["Record.store"], "before \"Delete everything\", the store directory holds Record.store: \(before.keys.sorted())")
        // r16-03 (5): the alert, and "Cancel".
        delete.tap()
        recordPlanAssertAlert(title: "Delete everything?", buttons: ["Delete everything", "Cancel"])
        lockFollowupsCancelTheAlert()
        XCTAssertTrue(page.exists, "\"Cancel\" keeps the page")
        let failure = element(labelled: "Could not delete. Try again.")
        XCTAssertFalse(failure.exists, "\"Cancel\" shows no line")
        XCTAssertFalse(element(labelBeginningWith: "Everything is deleted.").exists, "\"Cancel\" shows no deleted screen")
        XCTAssertEqual(lockFollowupsStoreBytes(), before, "\"Cancel\" deletes nothing: the store directory holds the same files with the same bytes")
        // r14-01 (3): a deletion that fails keeps the page, with the line.
        makeTheDeletionFail()
        delete.tap()
        tapDialogButton("Delete everything")
        XCTAssertTrue(failure.waitForExistence(timeout: 10), "after a failed deletion the page shows \"Could not delete. Try again.\"")
        XCTAssertTrue(page.exists, "after a failed deletion the page stays")
        for control in ["Try again", "Get support", "Delete everything"] {
            let button = app.buttons[control].firstMatch
            XCTAssertTrue(button.exists, "the page still shows \"\(control)\"")
            XCTAssertLessThanOrEqual(button.frame.maxY, failure.frame.minY + 1, "the line shows under the page's controls (\"\(control)\")")
        }
        XCTAssertFalse(element(labelBeginningWith: "Everything is deleted.").exists, "after a failed deletion no deleted screen shows")
        XCTAssertEqual(app.alerts.count, 0, "the app shows no other message about the failure")
        // r14-01 (4): the deletion works again.
        removeDeletionFault()
        delete.tap()
        tapDialogButton("Delete everything")
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "with the deletion fixed, the deleted screen shows")
        XCTAssertFalse(failure.exists, "the line goes")
        XCTAssertEqual(filesInTheStoreDirectory(), [], "after \"Delete everything\" the store directory holds no file")
    }

    // MARK: mm-t12b.1 (r16-03): the cover

    /// mm-t12b.1, ruling r16-03 (mm-t12b.28), item (5), the cover:
    /// "Delete everything" (after the request succeeds) shows an alert in
    /// the centre of the screen with "Delete everything" and "Cancel".
    /// "Cancel" closes it, the cover stays, and nothing is deleted: the
    /// store directory holds the same files, and Record.store (with its
    /// write-ahead log) the same bytes. Item (6): after an enrolment
    /// change, "Delete from this device" shows an alert in the centre of
    /// the screen with "Delete from this device" and "Cancel"; "Cancel"
    /// closes it, the cover stays with "Delete from this device" and no
    /// "Unlock", nothing is deleted, and the app makes no request. The test
    /// does the same check for "Delete everything" after the enrolment
    /// change. (The test seam gives the result of the request and the
    /// changed enrolment hash.)
    func testTheCoverConfirmationsAreCentredAlerts() throws {
        // (5) "Delete everything" on the cover.
        try launchWithTheSeam("lock-week1", results: ["cancel"])
        assertTheLockedCover("at launch")
        assertAppLockRequests(1, "the launch makes one request")
        let before = storeContents()
        XCTAssertNotNil(before.record, "before \"Delete everything\", Record.store can be read")
        scriptAppLock(["succeed"])
        deleteEverythingButton.tap()
        recordPlanAssertAlert(title: "Delete everything?", buttons: ["Delete everything", "Cancel"])
        lockFollowupsCancelTheAlert()
        assertTheLockedCover("after \"Cancel\" in \"Delete everything?\"")
        assertNothingIsDeleted(since: before, "after \"Cancel\" in \"Delete everything?\" on the cover")
        assertAppLockRequests(2, "\"Delete everything\" makes one request, and \"Cancel\" none")

        // (6) "Delete from this device" after an enrolment change.
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-face-only", results: [], enrolmentHash: "B")
        assertTheLockedCover(afterAnEnrolmentChange: true, "after an enrolment change")
        let kept = storeContents()
        XCTAssertNotNil(kept.record, "before \"Delete from this device\", Record.store can be read")
        deleteFromThisDeviceButton.tap()
        recordPlanAssertAlert(title: "Delete from this device?", buttons: ["Delete from this device", "Cancel"])
        lockFollowupsCancelTheAlert()
        assertTheLockedCover(afterAnEnrolmentChange: true, "after \"Cancel\" in \"Delete from this device?\"")
        assertNothingIsDeleted(since: kept, "after \"Cancel\" in \"Delete from this device?\"")
        deleteEverythingButton.tap()
        recordPlanAssertAlert(title: "Delete everything?", buttons: ["Delete everything", "Cancel"])
        lockFollowupsCancelTheAlert()
        assertTheLockedCover(afterAnEnrolmentChange: true, "after \"Cancel\" in \"Delete everything?\" after an enrolment change")
        assertNothingIsDeleted(since: kept, "after \"Cancel\" in \"Delete everything?\" after an enrolment change")
        assertAppLockRequests(0, "after an enrolment change the app makes no request")
    }

    // MARK: mm-t12b.1 (r16-03): the call warning

    /// mm-t12b.1, ruling r16-03 (mm-t12b.28), item (4): "Call" on a number
    /// in the support sheet shows the Recents warning as an alert in the
    /// centre of the screen with "Call" and "Cancel". "Cancel" closes it,
    /// the support sheet stays, and the app starts no call (the call record
    /// of a Debug build stays empty; see `turnOnTheCallRecord`). As the
    /// positive control, "Call" and "Call" on the warning then write the
    /// call to 116 123, so the record works in this run. (The system call
    /// flow stays a device check.)
    func testTheCallWarningIsACentredAlert() throws {
        turnOnTheCallRecord()
        try launchOnToday("week1")
        getSupport(on: "Today").tap()
        assertScreen("Get support")
        guard let alert = openTheRecentsWarning(beside: "116 123", bar: nil) else { return }
        recordPlanAssertAlert(title: AutomatedChecks.recentsWarning, buttons: ["Call", "Cancel"])
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "\"Cancel\" closes the warning")
        assertScreen("Get support")
        sleep(1)
        XCTAssertEqual(recordedCalls(), [], "\"Cancel\" starts no call")
        callAndConfirm("116 123", bar: nil)
        assertScreen("Get support")
    }
}
