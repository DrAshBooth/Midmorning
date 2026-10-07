import XCTest
import PDFKit

/// Rulings r13-19 and r16-01 (epic mm-t45): bug mm-t45.11 and the checks of
/// the device-check bead mm-t42.14 (export) about a PDF that stays in the
/// app's `tmp` folder, and the check of the pages and the tag tree of a
/// long export (`testTheLongExportKeepsEachHeadingWithItsLinesAndOneH2PerDay`,
/// store `exportPages`, `seeder/Sources/Seeder/ExportPagesScenarios.swift`).
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

    // MARK: mm-t42.14, comment of mm-t42.22, mm-t42.25 and mm-t42.26: the pages of a long export

    /// The rows of text on `page`, top to bottom. A row joins, left to
    /// right, each line of text at one height, so that the column headings
    /// and each entry are one row.
    private func textRows(of page: PDFPage) -> [String] {
        guard let selection = page.selection(for: page.bounds(for: .mediaBox)) else { return [] }
        var rows: [(y: CGFloat, parts: [(x: CGFloat, text: String)])] = []
        for line in selection.selectionsByLine() {
            guard let text = line.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { continue }
            let bounds = line.bounds(for: page)
            if let index = rows.firstIndex(where: { abs($0.y - bounds.midY) < 3 }) {
                rows[index].parts.append((bounds.minX, text))
            } else {
                rows.append((bounds.midY, [(bounds.minX, text)]))
            }
        }
        return rows.sorted { $0.y > $1.y }.map { $0.parts.sorted { $0.x < $1.x }.map(\.text).joined(separator: " ") }
    }

    /// A day heading of the PDF, for example "Tuesday 22 September 2026".
    private func isDayHeading(_ row: String) -> Bool {
        row.range(of: #"^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday) [0-9]{1,2} [A-Z][a-z]+ [0-9]{4}$"#, options: .regularExpression) != nil
    }

    /// An entry row: it starts with the time, for example "08:15".
    private func isEntryRow(_ row: String) -> Bool {
        row.range(of: #"^[0-9]{2}:[0-9]{2}"#, options: .regularExpression) != nil
    }

    /// The column headings row.
    private func isColumnHeadings(_ row: String) -> Bool {
        row.hasPrefix("Time") && row.contains("What") && row.contains("Where")
    }

    /// One structure element of the PDF's tag tree: its type (for example
    /// "H2"), the index of its page when it has one, its language and its
    /// ActualText.
    private struct TagElement {
        let type: String
        let page: Int?
        let language: String?
        let actualText: String?
        let kids: [TagElement]
    }

    /// The tag tree of the PDF at `url`, read with Core Graphics, as the
    /// tag panel of a PDF reader shows it, and the language of the
    /// document catalog. The page of an element is its `/Pg`, or the page
    /// of its first kid that has one.
    private func tagTree(of url: URL) -> (elements: [TagElement], catalogLanguage: String?)? {
        guard let document = CGPDFDocument(url as CFURL), let catalog = document.catalog else { return nil }
        var pages: [CGPDFDictionaryRef] = []
        for number in 0..<document.numberOfPages {
            if let page = document.page(at: number + 1), let dictionary = page.dictionary { pages.append(dictionary) }
        }
        func text(_ dictionary: CGPDFDictionaryRef, _ key: String) -> String? {
            var value: CGPDFStringRef?
            guard CGPDFDictionaryGetString(dictionary, key, &value), let value else { return nil }
            return CGPDFStringCopyTextString(value) as String?
        }
        func elements(in object: CGPDFObjectRef) -> [TagElement] {
            var array: CGPDFArrayRef?
            if CGPDFObjectGetValue(object, .array, &array), let array {
                return (0..<CGPDFArrayGetCount(array)).flatMap { index -> [TagElement] in
                    var item: CGPDFObjectRef?
                    guard CGPDFArrayGetObject(array, index, &item), let item else { return [] }
                    return elements(in: item)
                }
            }
            var dictionary: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(object, .dictionary, &dictionary), let dictionary else { return [] }
            var name: UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(dictionary, "S", &name), let name else { return [] }
            var kids: [TagElement] = []
            var kidObject: CGPDFObjectRef?
            if CGPDFDictionaryGetObject(dictionary, "K", &kidObject), let kidObject { kids = elements(in: kidObject) }
            var pageDictionary: CGPDFDictionaryRef?
            let page = CGPDFDictionaryGetDictionary(dictionary, "Pg", &pageDictionary)
                ? pages.firstIndex { $0 == pageDictionary } : kids.lazy.compactMap(\.page).first
            return [TagElement(type: String(cString: name), page: page, language: text(dictionary, "Lang"), actualText: text(dictionary, "ActualText"), kids: kids)]
        }
        var root: CGPDFDictionaryRef?
        var top: CGPDFObjectRef?
        guard CGPDFDictionaryGetDictionary(catalog, "StructTreeRoot", &root), let root,
              CGPDFDictionaryGetObject(root, "K", &top), let top else { return ([], text(catalog, "Lang")) }
        return (elements(in: top), text(catalog, "Lang"))
    }

    /// Each element of `elements` and of their kids, at any depth.
    private func flatten(_ elements: [TagElement]) -> [TagElement] {
        elements.flatMap { [$0] + flatten($0.kids) }
    }

    /// mm-t42.14, comment of 26 September 2026 from mm-t42.22, mm-t42.25 and
    /// mm-t42.26 (commit 011328b), with the store `exportPages`: seven
    /// record days, one of them with 45 entries, two paused days, one
    /// "Didn't record" day and one weigh-in. On the export screen, turn on
    /// "Include weigh-ins" and tap "Make PDF". The test reads the PDF in
    /// tmp/Export with PDFKit (the text of each page) and Core Graphics
    /// (the tag tree):
    /// - "Weigh-ins" starts its own last page, which holds the weigh-in
    ///   row and nothing else, and no weight value prints under the record.
    /// - No page ends with a day heading, a "Paused" line or the column
    ///   headings.
    /// - The long day continues on the next page, which repeats its
    ///   heading. The tag tree holds one H1, one H2 for each day (seven),
    ///   and no H2 for a repeated heading: on each page, the number of H2
    ///   is the number of day headings less the repeated one. Each page
    ///   holds one tagged list for each day with entries on that page, and
    ///   one list item for each entry.
    /// - Bug mm-t45.13: each tag declares the language en-GB, and the
    ///   ActualText of each list item is the text of its entry row.
    /// (How the PDF looks, a screen reader on the PDF and the language in a
    /// PDF reader's document properties stay device checks. Core Graphics
    /// has no key for the language of the whole document, so the test
    /// writes to the log the language of the document catalog.)
    func testTheLongExportKeepsEachHeadingWithItsLinesAndOneH2PerDay() throws {
        try launchOnToday("exportPages")
        tapToolbar("Settings")
        assertScreen("Settings")
        let export = app.buttons["Export"].firstMatch
        XCTAssertTrue(scrollTo(export), "Settings shows \"Export\"")
        export.tap()
        assertScreen("Export")
        let weighIns = app.switches["Include weigh-ins"].firstMatch
        XCTAssertTrue(scrollTo(weighIns), "the export screen shows \"Include weigh-ins\"")
        XCTAssertEqual(weighIns.value as? String, "0", "\"Include weigh-ins\" is off by default")
        flipSwitch("Include weigh-ins")
        XCTAssertEqual(weighIns.value as? String, "1", "\"Include weigh-ins\" is on")
        let makePDF = app.buttons["Make PDF"].firstMatch
        XCTAssertTrue(scrollTo(makePDF), "the export screen shows \"Make PDF\"")
        makePDF.tap()
        let sheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 20), "\"Make PDF\" shows the system share sheet")
        let folder = printTmpAppData.appendingPathComponent("tmp/Export")
        let made = (FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? [])
            .first { $0.pathExtension == "pdf" }
        let url = try XCTUnwrap(made, "tmp/Export holds the PDF")
        // A copy, so that the close of the share sheet cannot remove the
        // file while the test reads it.
        let copy = FileManager.default.temporaryDirectory.appendingPathComponent("exportPages-\(UUID().uuidString).pdf")
        try FileManager.default.copyItem(at: url, to: copy)
        addTeardownBlock { try? FileManager.default.removeItem(at: copy) }
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 10), "the share sheet closes")

        let pdf = try XCTUnwrap(PDFDocument(url: copy), "PDFKit opens the PDF")
        let pages = (0..<pdf.pageCount).compactMap { pdf.page(at: $0) }.map(textRows(of:))
        let summary = pages.enumerated().map { "page \($0.offset + 1): first \($0.element.first ?? "-") | last \($0.element.last ?? "-")" }.joined(separator: "; ")
        print("mm-t42.14 export pages: \(summary)")
        XCTAssertGreaterThanOrEqual(pages.count, 3, "the PDF has record pages and the weigh-in page: \(summary)")

        // "Weigh-ins" starts its own last page, with the weigh-in and
        // nothing else; no weight value prints under the record.
        let weighInPage = try XCTUnwrap(pages.last)
        XCTAssertEqual(weighInPage.first, "Weigh-ins", "\"Weigh-ins\" starts the last page: \(weighInPage)")
        XCTAssertEqual(weighInPage.count, 2, "the last page holds the heading and the one weigh-in row, and nothing else: \(weighInPage)")
        XCTAssertTrue(weighInPage.last?.contains("70.4") == true, "the weigh-in row shows 70.4: \(weighInPage)")
        let recordPages = Array(pages.dropLast())
        for (index, rows) in recordPages.enumerated() {
            XCTAssertFalse(rows.contains("Weigh-ins"), "record page \(index + 1) holds no \"Weigh-ins\" heading: \(rows)")
            XCTAssertFalse(rows.contains { $0.contains("70.4") || $0.contains(" kg") }, "no weight value prints on record page \(index + 1): \(rows)")
        }

        // No page ends with a day heading, a "Paused" line or the column
        // headings.
        for (index, rows) in recordPages.enumerated() {
            let last = rows.last ?? ""
            XCTAssertFalse(isDayHeading(last), "record page \(index + 1) does not end with a day heading: \(summary)")
            XCTAssertNotEqual(last, "Paused", "record page \(index + 1) does not end with \"Paused\": \(summary)")
            XCTAssertFalse(isColumnHeadings(last), "record page \(index + 1) does not end with the column headings: \(summary)")
        }

        // The headings of each page. A page that continues a day starts
        // with a copy of a heading that an earlier page shows.
        var seen: Set<String> = []
        var headingsPerPage: [Int] = []
        var repeatedPerPage: [Int] = []
        var listsPerPage: [Int] = []
        var entriesPerPage: [Int] = []
        var entryRowsPerPage: [[String]] = []
        for rows in recordPages {
            let headings = rows.filter(isDayHeading)
            let repeated = rows.first.map { isDayHeading($0) && seen.contains($0) } == true ? 1 : 0
            headingsPerPage.append(headings.count)
            repeatedPerPage.append(repeated)
            seen.formUnion(headings)
            var day: String?
            var daysWithEntries: Set<String> = []
            for row in rows {
                if isDayHeading(row) { day = row }
                if isEntryRow(row), let day { daysWithEntries.insert(day) }
            }
            listsPerPage.append(daysWithEntries.count)
            entriesPerPage.append(rows.filter(isEntryRow).count)
            entryRowsPerPage.append(rows.filter(isEntryRow))
        }
        XCTAssertEqual(seen.count, 7, "the record pages show the seven day headings of the range: \(seen.sorted())")
        XCTAssertGreaterThanOrEqual(repeatedPerPage.reduce(0, +), 1, "the long day continues on the next page, which repeats its heading: \(summary)")
        XCTAssertEqual(entriesPerPage.reduce(0, +), 84, "the record pages show the 84 entries: \(entriesPerPage)")

        // The tag tree.
        let tree = try XCTUnwrap(tagTree(of: copy), "Core Graphics reads the PDF")
        let all = flatten(tree.elements)
        XCTAssertEqual(all.filter { $0.type == "H1" }.count, 1, "the tag tree holds one H1, \"Record\"")
        let h2 = all.filter { $0.type == "H2" }
        XCTAssertEqual(h2.count, 7, "the tag tree holds one H2 for each of the seven days, and none for a repeated heading")
        for page in recordPages.indices {
            XCTAssertEqual(h2.filter { $0.page == page }.count, headingsPerPage[page] - repeatedPerPage[page],
                           "page \(page + 1): one H2 for each day heading on the page, and none for the repeated heading: \(summary)")
            XCTAssertEqual(all.filter { $0.type == "L" && $0.page == page }.count, listsPerPage[page],
                           "page \(page + 1): one tagged list for each day with entries on the page")
            XCTAssertEqual(all.filter { $0.type == "LI" && $0.page == page }.count, entriesPerPage[page],
                           "page \(page + 1): one tagged list item for each entry on the page")
            // Scenario "One pass per entry": each list item reads the
            // entry's row: the time, the asterisk when starred, the What
            // and the Where (bug mm-t45.13).
            XCTAssertEqual(all.filter { $0.type == "LI" && $0.page == page }.map { $0.actualText ?? "(no ActualText)" }, entryRowsPerPage[page],
                           "page \(page + 1): the ActualText of each list item is the text of its entry row")
        }
        XCTAssertEqual(h2.filter { $0.page == recordPages.count }.count, 0, "the weigh-in page holds no H2")
        // The language (bug mm-t45.13): each tag declares en-GB. Core
        // Graphics has no key for the language of the whole document.
        let tagged = all.filter { ["H1", "H2", "L", "LI"].contains($0.type) }
        let withoutEnGB = tagged.filter { $0.language != "en-GB" }
        XCTAssertEqual(withoutEnGB.count, 0, "each H1, H2, L and LI declares the language en-GB; \(withoutEnGB.count) of \(tagged.count) do not")
        print("mm-t42.14 export language: the document catalog declares \(tree.catalogLanguage ?? "no language"); \(tagged.count - withoutEnGB.count) of \(tagged.count) tags declare en-GB")
    }
}
