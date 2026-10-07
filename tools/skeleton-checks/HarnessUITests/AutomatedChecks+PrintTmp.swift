import XCTest

/// Rulings r13-19 and r16-01 (epic mm-t45): bug mm-t45.11 and the checks of
/// the device-check bead mm-t42.14 (export) about a PDF that stays in the
/// app's `tmp` folder.
///
/// When the person taps Print in the export share sheet, iOS writes its own
/// copy of the PDF to `tmp/<UUID>/`, beside the app's own file in
/// `tmp/Export`. iOS removes that copy when the print options close. When
/// the app ends first, or when the record is deleted while the print
/// options show, the app must remove it: the next launch, Delete-all and
/// "Delete from this device" remove each PDF in `tmp`
/// (`Record.TemporaryPDFFiles`), not only `tmp/Export`.
///
/// The tests use the stores `week1`, `lock-week1` and `lock-face-only`
/// (`seeder/Sources/Seeder/AutomatedScenarios.swift` and
/// `AppLockScenarios.swift`), and the app-lock test seam
/// (`AutomatedChecks+AppLock.swift`).
extension AutomatedChecks {
    // MARK: Helpers (private to this file)

    private var printTmpAppData: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"]!)
    }

    /// The app's App Group container (`group.uk.midmorning`) on the
    /// simulator, found by its container metadata.
    private func printTmpAppGroupDirectory() -> URL? {
        let shared = printTmpAppData
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

    /// Every PDF in the app's data container (tmp, Library and Documents)
    /// and in its App Group container, as a path from the top of its
    /// container.
    private func printTmpPDFs() -> [String] {
        let roots = [printTmpAppData, printTmpAppGroupDirectory()].compactMap { $0 }
        return roots.flatMap { root -> [String] in
            let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            let prefix = root.resolvingSymlinksInPath().path + "/"
            return files.filter { $0.pathExtension.lowercased() == "pdf" }.map { file in
                let path = file.resolvingSymlinksInPath().path
                return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
            }
        }.sorted()
    }

    /// The PDFs in `tmp` that are not in `tmp/Export`: the copy that Print
    /// keeps in `tmp/<UUID>/`.
    private func printCopies(in pdfs: [String]) -> [String] {
        pdfs.filter { $0.hasPrefix("tmp/") && !$0.hasPrefix("tmp/Export/") }
    }

    /// When a test fails before the app removes the print copy, the
    /// teardown removes each PDF in `tmp`, so that the export tests after
    /// it do not fail because of it. (It does not end the app first, so
    /// that `tearDown` keeps the screen of a failure.)
    private func removeLeftoverPDFsAtTheEnd() {
        addTeardownBlock { [self] in
            for path in printTmpPDFs() where path.hasPrefix("tmp/") {
                try? FileManager.default.removeItem(at: printTmpAppData.appendingPathComponent(path))
            }
        }
    }

    /// From Today: Settings, Export, "Make PDF". Waits for the share sheet.
    private func makeAPDFForPrint(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
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

    /// Taps "Print" in the share sheet and waits for the print options and
    /// for the copy of the PDF that iOS keeps in `tmp/<UUID>/`. Answers the
    /// PDFs in the app's containers while the print options show: the
    /// app's own file in `tmp/Export` and the print copy.
    @discardableResult
    private func printAndWaitForTheCopy(_ sheet: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> [String] {
        let print = sheet.cells.matching(identifier: "actionGroupCell").matching(NSPredicate(format: "label == %@", "Print")).firstMatch
        XCTAssertTrue(print.waitForExistence(timeout: 10), "the share sheet offers \"Print\"", file: file, line: line)
        print.tap()
        XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 10), "\"Print\" shows the print options with \"Cancel\"", file: file, line: line)
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5), "while the print options show, the share sheet is gone", file: file, line: line)
        var pdfs = printTmpPDFs()
        for _ in 0..<20 where printCopies(in: pdfs).isEmpty {
            usleep(500_000)
            pdfs = printTmpPDFs()
        }
        XCTAssertEqual(printCopies(in: pdfs).count, 1, "while the print options show, iOS keeps its own copy of the PDF in tmp/<UUID>/: \(pdfs)", file: file, line: line)
        XCTAssertEqual(pdfs.filter { $0.hasPrefix("tmp/Export/") }.count, 1, "while the print options show, tmp/Export holds the app's PDF: \(pdfs)", file: file, line: line)
        XCTAssertEqual(pdfs.count, 2, "while the print options show, the app's containers hold these two PDFs only: \(pdfs)", file: file, line: line)
        return pdfs
    }

    // MARK: mm-t45.11: the next launch

    /// Bug mm-t45.11, its acceptance: "Make PDF", then "Print". While the
    /// print options show, iOS keeps its own copy of the PDF in
    /// `tmp/<UUID>/`, beside the app's file in `tmp/Export`. Force-quit the
    /// app: the two PDFs stay. Open the app again: the app's data
    /// container and its App Group container hold no PDF. (Before the fix
    /// the launch removed only `tmp/Export`, and the print copy stayed.)
    func testTheNextLaunchRemovesThePrintCopyLeftByAForceQuit() throws {
        removeLeftoverPDFsAtTheEnd()
        try launchOnToday("week1")
        let whilePrintShows = printAndWaitForTheCopy(makeAPDFForPrint())
        app.terminate()
        XCTAssertEqual(printTmpPDFs(), whilePrintShows, "after the force-quit, the two PDFs stay: the print copy and the app's PDF")
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "Today shows after the next launch")
        XCTAssertEqual(printTmpPDFs(), [], "after the next launch, the app's data container and App Group container hold no PDF")
    }

    // MARK: mm-t45.11: Delete-all and "Delete from this device" while Print shows

    /// Bug mm-t45.11, Delete-all: with the app lock on ("Lock after" "At
    /// once"), "Make PDF", then "Print". While the print options show, go
    /// to the Home Screen and return: the cover shows, and the print copy
    /// is still in `tmp/<UUID>/`. "Delete everything" on the cover, the
    /// request (the test seam gives a success) and the confirmation: the
    /// deleted screen shows, and the app's containers hold no PDF.
    func testDeleteEverythingFromTheCoverWhilePrintShowsLeavesNoPDF() throws {
        removeLeftoverPDFsAtTheEnd()
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        let whilePrintShows = printAndWaitForTheCopy(makeAPDFForPrint())
        scriptAppLock(["cancel", "succeed"])
        leaveTheApp(for: 2)
        XCTAssertTrue(deleteEverythingButton.waitForExistence(timeout: 20), "after the return, the cover shows \"Delete everything\"")
        XCTAssertTrue(unlockButton.exists, "after the return, the cover shows \"Unlock\"")
        assertAppLockRequests(2, "the return makes one request with no tap (cancel)")
        XCTAssertEqual(printTmpPDFs(), whilePrintShows, "while the cover shows over the print options, the print copy and the app's PDF stay")
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8), "after a success, \"Delete everything?\" shows")
        tapDialogButton("Delete everything")
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "the deleted screen shows")
        XCTAssertEqual(printTmpPDFs(), [], "after \"Delete everything\", the app's data container and App Group container hold no PDF")
        sleep(3)
        XCTAssertEqual(printTmpPDFs(), [], "3 s after \"Delete everything\", the app's containers still hold no PDF")
    }

    /// Bug mm-t45.11, "Delete from this device": with the app lock on and
    /// "Face ID only" on, "Make PDF", then "Print". While the print options
    /// show, an enrolment change (the test seam gives a new hash), then go
    /// to the Home Screen and return: the cover shows "Delete from this
    /// device", and the print copy is still in `tmp/<UUID>/`. "Delete from
    /// this device" and its confirmation: the deleted screen shows, and the
    /// app's containers hold no PDF. (A real change of the enrolled faces
    /// stays a device check.)
    func testDeleteFromThisDeviceWhilePrintShowsLeavesNoPDF() throws {
        removeLeftoverPDFsAtTheEnd()
        setSimulatedFaceID(enrolled: true)
        try launchWithTheSeam("lock-face-only", results: ["succeed"], enrolmentHash: "A")
        assertNoCover(on: "Today", "after the request at launch succeeds")
        let whilePrintShows = printAndWaitForTheCopy(makeAPDFForPrint())
        scriptAppLock([], enrolmentHash: "C")
        leaveTheApp(for: 2)
        XCTAssertTrue(deleteFromThisDeviceButton.waitForExistence(timeout: 20), "after an enrolment change, the cover shows \"Delete from this device\"")
        XCTAssertFalse(unlockButton.exists, "after an enrolment change, the cover shows no \"Unlock\"")
        XCTAssertEqual(printTmpPDFs(), whilePrintShows, "while the cover shows over the print options, the print copy and the app's PDF stay")
        deleteFromThisDeviceButton.tap()
        XCTAssertTrue(app.alerts["Delete from this device?"].waitForExistence(timeout: 8), "\"Delete from this device?\" shows")
        tapDialogButton("Delete from this device")
        XCTAssertTrue(element(labelBeginningWith: "This device").waitForExistence(timeout: 10), "the deleted screen shows")
        XCTAssertEqual(printTmpPDFs(), [], "after \"Delete from this device\", the app's data container and App Group container hold no PDF")
        sleep(3)
        XCTAssertEqual(printTmpPDFs(), [], "3 s after \"Delete from this device\", the app's containers still hold no PDF")
        assertAppLockRequests(1, "after an enrolment change the app makes no request")
    }

    // MARK: mm-t42.14, comment of mm-t42.24, part 2

    /// mm-t42.14, comment of mm-t42.24 (commit da168bb), part 2: with the
    /// app lock on, make a PDF, and while the share sheet shows, force-quit
    /// the app: the PDF stays in `tmp/Export`. Open the app, and from the
    /// cover tap "Delete everything" at once (the request at launch is
    /// cancelled; the request of "Delete everything" succeeds), then
    /// confirm: the deleted screen shows, and `tmp` and the other parts of
    /// the app's containers hold no PDF. (The launch sweep can remove the
    /// PDF before the cover shows; the test proves the words of the check:
    /// no PDF after the deletion.)
    func testDeleteEverythingStraightFromTheCoverAfterAForceQuit() throws {
        removeLeftoverPDFsAtTheEnd()
        try launchWithTheSeam("lock-week1", results: ["succeed"])
        assertNoCover(on: "Today", "after the request at launch succeeds")
        _ = makeAPDFForPrint()
        let whileTheShareSheetShows = printTmpPDFs()
        XCTAssertEqual(whileTheShareSheetShows.count, 1, "while the share sheet shows, the app's containers hold one PDF: \(whileTheShareSheetShows)")
        XCTAssertTrue(whileTheShareSheetShows.allSatisfy { $0.hasPrefix("tmp/Export/") }, "the PDF is in tmp/Export: \(whileTheShareSheetShows)")
        app.terminate()
        XCTAssertEqual(printTmpPDFs(), whileTheShareSheetShows, "after the force-quit, the PDF stays in tmp/Export")
        scriptAppLock(["cancel", "succeed"])
        app.launch()
        XCTAssertTrue(deleteEverythingButton.waitForExistence(timeout: 20), "the app opens on the cover with \"Delete everything\"")
        XCTAssertEqual(app.navigationBars.count, 0, "no screen shows under the cover")
        assertAppLockRequests(2, "the launch makes one request with no tap (cancel)")
        deleteEverythingButton.tap()
        XCTAssertTrue(app.alerts["Delete everything?"].waitForExistence(timeout: 8), "after a success, \"Delete everything?\" shows")
        tapDialogButton("Delete everything")
        XCTAssertTrue(element(labelBeginningWith: "Everything is deleted.").waitForExistence(timeout: 10), "the deleted screen shows")
        XCTAssertEqual(printTmpPDFs(), [], "after \"Delete everything\" straight from the cover, tmp and the rest of the app's containers hold no PDF")
    }
}
