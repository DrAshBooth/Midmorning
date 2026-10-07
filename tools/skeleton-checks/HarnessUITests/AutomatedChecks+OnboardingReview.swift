import XCTest
import UIKit

/// Rulings r13-19 and r16-01 (mm-t43.32 and mm-t43.33, epic mm-t45): the
/// navigation, text and flow checks of the device-check beads mm-t14.28
/// (onboarding and safeguarding), mm-t21.24 (programme) and mm-t32.17
/// (weekly review), as UI tests. Each test names its device-check bead and
/// the item it replaces. The seeded stores whose names begin with "or-"
/// are in `seeder/Sources/Seeder/OnboardingReviewScenarios.swift`. The
/// call tests turn on the app's Debug-only call record
/// (`MIDMORNING_CALL_RECORD=1` in the launch environment; the app writes
/// each call to `tmp/CallRecord` in its container): see "The call record"
/// below.
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
        let identifier: String
        let label: String
        let value: String?
        let placeholder: String?
        let frame: CGRect
        let isSelected: Bool
        let isEnabled: Bool
    }

    /// Every element on the screen (or under `element`), in one snapshot.
    /// A snapshot that fails three times fails the test: an empty list
    /// would let a check that something does not show pass with no look.
    func look(_ element: XCUIElement? = nil, file: StaticString = #filePath, line: UInt = #line) -> [Seen] {
        var snapshot: XCUIElementSnapshot?
        var failure: Error?
        for attempt in 0..<3 {
            if attempt > 0 { usleep(500_000) }
            do {
                snapshot = try (element ?? app).snapshot()
                break
            } catch {
                failure = error
            }
        }
        guard let root = snapshot else {
            XCTFail("a snapshot of the screen failed: \(failure.map { "\($0)" } ?? "no snapshot")", file: file, line: line)
            return []
        }
        var all: [Seen] = []
        func walk(_ snapshot: XCUIElementSnapshot) {
            all.append(Seen(type: snapshot.elementType, identifier: snapshot.identifier, label: snapshot.label,
                            value: snapshot.value as? String, placeholder: snapshot.placeholderValue, frame: snapshot.frame,
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

    /// Fills onboarding screen 2 with answers that exclude nothing (age 30,
    /// 170 cm, 65 kg, and "No" to the three questions), each answer found
    /// by its own question and checked, then taps "Continue" and waits for
    /// screen 3. The other groups' onboarding walks use this, because a
    /// "first open No" search can answer one question twice and leave
    /// another unanswered, so that screen 2 stays.
    func completeScreen2(file: StaticString = #filePath, line: UInt = #line) {
        fill("How old are you?", "30", file: file, line: line)
        fill("Height in centimetres", "170", file: file, line: line)
        fill("Weight in kilograms", "65", file: file, line: line)
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] {
            answer(question, "No", file: file, line: line)
        }
        tapConfirm(file: file, line: line)
        assertScreen("Your start", file: file, line: line)
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
    /// under the week line. The row with "Now" has the label "Getting started,
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
        XCTAssertTrue(seen.contains { $0.label == "Getting started, Now" }, "the row with \"Now\" has the label \"Getting started, Now\"")
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
    ///
    /// The "review" store is on the day stage 2 opens. Its entries have
    /// times from eight record days ago to now, but the seeder writes each
    /// one with a save moment (`createdAt`) about one hour before the
    /// seeding. The programme counts a recorded day from the moment of its
    /// first save (programme spec, "Stage 2 opens after five recorded
    /// days"; `nthDistinctDayEntry` sorts by `savedAt`), so stage 2 opens
    /// at the fifth save, on the current record day.
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

    // MARK: The support items inline and in the sheet

    /// The inline items under the self-harm support line, in order, with
    /// Samaritans first (safeguarding spec, "The self-harm item").
    static let inlineOrder = ["Samaritans", "Beat helpline", "Beat webchat", "Lifeline, Northern Ireland", "NHS 111", "999", "Talk to your GP"]
    static let supportHeaders: Set<String> = ["Samaritans", "Beat helpline", "Lifeline, Northern Ireland", "NHS 111", "999", "Talk to your GP"]
    static let supportNumbers = ["116 123", "0808 164 0123", "0808 801 0677", "0808 801 0432", "0808 801 0433", "0808 801 0434", "0808 808 8000", "111", "999"]
    static let recentsWarning = "This call will show in your phone's Recents."
    static let copiedLine = "Copied. It clears in a minute."

    /// The row of one number: one element that reads "<label>, <number>".
    func numberRow(_ number: String, in seen: [Seen]) -> Seen? {
        seen.first { $0.type == .staticText && $0.label.hasSuffix(", " + number) }
    }

    /// The control `label` ("Call", "Copy number" or "Copied") in the same
    /// row as `row`, to its right.
    func control(_ label: String, besideRow row: Seen, in seen: [Seen]) -> Seen? {
        seen.first { $0.type == .button && $0.label == label && $0.frame.midY >= row.frame.minY && $0.frame.midY <= row.frame.maxY && $0.frame.minX >= row.frame.maxX - 1 }
    }

    // MARK: The call record

    /// The simulator has no app for a `tel://` URL, so a call cannot start
    /// or show there. A Debug build of the app writes each call that it
    /// asks iOS to start to `tmp/CallRecord` in its container, when the
    /// launch environment holds this key (`CallRecorder` in the App target;
    /// `SupportCallSourceTests` proves that `NumberRow.startCall` is the
    /// app's only route to a call, and that a Release build has no record).
    static let callRecordKey = "MIDMORNING_CALL_RECORD"

    var callRecordFile: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["APP_DATA"] ?? "/dev/null").appendingPathComponent("tmp/CallRecord")
    }

    /// Turns on the call record for each launch of this test, and removes
    /// the record of an earlier test. Call it before the first launch.
    func turnOnTheCallRecord() {
        app.launchEnvironment[Self.callRecordKey] = "1"
        try? FileManager.default.removeItem(at: callRecordFile)
    }

    /// The URL of each call that the app asked iOS to start since
    /// `turnOnTheCallRecord`, in order. No file means no call. Each test
    /// that reads the record also shows, with "Call" on the warning, that
    /// the record gets a call in that run, so a check for no call can fail.
    func recordedCalls(file: StaticString = #filePath, line: UInt = #line) -> [String] {
        guard app.launchEnvironment[Self.callRecordKey] == "1" else {
            XCTFail("the test turns on the call record before its first launch", file: file, line: line)
            return []
        }
        guard let text = try? String(contentsOf: callRecordFile, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").map(String.init)
    }

    /// The `tel://` URL that `NumberRow.startCall` makes for `number`.
    static func callURL(_ number: String) -> String {
        "tel://" + number.filter(\.isNumber)
    }

    /// Taps "Call" beside `number` and returns the Recents warning, which
    /// shows as an alert with "Call" and "Cancel".
    func openTheRecentsWarning(beside number: String, bar: String?, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement? {
        guard let row = reveal(bar: bar, { self.numberRow(number, in: $0) }),
              let call = control("Call", besideRow: row, in: look()) else {
            XCTFail("\(number) shows with \"Call\"", file: file, line: line)
            return nil
        }
        tap(call.frame)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "\"Call\" beside \(number) shows the Recents warning first", file: file, line: line)
        XCTAssertTrue(alert.staticTexts[Self.recentsWarning].exists, "the warning reads \"\(Self.recentsWarning)\"", file: file, line: line)
        XCTAssertTrue(alert.buttons["Call"].exists, "the warning shows \"Call\"", file: file, line: line)
        XCTAssertTrue(alert.buttons["Cancel"].exists, "the warning shows \"Cancel\"", file: file, line: line)
        return alert
    }

    /// "Call" beside `number`, then "Call" on the Recents warning: the app
    /// asks iOS to start the call to `number`, and to nothing else.
    func callAndConfirm(_ number: String, bar: String?, file: StaticString = #filePath, line: UInt = #line) {
        let before = recordedCalls(file: file, line: line)
        guard let alert = openTheRecentsWarning(beside: number, bar: bar, file: file, line: line) else { return }
        XCTAssertEqual(recordedCalls(file: file, line: line), before, "\"Call\" beside \(number) starts no call before the warning", file: file, line: line)
        alert.buttons["Call"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "\"Call\" closes the warning", file: file, line: line)
        sleep(1)
        XCTAssertEqual(recordedCalls(file: file, line: line), before + [Self.callURL(number)], "\"Call\" on the warning starts the call to \(number)", file: file, line: line)
    }

    /// "Call" beside 116 123 shows the Recents warning with "Call" and
    /// "Cancel". "Cancel" closes it, the screen `screen` returns, and the
    /// app starts no call: the call record stays empty. Then, as the
    /// positive control, "Call" beside 116 123 and "Call" on the warning
    /// write the call to 116 123, so the record works in this run.
    func callSamaritansCancelThenCall(bar: String?, screen: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(recordedCalls(file: file, line: line), [], "no call before the test", file: file, line: line)
        guard let alert = openTheRecentsWarning(beside: "116 123", bar: bar, file: file, line: line) else { return }
        XCTAssertEqual(recordedCalls(file: file, line: line), [], "\"Call\" beside 116 123 starts no call before the warning", file: file, line: line)
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "\"Cancel\" closes the warning", file: file, line: line)
        assertScreen(screen, file: file, line: line)
        sleep(1)
        XCTAssertEqual(recordedCalls(file: file, line: line), [], "\"Cancel\" starts no call", file: file, line: line)
        callAndConfirm("116 123", bar: bar, file: file, line: line)
        assertScreen(screen, file: file, line: line)
    }

    /// mm-t14.29: after "Yes" and then "No" to the self-harm item, the
    /// support line shows, and under it every item of the support sheet
    /// inline, with Samaritans first. Each number shows "Call" and "Copy
    /// number". "Call" beside 116 123 shows the Recents warning, and
    /// "Cancel" starts no call (`callSamaritansCancelThenCall`). The
    /// confirming control `bar` stays active.
    func assertInlineSupportAfterYesThenNo(bar: String, screen: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(reveal(bar: bar, { self.first(.staticText, Self.supportLine, in: $0) }), "the support line shows", file: file, line: line)
        callSamaritansCancelThenCall(bar: bar, screen: screen, file: file, line: line)
        // Bring the support line near the top, then walk down the items.
        _ = reveal(bar: bar) { self.first(.staticText, Self.supportLine, in: $0) }
        var order: [String] = []
        var numbers: [String: Bool] = [:]
        for _ in 0..<16 {
            let seen = look()
            let bounds = listBounds(seen, bar: bar)
            let lineBottom = first(.staticText, Self.supportLine, in: seen)?.frame.maxY ?? -.infinity
            let items = seen.filter { item in
                item.frame.minY > lineBottom && (
                    (item.type == .staticText && item.frame.minX < 24 && Self.supportHeaders.contains(item.label))
                    || (item.type == .button && item.label == "Beat webchat"))
            }.sorted { $0.frame.minY < $1.frame.minY }
            for item in items where !order.contains(item.label) { order.append(item.label) }
            for number in Self.supportNumbers {
                guard let row = numberRow(number, in: seen), row.frame.minY > lineBottom else { continue }
                numbers[number] = control("Call", besideRow: row, in: seen) != nil && control("Copy number", besideRow: row, in: seen) != nil
            }
            if order.contains("Talk to your GP"), numbers.count == Self.supportNumbers.count { break }
            dragList(by: (bounds.bottom - bounds.top) * 0.7, bounds: bounds)
        }
        XCTAssertEqual(order, Self.inlineOrder, "the support sheet's items show inline under the line, with Samaritans first", file: file, line: line)
        for number in Self.supportNumbers {
            XCTAssertEqual(numbers[number], true, "\(number) shows \"Call\" and \"Copy number\"", file: file, line: line)
        }
        XCTAssertEqual(widest(bar, in: look())?.isEnabled, true, "\"\(bar)\" stays active", file: file, line: line)
    }

    // MARK: mm-t14.29 (comment of 15:19 on mm-t14.28)

    /// mm-t14.28, mm-t14.29 (mm-t43.32), on onboarding screen 2: "Yes" and
    /// then "No" to the self-harm item show the support line and the inline
    /// support items, Samaritans first, with "Call" and "Copy number" on
    /// each number. "Call" shows the Recents warning, and "Cancel" starts
    /// no call (the call record stays empty; "Call" on the warning then
    /// writes the call to 116 123). "Continue" stays active. (The system
    /// call flow stays a device check.)
    func testInlineSupportAfterYesThenNoOnScreen2() throws {
        turnOnTheCallRecord()
        try openScreen2()
        answer(Self.selfHarmQuestion, "Yes")
        answer(Self.selfHarmStep2Question, "No")
        assertInlineSupportAfterYesThenNo(bar: "Continue", screen: "A few questions first")
    }

    /// mm-t14.28, mm-t14.29 (mm-t43.32): the same at the weekly review,
    /// where "Done" stays active.
    func testInlineSupportAfterYesThenNoAtTheReview() throws {
        turnOnTheCallRecord()
        try launchOnToday("review")
        openTheDueReview()
        answer(Self.selfHarmQuestion, "Yes", bar: "Done")
        answer(Self.selfHarmStep2Question, "No", bar: "Done")
        assertInlineSupportAfterYesThenNo(bar: "Done", screen: "Weekly review")
    }

    /// mm-t14.28, mm-t14.29 (mm-t43.32): the same at the restart re-screen.
    func testInlineSupportAfterYesThenNoAtTheRescreen() throws {
        turnOnTheCallRecord()
        try openRescreen()
        answer(Self.selfHarmQuestion, "Yes")
        answer(Self.selfHarmStep2Question, "No")
        assertInlineSupportAfterYesThenNo(bar: "Continue", screen: "A few questions first")
    }

    /// mm-t14.28, item 7 of the comment of 06:10 (mm-t14.24; safeguarding
    /// spec, "The support sheet"), in the sheet from Today. "Cancel the
    /// call": "Call" beside 116 123 shows the Recents warning with "Call"
    /// and "Cancel"; "Cancel" returns to the sheet, and the app starts no
    /// call. "Call Samaritans": "Call" on the warning starts the call to
    /// 116 123. "Call Beat in Scotland": "Call" beside 0808 801 0432 and
    /// "Call" on the warning start the call to 0808 801 0432. A test can
    /// see the app's call only in the call record; the system call flow
    /// that follows stays a device check.
    func testCallAndCancelInTheSupportSheet() throws {
        turnOnTheCallRecord()
        try launchOnToday("week1")
        getSupport(on: "Today").tap()
        assertScreen("Get support")
        callSamaritansCancelThenCall(bar: nil, screen: "Get support")
        callAndConfirm("0808 801 0432", bar: nil)
        assertScreen("Get support")
        XCTAssertEqual(recordedCalls(), [Self.callURL("116 123"), Self.callURL("0808 801 0432")], "the app started only the two confirmed calls")
    }

    /// mm-t14.28, item 6 of the comment of 06:10 (mm-t14.19; safeguarding
    /// spec, "The exclusion page", scenario "Call Beat"): on the exclusion
    /// page, "Call" beside England 0808 801 0677 shows the Recents warning,
    /// and "Call" on the warning starts the call to 0808 801 0677. The
    /// system call flow that follows stays a device check.
    func testCallBeatOnTheExclusionPage() throws {
        turnOnTheCallRecord()
        try openScreen2()
        fill("How old are you?", "17")
        fill("Height in centimetres", "170")
        fill("Weight in kilograms", "65")
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] { answer(question, "No") }
        tapConfirm()
        XCTAssertTrue(element(labelled: "Not right now").waitForExistence(timeout: 8), "the exclusion page shows")
        callAndConfirm("0808 801 0677", bar: nil)
        XCTAssertTrue(element(labelled: "Not right now").exists, "the exclusion page stays after the call")
        XCTAssertEqual(recordedCalls(), [Self.callURL("0808 801 0677")], "the app started only the confirmed call")
    }

    // MARK: mm-t14.36 (comment of 15:46 on mm-t14.28)

    /// mm-t14.28, mm-t14.36 (mm-t43.32): in the support sheet, "Copy
    /// number" beside 116 123 reads "Copied" for about two seconds (the
    /// spec: "for two seconds") and then reads "Copy number" again.
    /// "Copied. It clears in a minute." shows under that number, once, and
    /// stays until the sheet closes: the test looks at it every 10 seconds
    /// until 65 seconds after the tap, past the 60-second expiry of the
    /// pasteboard, and then closes the sheet. (The pasteboard itself and
    /// the largest text size of mm-t14.41 stay device checks.)
    func testCopyNumberShowsCopiedForAboutTwoSeconds() throws {
        try launchOnToday("week1")
        getSupport(on: "Today").tap()
        XCTAssertTrue(app.navigationBars["Get support"].waitForExistence(timeout: 8), "the support sheet shows")
        guard let row = reveal(extra: 80, { self.numberRow("116 123", in: $0) }),
              let copy = control("Copy number", besideRow: row, in: look()) else {
            XCTFail("116 123 shows with \"Copy number\"")
            return
        }
        // A snapshot shows the screen at one moment between the time just
        // before it and the time just after it, so the test keeps both
        // times. Each time is from just before the tap. The tap returns
        // after the app is idle again, so the app changed the label before
        // `tapped`. The list settles first, so that the tap does not wait
        // long for an idle app before it touches the screen.
        usleep(1_000_000)
        let start = Date()
        func elapsed() -> TimeInterval { Date().timeIntervalSince(start) }
        tap(copy.frame)
        let tapped = elapsed()
        var copiedFirstAfter: TimeInterval?
        var copiedLastBefore: TimeInterval?
        var backAfter: TimeInterval?
        while elapsed() < 6 {
            let before = elapsed()
            let seen = look()
            let after = elapsed()
            if control("Copied", besideRow: row, in: seen) != nil {
                if copiedFirstAfter == nil { copiedFirstAfter = after }
                copiedLastBefore = before
            } else if copiedLastBefore != nil, control("Copy number", besideRow: row, in: seen) != nil {
                backAfter = after
                break
            }
        }
        XCTAssertNotNil(copiedFirstAfter, "the control reads \"Copied\"")
        XCTAssertLessThan(copiedFirstAfter ?? 99, 1.2, "the control reads \"Copied\" at once")
        XCTAssertNotNil(backAfter, "the control reads \"Copy number\" again")
        // "Copied" showed from a moment before `tapped` until a moment
        // after `copiedLastBefore`, and "Copy number" showed again at a
        // moment before `backAfter`. The tap itself takes about 0.4 s and
        // the label changes at a moment inside it, so the two bounds are
        // about 0.5 s apart: on 7 October 2026 they were 1.86 s to 2.42 s
        // and 1.78 s to 2.28 s. The limits 1.7 s and 2.6 s leave room for a
        // slower tap. A label that shows for less than 1.7 s, or for more
        // than 2.6 s, always fails.
        let atLeast = (copiedLastBefore ?? 0) - tapped
        let atMost = backAfter ?? 99
        print("mm-t14.36: \"Copied\" showed for \(String(format: "%.2f", atLeast)) s to \(String(format: "%.2f", atMost)) s (tap \(String(format: "%.2f", tapped)) s)")
        XCTAssertGreaterThanOrEqual(atLeast, 1.7, "\"Copied\" shows for about two seconds, not less")
        XCTAssertLessThanOrEqual(atMost, 2.6, "\"Copied\" shows for about two seconds, not more")
        // The confirmation line, under that number, until the sheet closes:
        // once after the label changes back, then every 10 seconds until 65
        // seconds after the tap, past the 60-second pasteboard expiry.
        let times: [TimeInterval?] = [nil] + stride(from: 15.0, through: 65.0, by: 10.0).map { $0 }
        for time in times {
            let check = time.map { "\(Int($0)) seconds after the tap" } ?? "after the label changes back"
            if let time, time > elapsed() { usleep(UInt32((time - elapsed()) * 1_000_000)) }
            let seen = look()
            let lines = seen.filter { $0.type == .staticText && $0.label == Self.copiedLine }
            XCTAssertEqual(lines.count, 1, "\"\(Self.copiedLine)\" shows once, \(check)")
            if let shown = lines.first, let number = numberRow("116 123", in: seen) {
                XCTAssertGreaterThanOrEqual(shown.frame.minY, number.frame.maxY - 1, "the line shows under the number, \(check)")
                XCTAssertLessThan(shown.frame.minY - number.frame.maxY, 40, "the line shows right under the number, \(check)")
                XCTAssertLessThan(shown.frame.minY, first(.staticText, "Any time, about anything.", in: seen)?.frame.minY ?? .infinity, "the line shows in the row of 116 123, \(check)")
            }
        }
        XCTAssertGreaterThanOrEqual(elapsed(), 65, "the last look is 65 seconds after the tap or later")
        app.navigationBars["Get support"].buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Get support"].waitForNonExistence(timeout: 5))
        getSupport(on: "Today").tap()
        XCTAssertTrue(app.navigationBars["Get support"].waitForExistence(timeout: 8))
        XCTAssertNotNil(reveal(extra: 80, { self.numberRow("116 123", in: $0) }))
        XCTAssertFalse(look().contains { $0.label == Self.copiedLine }, "after the sheet closes, the line is gone")
    }

    // MARK: mm-t32.24 (comment of 15:27 on mm-t32.17)

    /// mm-t32.17, mm-t32.24 (mm-t43.32), at the restart re-screen: step 1
    /// "Yes", step 2 "Yes", then step 1 "No" and "Yes" again: step 2 shows
    /// again with no answer. The same with step 2 "No".
    func testRescreenStepTwoLosesItsAnswerWhenStepOneChanges() throws {
        try openRescreen()
        for step2 in ["Yes", "No"] {
            answer(Self.selfHarmQuestion, "Yes")
            answer(Self.selfHarmStep2Question, step2)
            answer(Self.selfHarmQuestion, "No")
            XCTAssertNil(first(.staticText, Self.selfHarmStep2Question, in: look()), "step 2 hides after step 1 \"No\"")
            answer(Self.selfHarmQuestion, "Yes")
            XCTAssertNotNil(reveal(extra: 110, bar: "Continue", { self.first(.staticText, Self.selfHarmStep2Question, in: $0) }), "step 2 shows again")
            let seen = look()
            let rows = ["No", "Yes"].compactMap { answerRow($0, under: Self.selfHarmStep2Question, in: seen) }
            XCTAssertEqual(rows.count, 2, "step 2 shows \"No\" and \"Yes\"")
            XCTAssertFalse(rows.contains { $0.isSelected }, "after step 2 \"\(step2)\", step 2 shows again with no answer")
        }
    }

    // MARK: mm-t32.28 (comment of 08:19 on mm-t32.17)

    /// The rows under `question`, top to bottom, read `answers`; the
    /// question shows once, and no row reads the question.
    func assertRowsReadTheirAnswers(_ question: String, _ answers: [String], bar: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(reveal(extra: CGFloat(answers.count) * 56, bar: bar, { self.first(.staticText, question, in: $0) }), "the screen shows \"\(question)\"", file: file, line: line)
        let seen = look()
        guard let header = first(.staticText, question, in: seen) else { return }
        let rows = seen.filter { $0.type == .button && $0.frame.minY >= header.frame.maxY - 1 }
            .sorted { $0.frame.minY < $1.frame.minY }
            .prefix(answers.count)
            .map(\.label)
        XCTAssertEqual(Array(rows), answers, "each row under \"\(question)\" is one element labelled with its own answer", file: file, line: line)
        XCTAssertEqual(seen.filter { $0.label == question }.count, 1, "\"\(question)\" shows once", file: file, line: line)
        XCTAssertFalse(seen.contains { $0.type != .staticText && $0.label.contains(question) }, "no row reads \"\(question)\"", file: file, line: line)
    }

    /// mm-t32.17, mm-t32.28: at the weekly review, each row of the
    /// self-harm item is an element labelled with its own answer: "No",
    /// "Yes" and "I'd rather not say" for step 1, then "No" and "Yes" for
    /// step 2. Each question shows once, and no row reads the question.
    /// (The VoiceOver walk stays a device check.)
    func testEachSelfHarmRowAtTheReviewReadsItsAnswer() throws {
        try launchOnToday("review")
        openTheDueReview()
        assertRowsReadTheirAnswers(Self.selfHarmQuestion, ["No", "Yes", "I'd rather not say"], bar: "Done")
        answer(Self.selfHarmQuestion, "Yes", bar: "Done")
        assertRowsReadTheirAnswers(Self.selfHarmStep2Question, ["No", "Yes"], bar: "Done")
    }

    /// mm-t32.17, mm-t32.28: on onboarding screen 2 and at the restart
    /// re-screen, each row of the treatment, pregnancy and self-harm
    /// questions is an element labelled with its own answer, and each
    /// question shows once. (The VoiceOver walk stays a device check.)
    func testEachScreeningRowReadsItsAnswer() throws {
        for opening in ["screen 2", "re-screen"] {
            if opening == "screen 2" { try openScreen2() } else { try openRescreen() }
            assertRowsReadTheirAnswers(Self.treatmentQuestion, ["No", "Yes, and they are happy for me to use this", "Yes"], bar: "Continue")
            assertRowsReadTheirAnswers(Self.pregnancyQuestion, ["No", "Yes", "Doesn't apply to me"], bar: "Continue")
            assertRowsReadTheirAnswers(Self.selfHarmQuestion, ["No", "Yes", "I'd rather not say"], bar: "Continue")
            answer(Self.selfHarmQuestion, "Yes")
            assertRowsReadTheirAnswers(Self.selfHarmStep2Question, ["No", "Yes"], bar: "Continue")
        }
    }

    // MARK: mm-t32.19 with a pinned note (comment of 15:27 on mm-t32.17)

    /// mm-t32.17, mm-t32.19 (mm-t43.32): with the pinned note "Eat
    /// breakfast" of the review of week 1, the review of week 2 gets an
    /// answer under "What made things harder?", then "I'm getting worse"
    /// and "Done" on the GP page. Back on Today, "Weekly review" and the
    /// pinned note still show, and the review opens again with the answer.
    func testGettingWorseKeepsThePinnedNoteAndTheReviewDue() throws {
        try launchOnToday("or-pinned")
        XCTAssertTrue(element(labelled: "Eat breakfast").waitForExistence(timeout: 5), "Today shows the pinned note of the review of week 1")
        openTheDueReview()
        fill("What made things harder?", "Late shifts", bar: "Done")
        tapGettingWorse()
        tapDoneOnThePage("It might help to see your GP")
        assertTodayKeepsTheReviewAndTheNote("Eat breakfast", question: "What made things harder?", answer: "Late shifts")
    }

    /// mm-t32.17, mm-t32.19 (mm-t43.32): the same with "Yes" and then
    /// "Yes" to the self-harm item, and "Done" on the not-right-now page.
    func testSelfHarmYesYesKeepsThePinnedNoteAndTheReviewDue() throws {
        try launchOnToday("or-pinned")
        XCTAssertTrue(element(labelled: "Eat breakfast").waitForExistence(timeout: 5), "Today shows the pinned note of the review of week 1")
        openTheDueReview()
        fill("What made things harder?", "Late shifts", bar: "Done")
        answer(Self.selfHarmQuestion, "Yes", bar: "Done")
        answer(Self.selfHarmStep2Question, "Yes", bar: "Done", verify: false)
        tapDoneOnThePage("This may not be right for you now")
        assertTodayKeepsTheReviewAndTheNote("Eat breakfast", question: "What made things harder?", answer: "Late shifts")
    }

    /// Leaves the review with no "Done": Today still shows the "Weekly
    /// review" line and the pinned note `note`, and the review opens again
    /// with `answer` under `question`.
    func assertTodayKeepsTheReviewAndTheNote(_ note: String, question: String, answer: String, file: StaticString = #filePath, line: UInt = #line) {
        goBack()
        assertScreen("Today", file: file, line: line)
        XCTAssertTrue(app.buttons["Weekly review"].firstMatch.waitForExistence(timeout: 5), "Today still shows \"Weekly review\"", file: file, line: line)
        XCTAssertTrue(element(labelled: note).exists, "Today still shows the pinned note \"\(note)\"", file: file, line: line)
        openTheDueReview(file: file, line: line)
        XCTAssertEqual(reveal(bar: "Done", field(question))?.value, answer, "the review keeps the answer", file: file, line: line)
    }

    // MARK: mm-t32.21 (comment of 15:27 on mm-t32.17)

    /// mm-t32.17, mm-t32.21 (mm-t43.32): with 2, 3, 4 and 5 starred entries
    /// in weeks 2 to 5, the app freezes those counts, and the review of
    /// week 5 opens with the GP suggestion page. After "Done" on the page
    /// and a return to Today, the review opens again from Today with no
    /// page. After "Done" on the review, it opens from the "Reviews" list
    /// with no page. (The open from the reminder needs a real reminder and
    /// stays a device check.)
    func testTheDeteriorationPageShowsOnce() throws {
        let heading = "It might help to see your GP"
        try launchOnToday("or-deterioration")
        openTheDueReview()
        XCTAssertTrue(element(labelled: heading).waitForExistence(timeout: 8), "the review of week 5 opens with the GP suggestion page")
        XCTAssertTrue(text("Your starred entries have gone up each week lately.").exists, "the page gives the deterioration reason")
        tapDoneOnThePage(heading)
        XCTAssertNotNil(reveal(bar: "Done", { self.first(.staticText, "Starred entries: 5 this week, 4 last week.", in: $0) }), "the review reads the frozen counts of weeks 4 and 5")
        goBack()
        assertScreen("Today")
        openTheDueReview()
        XCTAssertFalse(element(labelled: heading).waitForExistence(timeout: 3), "a new open from Today shows no GP suggestion page")
        tapConfirm("Done")
        assertScreen("Today")
        XCTAssertFalse(app.buttons["Weekly review"].exists, "\"Done\" finishes the review")
        tapToolbar("Reviews")
        assertScreen("Reviews")
        let row = element(labelBeginningWith: "Week 5, ")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "the \"Reviews\" list shows the review of week 5")
        XCTAssertTrue(row.label.hasSuffix("Starred entries: 5."), "the row shows the frozen count 5: \(row.label)")
        row.tap()
        assertScreen("Weekly review")
        XCTAssertFalse(element(labelled: heading).waitForExistence(timeout: 3), "an open from the \"Reviews\" list shows no GP suggestion page")
    }

    // MARK: mm-t32.22 (comment of 15:27 on mm-t32.17)

    /// The date range of a "Reviews" row for the record days `first` to
    /// `last` days from the current record day, as the app writes it
    /// (`ReviewText.weekDateRangeText`).
    func weekRangeText(first firstOffset: Int, last lastOffset: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        let recordDay = calendar.component(.hour, from: now) < 4 ? calendar.date(byAdding: .day, value: -1, to: now)! : now
        let today = calendar.startOfDay(for: recordDay)
        let start = calendar.date(byAdding: .day, value: firstOffset, to: today)!
        let end = calendar.date(byAdding: .day, value: lastOffset, to: today)!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = calendar.component(.month, from: start) == calendar.component(.month, from: end) ? "d" : "d MMMM"
        let startText = formatter.string(from: start)
        formatter.dateFormat = "d MMMM"
        return "\(startText)–\(formatter.string(from: end))"
    }

    /// mm-t32.17, mm-t32.22 (mm-t43.32): with the reviews of weeks 1 and 2
    /// finished, "Start week 1 again" and "Today". The "Reviews" list then
    /// shows both first-run rows, "Week 2" above "Week 1", each with its
    /// own dates. A tap on each row opens that review with its saved
    /// answers. A tap on the first-run pinned note opens its review.
    func testTwoFirstRunReviewsAfterARestart() throws {
        try launchOnToday("or-tworuns")
        XCTAssertTrue(element(labelled: "Plan lunch").waitForExistence(timeout: 5), "Today shows the pinned note of the review of week 2")
        tapToolbar("Programme")
        assertScreen("Programme")
        let restart = app.buttons["Start week 1 again"].firstMatch
        XCTAssertTrue(scrollTo(restart))
        restart.tap()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForExistence(timeout: 8), "the start-day choice shows, with no re-screen")
        app.collectionViews.buttons["Today"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Start week 1 again"].waitForNonExistence(timeout: 5))
        goBack()
        assertScreen("Today")
        tapToolbar("Reviews")
        assertScreen("Reviews")
        let week2 = element(labelBeginningWith: "Week 2, \(weekRangeText(first: -8, last: -2)).")
        let week1 = element(labelBeginningWith: "Week 1, \(weekRangeText(first: -15, last: -9)).")
        XCTAssertTrue(week2.waitForExistence(timeout: 5), "the list shows the first-run row of week 2 with its own dates")
        XCTAssertTrue(week1.exists, "the list shows the first-run row of week 1 with its own dates")
        XCTAssertLessThan(week2.frame.minY, week1.frame.minY, "the newest review shows first")
        week1.tap()
        assertScreen("Weekly review")
        XCTAssertEqual(reveal(bar: "Done", field("What is hardest at the moment?"))?.value, "Evenings", "the review of week 1 opens with its week-1 answers")
        XCTAssertEqual(reveal(bar: "Done", field("What made things harder?"))?.value, "Week one harder", "the review of week 1 opens with its own answers")
        goBack()
        assertScreen("Reviews")
        week2.tap()
        assertScreen("Weekly review")
        XCTAssertEqual(reveal(bar: "Done", field("What made things harder?"))?.value, "Week two harder", "the review of week 2 opens with its own answers")
        XCTAssertFalse(app.textFields["What is hardest at the moment?"].exists, "the review of week 2 asks no week-1 question")
        goBack()
        assertScreen("Reviews")
        goBack()
        assertScreen("Today")
        let note = element(labelled: "Plan lunch")
        XCTAssertTrue(note.waitForExistence(timeout: 5), "Today shows the first-run pinned note")
        note.tap()
        assertScreen("Weekly review")
        XCTAssertEqual(reveal(bar: "Done", field("What made things harder?"))?.value, "Week two harder", "the pinned note opens its own review")
    }

    // MARK: mm-t32.23 (comment of 15:27 on mm-t32.17)

    /// mm-t32.17, mm-t32.23 (mm-t43.32): after a done weigh-in, the review
    /// of that week shows "Weigh-in: done on <weekday>.". After "I won't be
    /// weighing" in Settings, the same review shows no weigh-in line.
    func testNoWeighInLineAfterIWontBeWeighing() throws {
        let weighInLine: ([Seen]) -> Seen? = { $0.first { $0.type == .staticText && $0.label.hasPrefix("Weigh-in: done on ") } }
        try launchOnToday("or-weighin")
        openTheDueReview()
        XCTAssertNotNil(reveal(bar: "Done", weighInLine), "before the change, the review shows the weigh-in line")
        goBack()
        assertScreen("Today")
        tapToolbar("Settings")
        assertScreen("Settings")
        let picker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Weigh-in day")).firstMatch
        XCTAssertTrue(scrollTo(picker), "Settings shows \"Weigh-in day\"")
        picker.tap()
        let wontBeWeighing = app.buttons["I won't be weighing"].firstMatch
        XCTAssertTrue(wontBeWeighing.waitForExistence(timeout: 5), "\"Weigh-in day\" offers \"I won't be weighing\"")
        wontBeWeighing.tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(picker.staticTexts["I won't be weighing"].exists || picker.label.contains("I won't be weighing") || (picker.value as? String) == "I won't be weighing", "Settings shows \"I won't be weighing\"")
        goBack()
        assertScreen("Today")
        openTheDueReview()
        let summary = reveal(bar: "Done") { $0.first { $0.type == .staticText && $0.label.hasPrefix("Days with an entry:") } }
        XCTAssertNotNil(summary, "the review shows its summary")
        XCTAssertNil(weighInLine(look()), "after \"I won't be weighing\", the review shows no weigh-in line")
    }

    // MARK: mm-t21.28 (comment of 15:31 on mm-t21.24)

    /// mm-t21.24, mm-t21.28 (mm-t43.32): with stage 2 open and no plan,
    /// Today shows "Your plan isn't set yet. It takes about two minutes.".
    /// "Plan" on the stage 2 screen and "Save" set the weekday plan; back on
    /// Today, at once and with no restart, the line is gone. (The plan rows
    /// show from the next record day: regular-eating-plan spec, "Weekday
    /// and weekend templates", says that a change to a template MUST NOT
    /// change the current record day's plan.)
    func testPlanOnTheStage2ScreenRemovesThePlanCard() throws {
        try launchOnToday("or-plancard")
        let cardLine = text("Your plan isn't set yet. It takes about two minutes.")
        XCTAssertTrue(cardLine.waitForExistence(timeout: 8), "before the plan, Today shows the plan card")
        tapToolbar("Programme")
        assertScreen("Programme")
        element(labelBeginningWith: "Regular eating").tap()
        assertScreen("Regular eating")
        // The "Tools" group holds "Plan". The group is one accessibility
        // container, so the test taps the row's point on the screen.
        guard let plan = reveal({ self.first(.button, "Plan", in: $0) }) else {
            XCTFail("the stage 2 screen shows \"Plan\"")
            return
        }
        tap(plan.frame)
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForExistence(timeout: 8), "\"Plan\" opens the weekday plan")
        for slot in ["Breakfast", "Mid-morning", "Lunch", "Mid-afternoon", "Evening meal"] {
            let place = app.buttons[slot].firstMatch
            XCTAssertTrue(scrollTo(place), "the plan builder offers \"\(slot)\"")
            place.tap()
        }
        let save = app.buttons["Save"].firstMatch
        XCTAssertTrue(scrollTo(save), "the plan builder shows \"Save\"")
        save.tap()
        let saveAnyway = app.alerts.buttons["Save anyway"].firstMatch
        if saveAnyway.waitForExistence(timeout: 2) { saveAnyway.tap() }
        XCTAssertTrue(app.navigationBars["Weekday plan"].waitForNonExistence(timeout: 5), "\"Save\" closes the plan builder")
        assertScreen("Regular eating")
        goBack()
        assertScreen("Programme")
        goBack()
        assertScreen("Today")
        XCTAssertTrue(cardLine.waitForNonExistence(timeout: 5), "at once, Today shows no \"Your plan isn't set yet\"")
    }

    // MARK: mm-t14.30 (comment of 15:19 on mm-t14.28)

    /// What a tap can start: the Recents warning, Beat's page in the
    /// in-app browser, a "Copied" control, a "Copied. It clears in a
    /// minute." line, the new-entry screen, or a call (in the call record).
    struct Effects: Equatable, CustomStringConvertible {
        var warning = 0
        var browser = 0
        var copiedControls = 0
        var copiedLines = 0
        var newEntry = 0
        var calls = 0

        var description: String {
            "warning \(warning), browser \(browser), \"Copied\" \(copiedControls), copied line \(copiedLines), new entry \(newEntry), calls \(calls)"
        }

        static func - (lhs: Effects, rhs: Effects) -> Effects {
            Effects(warning: lhs.warning - rhs.warning, browser: lhs.browser - rhs.browser, copiedControls: lhs.copiedControls - rhs.copiedControls,
                    copiedLines: lhs.copiedLines - rhs.copiedLines, newEntry: lhs.newEntry - rhs.newEntry, calls: lhs.calls - rhs.calls)
        }
    }

    /// The effects on the screen now. A test that reads them turns on the
    /// call record first (`turnOnTheCallRecord`).
    func effects() -> Effects {
        let seen = look()
        return Effects(
            warning: seen.contains { $0.type == .alert } ? 1 : 0,
            // The in-app browser's view is not part of the snapshot, so a
            // query finds it.
            browser: app.otherElements["TopBrowserBar"].exists ? 1 : 0,
            copiedControls: seen.filter { $0.type == .button && $0.label == "Copied" }.count,
            copiedLines: seen.filter { $0.type == .staticText && $0.label == Self.copiedLine }.count,
            newEntry: seen.contains { $0.type == .switch && $0.label == "felt like a binge" } ? 1 : 0,
            calls: recordedCalls().count
        )
    }

    /// Taps the centre of `frame` and asserts that only `expected` follows:
    /// each other effect stays as it was. It waits up to 4 seconds for the
    /// expected effect (the browser takes a moment to show), and then looks
    /// once more, so that a second action that comes late also shows.
    func assertTapRunsOnly(_ expected: Effects, at frame: CGRect, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let before = effects()
        tap(frame)
        let start = Date()
        var change = Effects()
        var reached = false
        repeat {
            sleep(1)
            change = effects() - before
            reached = change == expected
        } while !reached && Date().timeIntervalSince(start) < 4
        XCTAssertEqual(change, expected, "a tap on \(what) runs only its own action", file: file, line: line)
        guard reached else { return }
        sleep(1)
        var late = effects() - before
        // A "Copied" control reads "Copy" again after two seconds; only the
        // line under it stays.
        if expected.copiedControls > 0, late.copiedControls == 0 { late.copiedControls = expected.copiedControls }
        XCTAssertEqual(late, expected, "a tap on \(what) starts no second action later", file: file, line: line)
    }

    /// The point of the text of a borderless control: its leading part,
    /// where the label is. A List row gives the control the full row as its
    /// frame, but only the label takes the tap.
    func textPoint(of frame: CGRect) -> CGRect {
        CGRect(x: frame.minX + 24, y: frame.minY, width: 8, height: frame.height)
    }

    /// In the support items (the sheet or inline), each control alone runs
    /// only its own action: "Call", "Copy number", "Beat webchat" and the GP
    /// paragraph's "Copy". A tap on the text of a number row, away from its
    /// controls, runs nothing. No tap starts a call; at the end, "Call" and
    /// "Call" on the warning write the one call, so the call record works
    /// in this run.
    func checkEachSupportControlAlone(bar: String?, file: StaticString = #filePath, line: UInt = #line) {
        // "Call" beside the England number.
        guard let row = reveal(extra: 60, bar: bar, { self.numberRow("0808 801 0677", in: $0) }) else {
            XCTFail("the support items show 0808 801 0677", file: file, line: line)
            return
        }
        let seen = look()
        guard let call = control("Call", besideRow: row, in: seen), let copy = control("Copy number", besideRow: row, in: seen) else {
            XCTFail("0808 801 0677 shows \"Call\" and \"Copy number\"", file: file, line: line)
            return
        }
        assertTapRunsOnly(Effects(warning: 1), at: call.frame, "\"Call\"", file: file, line: line)
        app.alerts.firstMatch.buttons["Cancel"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5), file: file, line: line)
        sleep(1)
        XCTAssertEqual(recordedCalls(file: file, line: line), [], "\"Cancel\" starts no call", file: file, line: line)
        // The text of the row, away from its controls.
        assertTapRunsOnly(Effects(), at: row.frame, "the text of the number row", file: file, line: line)
        // "Beat webchat".
        guard let webchat = reveal(bar: bar, { self.first(.button, "Beat webchat", in: $0) }) else {
            XCTFail("the support items show \"Beat webchat\"", file: file, line: line)
            return
        }
        assertTapRunsOnly(Effects(browser: 1), at: textPoint(of: webchat.frame), "\"Beat webchat\"", file: file, line: line)
        let browserClose = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(browserClose.waitForExistence(timeout: 5), "the browser shows \"Close\"", file: file, line: line)
        browserClose.tap()
        XCTAssertTrue(app.otherElements["TopBrowserBar"].waitForNonExistence(timeout: 5), file: file, line: line)
        // The GP paragraph's "Copy".
        guard let gpCopy = reveal(bar: bar, { self.first(.button, "Copy", in: $0) }) else {
            XCTFail("the support items show the GP paragraph's \"Copy\"", file: file, line: line)
            return
        }
        assertTapRunsOnly(Effects(copiedControls: 1, copiedLines: 1), at: textPoint(of: gpCopy.frame), "the GP paragraph's \"Copy\"", file: file, line: line)
        // The text above the GP paragraph, away from a control.
        if let compensation = look().first(where: { $0.type == .staticText && $0.label.hasPrefix("Some people make themselves sick") }) {
            assertTapRunsOnly(Effects(), at: compensation.frame, "the text of the GP row", file: file, line: line)
        } else {
            XCTFail("the GP item shows its first sentence", file: file, line: line)
        }
        // "Copy number" beside the England number, once the GP "Copied"
        // reads "Copy" again.
        sleep(2)
        guard let row2 = reveal(extra: 60, bar: bar, { self.numberRow("0808 801 0677", in: $0) }),
              let copy2 = control("Copy number", besideRow: row2, in: look()) else {
            XCTFail("0808 801 0677 shows \"Copy number\" again", file: file, line: line)
            return
        }
        _ = copy
        assertTapRunsOnly(Effects(copiedControls: 1, copiedLines: 1), at: copy2.frame, "\"Copy number\"", file: file, line: line)
        // The positive control: the call record gets a confirmed call.
        callAndConfirm("0808 801 0677", bar: bar, file: file, line: line)
        XCTAssertEqual(recordedCalls(file: file, line: line), [Self.callURL("0808 801 0677")], "only the confirmed call started", file: file, line: line)
    }

    /// mm-t14.28, mm-t14.30 (mm-t43.32), in the support sheet: "Call",
    /// "Copy number", "Beat webchat" and the GP paragraph's "Copy" each run
    /// only their own action, and a tap on the text of a row runs nothing.
    /// (The call itself and Safari's page stay device checks.)
    func testEachSupportSheetControlRunsOnlyItsOwnAction() throws {
        turnOnTheCallRecord()
        try launchOnToday("week1")
        getSupport(on: "Today").tap()
        XCTAssertTrue(app.navigationBars["Get support"].waitForExistence(timeout: 8), "the support sheet shows")
        checkEachSupportControlAlone(bar: nil)
    }

    /// mm-t14.28, mm-t14.30 (mm-t43.32): the same in the inline support on
    /// onboarding screen 2, after "Yes" and then "No" to the self-harm
    /// item.
    func testEachInlineSupportControlRunsOnlyItsOwnAction() throws {
        turnOnTheCallRecord()
        try openScreen2()
        answer(Self.selfHarmQuestion, "Yes")
        answer(Self.selfHarmStep2Question, "No")
        checkEachSupportControlAlone(bar: "Continue")
    }

    /// mm-t14.28, mm-t14.30 (mm-t43.32), a Today card: a tap on the card's
    /// title runs nothing; "Close" removes the card and opens nothing;
    /// "Read" opens the card screen, and the card does not come back.
    func testEachTodayCardControlRunsOnlyItsOwnAction() throws {
        try launchOnToday("or-secondday")
        let title = text("Why write it down")
        XCTAssertTrue(title.waitForExistence(timeout: 8), "Today shows the stage 1 card")
        title.tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Today"].exists, "a tap on the card's title opens nothing")
        XCTAssertTrue(title.exists, "a tap on the card's title keeps the card")
        let cell = app.cells.containing(NSPredicate(format: "label == %@", "Why write it down")).firstMatch
        cell.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(title.waitForNonExistence(timeout: 5), "\"Close\" removes the card")
        XCTAssertTrue(app.navigationBars["Today"].exists, "\"Close\" opens nothing")
        XCTAssertFalse(app.navigationBars["Why write it down"].exists, "\"Close\" does not open the card screen")

        try launchOnToday("or-secondday")
        XCTAssertTrue(title.waitForExistence(timeout: 8))
        app.cells.containing(NSPredicate(format: "label == %@", "Why write it down")).firstMatch.buttons["Read"].firstMatch.tap()
        assertScreen("Why write it down")
        goBack()
        assertScreen("Today")
        XCTAssertFalse(title.exists, "after \"Read\", the card does not come back")
    }

    /// mm-t14.28, mm-t14.30 (mm-t43.32), the plan builder with two planned
    /// meals, Breakfast and Lunch: "Rename" opens only the rename sheet and
    /// keeps the planned meal; a tap between the two controls runs nothing;
    /// "Remove" removes only that planned meal (Lunch stays) and opens no
    /// sheet.
    func testRenameAndRemoveInThePlanBuilderRunAlone() throws {
        try launchOnToday("review")
        tapDayMenu("Today's plan")
        assertScreen("Today's plan")
        for slot in ["Breakfast", "Lunch"] {
            let place = app.buttons[slot].firstMatch
            XCTAssertTrue(scrollTo(place), "the plan builder offers \"\(slot)\"")
            place.tap()
            XCTAssertTrue(app.buttons["Remove \(slot)"].firstMatch.waitForExistence(timeout: 5), "\"\(slot)\" is a planned meal")
        }
        let renameLunch = app.buttons["Rename Lunch"].firstMatch
        let removeLunch = app.buttons["Remove Lunch"].firstMatch
        _ = scrollTo(app.buttons["Remove Breakfast"].firstMatch)
        let rename = app.buttons["Rename Breakfast"].firstMatch
        let remove = app.buttons["Remove Breakfast"].firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 5) && remove.exists, "the planned meal shows \"Rename\" and \"Remove\"")
        rename.tap()
        XCTAssertTrue(app.navigationBars["Rename"].waitForExistence(timeout: 5), "\"Rename\" opens the rename sheet")
        app.navigationBars["Rename"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Rename"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(remove.exists, "\"Rename\" keeps the planned meal")
        // Between the two controls.
        let between = CGRect(x: (rename.frame.maxX + remove.frame.minX) / 2 - 4, y: rename.frame.minY, width: 8, height: rename.frame.height)
        tap(between)
        sleep(1)
        XCTAssertFalse(app.navigationBars["Rename"].exists, "a tap between the controls opens no sheet")
        XCTAssertTrue(remove.exists, "a tap between the controls keeps the planned meal")
        remove.tap()
        XCTAssertTrue(remove.waitForNonExistence(timeout: 5), "\"Remove\" removes the planned meal")
        XCTAssertFalse(app.navigationBars["Rename"].exists, "\"Remove\" opens no rename sheet")
        XCTAssertTrue(app.buttons["Breakfast"].firstMatch.exists, "\"Breakfast\" is free to place again")
        XCTAssertTrue(scrollTo(removeLunch) && renameLunch.exists, "\"Remove\" on Breakfast removes only Breakfast: Lunch stays a planned meal")
        app.navigationBars["Today's plan"].buttons["Cancel"].tap()
    }

    /// mm-t14.28, mm-t14.30 (mm-t43.32), the missed planned meal prompt: a
    /// tap on the row's slot label runs nothing; "Add it" opens only the
    /// new-entry screen and does not answer "Skipped"; "Skipped" answers
    /// "Skipped" and opens nothing.
    func testSkippedAndAddItOnAMissedMealRunAlone() throws {
        turnOnTheCallRecord()
        try launchOnToday("or-plan")
        let prompt = text("Skipped, or not recorded yet?")
        XCTAssertTrue(prompt.waitForExistence(timeout: 8), "Today shows the missed planned meal prompt")
        let rowFinder: ([Seen]) -> Seen? = { $0.first { $0.type == .staticText && $0.label == "Breakfast" } }
        guard let slot = rowFinder(look()) else {
            XCTFail("the planned meal row shows \"Breakfast\"")
            return
        }
        assertTapRunsOnly(Effects(), at: slot.frame, "the slot label of the row")
        XCTAssertTrue(prompt.exists, "a tap on the row's text keeps the prompt")
        let addIt = app.buttons["Add it"].firstMatch
        addIt.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "\"Add it\" opens the new-entry screen")
        app.navigationBars.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertTrue(prompt.exists, "\"Add it\" does not answer \"Skipped\": the prompt stays")
        assertTapRunsOnly(Effects(), at: app.buttons["Skipped"].firstMatch.frame, "\"Skipped\"")
        XCTAssertTrue(prompt.waitForNonExistence(timeout: 5), "\"Skipped\" answers the prompt")
        XCTAssertTrue(app.staticTexts["Skipped"].firstMatch.exists, "the row reads \"Skipped\"")
    }

    // MARK: mm-t14.38 to mm-t14.40 (comment of 15:46 on mm-t14.28)

    /// The colour of one point of `image`, as red, green and blue from 0 to 1.
    func colour(at point: CGPoint, in image: CGImage, scale: CGFloat) -> [CGFloat] {
        var pixel: [UInt8] = [0, 0, 0, 0]
        let space = CGColorSpaceCreateDeviceRGB()
        pixel.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            context.draw(image, in: CGRect(x: -point.x * scale, y: -(CGFloat(image.height) - point.y * scale), width: CGFloat(image.width), height: CGFloat(image.height)))
        }
        return pixel.prefix(3).map { CGFloat($0) / 255 }
    }

    /// The confirming control `label` is a filled button across the full
    /// width, below the content of `container`: after a scroll to the end,
    /// no element of the content is lower than its top. Filled: a point at
    /// each end of the button, away from its title, differs clearly in
    /// colour from the background just above the button.
    ///
    /// Which button: a page or a sheet that covers another screen holds
    /// its button inside its scroll view (`inPage`), and the screen under
    /// it stays in the hierarchy with its own button. So the button comes
    /// from `container`, never from the screen under it. A list screen
    /// holds its button in the bottom inset, outside the list; the button
    /// then comes from the whole screen, and the test first proves that the
    /// screen shows only one full-width button with that label.
    func assertFullWidthFilledBelowTheContent(_ label: String, in container: XCUIElement, _ screen: String, inPage: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(container.waitForExistence(timeout: 8), "\(screen) shows", file: file, line: line)
        var last = ""
        for _ in 0..<10 {
            container.swipeUp()
            let now = look(container).filter { $0.type == .staticText || $0.type == .button }.map(\.label).joined(separator: "|")
            if now == last { break }
            last = now
        }
        sleep(1)
        let window = app.windows.firstMatch.frame
        let seen = inPage ? look(container) : look()
        if !inPage {
            let wide = seen.filter { $0.type == .button && $0.label == label && $0.frame.width >= window.width - 48 }
            XCTAssertEqual(wide.count, 1, "on \(screen), one full-width \"\(label)\" shows, so the button read is the screen's own", file: file, line: line)
        }
        guard let button = widest(label, in: seen) else {
            XCTFail("\(screen) shows \"\(label)\"\(inPage ? " inside the page" : "")", file: file, line: line)
            return
        }
        XCTAssertGreaterThanOrEqual(button.frame.width, window.width - 48, "on \(screen), \"\(label)\" spans the full width", file: file, line: line)
        XCTAssertTrue(button.isEnabled, "on \(screen), \"\(label)\" is active", file: file, line: line)
        let content = look(container).filter { item in
            [.staticText, .textField, .textView, .button, .switch].contains(item.type) && item.frame.height > 0
                && item.frame != button.frame && item.frame.minY < window.maxY && item.frame.maxY > 0
        }
        let lowest = content.max { $0.frame.maxY < $1.frame.maxY }
        if let lowest {
            XCTAssertLessThanOrEqual(lowest.frame.maxY, button.frame.minY + 1, "on \(screen), \"\(label)\" shows below the content (lowest: \(lowest.label))", file: file, line: line)
        }
        guard let image = XCUIScreen.main.screenshot().image.cgImage else {
            XCTFail("no screenshot", file: file, line: line)
            return
        }
        let scale = CGFloat(image.width) / window.width
        let background = colour(at: CGPoint(x: button.frame.midX, y: button.frame.minY - 5), in: image, scale: scale)
        for x in [button.frame.minX + button.frame.height, button.frame.maxX - button.frame.height] {
            let inside = colour(at: CGPoint(x: x, y: button.frame.midY), in: image, scale: scale)
            let difference = zip(inside, background).map { abs($0 - $1) }.reduce(0, +)
            XCTAssertGreaterThan(difference, 0.4, "on \(screen), \"\(label)\" is a filled button (\(inside) against \(background))", file: file, line: line)
        }
    }

    /// The list or scroll view of the screen on top: of the lists that
    /// show, the one that starts lowest (a sheet starts under the screen
    /// it covers).
    func topList() -> XCUIElement {
        let lists = app.collectionViews.allElementsBoundByIndex.filter { $0.exists }
        return lists.max { $0.frame.minY < $1.frame.minY } ?? app.collectionViews.firstMatch
    }

    /// mm-t14.28, mm-t14.38 to mm-t14.40 (mm-t43.32), onboarding: on
    /// screens 1 to 4 the confirming control ("Continue", then "Start") is a
    /// filled button across the full width, below the content. On screen
    /// 4, "Show me how" opens a sheet with "Close", and one tap on "Close"
    /// returns to screen 4. (The heading rotor stays a VoiceOver device
    /// check.)
    func testOnboardingConfirmingButtonsAndShowMeHow() throws {
        try launch(nil)
        assertFullWidthFilledBelowTheContent("Continue", in: app.scrollViews.firstMatch, "screen 1", inPage: true)
        let firstContinue = app.buttons["Continue"].firstMatch
        firstContinue.tap()
        assertScreen("A few questions first")
        assertFullWidthFilledBelowTheContent("Continue", in: app.collectionViews.firstMatch, "screen 2", inPage: false)
        answer(Self.treatmentQuestion, "No")
        answer(Self.pregnancyQuestion, "No")
        answer(Self.selfHarmQuestion, "No")
        fill("Weight in kilograms", "65")
        fill("Height in centimetres", "170")
        fill("How old are you?", "30")
        tapConfirm()
        dismissKeyboardTipBesideAFullWidthControl()
        assertScreen("Your start")
        assertFullWidthFilledBelowTheContent("Continue", in: app.collectionViews.firstMatch, "screen 3", inPage: false)
        guard let wont = reveal(bar: "Continue", { self.first(.button, "I won't be weighing", in: $0) }) else {
            XCTFail("screen 3 offers \"I won't be weighing\"")
            return
        }
        tap(wont.frame)
        tapConfirm()
        assertScreen("Permissions")
        assertFullWidthFilledBelowTheContent("Start", in: app.collectionViews.firstMatch, "screen 4", inPage: false)
        guard let showMeHow = reveal(bar: "Start", { self.first(.button, "Show me how", in: $0) }) else {
            XCTFail("screen 4 shows \"Show me how\"")
            return
        }
        tap(showMeHow.frame)
        let sheet = app.navigationBars["Show me how"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5), "\"Show me how\" opens its sheet")
        XCTAssertTrue(sheet.buttons["Close"].exists, "the sheet shows \"Close\"")
        sheet.buttons["Close"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5), "one tap on \"Close\" closes the sheet")
        assertScreen("Permissions")
    }

    /// mm-t14.28, mm-t14.38 (mm-t43.32): on the exclusion page and on the
    /// caution sheet, the confirming control ("Done", "Continue") is a
    /// filled button across the full width, below the content.
    func testExclusionAndCautionConfirmingButtons() throws {
        try openScreen2()
        fill("How old are you?", "17")
        fill("Height in centimetres", "170")
        fill("Weight in kilograms", "65")
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] { answer(question, "No") }
        tapConfirm()
        let exclusion = app.scrollViews.containing(NSPredicate(format: "label == %@", "Not right now")).firstMatch
        assertFullWidthFilledBelowTheContent("Done", in: exclusion, "the exclusion page", inPage: true)

        try openScreen2()
        fill("How old are you?", "30")
        fill("Height in centimetres", "170")
        fill("Weight in kilograms", "54")
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] { answer(question, "No") }
        tapConfirm()
        let caution = app.scrollViews.containing(NSPredicate(format: "label BEGINSWITH %@", "Your height and weight put you close")).firstMatch
        assertFullWidthFilledBelowTheContent("Continue", in: caution, "the caution sheet", inPage: true)
    }

    /// mm-t14.28, mm-t14.38 to mm-t14.40 (mm-t43.32): on the weekly
    /// review, the GP suggestion page and the not-right-now page, the
    /// confirming control ("Done") is a filled button across the full
    /// width, below the content.
    func testReviewAndPageConfirmingButtons() throws {
        try launchOnToday("review")
        openTheDueReview()
        assertFullWidthFilledBelowTheContent("Done", in: app.collectionViews.firstMatch, "the weekly review", inPage: false)
        tapGettingWorse()
        let gpPage = app.scrollViews.containing(NSPredicate(format: "label == %@", "It might help to see your GP")).firstMatch
        assertFullWidthFilledBelowTheContent("Done", in: gpPage, "the GP suggestion page", inPage: true)
        tapDoneOnThePage("It might help to see your GP")
        answer(Self.selfHarmQuestion, "Yes", bar: "Done")
        answer(Self.selfHarmStep2Question, "Yes", bar: "Done", verify: false)
        let notRightNow = app.scrollViews.containing(NSPredicate(format: "label == %@", "This may not be right for you now")).firstMatch
        assertFullWidthFilledBelowTheContent("Done", in: notRightNow, "the not-right-now page", inPage: true)
    }

    /// mm-t14.28, mm-t14.38 and mm-t14.39 (mm-t43.32): on Close the day,
    /// "Done" is a filled button across the full width, below the content,
    /// and "Get support" is the only control in the navigation bar, in the
    /// trailing position.
    func testCloseTheDayConfirmingButtonAndGetSupport() throws {
        try launchOnToday("or-plan")
        let closeTheDay = app.buttons["Close the day"].firstMatch
        XCTAssertTrue(closeTheDay.waitForExistence(timeout: 8), "Today shows \"Close the day\" after the last planned meal")
        closeTheDay.tap()
        let bar = app.navigationBars["Close the day"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5), "Close the day shows")
        let buttons = bar.buttons.allElementsBoundByIndex.filter { $0.exists }
        XCTAssertEqual(buttons.map(\.label), ["Get support"], "\"Get support\" is the only control in the navigation bar")
        if let support = buttons.first {
            XCTAssertGreaterThan(support.frame.minX, bar.frame.midX, "\"Get support\" is in the trailing position")
        }
        assertFullWidthFilledBelowTheContent("Done", in: topList(), "Close the day", inPage: false)
    }
}
