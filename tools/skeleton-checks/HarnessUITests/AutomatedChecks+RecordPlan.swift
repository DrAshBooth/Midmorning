import XCTest
import Vision
import PDFKit

/// Rulings r13-19 and r16-01 (mm-t43.32): the record checks of mm-t12b.1
/// and the plan checks of mm-t23.15 that the simulator can run, and ruling
/// r16-03 for the confirmations of the record and plan screens. Each test
/// names its device-check bead and the check that it replaces.
///
/// The seeded stores are in `seeder/Sources/Seeder/RecordPlanScenarios.swift`.
/// Their times come from the moment of the seed, and a scenario writes the
/// clock times that a test needs to `<stores>/<scenario>.json`
/// (`recordPlanFacts`).
extension AutomatedChecks {
    // MARK: Helpers for this file

    /// The clock times and day keys that `seeder` wrote for `scenario`.
    func recordPlanFacts(_ scenario: String) throws -> [String: String] {
        let stores = URL(fileURLWithPath: ProcessInfo.processInfo.environment["STORES"] ?? "")
        let data = try Data(contentsOf: stores.appendingPathComponent("\(scenario).json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String], "the facts of \(scenario)")
    }

    /// The Gregorian calendar in GMT, for day-key arithmetic: a day key
    /// names a calendar date and carries no zone.
    var recordPlanKeyCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "GMT")!
        return calendar
    }

    func recordPlanDate(ofKey key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        return recordPlanKeyCalendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
    }

