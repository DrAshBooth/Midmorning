import XCTest

/// Drives the installed Midmorning app (uk.midmorning.app) for the
/// record-entry-on-today device checks. The host seeds the store before a run.
final class SkeletonChecks: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "uk.midmorning.app")
    var outDir: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["OUT_DIR"] ?? NSTemporaryDirectory()) }

    override func setUp() { continueAfterFailure = true }

    func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 1.0)
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: outDir.appendingPathComponent(name + ".png"))
    }
    func log(_ line: String) {
        print("EVIDENCE: " + line)
        let url = outDir.appendingPathComponent("evidence.log")
        let data = (line + "\n").data(using: .utf8)!
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(data); try? h.close() }
        else { try? data.write(to: url) }
    }
    func timeRows() -> [String] {
        let q = app.descendants(matching: .any).matching(NSPredicate(format: "label MATCHES %@", "^[0-9][0-9]:[0-9][0-9].*"))
        let all = q.allElementsBoundByIndex.map { $0.label }
        let full = all.filter { $0.count > 5 }
        var out: [String] = []
        for l in all where !out.contains(l) && !(l.count == 5 && full.contains(where: { $0.hasPrefix(l + ",") })) { out.append(l) }
        return out
    }
    func headings() -> [String] {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "September")).allElementsBoundByIndex.map { $0.label }
    }
    func whatField() -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == 'What' AND (elementType == %d OR elementType == %d)", XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
    }
    func dismissKeyboardTip() {
        let cont = app.buttons["Continue"]
        if cont.waitForExistence(timeout: 2) { cont.tap(); Thread.sleep(forTimeInterval: 0.8) }
    }
    func launchFresh(_ env: [String: String] = [:]) {
        app.terminate(); app.launchEnvironment = env; app.launch()
        XCTAssert(app.navigationBars["Today"].waitForExistence(timeout: 15), "Today did not appear")
        Thread.sleep(forTimeInterval: 3)
    }

    func testDump() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        Thread.sleep(forTimeInterval: 1)
        try? app.debugDescription.write(to: outDir.appendingPathComponent("dump.txt"), atomically: true, encoding: .utf8)
    }

    // 2.4 and 2.5: the seeded day in order, and the starred row's label.
    func test24_25_Today() {
        launchFresh()
        log("2.4 headings: " + headings().joined(separator: " | "))
        log("2.4 rows top to bottom: " + timeRows().joined(separator: " | "))
        shot("2.4-today")
        let starred = app.descendants(matching: .any).matching(identifier: "13:05, Toast and tea, felt like a binge").firstMatch
        log("2.5 starred row exists: \(starred.exists), label: \"\(starred.label)\"")
        let emptyWhat = app.descendants(matching: .any).matching(identifier: "10:45").firstMatch
        log("2.5 empty-What row exists: \(emptyWhat.exists), label: \"\(emptyWhat.label)\"")
        shot("2.5-inspector")
        XCTAssert(starred.exists)
    }

    // 2.6: one tap opens the new-entry screen.
    func test26_OneTap() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        let what = whatField()
        log("2.6 one tap on \"New entry\" shows the What field: \(what.waitForExistence(timeout: 5))")
        shot("2.6-one-tap")
        app.buttons["Cancel"].tap()
    }

    // 2.6: the heading changes after the day start, on reactivation. The host
    // runs this with HEADING_TZ set to a zone a minute or two before 04:00.
    func test26_Heading() {
        let tzName = ProcessInfo.processInfo.environment["HEADING_TZ"] ?? "Pacific/Guadalcanal"
        let tz = TimeZone(identifier: tzName)!
        let f = DateFormatter(); f.timeZone = tz; f.dateFormat = "EEE d MMM HH:mm:ss"
        launchFresh(["TZ": tzName])
        let before = headings()
        log("2.6 at \(f.string(from: Date())) \(tzName): headings \(before)")
        shot("2.6-heading-before")
        XCUIDevice.shared.press(.home)
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        while true {
            let c = cal.dateComponents([.hour, .minute, .second], from: Date())
            if c.hour == 4 && (c.second! >= 5 || c.minute! > 0) { break }
            if c.hour! > 4 { break }
            Thread.sleep(forTimeInterval: 1)
        }
        app.activate()
        _ = app.navigationBars["Today"].waitForExistence(timeout: 10)
        Thread.sleep(forTimeInterval: 1)
        let after = headings()
        log("2.6 after reactivation at \(f.string(from: Date())) \(tzName): headings \(after)")
        shot("2.6-heading")
        XCTAssertNotEqual(before, after)
    }

    // 2.7: keyboard on open, focus in What, no placeholder, no title, the star label, the range, the reading order.
    func test27_NewEntry() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        let what = whatField()
        _ = what.waitForExistence(timeout: 5)
        log("2.7 keyboard up on open: \(app.keyboards.firstMatch.waitForExistence(timeout: 4))")
        log("2.7 What has keyboard focus: \((what.value(forKey: "hasKeyboardFocus") as? Bool) ?? false)")
        log("2.7 What placeholder: \"\(what.placeholderValue ?? "")\", value: \"\((what.value as? String) ?? "")\"")
        let sheetBars = app.navigationBars.allElementsBoundByIndex.map { "\($0.identifier)|\($0.staticTexts.allElementsBoundByIndex.map { $0.label })" }
        log("2.7 navigation bars (identifier|titles): \(sheetBars)")
        log("2.7 star control \"felt like a binge\" exists: \(app.switches["felt like a binge"].exists)")
        let wanted = ["What", "felt like a binge", "Time", "Save", "Cancel"]
        var order: [String] = []
        for e in app.descendants(matching: .any).allElementsBoundByIndex {
            let l = e.label
            if wanted.contains(l) && !order.contains(l) { order.append(l) }
        }
        log("2.7 accessibility tree order of the five controls: \(order)")
        shot("2.7-new-entry")
        // The range: open the compact date picker and read which days it offers.
        let picker = app.datePickers.firstMatch
        if picker.exists {
            picker.buttons.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1.5)
            let days = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "September")).allElementsBoundByIndex
            log("2.7 calendar days and whether each is enabled: " + days.map { "\($0.label)=\($0.isEnabled)" }.joined(separator: "; "))
            shot("2.7-range")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        } else { log("2.7 no date picker found") }
    }

    // 2.7: the time control's VoiceOver label and value, and the elements inside it.
    func test27_TimeValue() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        XCTAssert(whatField().waitForExistence(timeout: 5))
        for e in app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Time")).allElementsBoundByIndex {
            log("2.7 element labelled Time: type \(e.elementType.rawValue), value \"\(String(describing: e.value))\"")
        }
        let picker = app.datePickers.firstMatch
        log("2.7 date picker label \"\(picker.label)\", value \"\(String(describing: picker.value))\"")
        for b in picker.buttons.allElementsBoundByIndex {
            log("2.7 button inside the picker: label \"\(b.label)\", value \"\(String(describing: b.value))\"")
        }
    }

    // Xcode's accessibility audit of Today and the new-entry screen. Every issue is logged, none fails the test.
    func testAudit() throws {
        launchFresh()
        func audit(_ screen: String) throws {
            var n = 0
            try app.performAccessibilityAudit(for: .all) { issue in
                n += 1
                self.log("audit \(screen): \(issue.auditType) | \(issue.compactDescription) | element \"\(issue.element?.label ?? "none")\" | \(issue.detailedDescription)")
                return true
            }
            log("audit \(screen): \(n) issues")
        }
        try audit("Today")
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        XCTAssert(whatField().waitForExistence(timeout: 5))
        try audit("new entry")
    }

    // 2.8: save closes the sheet, Today shows the entry, scrolled into view, and nothing else.
    func test28_Save() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        let what = whatField()
        XCTAssert(what.waitForExistence(timeout: 5))
        what.typeText("Toast and tea")
        app.buttons["Save"].tap()
        let gone = what.waitForNonExistence(timeout: 5)
        let saved = app.descendants(matching: .any).matching(NSPredicate(format: "label ENDSWITH %@", ", Toast and tea")).firstMatch
        _ = saved.waitForExistence(timeout: 5)
        log("2.8 sheet closed: \(gone); Today shown: \(app.navigationBars["Today"].exists); saved row \"\(saved.label)\" visible: \(saved.isHittable); alerts: \(app.alerts.count); sheets: \(app.sheets.count)")
        log("2.8 rows top to bottom: " + timeRows().joined(separator: " | "))
        shot("2.8-save")
        // An empty What gives a row whose label is the time alone. Count the
        // elements labelled with that time before and after the empty save.
        let hhmm = String(saved.label.prefix(5))
        let bare = { self.app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", hhmm)).count }
        let before = bare()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        XCTAssert(whatField().waitForExistence(timeout: 5))
        app.buttons["Save"].tap()
        _ = whatField().waitForNonExistence(timeout: 5)
        Thread.sleep(forTimeInterval: 0.8)
        log("2.8 elements labelled \"\(hhmm)\" alone: \(before) before the empty save, \(bare()) after")
        shot("2.8-save-empty")
    }

    // 2.9: the app switcher shows no entry text.
    func test29_Switcher() {
        launchFresh()
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.998))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 1.2)
        Thread.sleep(forTimeInterval: 1.5)
        shot("2.9-switcher")
        log("2.9 app state after the switcher gesture: \(app.state.rawValue) (4 = foreground, 3 = background, 2 = suspended)")
    }

    // 2.9: the app switcher while the new-entry screen holds typed text and the star is on.
    func test29_SwitcherWithSheet() {
        launchFresh()
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        let what = whatField()
        XCTAssert(what.waitForExistence(timeout: 5))
        what.typeText("Toast and tea")
        let row = app.switches["felt like a binge"]
        let knob = row.switches.firstMatch
        (knob.exists ? knob : row).tap()
        Thread.sleep(forTimeInterval: 0.8)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.998))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 1.2)
        Thread.sleep(forTimeInterval: 1.5)
        // Drag the cards left so the current app's card sits whole in the view.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)))
        Thread.sleep(forTimeInterval: 1.5)
        shot("2.9-switcher-new-entry")
        app.activate()
        Thread.sleep(forTimeInterval: 1.5)
        let back = whatField()
        log("2.9 back from the switcher: What \"\((back.value as? String) ?? "")\", focus \((back.value(forKey: "hasKeyboardFocus") as? Bool) ?? false), keyboard \(app.keyboards.firstMatch.exists), star \(String(describing: row.value))")
        shot("2.9-back-from-switcher")
    }

    // 2.12: the starred-entry path, for the shame walk.
    func test212_ShameWalk() {
        launchFresh()
        shot("2.12-a-today")
        app.buttons["New entry"].tap(); dismissKeyboardTip()
        XCTAssert(whatField().waitForExistence(timeout: 5))
        let row = app.switches["felt like a binge"]
        let knob = row.switches.firstMatch
        (knob.exists ? knob : row).tap()
        Thread.sleep(forTimeInterval: 0.8)
        log("2.12 star value after the tap: \(String(describing: row.value))")
        shot("2.12-b-new-entry-star-on")
        app.buttons["Save"].tap()
        _ = whatField().waitForNonExistence(timeout: 5)
        Thread.sleep(forTimeInterval: 0.8)
        shot("2.12-c-today-after-save")
        log("2.12 rows after the starred save: " + timeRows().joined(separator: " | "))
    }
}
