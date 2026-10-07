import XCTest
import UIKit

/// Rulings r13-19 and r16-01 (mm-t43.32 and mm-t43.33, epic mm-t45): the
/// navigation, text and flow checks of the device-check beads mm-t14.28
/// (onboarding and safeguarding), mm-t21.24 (programme) and mm-t32.17
/// (weekly review), as UI tests. Each test names its device-check bead and
/// the item it replaces. The seeded stores whose names begin with "or-"
/// are in `seeder/Sources/Seeder/OnboardingReviewScenarios.swift`.
///
/// The long forms (onboarding screen 2, the restart re-screen, the review)
/// are lists that make a row only near the screen. The helpers below read
/// one snapshot of the screen for each step, find a row by its label and
/// its place under a question, and tap its point on the screen. This is
/// much faster than a query for each element.
extension AutomatedChecks {

    // MARK: Questions, answers and messages

    static let selfHarmQuestion = "Over the last two weeks, have you had thoughts that you'd be better off dead, or of hurting yourself?"
    static let selfHarmStep2Question = "Have you thought about how you would do it?"
    static let treatmentQuestion = "Are you getting help from a clinic or a therapist for your eating at the moment?"
    static let pregnancyQuestion = "We ask everyone the same questions. Pregnancy changes what eating needs to look like, so: are you pregnant at the moment?"
    static let supportLine = "That deserves a person. Samaritans are there any time, on 116 123."
    static let pleaseAnswer = "Please answer this one."
    static let heightCmMessage = "Enter a height between 100 and 250 cm."
    static let weightKgMessage = "Enter a weight of 30 kg or more."
    static let heightFtInMessage = "Enter a height between 3 ft 4 in and 8 ft 2 in."
    static let weightStLbMessage = "Enter a weight of 4 st 11 lb or more."

    // MARK: One snapshot of the screen

    /// One element of a snapshot: its type, label, value and frame.
    struct Seen {
        let type: XCUIElement.ElementType
        let label: String
        let value: String?
        let placeholder: String?
        let frame: CGRect
        let isSelected: Bool
        let isEnabled: Bool
    }

    /// Every element on the screen, in one snapshot.
    func look() -> [Seen] {
        guard let root = try? app.snapshot() else { return [] }
        var all: [Seen] = []
        func walk(_ snapshot: XCUIElementSnapshot) {
            all.append(Seen(type: snapshot.elementType, label: snapshot.label, value: snapshot.value as? String,
                            placeholder: snapshot.placeholderValue, frame: snapshot.frame,
                            isSelected: snapshot.isSelected, isEnabled: snapshot.isEnabled))
            snapshot.children.forEach(walk)
        }
        walk(root)
        return all
    }