    func recordPlanKey(_ date: Date) -> String {
        let parts = recordPlanKeyCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    func recordPlanAdding(_ days: Int, to key: String) -> String {
        recordPlanKey(recordPlanKeyCalendar.date(byAdding: .day, value: days, to: recordPlanDate(ofKey: key))!)
    }

    /// The text of a day key with `format`, in en-GB: "EEEE d MMMM" gives
    /// "Saturday 3 October", as a day heading and an "Earlier days" row show
    /// it.
    func recordPlanDayText(_ key: String, format: String = "EEEE d MMMM") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = recordPlanKeyCalendar
        formatter.timeZone = recordPlanKeyCalendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: recordPlanDate(ofKey: key))
    }

    /// The key of the record day that holds now in `zone`, for a day start
    /// at 04:00.
    func recordPlanCurrentDayKey(in zone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let now = Date()
        let day = calendar.component(.hour, from: now) < 4 ? calendar.date(byAdding: .day, value: -1, to: now)! : now
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    /// A zone with no daylight saving time in which the clock now shows
    /// `hour` (one of `hours`, the first that a zone has), for a check at a
    /// time of night with no change of the clock.
    func recordPlanZone(localHour hours: [Int]) -> TimeZone {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "GMT")!
        let utcHour = utc.component(.hour, from: Date())
        for hour in hours {
            for offset in [hour - utcHour, hour - utcHour + 24, hour - utcHour - 24] where (-12...14).contains(offset) {
                // "Etc/GMT-5" is 5 hours ahead of GMT.
                return TimeZone(identifier: offset == 0 ? "Etc/GMT" : String(format: "Etc/GMT%+d", -offset))!
            }
        }
        return TimeZone(identifier: "GMT")!
    }

    /// The weekday and date of the calendar date `days` from today in
    /// `zone`, as a day heading shows it.
    func recordPlanDateText(days: Int, in zone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let day = calendar.date(byAdding: .day, value: days, to: Date())!
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return recordPlanDayText(String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!))
    }

    /// "HH:mm" in `zone`, `minutes` from now.
    func recordPlanClockNow(in zone: TimeZone, adding minutes: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = zone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date().addingTimeInterval(Double(minutes) * 60))
    }

    func recordPlanElement(labelEndingWith suffix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label ENDSWITH %@", suffix)).firstMatch
    }

    /// The text that the screen draws in `rect` (points), read from a
    /// screenshot with Vision, line by line with each line's frame. A label
    /// that is hidden from VoiceOver is not in the accessibility hierarchy,
    /// so a test reads it from the pixels.
    func recordPlanDrawnText(in rect: CGRect) -> [(text: String, frame: CGRect)] {
        guard let image = XCUIScreen.main.screenshot().image.cgImage else { return [] }
        let scale = CGFloat(image.width) / app.frame.width
        let pixels = CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale).integral
        guard let cropped = image.cropping(to: pixels) else { return [] }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try? VNImageRequestHandler(cgImage: cropped, options: [:]).perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            let box = observation.boundingBox // normalised, origin at the bottom left
            let frame = CGRect(x: rect.minX + box.minX * rect.width, y: rect.minY + (1 - box.maxY) * rect.height,
                               width: box.width * rect.width, height: box.height * rect.height)
            return (text, frame)
        }
    }

    /// Ruling r16-03: the confirmation is an alert in the centre of the
    /// screen with exactly `buttons`.
    func recordPlanAssertAlert(title: String, buttons: [String], file: StaticString = #filePath, line: UInt = #line) {
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "the confirmation shows as an alert", file: file, line: line)
        XCTAssertEqual(alert.label, title, "the alert asks \"\(title)\"", file: file, line: line)
        XCTAssertEqual(Set(alert.buttons.allElementsBoundByIndex.map(\.label)), Set(buttons), "the alert shows both buttons", file: file, line: line)
        XCTAssertEqual(alert.frame.midX, app.frame.midX, accuracy: 10, "the alert is in the centre of the screen", file: file, line: line)
        XCTAssertEqual(alert.frame.midY, app.frame.midY, accuracy: app.frame.height * 0.1, "the alert is in the centre of the screen", file: file, line: line)
    }

    /// True when the gap band shows between the rows `upper` and `lower`.
    func recordPlanBandShows(between upper: XCUIElement, and lower: XCUIElement) -> Bool {
        let bands = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Gap of more than 4 hours")).allElementsBoundByIndex
        return bands.contains { $0.frame.minY >= upper.frame.maxY - 1 && $0.frame.maxY <= lower.frame.minY + 1 }
    }

    /// The labels of the entry rows "HH:mm, Entry N" on Today, from the top
    /// of the list to the bottom.
    func recordPlanEntryLabels() -> Set<String> {
        for _ in 0..<6 { app.swipeDown() }
        let rows = app.descendants(matching: .other).matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}, (Entry [0-9]+|Sixteenth)"))
        var labels = Set<String>()
        for _ in 0..<8 {
            labels.formUnion(rows.allElementsBoundByIndex.map(\.label))
            app.swipeUp()
        }
        labels.formUnion(rows.allElementsBoundByIndex.map(\.label))
        for _ in 0..<6 { app.swipeDown() }
        return labels
    }

    /// Turns the hour and the minute wheels to `clock` ("HH:mm").
    func recordPlanTurnWheels(to clock: String, file: StaticString = #filePath, line: UInt = #line) {
        let parts = clock.split(separator: ":").map(String.init)
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.element(boundBy: 1).waitForExistence(timeout: 5), "the time wheels show", file: file, line: line)
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: parts[0])
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: parts[1])
    }

    /// Sets a time control of the plan builder to `clock`: a tap opens the
    /// wheels, and a tap on the screen title closes them.
    func recordPlanSetBuilderTime(_ picker: XCUIElement, to clock: String, title: String, file: StaticString = #filePath, line: UInt = #line) {
        picker.tap()
        recordPlanTurnWheels(to: clock, file: file, line: line)
        app.staticTexts[title].firstMatch.tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForNonExistence(timeout: 5), "the wheels close", file: file, line: line)
        XCTAssertEqual(picker.value as? String, clock, "the time control shows \(clock)", file: file, line: line)
    }

    /// The time controls of the plan builder, top to bottom.
    func recordPlanBuilderTimes() -> [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "label == %@", "Time Picker")).allElementsBoundByIndex.sorted { $0.frame.minY < $1.frame.minY }
    }

    /// `clock` ("HH:mm") moved by `minutes`, on a 24-hour clock.
    func recordPlanClock(_ clock: String, adding minutes: Int) -> String {
        let parts = clock.split(separator: ":").compactMap { Int($0) }
        let total = ((parts[0] * 60 + parts[1] + minutes) % 1440 + 1440) % 1440
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Makes the files of the record store in the app's container read-only
    /// (or writable again). The app then opens the store, but every save
    /// fails.
    func recordPlanSetStoreWritable(_ writable: Bool) throws {
        let record = URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"] ?? "")
            .appendingPathComponent("Library/Application Support/Record")
        for file in try FileManager.default.contentsOfDirectory(at: record, includingPropertiesForKeys: nil) {
            try FileManager.default.setAttributes([.posixPermissions: writable ? 0o644 : 0o444], ofItemAtPath: file.path)
        }
    }

    // MARK: mm-t12b.1 (record-full)

    /// mm-t12b.1, comment of mm-t12b.6 (the part that
    /// `testASaveExpandsACollapsedDay` does not do): with the previous day
    /// collapsed, an entry saved at 23:30 in the previous-day segment
    /// expands the previous day and shows the 23:30 entry; after the app
    /// opens again on the same record day, the previous day stays expanded.
    func testASaveAt2330ExpandsTheCollapsedPreviousDay() throws {
        try launchOnToday("review")
        let count = element(labelled: "3 entries")
        XCTAssertTrue(scrollTo(count), "the previous day is collapsed and shows its count line")
        XCTAssertFalse(element(labelContaining: "Soup").exists, "the collapsed previous day shows no row")
        for _ in 0..<3 { app.swipeDown() }
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Late snack")
        // The previous-day segment, then 23:30 on the wheel. The wheel sits
        // under the keyboard, so the form scrolls first.
        let segment = app.segmentedControls.firstMatch.buttons.element(boundBy: 0)
        XCTAssertTrue(segment.waitForExistence(timeout: 5), "the time control shows the previous-day segment")
        let previousTitle = segment.label
        segment.tap()
        let keyboardTop = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY : app.frame.maxY
        XCTAssertTrue(dragTo(app.pickerWheels.element(boundBy: 1), above: keyboardTop - 50), "the wheel is above the keyboard")
        recordPlanTurnWheels(to: "23:30")
        let time = app.otherElements["Time"].firstMatch
        XCTAssertEqual(time.value as? String, "\(previousTitle), 23:30", "the time is 23:30 on the previous record day")
        tapSaveInTheNavigationBar()
        let row = element(labelled: "23:30, Late snack")
        XCTAssertTrue(scrollTo(row), "Today shows the 23:30 entry")
        XCTAssertTrue(scrollTo(element(labelContaining: "Soup")), "the previous day is expanded: its other rows show")
        XCTAssertFalse(element(labelled: "4 entries").exists, "the previous day shows no count line")
        // Open the app again, with the same store, on the same record day.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        XCTAssertTrue(scrollTo(row), "the previous day stays expanded after the app opens again")
        XCTAssertFalse(element(labelled: "4 entries").exists, "the previous day stays expanded after the app opens again")
    }

    /// mm-t12b.1, comment of mm-t12b.7 (the part from stage 2 that
    /// `testDeleteAnEntryAsksFirst` does not do): a swipe on a planned meal
    /// row that shows a matched entry, and "Delete", show "Delete this
    /// entry?" with "Delete" and "Cancel" as an alert (r16-03); the row
    /// stays while the alert shows; "Cancel" keeps the entry; "Delete"
    /// removes the entry and leaves the planned meal row. (The VoiceOver
    /// action stays a device check.)
    func testDeleteAMatchedEntryOnAPlannedMealRow() throws {
        let facts = try recordPlanFacts("planMatched")
        let lunch = facts["lunch"]!
        try launchOnToday("planMatched")
        let row = element(labelBeginningWith: "Lunch, \(lunch), \(facts["entry"]!), Toast and tea")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "the Lunch row shows the matched entry")
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        recordPlanAssertAlert(title: "Delete this entry?", buttons: ["Delete", "Cancel"])
        XCTAssertTrue(row.exists, "the row stays on screen while the alert shows")
        tapDialogButton("Cancel")
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertTrue(row.exists, "Cancel keeps the entry")
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        tapDialogButton("Delete")
        XCTAssertTrue(element(labelContaining: "Toast and tea").waitForNonExistence(timeout: 5), "Delete removes the entry")
        XCTAssertTrue(element(labelBeginningWith: "Lunch, \(lunch)").exists, "Delete leaves the planned meal row")
        XCTAssertEqual(app.alerts.count, 0, "the delete shows no message")
    }

    /// mm-t12b.1, comment of mm-t12b.8: with fifteen entries on the current
    /// day and notification permission not determined, the permission line
    /// is the first row under "Add an entry", above the entries. After a
    /// scroll to the last row, the current day heading and "Add an entry"
    /// stay at the top of the list, and one tap on "Add an entry" opens the
    /// new-entry screen. (The contrast of the pinned header stays a device
    /// check.) This check needs a simulator on which the app has not asked
    /// for notification permission.
    func testFifteenEntriesKeepThePinnedHeader() throws {
        try launchOnToday("fifteen")
        let addEntry = app.buttons["Add an entry"].firstMatch
        let permissionLine = app.buttons["Allow notifications to get reminders."].firstMatch
        XCTAssertTrue(permissionLine.waitForExistence(timeout: 8), "with notification permission not determined, Today shows the permission line. If the app already asked for the permission on this simulator, run this check on a new simulator (DEVICE_NAME) or after xcrun simctl uninstall.")
        let firstEntry = recordPlanElement(labelEndingWith: ", Entry 1")
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(permissionLine.frame.minY, addEntry.frame.maxY - 1, "the permission line is under \"Add an entry\"")
        XCTAssertLessThan(permissionLine.frame.minY - addEntry.frame.maxY, 24, "no row is between \"Add an entry\" and the permission line")
        XCTAssertLessThanOrEqual(permissionLine.frame.maxY, firstEntry.frame.minY + 1, "the permission line is above the entries")
        // Scroll to the last row.
        let lastEntry = recordPlanElement(labelEndingWith: ", Entry 15")
        XCTAssertTrue(scrollTo(lastEntry, maxSwipes: 12), "the list scrolls to the last row")
        let heading = app.staticTexts[recordPlanDayText(recordPlanCurrentDayKey())].firstMatch
        let bar = app.navigationBars["Today"]
        XCTAssertTrue(heading.isHittable, "the current day heading stays on screen")
        XCTAssertTrue(addEntry.isHittable, "\"Add an entry\" stays on screen")
        XCTAssertEqual(heading.frame.minY, bar.frame.maxY, accuracy: 30, "the heading stays at the top of the list")
        XCTAssertLessThan(addEntry.frame.maxY, lastEntry.frame.minY, "\"Add an entry\" stays above the rows")
        XCTAssertFalse(firstEntry.exists && firstEntry.isHittable, "the first rows scrolled away under the header")
        addEntry.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "one tap on \"Add an entry\" opens the new-entry screen")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
    }

    /// mm-t12b.1, comment of mm-t12b.11, Earlier days in the New York zone:
    /// each row of "Earlier days" shows the weekday and date of its own
    /// record day, and the day screen's title matches the row. The seeded
    /// days come from the Mac's own zone (London on Ash's Mac); the app runs
    /// with `TZ` set to America/New_York.
    func testEarlierDaysInNewYorkShowTheirOwnDates() throws {
        let facts = try recordPlanFacts("bands")
        let newYork = TimeZone(identifier: "America/New_York")!
        app.launchEnvironment["TZ"] = newYork.identifier
        try launchOnToday("bands")
        // The list runs from the earliest day with an entry to the day
        // before the previous record day, most recent first.
        let previous = recordPlanAdding(-1, to: recordPlanCurrentDayKey(in: newYork))
        var expected: [String] = []
        var key = recordPlanAdding(-1, to: previous)
        while key >= facts["before"]! {
            expected.append(recordPlanDayText(key))
            key = recordPlanAdding(-1, to: key)
        }
        XCTAssertEqual(expected.count, 3, "the seeded record has three earlier days in New York")
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        let cells = app.collectionViews.firstMatch.cells
        XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 5))
        let rows = cells.allElementsBoundByIndex.map { $0.staticTexts.firstMatch.label }
        XCTAssertEqual(rows, expected, "each row shows the weekday and date of its own record day")
        for (index, title) in rows.enumerated() {
            cells.element(boundBy: index).tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 8), "the day title matches the row \"\(title)\"")
            XCTAssertTrue(element(labelBeginningWith: "\(title), ").exists, "the day heading matches the row \"\(title)\"")
            goBack()
            assertScreen("Earlier days")
        }
    }

    /// mm-t12b.1, comment of mm-t12b.11, Export in the New York zone:
    /// "From" and "To" show the same dates as in the home zone (London on
    /// Ash's Mac): the earliest day with an entry and the current record
    /// day. A date picked in "From" gives that date in the PDF: the PDF's
    /// file name and its first day heading. The test reads the PDF that
    /// "Make PDF" writes to the app's temporary folder.
    func testExportInNewYorkShowsTheSameDates() throws {
        let facts = try recordPlanFacts("bands")
        func openExport() {
            tapToolbar("Settings")
            assertScreen("Settings")
            let export = app.buttons["Export"].firstMatch
            XCTAssertTrue(scrollTo(export), "Settings shows \"Export\"")
            export.tap()
            assertScreen("Export")
        }
        /// The day key that a date picker shows: "3 Oct 2026" or, on its
        /// first layout, "03/10/2026".
        func shownKey(_ label: String) -> String? {
            guard let value = app.datePickers[label].buttons.firstMatch.value as? String else { return nil }
            for format in ["d MMM yyyy", "dd/MM/yyyy"] {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_GB")
                formatter.timeZone = recordPlanKeyCalendar.timeZone
                formatter.dateFormat = format
                if let date = formatter.date(from: value) { return recordPlanKey(date) }
            }
            return value
        }
        try launchOnToday("bands")
        openExport()
        let home = (from: shownKey("From"), to: shownKey("To"))
        let newYork = TimeZone(identifier: "America/New_York")!
        app.launchEnvironment["TZ"] = newYork.identifier
        try launchOnToday("bands")
        openExport()
        let from = shownKey("From")
        let to = shownKey("To")
        XCTAssertEqual(from, home.from, "\"From\" shows the same date in New York as in the home zone")
        XCTAssertEqual(to, home.to, "\"To\" shows the same date in New York as in the home zone")
        XCTAssertEqual(from, facts["before"], "\"From\" shows the earliest day with an entry")
        XCTAssertEqual(to, recordPlanCurrentDayKey(in: newYork), "\"To\" shows the current record day")
        // Pick the next day in "From".
        let picked = facts["opened"]!
        app.datePickers["From"].buttons.firstMatch.tap()
        let day = app.buttons[recordPlanDayText(picked)].firstMatch
        if !day.waitForExistence(timeout: 5) { app.buttons["Next Month"].firstMatch.tap() }
        XCTAssertTrue(day.waitForExistence(timeout: 5), "the calendar shows \(picked)")
        day.tap()
        app.staticTexts["Export"].firstMatch.tap()
        XCTAssertEqual(shownKey("From"), picked, "\"From\" shows the picked date")
        app.buttons["Make PDF"].firstMatch.tap()
        // The PDF in the app's temporary folder, tmp/Export/<UUID>/<name>.
        let exportFolder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"] ?? "").appendingPathComponent("tmp/Export")
        let name = "Record \(picked) to \(to ?? "").pdf"
        var pdf: URL?
        for _ in 0..<20 where pdf == nil {
            let files = FileManager.default.enumerator(at: exportFolder, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            pdf = files.first { $0.lastPathComponent == name }
            if pdf == nil { Thread.sleep(forTimeInterval: 0.5) }
        }
        let file = try XCTUnwrap(pdf, "Make PDF writes \"\(name)\"")
        let text = try XCTUnwrap(PDFDocument(url: file)?.string, "the PDF has text")
        let pickedHeading = recordPlanDayText(picked, format: "EEEE d MMMM y")
        XCTAssertTrue(text.contains(pickedHeading), "the PDF shows the picked date, \(pickedHeading)")
        XCTAssertFalse(text.contains(recordPlanDayText(facts["before"]!, format: "EEEE d MMMM y")), "the PDF starts at the picked date")
    }

    /// mm-t12b.1, comment of mm-t12b.14, the part with no colour: "Add a
    /// place" opens a field that fills the row under the chips, with the
    /// label "Add a place" above it. The label is hidden from VoiceOver, so
    /// the test reads it from the screen with text recognition. (The chip
    /// colours in light mode, dark mode and with Increase Contrast stay a
    /// device check.)
    func testAddAPlaceOpensAFieldThatFillsTheRow() throws {
        try launchOnToday("week1")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        let chips = ["Home", "Work", "Out", "Travelling"].map { app.buttons[$0].firstMatch }
        app.buttons["Add a place"].firstMatch.tap()
        let field = app.textViews["Add a place"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "\"Add a place\" opens a field")
        let chipsBottom = chips.map(\.frame.maxY).max() ?? 0
        XCTAssertGreaterThan(field.frame.minY, chipsBottom, "the field is under the chips")
        XCTAssertEqual(field.frame.minX, what.frame.minX, accuracy: 1, "the field starts at the leading edge of the row")
        XCTAssertEqual(field.frame.width, what.frame.width, accuracy: 1, "the field fills the row, as What does")
        XCTAssertEqual(field.frame.minX, chips[0].frame.minX, accuracy: 1, "the field lines up with the chips")
        let drawn = recordPlanDrawnText(in: CGRect(x: 0, y: chipsBottom, width: app.frame.width, height: field.frame.minY - chipsBottom))
        XCTAssertEqual(drawn.map(\.text), ["Add a place"], "the label \"Add a place\" shows between the chips and the field")
        if let label = drawn.first {
            XCTAssertEqual(label.frame.minX, field.frame.minX, accuracy: 4, "the label starts at the field's leading edge")
        }
    }

    /// mm-t12b.1, comment of mm-t12b.18: with stage 2 open, an expanded
    /// previous day with entries at 08:00 and 13:30 shows a band between the
    /// two rows. An earlier day on or after the day that stage 2 opened,
    /// with the same entries, shows a band; an earlier day before that day
    /// shows no band.
    func testGapBandsOnEarlierDaysFollowTheStage2Day() throws {
        let facts = try recordPlanFacts("bands")
        try launchOnToday("bands")
        let previousMenu = app.buttons.matching(identifier: "Day options").element(boundBy: 1)
        XCTAssertTrue(scrollTo(previousMenu), "Today shows the previous day")
        previousMenu.tap()
        app.buttons["Expand day"].firstMatch.tap()
        let breakfast = element(labelled: "08:00, Porridge")
        let lunch = element(labelled: "13:30, Soup")
        XCTAssertTrue(scrollTo(lunch), "the expanded previous day shows its rows")
        XCTAssertTrue(recordPlanBandShows(between: breakfast, and: lunch), "the previous day shows a band between 08:00 and 13:30")
        for _ in 0..<3 { app.swipeDown() }
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        let after = recordPlanDayText(facts["after"]!)
        app.collectionViews.firstMatch.cells.containing(NSPredicate(format: "label == %@", after)).firstMatch.tap()
        XCTAssertTrue(app.navigationBars[after].waitForExistence(timeout: 8))
        XCTAssertTrue(lunch.waitForExistence(timeout: 5))
        XCTAssertTrue(recordPlanBandShows(between: breakfast, and: lunch), "a day after the stage 2 day shows a band")
        app.buttons["Previous day"].tap()
        XCTAssertTrue(app.navigationBars[recordPlanDayText(facts["opened"]!)].waitForExistence(timeout: 8))
        XCTAssertTrue(lunch.waitForExistence(timeout: 5))
        XCTAssertTrue(recordPlanBandShows(between: breakfast, and: lunch), "the day that stage 2 opened shows a band")
        app.buttons["Previous day"].tap()
        XCTAssertTrue(app.navigationBars[recordPlanDayText(facts["before"]!)].waitForExistence(timeout: 8))
        XCTAssertTrue(lunch.waitForExistence(timeout: 5), "the day before shows the same entries")
        XCTAssertTrue(breakfast.exists)
        XCTAssertFalse(element(labelled: "Gap of more than 4 hours").exists, "a day before the stage 2 day shows no band")
    }

    /// mm-t12b.1, comment of mm-t12b.19, the part after the 44-point
    /// check of `testEarlierDayControls`: a tap near the edge of the hit
    /// area of the day menu's chevron, and of the previous-day and next-day
    /// chevrons on an earlier day, makes the control respond. Each tap is 8
    /// points inside a corner of the 44-point area: outside the glyph in
    /// its centre, so a hit area of the glyph only would not respond.
    func testTheChevronsRespondToATapNearTheirEdge() throws {
        let facts = try recordPlanFacts("bands")
        try launchOnToday("bands")
        func tapNearCorner(_ control: XCUIElement, _ corner: (CGFloat, CGFloat)) {
            let frame = control.frame
            XCTAssertGreaterThanOrEqual(min(frame.width, frame.height), 44, "\(control.label) has a hit area of at least 44 by 44 points")
            let dx = corner.0 == 0 ? 8 / frame.width : 1 - 8 / frame.width
            let dy = corner.1 == 0 ? 8 / frame.height : 1 - 8 / frame.height
            control.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).tap()
        }
        // The day menu: a tap near its top-leading corner opens the menu.
        let menu = app.buttons["Day options"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 8))
        tapNearCorner(menu, (0, 0))
        XCTAssertTrue(app.buttons["Earlier days"].firstMatch.waitForExistence(timeout: 5), "a tap near the edge of the day menu opens the menu")
        app.buttons["Earlier days"].firstMatch.tap()
        assertScreen("Earlier days")
        let after = recordPlanDayText(facts["after"]!)
        let opened = recordPlanDayText(facts["opened"]!)
        app.collectionViews.firstMatch.cells.containing(NSPredicate(format: "label == %@", after)).firstMatch.tap()
        XCTAssertTrue(app.navigationBars[after].waitForExistence(timeout: 8))
        // The previous-day chevron: a tap near its bottom-trailing corner.
        tapNearCorner(app.buttons["Previous day"], (1, 1))
        XCTAssertTrue(app.navigationBars[opened].waitForExistence(timeout: 5), "a tap near the edge of the previous-day chevron moves to the previous day")
        // The next-day chevron: a tap near its top-leading corner.
        tapNearCorner(app.buttons["Next day"], (0, 0))
        XCTAssertTrue(app.navigationBars[after].waitForExistence(timeout: 5), "a tap near the edge of the next-day chevron moves to the next day")
        tapNearCorner(app.buttons["Previous day"], (0, 1))
        XCTAssertTrue(app.navigationBars[opened].waitForExistence(timeout: 5), "a tap near another corner of the previous-day chevron moves to the previous day")
        tapNearCorner(app.buttons["Next day"], (1, 0))
        XCTAssertTrue(app.navigationBars[after].waitForExistence(timeout: 5), "a tap near another corner of the next-day chevron moves to the next day")
    }

    /// mm-t12b.1, comment of mm-t11.39: a failed save shows "Could not
    /// save. Try again." on the new-entry screen and on the edit screen; the
    /// screen stays open with the typed text, and nothing is saved. The test
    /// makes the save fail: it makes the store files read-only before the
    /// app opens them.
    func testAFailedSaveShowsCouldNotSave() throws {
        try launchOnToday("week1")
        app.terminate()
        try recordPlanSetStoreWritable(false)
        defer { try? recordPlanSetStoreWritable(true) }
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "Today opens on a read-only store")
        let message = app.staticTexts["Could not save. Try again."].firstMatch
        // The new-entry screen.
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Apple")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(message.waitForExistence(timeout: 5), "a failed save on the new-entry screen shows \"Could not save. Try again.\"")
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.exists, "the new-entry screen stays open")
        XCTAssertEqual(what.value as? String, "Apple", "the new-entry screen keeps the typed text")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertFalse(element(labelContaining: "Apple").exists, "nothing is saved")
        // The edit screen.
        let row = element(labelContaining: "Toast and tea")
        row.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8), "the edit screen shows")
        what.tap()
        dismissKeyboardTip()
        what.typeText(" and jam")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(message.waitForExistence(timeout: 5), "a failed save on the edit screen shows \"Could not save. Try again.\"")
        XCTAssertEqual(what.value as? String, "Toast and tea and jam", "the edit screen keeps the typed text")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(row.exists, "the entry stays")
        XCTAssertFalse(element(labelContaining: "and jam").exists, "nothing is saved")
    }

    /// mm-t12b.1, comment of mm-t11.39: between 00:00 and the day start,
    /// the current day heading shows ", night" after the date. mm-t13.8,
    /// comment of mm-t13.10 and mm-t13.12, the part before 06:00: with "Day
    /// starts at" 06:00 in force, at a time after 04:00 and before 06:00
    /// Today shows the previous date with ", night", a new entry shows under
    /// that day, and the edit screen shows that day. The app runs in a zone
    /// in which the clock now shows that time, so the check needs no change
    /// of the clock.
    func testTheNightHeadingAndADayStartAt0600() throws {
        func nightHeading(in zone: TimeZone) -> String { recordPlanDateText(days: -1, in: zone) }
        // The day start at 04:00: 02:00 to 02:59.
        let twoInTheMorning = recordPlanZone(localHour: [2, 1])
        app.launchEnvironment["TZ"] = twoInTheMorning.identifier
        try launchOnToday("week1")
        let title = nightHeading(in: twoInTheMorning)
        XCTAssertTrue(app.staticTexts["\(title), night"].waitForExistence(timeout: 8), "Today shows \"\(title), night\" (\(twoInTheMorning.identifier))")
        // The day start at 06:00: 05:00 to 05:44, or 04:00 to 04:59.
        let minute = Calendar.current.component(.minute, from: Date())
        let beforeSix = recordPlanZone(localHour: minute < 45 ? [5, 4] : [4])
        app.launchEnvironment["TZ"] = beforeSix.identifier
        try launchOnToday("dayStart6")
        let sixTitle = nightHeading(in: beforeSix)
        XCTAssertTrue(app.staticTexts["\(sixTitle), night"].waitForExistence(timeout: 8), "with the day start at 06:00, Today shows \"\(sixTitle), night\" (\(beforeSix.identifier))")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Night snack")
        tapSaveInTheNavigationBar()
        let row = recordPlanElement(labelEndingWith: ", Night snack")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "the new entry shows on Today")
        let heading = app.staticTexts["\(sixTitle), night"].firstMatch
        XCTAssertGreaterThan(row.frame.minY, heading.frame.maxY, "the new entry shows under \"\(sixTitle), night\"")
        XCTAssertEqual(app.buttons.matching(identifier: "Day options").count, 1, "Today shows one day, the current one")
        row.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8), "the edit screen shows")
        XCTAssertTrue(app.otherElements["Time"].staticTexts[sixTitle].exists, "the edit screen shows the entry's day, \(sixTitle)")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
    }

    /// mm-t12b.1, comment of mm-t12b.5, the part at 01:00: between 00:00
    /// and the day start, the wheel of the current segment keeps 23:00 on
    /// the evening before and 00:30 after midnight, and does not jump back;
    /// a save at 00:30 shows under the current day. The app runs in a zone
    /// in which the clock now shows 01:00 to 02:59. The part at 07:30 (23:30
    /// in the previous-day segment) is
    /// `testASaveAt2330ExpandsTheCollapsedPreviousDay`, at the time of the
    /// run. (That the wheel greys out the times after now stays a device
    /// check: the accessibility hierarchy does not show it.)
    func testTheWheelKeepsTimesOnBothSidesOfMidnight() throws {
        let zone = recordPlanZone(localHour: [1, 2])
        app.launchEnvironment["TZ"] = zone.identifier
        try launchOnToday("week1")
        let currentDay = recordPlanDateText(days: -1, in: zone)
        let calendarToday = recordPlanDateText(days: 0, in: zone)
        XCTAssertTrue(app.staticTexts["\(currentDay), night"].waitForExistence(timeout: 8), "Today shows the night of \(currentDay) (\(zone.identifier))")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Late tea")
        let segments = app.segmentedControls.firstMatch.buttons
        XCTAssertTrue(segments.element(boundBy: 1).waitForExistence(timeout: 5))
        XCTAssertEqual(segments.element(boundBy: 1).label, currentDay, "the current segment is \(currentDay)")
        XCTAssertTrue(segments.element(boundBy: 1).isSelected, "the current segment is selected")
        let keyboardTop = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY : app.frame.maxY
        XCTAssertTrue(dragTo(app.pickerWheels.element(boundBy: 1), above: keyboardTop - 50), "the wheel is above the keyboard")
        let time = app.otherElements["Time"].firstMatch
        recordPlanTurnWheels(to: "23:00")
        XCTAssertEqual(time.value as? String, "\(currentDay), 23:00", "the wheel keeps 23:00 on the evening of \(currentDay)")
        recordPlanTurnWheels(to: "00:30")
        XCTAssertEqual(time.value as? String, "\(calendarToday), 00:30", "the wheel keeps 00:30 after midnight")
        XCTAssertTrue(segments.element(boundBy: 1).isSelected, "the current segment stays selected")
        tapSaveInTheNavigationBar()
        let row = element(labelled: "00:30, Late tea")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "Today shows the entry at 00:30")
        XCTAssertGreaterThan(row.frame.minY, app.staticTexts["\(currentDay), night"].firstMatch.frame.maxY, "the entry shows under the current day")
    }

    /// mm-t12b.1, comment of r13-16 (mm-t12b.22, commit b0cbb4b): an entry
    /// saved in another zone (Asia/Tokyo, or America/New_York when Tokyo is
    /// on another record day) keeps its time after the app opens in the
    /// home zone (London on Ash's Mac) and an edit of its What. The entry
    /// is at the time of the run, not at 08:00, so the test turns no wheel.
    /// (A change of its time waits for mm-t12b.25.)
    func testAnEntryFromAnotherZoneKeepsItsTimeAfterAnEdit() throws {
        let home = TimeZone.current
        let homeDay = recordPlanCurrentDayKey(in: home)
        let away = try XCTUnwrap(["Asia/Tokyo", "America/New_York"].compactMap(TimeZone.init(identifier:)).first {
            recordPlanCurrentDayKey(in: $0) == homeDay && abs($0.secondsFromGMT() - home.secondsFromGMT()) >= 3 * 3600
        }, "a zone on the same record day, at least 3 hours from the home zone")
        app.launchEnvironment["TZ"] = away.identifier
        try launchOnToday("week1")
        let opened = (-1...1).map { recordPlanClockNow(in: away, adding: $0) }
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Rice")
        tapSaveInTheNavigationBar()
        let saved = recordPlanElement(labelEndingWith: ", Rice")
        XCTAssertTrue(saved.waitForExistence(timeout: 8), "Today shows the entry")
        let shown = String(saved.label.prefix(5))
        XCTAssertTrue(opened.contains(shown), "the entry shows the time in \(away.identifier): \(shown)")
        // The home zone.
        app.launchEnvironment["TZ"] = home.identifier
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20))
        XCTAssertFalse((-1...1).map { recordPlanClockNow(in: home, adding: $0) }.contains(shown), "the home zone shows another clock time")
        let row = element(labelled: "\(shown), Rice")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "in the home zone, the row still shows \(shown)")
        row.tap()
        XCTAssertTrue(app.buttons["Delete entry"].waitForExistence(timeout: 8), "the edit screen shows")
        what.tap()
        dismissKeyboardTip()
        what.typeText(" and peas")
        tapSaveInTheNavigationBar()
        XCTAssertTrue(element(labelled: "\(shown), Rice and peas").waitForExistence(timeout: 8), "after the edit, the row still shows \(shown)")
    }

    /// mm-t12b.1, comment of r16-03 (mm-t12b.28), item 3: "Delete entry"
    /// on the edit screen shows "Delete this entry?" as an alert in the
    /// centre of the screen with "Delete" and "Cancel". "Cancel" closes it
    /// and changes nothing: the edit screen stays with the change that is
    /// not saved, and the entry stays. "Delete" removes the entry. (Items 1
    /// and 2, Today and an earlier day, are `testDeleteAnEntryAsksFirst` and
    /// `testEarlierDayRowsAndMenu`; item 8 is
    /// `testThePlanBuilderStringsAndTheSoftRuleAlert`.)
    func testDeleteEntryOnTheEditScreenAsksWithAnAlert() throws {
        try launchOnToday("week1")
        let row = element(labelContaining: "Toast and tea")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let delete = app.buttons["Delete entry"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 8), "the edit screen shows")
        let what = app.textViews["What"].firstMatch
        what.tap()
        dismissKeyboardTip()
        what.typeText(" and jam")
        let keyboardTop = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY : app.frame.maxY
        XCTAssertTrue(dragTo(delete, above: keyboardTop - 50), "the edit screen shows \"Delete entry\"")
        delete.tap()
        recordPlanAssertAlert(title: "Delete this entry?", buttons: ["Delete", "Cancel"])
        tapDialogButton("Cancel")
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5), "Cancel closes the alert")
        XCTAssertTrue(delete.exists, "the edit screen stays")
        XCTAssertEqual(what.value as? String, "Toast and tea and jam", "Cancel keeps the change on the edit screen")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(delete.waitForNonExistence(timeout: 5))
        XCTAssertTrue(row.exists, "Cancel keeps the entry")
        XCTAssertFalse(element(labelContaining: "and jam").exists, "the entry does not change")
        row.tap()
        XCTAssertTrue(delete.waitForExistence(timeout: 8))
        delete.tap()
        recordPlanAssertAlert(title: "Delete this entry?", buttons: ["Delete", "Cancel"])
        tapDialogButton("Delete")
        XCTAssertTrue(row.waitForNonExistence(timeout: 8), "Delete removes the entry")
    }

    // MARK: mm-t23.15 (regular-eating-plan)

    /// mm-t23.15, comment of mm-t23.16: with "Day starts at" 07:00 in force
    /// and Breakfast at 06:00 in the plan (stage 2 open), the app opens on
    /// Today four times in a row (a launch and three more): Today shows the
    /// Breakfast row each time, the app does not stop, and safe mode does
    /// not start (safe mode's Today has no "Add an entry").
    func testAPlannedMealBeforeTheDayStartDoesNotStopTheApp() throws {
        try launchOnToday("planEarly")
        for open in 1...4 {
            if open > 1 {
                app.terminate()
                app.launch()
                XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "open \(open): Today shows")
            }
            XCTAssertTrue(element(labelBeginningWith: "Breakfast, 06:00").waitForExistence(timeout: 8), "open \(open): Today shows Breakfast at 06:00")
            XCTAssertTrue(app.buttons["Add an entry"].exists, "open \(open): the full Today shows, not safe mode")
            Thread.sleep(forTimeInterval: 2)
            XCTAssertEqual(app.state, .runningForeground, "open \(open): the app does not stop")
        }
    }

    /// mm-t23.15, comment of mm-t23.17, first part: with fifteen entries on
    /// the current day and the list at the top, a sixteenth saved entry
    /// makes Today scroll so that it is on screen, and no other row changes.
    func testASixteenthEntryScrollsIntoView() throws {
        try launchOnToday("fifteen")
        XCTAssertTrue(recordPlanElement(labelEndingWith: ", Entry 1").waitForExistence(timeout: 8))
        let before = recordPlanEntryLabels()
        XCTAssertEqual(before.count, 15, "Today shows the fifteen entries: \(before.sorted())")
        let lastSeeded = recordPlanElement(labelEndingWith: ", Entry 15")
        XCTAssertFalse(lastSeeded.exists && lastSeeded.isHittable, "at the top of the list, the last rows are off screen")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Sixteenth")
        tapSaveInTheNavigationBar()
        let sixteenth = recordPlanElement(labelEndingWith: ", Sixteenth")
        XCTAssertTrue(sixteenth.waitForExistence(timeout: 8), "Today shows the sixteenth entry")
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(sixteenth.isHittable, "Today scrolls so that the sixteenth entry is on screen")
        let sixteenthLabel = sixteenth.label
        let after = recordPlanEntryLabels()
        XCTAssertTrue(after.contains(sixteenthLabel), "Today keeps the sixteenth entry")
        XCTAssertEqual(after.subtracting([sixteenthLabel]), before, "no other row changes")
    }

    /// mm-t23.15, comment of mm-t23.17, second part: from stage 2, an entry
    /// saved while the matching planned meal row (Lunch) is off screen makes
    /// Today scroll to that row, which shows the entry.
    func testAMatchedPlannedMealRowScrollsIntoView() throws {
        let lunch = try recordPlanFacts("fifteenPlan")["lunch"]!
        try launchOnToday("fifteenPlan")
        XCTAssertTrue(recordPlanElement(labelEndingWith: ", Entry 1").waitForExistence(timeout: 8))
        let lunchRow = element(labelBeginningWith: "Lunch, \(lunch)")
        XCTAssertFalse(lunchRow.exists && lunchRow.isHittable, "at the top of the list, the Lunch row is off screen")
        openNewEntry()
        let what = app.textViews["What"].firstMatch
        what.tap()
        what.typeText("Sandwich")
        tapSaveInTheNavigationBar()
        let matched = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Lunch, \(lunch), ", ", Sandwich")).firstMatch
        XCTAssertTrue(matched.waitForExistence(timeout: 8), "the Lunch row shows the saved entry")
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(matched.isHittable, "Today scrolls to the Lunch row")
    }

    /// mm-t23.15, comment of mm-t23.18: with stage 2 open, Breakfast and
    /// Lunch more than 4 hours apart, and an entry at each planned time,
    /// Today shows the gap band between the Breakfast row and the Lunch
    /// row. The band's accessibility label is "Gap of more than 4 hours".
    /// (What VoiceOver speaks stays a device check.)
    func testABandShowsBetweenTwoPlannedMealRows() throws {
        let facts = try recordPlanFacts("planBand")
        try launchOnToday("planBand")
        let breakfast = element(labelBeginningWith: "Breakfast, \(facts["breakfast"]!), \(facts["breakfast"]!), Porridge")
        let lunch = element(labelBeginningWith: "Lunch, \(facts["lunch"]!), \(facts["lunch"]!), Soup")
        XCTAssertTrue(breakfast.waitForExistence(timeout: 8), "the Breakfast row shows its entry")
        XCTAssertTrue(scrollTo(lunch), "the Lunch row shows its entry")
        XCTAssertTrue(recordPlanBandShows(between: breakfast, and: lunch), "the band \"Gap of more than 4 hours\" shows between the Breakfast row and the Lunch row")
    }

    /// mm-t23.15, comment of mm-t23.19: with stage 2 open, a starred entry
    /// just before Lunch, and Mid-afternoon after Lunch: the Lunch row shows
    /// the entry and no next-planned-meal line; the Mid-afternoon row shows
    /// "Mid-afternoon at <time> still happens.". mm-t11.39: that line on the
    /// screen. Ruling r19-02 (mm-t23.26): the Mid-afternoon row's
    /// accessibility label ends with that line, after a comma and a space,
    /// and the Lunch row's label does not hold it.
    func testAStarredEntryPointsToTheNextPlannedMeal() throws {
        let facts = try recordPlanFacts("planStar")
        let midAfternoon = facts["midAfternoon"]!
        try launchOnToday("planStar")
        let lunchRow = element(labelBeginningWith: "Lunch, \(facts["lunch"]!), \(facts["entry"]!), Biscuits")
        XCTAssertTrue(lunchRow.waitForExistence(timeout: 8), "the Lunch row shows the starred entry")
        XCTAssertTrue(lunchRow.label.hasSuffix("felt like a binge"), "the Lunch row shows the star")
        let lines = NSPredicate(format: "label ENDSWITH %@", " still happens.")
        XCTAssertEqual(lunchRow.staticTexts.matching(lines).count, 0, "the Lunch row shows no line")
        let midRow = element(labelBeginningWith: "Mid-afternoon, \(midAfternoon)")
        XCTAssertTrue(scrollTo(midRow), "Today shows the Mid-afternoon row")
        XCTAssertTrue(midRow.staticTexts["Mid-afternoon at \(midAfternoon) still happens."].exists, "the Mid-afternoon row shows \"Mid-afternoon at \(midAfternoon) still happens.\"")
        // A line's own text holds no ", "; a row's label does (r19-02).
        let lineTexts = NSPredicate(format: "label ENDSWITH %@ AND NOT (label CONTAINS %@)", " still happens.", ", ")
        XCTAssertEqual(app.staticTexts.matching(lineTexts).count, 1, "Today shows one next-planned-meal line")
        // Ruling r19-02 (mm-t23.26): the row's label ends with the line.
        XCTAssertTrue(midRow.label.hasSuffix(", Mid-afternoon at \(midAfternoon) still happens."), "the Mid-afternoon row's accessibility label ends with the line: \"\(midRow.label)\"")
        XCTAssertFalse(lunchRow.label.hasSuffix(" still happens."), "the Lunch row's accessibility label holds no line: \"\(lunchRow.label)\"")
    }

    /// mm-t23.15, comment of mm-t23.20, the part with no text size: an
    /// entry with What, Where and Context that matches Lunch makes the
    /// Lunch row show the entry's time, What and Where on the row's first
    /// line, and the Context under them, with no field label. (The whole
    /// Context at the largest text size stays a device check.)
    func testAMatchedPlannedMealRowShowsWhatWhereAndContext() throws {
        let facts = try recordPlanFacts("planMatched")
        try launchOnToday("planMatched")
        let row = element(labelled: "Lunch, \(facts["lunch"]!), \(facts["entry"]!), Toast and tea, Home, Row with my sister")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "the Lunch row shows the entry's time, What, Where and Context")
        let firstLine = ["Lunch", facts["lunch"]!, facts["entry"]!, "Toast and tea", "Home"].map { row.staticTexts[$0].firstMatch }
        for (text, part) in zip(["Lunch", "the planned time", "the entry's time", "What", "Where"], firstLine) {
            XCTAssertTrue(part.exists, "the Lunch row shows \(text)")
            XCTAssertEqual(part.frame.midY, firstLine[0].frame.midY, accuracy: 2, "\(text) is on the row's first line")
        }
        XCTAssertEqual(firstLine.map(\.frame.minX), firstLine.map(\.frame.minX).sorted(), "the first line reads Lunch, the times, What and Where in order")
        let context = row.staticTexts["Row with my sister"].firstMatch
        XCTAssertTrue(context.exists, "the Lunch row shows the Context")
        XCTAssertGreaterThanOrEqual(context.frame.minY, firstLine.map(\.frame.maxY).max() ?? 0, "the Context is under the What and the Where")
        XCTAssertEqual(context.frame.minX, firstLine[0].frame.minX, accuracy: 1, "the Context starts at the row's leading edge")
        for label in ["Context", "What was going on just before?", "What", "Where"] {
            XCTAssertFalse(row.staticTexts[label].exists, "the row shows no field label \"\(label)\"")
        }
    }

    /// mm-t23.15, comment of mm-t23.21: with Lunch on Today, a change of
    /// Lunch in the weekday plan, and then "Copy to weekend plan", leave
    /// Today's Lunch row at its time; "Tomorrow's plan" shows the new time.
    /// On Monday to Friday the weekday change is the change that could reach
    /// today's plan; on Saturday or Sunday the copy is.
    func testATemplateChangeKeepsTodaysPlannedRows() throws {
        let facts = try recordPlanFacts("planMatched")
        let lunch = facts["lunch"]!
        let newTime = recordPlanClock(lunch, adding: -60)
        try launchOnToday("planMatched")
        let todayRow = element(labelBeginningWith: "Lunch, \(lunch), ")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 8), "Today shows Lunch at \(lunch)")
        let tomorrowKey = recordPlanAdding(1, to: recordPlanCurrentDayKey())
        let tomorrowIsWeekend = [1, 7].contains(recordPlanKeyCalendar.component(.weekday, from: recordPlanDate(ofKey: tomorrowKey)))
        func tomorrowsLunch() -> String? {
            tapDayMenu("Tomorrow's plan")
            assertScreen("Tomorrow's plan")
            let value = recordPlanBuilderTimes().first?.value as? String
            app.navigationBars.buttons["Cancel"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Tomorrow's plan"].waitForNonExistence(timeout: 5))
            return value
        }
        // The weekday plan: Lunch an hour earlier, then Save. One meal and no
        // snack break a soft rule, so the alert asks first.
        tapDayMenu("Weekday plan")
        assertScreen("Weekday plan")
        let picker = try XCTUnwrap(recordPlanBuilderTimes().first, "the weekday plan shows Lunch")
        XCTAssertTrue(app.staticTexts["Lunch time"].exists)
        recordPlanSetBuilderTime(picker, to: newTime, title: "Weekday plan")
        app.buttons["Save"].firstMatch.tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 3) { app.alerts.firstMatch.buttons["Save anyway"].tap() }
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForNonExistence(timeout: 5), "Save closes the plan builder")
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5), "after the weekday plan change, Today's Lunch row stays at \(lunch)")
        XCTAssertFalse(element(labelBeginningWith: "Lunch, \(newTime)").exists, "Today's Lunch row does not move to \(newTime)")
        XCTAssertEqual(tomorrowsLunch(), tomorrowIsWeekend ? lunch : newTime, "Tomorrow's plan shows Lunch from its own template")
        // "Copy to weekend plan".
        tapDayMenu("Weekday plan")
        assertScreen("Weekday plan")
        XCTAssertEqual(recordPlanBuilderTimes().first?.value as? String, newTime)
        app.buttons["Copy to weekend plan"].firstMatch.tap()
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5), "after \"Copy to weekend plan\", Today's Lunch row stays at \(lunch)")
        XCTAssertEqual(tomorrowsLunch(), newTime, "after the copy, Tomorrow's plan shows Lunch at \(newTime)")
    }

    /// mm-t23.15, comment of mm-t23.22, the part with no VoiceOver: Lunch
    /// passed with no entry, and a later entry matches no planned meal. The
    /// Lunch row shows "Skipped, or not recorded yet?" with the two buttons
    /// "Skipped" and "Add it" only. "Add it" opens the new-entry screen at
    /// Lunch's time. mm-t11.39: that line on the screen. (The VoiceOver
    /// actions stay a device check.) The spec also asks for buttons at
    /// least 44 points tall with 8 points between them, and the keyboard in
    /// What after "Add it".
    func testTheMissedPlannedMealPrompt() throws {
        let facts = try recordPlanFacts("planMissed")
        let lunch = facts["lunch"]!
        try launchOnToday("planMissed")
        let row = element(labelled: "Lunch, \(lunch), Skipped, or not recorded yet?")
        XCTAssertTrue(row.waitForExistence(timeout: 8), "the Lunch row shows the prompt")
        XCTAssertTrue(row.staticTexts["Skipped, or not recorded yet?"].exists, "the Lunch row shows \"Skipped, or not recorded yet?\"")
        let buttons = row.buttons.allElementsBoundByIndex
        XCTAssertEqual(buttons.map(\.label), ["Skipped", "Add it"], "the prompt shows \"Skipped\" and \"Add it\" only")
        // regular-eating-plan spec: "visible buttons at least 44 points
        // tall, with 8 points between them".
        for button in buttons {
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, "\"\(button.label)\" is at least 44 points tall")
        }
        if buttons.count == 2 {
            XCTAssertEqual(buttons[1].frame.minX - buttons[0].frame.maxX, 8, accuracy: 1, "8 points are between the two buttons")
        }
        XCTAssertTrue(element(labelled: "\(facts["entry"]!), Apple").exists, "the later entry matches no planned meal")
        row.buttons["Add it"].tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "\"Add it\" opens the new-entry screen")
        let what = app.textViews["What"].firstMatch
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "the keyboard shows")
        XCTAssertEqual(what.value(forKey: "hasKeyboardFocus") as? Bool, true, "the keyboard is in What")
        let time = app.otherElements["Time"].firstMatch
        XCTAssertTrue((time.value as? String)?.hasSuffix(", \(lunch)") ?? false, "the new-entry screen opens at \(lunch): \(String(describing: time.value))")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 5))
        // mm-t12b.13: after "Add it" and Cancel, "Add an entry" opens at the
        // current time again.
        let opened = Date()
        openNewEntry()
        let clock = DateFormatter()
        clock.locale = Locale(identifier: "en_GB")
        clock.dateFormat = "HH:mm"
        let nearNow = (-1...2).map { clock.string(from: opened.addingTimeInterval(Double($0) * 60)) }
        let value = time.value as? String ?? ""
        XCTAssertTrue(nearNow.contains { value.hasSuffix(", \($0)") }, "\"Add an entry\" opens at the current time, not at \(lunch): \(value)")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
    }

    /// mm-t12b.1, comment of mm-t12b.20 and mm-t12.37, item 2, the part on
    /// Today: from stage 2, a tap on "Skipped" on a missed planned meal
    /// makes the row show "Skipped", and the prompt goes. (That the planned
    /// meal reminder stops stays a device check. An earlier day shows no
    /// prompt, because its record day has ended, so it has no "Skipped" to
    /// tap.)
    func testSkippedOnAMissedPlannedMeal() throws {
        let lunch = try recordPlanFacts("planMissed")["lunch"]!
        try launchOnToday("planMissed")
        let prompt = element(labelled: "Lunch, \(lunch), Skipped, or not recorded yet?")
        XCTAssertTrue(prompt.waitForExistence(timeout: 8), "the Lunch row shows the prompt")
        prompt.buttons["Skipped"].tap()
        let skipped = element(labelled: "Lunch, \(lunch), Skipped")
        XCTAssertTrue(skipped.waitForExistence(timeout: 5), "the Lunch row shows \"Skipped\"")
        XCTAssertTrue(skipped.staticTexts["Skipped"].exists, "the Lunch row shows the word \"Skipped\"")
        XCTAssertFalse(app.staticTexts["Skipped, or not recorded yet?"].exists, "the prompt goes")
        XCTAssertEqual(skipped.buttons.count, 0, "the row shows no \"Skipped\" or \"Add it\" control")
    }

    /// mm-t23.15, comment of mm-t11.39, the plan strings on the screen: the
    /// builder of an empty plan lists the six default slot labels; a planned
    /// Lunch shows "Lunch time", "Remove Lunch" and the control "Rename
    /// Lunch"; a rename to "Midmorning" shows "That is the app's name.
    /// Choose another word.". Comment of r16-03 (mm-t12b.28) on mm-t12b.1,
    /// item 8: Save on 2 meals and 1 snack with a gap of 4 hours 30 minutes
    /// shows the soft-rule check as an alert in the centre of the screen,
    /// with both lines and with "Save anyway" and "Go back". "Go back"
    /// changes nothing: the builder keeps the change, and the plan is not
    /// saved. "Save anyway" saves.
    func testThePlanBuilderStringsAndTheSoftRuleAlert() throws {
        try launchOnToday("planStrings")
        // The weekend plan is empty.
        tapDayMenu("Weekend plan")
        assertScreen("Weekend plan")
        for label in ["Breakfast", "Mid-morning", "Lunch", "Mid-afternoon", "Evening meal", "Evening snack"] {
            XCTAssertTrue(app.buttons[label].firstMatch.exists, "the builder lists the slot \"\(label)\"")
        }
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Weekend plan"].waitForNonExistence(timeout: 5))
        // The weekday plan: Mid-morning 10:30, Lunch 12:30, Evening meal 17:00.
        tapDayMenu("Weekday plan")
        assertScreen("Weekday plan")
        XCTAssertEqual(recordPlanBuilderTimes().map { $0.value as? String }, ["10:30", "12:30", "17:00"])
        for label in ["Mid-morning time", "Lunch time", "Evening meal time"] {
            XCTAssertTrue(app.staticTexts[label].exists, "the builder shows \"\(label)\"")
        }
        XCTAssertTrue(app.buttons["Remove Lunch"].exists, "the builder shows \"Remove Lunch\"")
        let rename = app.buttons["Rename Lunch"].firstMatch
        XCTAssertTrue(rename.exists, "the rename control of Lunch reads \"Rename Lunch\"")
        // A rename to the app's name.
        rename.tap()
        XCTAssertTrue(app.navigationBars["Rename"].waitForExistence(timeout: 5), "the rename screen shows")
        let field = app.textFields.firstMatch
        field.tap()
        dismissKeyboardTip()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8) + "Midmorning")
        app.navigationBars["Rename"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["That is the app's name. Choose another word."].waitForExistence(timeout: 5), "a rename to \"Midmorning\" shows the message")
        app.navigationBars["Rename"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Rename"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Lunch time"].exists, "Lunch keeps its name")
        // A change that is not saved yet: Mid-morning at 10:00. The plan still
        // has 2 meals and 1 snack and the gap after Lunch.
        let softRules = "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?\n\n4 hours 30 minutes between Lunch at 12:30 and Evening meal at 17:00."
        recordPlanSetBuilderTime(recordPlanBuilderTimes()[0], to: "10:00", title: "Weekday plan")
        app.buttons["Save"].firstMatch.tap()
        recordPlanAssertAlert(title: softRules, buttons: ["Save anyway", "Go back"])
        app.alerts.firstMatch.buttons["Go back"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5), "\"Go back\" closes the alert")
        XCTAssertTrue(app.navigationBars["Weekday plan"].exists, "\"Go back\" keeps the plan builder open")
        XCTAssertEqual(recordPlanBuilderTimes().first?.value as? String, "10:00", "\"Go back\" keeps the change in the builder")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForNonExistence(timeout: 5))
        tapDayMenu("Weekday plan")
        assertScreen("Weekday plan")
        XCTAssertEqual(recordPlanBuilderTimes().first?.value as? String, "10:30", "\"Go back\" saved nothing")
        // "Save anyway" saves.
        recordPlanSetBuilderTime(recordPlanBuilderTimes()[0], to: "10:00", title: "Weekday plan")
        app.buttons["Save"].firstMatch.tap()
        recordPlanAssertAlert(title: softRules, buttons: ["Save anyway", "Go back"])
        app.alerts.firstMatch.buttons["Save anyway"].tap()
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForNonExistence(timeout: 5), "\"Save anyway\" saves and closes the builder")
        tapDayMenu("Weekday plan")
        assertScreen("Weekday plan")
        XCTAssertEqual(recordPlanBuilderTimes().first?.value as? String, "10:00", "\"Save anyway\" saved the plan")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
    }
}