    /// Taps the centre of `frame`.
    func tap(_ frame: CGRect) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
    }

    /// The part of the screen where the list shows: under the lowest
    /// navigation bar, and above the keyboard and the confirming control
    /// `bar` ("Continue" or "Done" at the bottom of a form).
    func listBounds(_ seen: [Seen], bar: String?) -> (top: CGFloat, bottom: CGFloat) {
        let window = app.windows.firstMatch.frame
        let top = seen.filter { $0.type == .navigationBar }.map(\.frame.maxY).max() ?? 0
        var bottom = (window.height > 0 ? window.maxY : 874) - 40
        for item in seen where item.type == .keyboard && item.frame.height > 0 {
            bottom = min(bottom, item.frame.minY - 8)
        }
        if let bar, let confirm = widest(bar, in: seen) {
            bottom = min(bottom, confirm.frame.minY - 8)
        }
        return (top, bottom)
    }

    /// The widest button with `label` in `seen`: the full-width confirming
    /// control when a smaller control has the same label.
    func widest(_ label: String, in seen: [Seen]) -> Seen? {
        seen.filter { $0.type == .button && $0.label == label }.max { $0.frame.width < $1.frame.width }
    }

    /// A slow drag of the list from its left margin, so that the drag
    /// never starts on a control or on the scroll bar. A positive
    /// `distance` moves the content up, to show what is lower in the list.
    /// The drag holds at its end, so the list does not move on after it.
    func dragList(by distance: CGFloat, bounds: (top: CGFloat, bottom: CGFloat)) {
        let room = max(bounds.bottom - bounds.top - 20, 40)
        let length = min(max(abs(distance), 30), room)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let fromY = distance > 0 ? bounds.bottom - 10 : bounds.top + 10
        let toY = distance > 0 ? fromY - length : fromY + length
        origin.withOffset(CGVector(dx: 8, dy: fromY))
            .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: 8, dy: toY)), withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    /// Drags the list until the element that `find` returns, and `extra`
    /// points under it, show between the navigation bar and `bar`. It drags
    /// down the list first, and back up when it found nothing in the first
    /// half of the drags. Returns the element from the last snapshot.
    @discardableResult
    func reveal(extra: CGFloat = 0, bar: String? = nil, maxDrags: Int = 20, _ find: ([Seen]) -> Seen?) -> Seen? {
        var drags = 0
        while true {
            let seen = look()
            let bounds = listBounds(seen, bar: bar)
            let room = bounds.bottom - bounds.top
            if let target = find(seen) {
                let low = target.frame.maxY + extra - bounds.bottom
                let high = bounds.top - target.frame.minY
                if low <= 0, high <= 1 { return target }
                guard drags < maxDrags else { return nil }
                dragList(by: low > 0 ? low + 12 : -(high + 12), bounds: bounds)
            } else {
                guard drags < maxDrags else { return nil }
                dragList(by: drags < maxDrags / 2 ? room * 0.6 : -room * 0.6, bounds: bounds)
            }
            drags += 1
        }
    }

    /// The element with `label` (or with `label` as its placeholder) of
    /// `type`, if any.
    func first(_ type: XCUIElement.ElementType, _ label: String, in seen: [Seen]) -> Seen? {
        seen.first { $0.type == type && ($0.label == label || ($0.label.isEmpty && $0.placeholder == label)) }
    }

    /// The nearest button with `label` under the question `question`.
    func answerRow(_ choice: String, under question: String, in seen: [Seen]) -> Seen? {
        guard let header = first(.staticText, question, in: seen) else { return nil }
        return seen.filter { $0.type == .button && $0.label == choice && $0.frame.minY >= header.frame.maxY - 1 }
            .min { $0.frame.minY < $1.frame.minY }
    }

    /// Taps the answer `choice` under the question `question` on onboarding
    /// screen 2, the restart re-screen or the review, and checks that the
    /// row is then selected.
    func answer(_ question: String, _ choice: String, bar: String? = "Continue", verify: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<2 {
            // The question and its answer rows on screen together.
            let header = reveal(bar: bar) { self.first(.staticText, question, in: $0) }
            guard header != nil else { break }
            guard let row = reveal(bar: bar, { self.answerRow(choice, under: question, in: $0) }) else { break }
            tap(row.frame)
            // An answer that opens a page ("Yes" to step 2 at the review)
            // is not checked here.
            if !verify || answerRow(choice, under: question, in: look())?.isSelected == true { return }
        }
        XCTFail("\"\(question)\" shows \"\(choice)\", and a tap selects it", file: file, line: line)
    }

    /// Types `value` into the text field `label`, in place of what the
    /// field holds.
    func fill(_ label: String, _ value: String, bar: String? = "Continue", file: StaticString = #filePath, line: UInt = #line) {
        guard let field = reveal(bar: bar, { self.first(.textField, label, in: $0) }) else {
            XCTFail("the screen shows the field \"\(label)\"", file: file, line: line)
            return
        }
        tap(field.frame)
        dismissKeyboardTipBesideAFullWidthControl()
        let current = field.value ?? ""
        var keys = ""
        if !current.isEmpty, current != field.placeholder {
            keys = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 1)
        }
        app.typeText(keys + value)
    }

    /// The first use of the keyboard on a new simulator can show a tip with
    /// its own "Continue". A screen with a full-width "Continue" then shows
    /// two; the tip's is the narrower one.
    func dismissKeyboardTipBesideAFullWidthControl() {
        let continues = look().filter { $0.type == .button && $0.label == "Continue" }
        guard continues.count > 1 else { return }
        let width = app.windows.firstMatch.frame.width
        if let tip = continues.first(where: { $0.frame.width < width * 0.7 }) { tap(tip.frame) }
    }

    /// Taps the full-width confirming control `label`.
    func tapConfirm(_ label: String = "Continue", file: StaticString = #filePath, line: UInt = #line) {
        guard let confirm = widest(label, in: look()) else {
            XCTFail("the screen shows \"\(label)\"", file: file, line: line)
            return
        }
        tap(confirm.frame)
    }

    /// Asserts that `message` shows once, under the element that `field`
    /// finds, and above the static text `next` (the next question), so that
    /// the message is under its own question and nowhere else.
    func assertMessage(_ message: String, under field: @escaping ([Seen]) -> Seen?, above next: String, bar: String? = "Continue", file: StaticString = #filePath, line: UInt = #line) {
        let shown = reveal(bar: bar) { self.first(.staticText, message, in: $0) }
        XCTAssertNotNil(shown, "\"\(message)\" shows", file: file, line: line)
        let seen = look()
        guard let text = first(.staticText, message, in: seen), let above = field(seen) else {
            XCTFail("\"\(message)\" and its field show together", file: file, line: line)
            return
        }
        XCTAssertGreaterThanOrEqual(text.frame.minY, above.frame.maxY - 1, "\"\(message)\" shows under its field", file: file, line: line)
        if let nextHeader = first(.staticText, next, in: seen) {
            XCTAssertLessThanOrEqual(text.frame.maxY, nextHeader.frame.minY + 1, "\"\(message)\" shows above \"\(next)\"", file: file, line: line)
        } else {
            XCTFail("\"\(next)\" shows under \"\(message)\"", file: file, line: line)
        }
        XCTAssertEqual(seen.filter { $0.type == .staticText && $0.label == message }.count, 1, "\"\(message)\" shows once", file: file, line: line)
    }

    /// A finder for the text field `label`.
    func field(_ label: String) -> ([Seen]) -> Seen? {
        { self.first(.textField, label, in: $0) }
    }

    /// The static text whose label is `text` exactly.
    func text(_ text: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
    }

    /// Onboarding screen 1, then "Continue": screen 2.
    func openScreen2(file: StaticString = #filePath, line: UInt = #line) throws {
        try launch(nil)
        let firstContinue = app.buttons["Continue"].firstMatch
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows", file: file, line: line)
        XCTAssertTrue(scrollTo(firstContinue), file: file, line: line)
        firstContinue.tap()
        assertScreen("A few questions first", file: file, line: line)
    }

    /// Today, "Programme", "Start week 1 again": the restart re-screen. The
    /// `week1` store holds no profile, so the re-screen shows first.
    func openRescreen(file: StaticString = #filePath, line: UInt = #line) throws {
        try launchOnToday("week1")
        tapToolbar("Programme")
        assertScreen("Programme", file: file, line: line)
        let restart = app.buttons["Start week 1 again"].firstMatch
        XCTAssertTrue(scrollTo(restart), file: file, line: line)
        restart.tap()
        assertScreen("A few questions first", file: file, line: line)
    }

    /// Taps a unit segment ("cm", "ft in", "kg" or "st lb").
    func chooseUnit(_ unit: String, bar: String? = "Continue", file: StaticString = #filePath, line: UInt = #line) {
        guard let segment = reveal(bar: bar, { self.first(.button, unit, in: $0) }) else {
            XCTFail("the screen shows the unit \"\(unit)\"", file: file, line: line)
            return
        }
        tap(segment.frame)
    }

    // MARK: r13-11 (mm-t14.44), comments of 20:46, 21:09 and 21:27 on mm-t14.28

    /// mm-t14.28, r13-11 (mm-t43.33): on onboarding screen 2 each height
    /// and weight message shows under its field, in the unit that the
    /// person chose: 17 cm, 6 kg, 2 ft 0 in and 3 st 0 lb. Then 3 ft 4 in
    /// and 4 st 11 lb, with "No" to the three questions: the screen accepts
    /// both, and screen 3 shows.
    func testScreen2LimitMessagesInEachUnit() throws {
        try openScreen2()
        fill("How old are you?", "30")
        checkLimitMessagesInEachUnit()
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] {
            answer(question, "No")
        }
        tapConfirm()
        assertScreen("Your start")
    }

    /// mm-t14.28, r13-11 (mm-t43.33): the same messages at the restart
    /// re-screen. 3 ft 4 in and 4 st 11 lb are accepted, and the start-day
    /// choice shows.
    func testRescreenLimitMessagesInEachUnit() throws {
        try openRescreen()
        checkLimitMessagesInEachUnit()
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] {
            answer(question, "No")
        }
        tapConfirm()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForExistence(timeout: 8), "3 ft 4 in and 4 st 11 lb are accepted: the start-day choice shows")
    }

    /// The four limit messages, each under its own field, then 3 ft 4 in
    /// and 4 st 11 lb with no message.
    private func checkLimitMessagesInEachUnit(file: StaticString = #filePath, line: UInt = #line) {
        fill("Height in centimetres", "17")
        tapConfirm()
        assertMessage(Self.heightCmMessage, under: field("Height in centimetres"), above: "Your weight", file: file, line: line)
        fill("Height in centimetres", "170")
        fill("Weight in kilograms", "6")
        tapConfirm()
        assertMessage(Self.weightKgMessage, under: field("Weight in kilograms"), above: Self.treatmentQuestion, file: file, line: line)
        XCTAssertFalse(text(Self.heightCmMessage).exists, "170 cm shows no height message", file: file, line: line)
        chooseUnit("ft in")
        fill("Height in feet", "2")
        fill("Height in inches", "0")
        tapConfirm()
        assertMessage(Self.heightFtInMessage, under: field("Height in feet"), above: "Your weight", file: file, line: line)
        fill("Height in feet", "3")
        fill("Height in inches", "4")
        chooseUnit("st lb")
        fill("Weight in stone", "3")
        fill("Weight in pounds", "0")
        tapConfirm()
        assertMessage(Self.weightStLbMessage, under: field("Weight in stone"), above: Self.treatmentQuestion, file: file, line: line)
        XCTAssertFalse(text(Self.heightFtInMessage).exists, "3 ft 4 in shows no height message", file: file, line: line)
        fill("Weight in stone", "4")
        fill("Weight in pounds", "11")
    }

    // MARK: mm-t14.34 and mm-t14.37 (comment of 15:28 on mm-t14.28)

    /// mm-t14.28, mm-t14.34 and mm-t14.37 (mm-t43.32): on onboarding screen
    /// 2 the line "We ask for your height and weight..." shows above the
    /// height field. With the height empty, "Continue" shows "Please answer
    /// this one." under the height; then the same for the weight; then,
    /// after "Yes" to the first self-harm question, under "Have you
    /// thought about how you would do it?". The fields have the labels
    /// "Height in centimetres", "Height in feet", "Height in inches",
    /// "Weight in kilograms", "Weight in stone" and "Weight in pounds",
    /// which VoiceOver reads. (The VoiceOver focus move stays a device
    /// check.)
    func testScreen2MessagesUnderTheHeightTheWeightAndStep2() throws {
        try openScreen2()
        let introFinder: ([Seen]) -> Seen? = { seen in seen.first { $0.type == .staticText && $0.label.hasPrefix("We ask for your height and weight") } }
        XCTAssertNotNil(reveal(extra: 200, bar: "Continue", introFinder), "screen 2 shows the line about height and weight")
        let seen = look()
        if let intro = introFinder(seen), let height = first(.textField, "Height in centimetres", in: seen), let question = first(.staticText, "Your height", in: seen) {
            XCTAssertLessThanOrEqual(intro.frame.maxY, question.frame.minY, "the line shows above the height question")
            XCTAssertLessThanOrEqual(intro.frame.maxY, height.frame.minY, "the line shows above the height field")
        } else {
            XCTFail("the line, the height question and the height field show together")
        }
        fill("How old are you?", "30")
        tapConfirm()
        assertMessage(Self.pleaseAnswer, under: field("Height in centimetres"), above: "Your weight")
        fill("Height in centimetres", "170")
        tapConfirm()
        assertMessage(Self.pleaseAnswer, under: field("Weight in kilograms"), above: Self.treatmentQuestion)
        fill("Weight in kilograms", "65")
        answer(Self.treatmentQuestion, "No")
        answer(Self.pregnancyQuestion, "No")
        answer(Self.selfHarmQuestion, "Yes")
        tapConfirm()
        // Step 2 is the last question, so the message is the last row.
        let message = reveal(extra: 0, bar: "Continue") { self.first(.staticText, Self.pleaseAnswer, in: $0) }
        XCTAssertNotNil(message, "\"Please answer this one.\" shows")
        let after = look()
        if let message = first(.staticText, Self.pleaseAnswer, in: after), let step2 = first(.staticText, Self.selfHarmStep2Question, in: after),
           let lastAnswer = answerRow("Yes", under: Self.selfHarmStep2Question, in: after) {
            XCTAssertGreaterThan(message.frame.minY, step2.frame.maxY, "the message shows under \"Have you thought about how you would do it?\"")
            XCTAssertGreaterThanOrEqual(message.frame.minY, lastAnswer.frame.maxY - 1, "the message shows under the answers of the second question")
        } else {
            XCTFail("the second question, its answers and the message show together")
        }
        XCTAssertEqual(after.filter { $0.type == .staticText && $0.label == Self.pleaseAnswer }.count, 1, "the message shows once")
        // The field labels for each unit.
        chooseUnit("ft in")
        chooseUnit("st lb")
        for label in ["Height in feet", "Height in inches", "Weight in stone", "Weight in pounds"] {
            XCTAssertNotNil(reveal(bar: "Continue", field(label)), "screen 2 shows the field \"\(label)\"")
        }
    }

    // MARK: mm-t21.26 and mm-t21.34 (comment of 15:28 on mm-t21.24)

    /// mm-t21.24, mm-t21.26 and mm-t21.34 (mm-t43.32): at the restart
    /// re-screen, 17 cm shows "Enter a height between 100 and 250 cm."
    /// under the height; 6 kg shows "Enter a weight of 30 kg or more."
    /// under the weight; an empty pregnancy question shows "Please answer
    /// this one." under that question, not at the end of the form. 170 cm
    /// and 54 kg, with no rule that excludes, show the caution sheet with
    /// "Continue", the GP paragraph and "Get support"; "Continue" opens the
    /// start-day choice. The height and weight fields have their names as
    /// labels, which VoiceOver reads. (The VoiceOver focus move stays a
    /// device check.)
    func testRescreenMessagesAndTheCautionSheet() throws {
        try openRescreen()
        XCTAssertNil(first(.textField, "How old are you?", in: look()), "the re-screen does not ask the age")
        fill("Height in centimetres", "17")
        tapConfirm()
        assertMessage(Self.heightCmMessage, under: field("Height in centimetres"), above: "Your weight")
        fill("Height in centimetres", "170")
        fill("Weight in kilograms", "6")
        tapConfirm()
        assertMessage(Self.weightKgMessage, under: field("Weight in kilograms"), above: Self.treatmentQuestion)
        fill("Weight in kilograms", "54")
        answer(Self.treatmentQuestion, "No")
        answer(Self.selfHarmQuestion, "No")
        tapConfirm()
        assertMessage(Self.pleaseAnswer, under: { self.answerRow("Doesn't apply to me", under: Self.pregnancyQuestion, in: $0) }, above: Self.selfHarmQuestion)
        answer(Self.pregnancyQuestion, "No")
        tapConfirm()
        // The caution sheet.
        let cautionBody = element(labelBeginningWith: "Your height and weight put you close to the range")
        XCTAssertTrue(cautionBody.waitForExistence(timeout: 8), "170 cm and 54 kg show the caution sheet")
        let gpParagraph = app.textViews["The GP paragraph"].firstMatch
        XCTAssertTrue(scrollTo(gpParagraph), "the caution sheet shows the GP paragraph")
        XCTAssertTrue(app.buttons["Copy"].firstMatch.exists, "the GP paragraph shows \"Copy\"")
        let sheet = app.scrollViews.containing(NSPredicate(format: "label BEGINSWITH %@", "Your height and weight put you close")).firstMatch
        let cautionContinue = sheet.buttons["Continue"].firstMatch
        XCTAssertTrue(scrollTo(cautionContinue), "the caution sheet shows \"Continue\"")
        // The sheet's own navigation bar holds "Get support": the bar that
        // is lowest on the screen, over the re-screen's bar.
        let bars = app.navigationBars.allElementsBoundByIndex.filter { $0.exists }
        let sheetBar = bars.max { $0.frame.minY < $1.frame.minY }
        XCTAssertNotNil(sheetBar?.buttons["Get support"].exists == true ? sheetBar : nil, "the caution sheet shows \"Get support\"")
        cautionContinue.tap()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForExistence(timeout: 8), "\"Continue\" opens the start-day choice")
        XCTAssertTrue(app.buttons["Today"].firstMatch.exists && app.buttons["Tomorrow"].firstMatch.exists, "the start-day choice offers \"Today\" and \"Tomorrow\"")
    }

    // MARK: mm-t11.46 (comments of 21:09 and 21:27 on mm-t21.24)

    /// mm-t21.24, mm-t11.46 (mm-t43.33): before week 1 the Programme
    /// screen's week line reads "Starts tomorrow"; in week 1 it reads "Week
    /// 1". The rows read "Getting started" to "Staying on track", in order,
    /// under the week line. The marked row has the label "Getting started,
    /// Now", and each row without its tool has the label "<stage>, Comes in
    /// a later version": the words that VoiceOver reads. "Getting started"
    /// opens the stage screen with the title "Getting started" and the line
    /// "Opened in week 1". (The VoiceOver walk stays a device check.)
    func testProgrammeWeekLineStageRowsAndStageScreen() throws {
        try launchOnToday("or-tomorrow")
        tapToolbar("Programme")
        assertScreen("Programme")
        XCTAssertTrue(text("Starts tomorrow").waitForExistence(timeout: 5), "before week 1 the week line reads \"Starts tomorrow\"")
        XCTAssertFalse(element(labelBeginningWith: "Week ").exists, "before week 1 the screen shows no week number")

        try launchOnToday("week1")
        tapToolbar("Programme")
        assertScreen("Programme")
        XCTAssertTrue(text("Week 1").waitForExistence(timeout: 5), "in week 1 the week line reads \"Week 1\"")
        let titles = ["Getting started", "Regular eating", "Alternatives", "Problem solving", "Taking stock", "Modules", "Staying on track"]
        let seen = look()
        let tops = titles.map { title in first(.staticText, title, in: seen)?.frame.minY ?? -1 }
        XCTAssertFalse(tops.contains(-1), "the Programme screen shows the seven rows: \(tops)")
        XCTAssertEqual(tops, tops.sorted(), "the rows read \"Getting started\" to \"Staying on track\", in order")
        if let week = first(.staticText, "Week 1", in: seen) {
            XCTAssertLessThan(week.frame.maxY, tops[0], "the week line shows above the rows")
        }
        XCTAssertTrue(seen.contains { $0.label == "Getting started, Now" }, "the marked row has the label \"Getting started, Now\"")
        for title in titles.dropFirst(2) {
            XCTAssertTrue(seen.contains { $0.label == "\(title), Comes in a later version" }, "the row \"\(title)\" has the label \"\(title), Comes in a later version\"")
        }
        element(labelBeginningWith: "Getting started").tap()
        assertScreen("Getting started")
        XCTAssertTrue(text("Opened in week 1").waitForExistence(timeout: 5), "the stage screen shows \"Opened in week 1\"")
    }

    // MARK: mm-t21.35 (comment of 15:38 on mm-t21.24) and mm-t11.46

    /// mm-t21.24, mm-t21.35 (mm-t43.32) and mm-t11.46 (mm-t43.33): on
    /// Today, on the second recorded day, the stage 1 card row shows the
    /// card title "Why write it down" with "Read" and "Close". With stage 2
    /// open for three days and no plan, the plan card shows "Your plan
    /// isn't set yet. It takes about two minutes." with "Set it up" and
    /// "Close". On the day stage 2 opens, the opening card shows the title
    /// "Regular eating" and the sentence "You can now plan when to eat. The
    /// app reminds you at each planned meal." with "Open" and "Close". (The
    /// Instruments part of mm-t21.35 stays a device check.)
    func testTodayShowsTheCardRows() throws {
        try launchOnToday("or-secondday")
        assertCardRow(lines: ["Why write it down"], primary: "Read")
        try launchOnToday("or-plancard")
        assertCardRow(lines: ["Your plan isn't set yet. It takes about two minutes."], primary: "Set it up")
        try launchOnToday("review")
        assertCardRow(lines: ["Regular eating", "You can now plan when to eat. The app reminds you at each planned meal."], primary: "Open")
    }

    /// The card row on Today: its lines, in order, and under them the
    /// primary control and "Close", in the same cell.
    func assertCardRow(lines: [String], primary: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text(lines[0]).waitForExistence(timeout: 8), "Today shows \"\(lines[0])\"", file: file, line: line)
        let cell = app.cells.containing(NSPredicate(format: "label == %@", lines[0])).firstMatch
        XCTAssertTrue(cell.exists, file: file, line: line)
        var lastTop: CGFloat = -1
        for text in lines {
            let shown = cell.staticTexts[text].firstMatch
            XCTAssertTrue(shown.exists, "the card row shows \"\(text)\"", file: file, line: line)
            XCTAssertGreaterThan(shown.frame.minY, lastTop, "\"\(text)\" shows under the line before it", file: file, line: line)
            lastTop = shown.frame.minY
        }
        for control in [primary, "Close"] {
            let button = cell.buttons[control].firstMatch
            XCTAssertTrue(button.exists, "the card row shows \"\(control)\"", file: file, line: line)
            XCTAssertGreaterThan(button.frame.minY, lastTop, "\"\(control)\" shows under the card's text", file: file, line: line)
        }
    }

    // MARK: r13-17 (mm-t32.25), comment of 20:33 on mm-t32.17

    /// mm-t32.17, r13-17 (mm-t43.33): in the review of week 1, an answer
    /// under "What is hardest at the moment?", then "I'm getting worse",
    /// "Done" on the GP suggestion page, and a return to Today with no
    /// "Done" on the review. Today still shows "Weekly review", and the
    /// review of week 1 opens again with the answer.
    func testWeekOneAnswerStaysAfterGettingWorse() throws {
        try launchOnToday("review")
        openTheDueReview()
        fill("What is hardest at the moment?", "Mornings", bar: "Done")
        tapGettingWorse()
        tapDoneOnThePage("It might help to see your GP")
        assertReviewKeeps("What is hardest at the moment?", "Mornings")
    }

    /// mm-t32.17, r13-17 (mm-t43.33): the same with "Yes" to step 1 and
    /// "Yes" to step 2 of the self-harm item, and "Done" on the
    /// not-right-now page.
    func testWeekOneAnswerStaysAfterSelfHarmYesYes() throws {
        try launchOnToday("review")
        openTheDueReview()
        fill("What is hardest at the moment?", "Mornings", bar: "Done")
        answer(Self.selfHarmQuestion, "Yes", bar: "Done")
        answer(Self.selfHarmStep2Question, "Yes", bar: "Done", verify: false)
        tapDoneOnThePage("This may not be right for you now")
        assertReviewKeeps("What is hardest at the moment?", "Mornings")
    }

    /// Taps Today's "Weekly review" line and waits for the review.
    func openTheDueReview(file: StaticString = #filePath, line: UInt = #line) {
        let reviewLine = app.buttons["Weekly review"].firstMatch
        XCTAssertTrue(reviewLine.waitForExistence(timeout: 8), "Today shows the \"Weekly review\" line", file: file, line: line)
        reviewLine.tap()
        assertScreen("Weekly review", file: file, line: line)
    }

    /// Taps "I'm getting worse" at the review.
    func tapGettingWorse(file: StaticString = #filePath, line: UInt = #line) {
        guard let worse = reveal(bar: "Done", { self.first(.button, "I'm getting worse", in: $0) }) else {
            XCTFail("the review shows \"I'm getting worse\"", file: file, line: line)
            return
        }
        tap(worse.frame)
    }

    /// Taps "Done" on the safeguarding page with `heading`, and waits for
    /// the review to show again.
    func tapDoneOnThePage(_ heading: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element(labelled: heading).waitForExistence(timeout: 8), "the page \"\(heading)\" shows", file: file, line: line)
        // The review's own "Done" stays in the hierarchy under the page, so
        // the page's "Done" is found inside the page.
        let page = app.scrollViews.containing(NSPredicate(format: "label == %@", heading)).firstMatch
        let done = page.buttons["Done"].firstMatch
        XCTAssertTrue(scrollTo(done), "the page shows \"Done\"", file: file, line: line)
        done.tap()
        XCTAssertTrue(element(labelled: heading).waitForNonExistence(timeout: 5), file: file, line: line)
        assertScreen("Weekly review", file: file, line: line)
    }

    /// Leaves the review with no "Done", and opens it again from Today's
    /// line: the field `question` still holds `answer`.
    func assertReviewKeeps(_ question: String, _ answer: String, file: StaticString = #filePath, line: UInt = #line) {
        goBack()
        assertScreen("Today", file: file, line: line)
        openTheDueReview(file: file, line: line)
        let kept = reveal(bar: "Done", field(question))
        XCTAssertEqual(kept?.value, answer, "the review keeps the answer under \"\(question)\"", file: file, line: line)
    }

}
