import XCTest
import UIKit

/// Ash, 8 October 2026: "I don't want to test the accessibility features."
/// So no VoiceOver, Voice Control, largest-text-size, contrast or
/// Accessibility Inspector check stays on a device-check bead (bd memory
/// ash-no-accessibility-device-checks). The app must still obey
/// product-rules "Accessibility everywhere" and the accessibility
/// requirement of each spec. These tests prove what a UI test can prove:
///
/// - Xcode's accessibility audit (`performAccessibilityAudit`, iOS 17 and
///   later) on each main screen, at the default text size and again at the
///   largest accessibility text size (AX5). The audit looks for contrast,
///   element detection, hit regions, element descriptions, Dynamic Type,
///   clipped text and traits. Each audit also checks that each control has
///   a label of its own (`unlabelledControls`), and that each control has a
///   hit area of at least 44 by 44 points (`smallControls`): the audit's
///   own hit-region check reported nothing.
/// - The contrast audit in dark mode on the same screens
///   (`testAuditContrastInDarkMode` and the two tests after it). A UI test
///   cannot turn on Increase Contrast: mm-t45.19 holds the question of a
///   pass of the script with Increase Contrast on.
/// - Checks of the accessibility tree for what the audit cannot see and the
///   specs name: header traits, the labels and the reading order that the
///   specs give, and the VoiceOver custom actions of rows and day headings.
/// - A check of the pixels that the audit cannot make: the GP paragraph's
///   editor draws its text (`assertTheGPParagraphShowsItsText`).
///
/// Each audit walks its screen page by page to the end of the content. The
/// walk proves that it reached the end: the scroll status of the content
/// ("page 3 of 3") or the screen's last element (`last`). A walk that does
/// not reach the end fails the test.
///
/// Each issue goes one of three ways. An issue that `auditExclusions` or
/// `auditElementlessExclusions` takes is not a fault of the app: each entry
/// tells why. An issue that `auditKnownDefects` takes is a fault that a bead
/// holds: it shows as an expected failure. Every other issue fails the
/// test, and the failure message lists each one (screen, text size, type,
/// element, description). An issue with no frame fails the test unless an
/// entry for its type and its description takes it, and each entry takes
/// at most a pinned count of them on one page of each screen. The test
/// keeps the screen of each issue with no element in `OUT_DIR/audit-shots`.
/// A contrast issue of an element that a bar covers in part stays open
/// until a later page shows the element clear of the bars, and fails the
/// test when no page does. The log `accessibility-audit.log` in `OUT_DIR`
/// holds every issue and the decision about it: one line for each issue
/// that the audit gives.
///
/// Run these tests by name with `tools/skeleton-checks/automated-checks.sh`
/// (for example `testAuditOnboardingScreens`). The suite runs them with the
/// other checks.
extension AutomatedChecks {

    // MARK: Text size

    /// The two text sizes of each audit. The launch argument
    /// `-UIPreferredContentSizeCategoryName` sets the size of the app only.
    /// Its value is the raw value of the category: for AX5 that is
    /// "UICTContentSizeCategoryAccessibilityXXXL". (The name
    /// "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge" is not a
    /// category: iOS ignores it and keeps the default size.)
    enum AuditTextSize: String, CaseIterable {
        case standard = "default text size"
        case largest = "AX5"

        var launchArguments: [String] {
            switch self {
            case .standard: return []
            case .largest: return ["-UIPreferredContentSizeCategoryName", UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue]
            }
        }
    }

    /// Puts the seeded store `scenario` (or no store) into the app's
    /// container and launches the app at the text size `size`. This is
    /// `launch(_:launchMarker:)` with one more launch argument.
    func auditLaunch(_ scenario: String?, size: AuditTextSize, launchMarker: String? = nil) throws {
        app.terminate()
        let environment = ProcessInfo.processInfo.environment
        let fileManager = FileManager.default
        let support = URL(fileURLWithPath: environment["APP_DATA"]!).appendingPathComponent("Library/Application Support")
        let record = support.appendingPathComponent("Record")
        let marker = support.appendingPathComponent("LaunchMarker")
        try? fileManager.removeItem(at: record)
        try? fileManager.removeItem(at: marker)
        try fileManager.createDirectory(at: record, withIntermediateDirectories: true)
        if let scenario {
            let seeded = URL(fileURLWithPath: environment["STORES"]!).appendingPathComponent(scenario)
            for file in try fileManager.contentsOfDirectory(at: seeded, includingPropertiesForKeys: nil) {
                try fileManager.copyItem(at: file, to: record.appendingPathComponent(file.lastPathComponent))
            }
        }
        if let launchMarker {
            try Data(launchMarker.utf8).write(to: marker)
        }
        app.launchArguments = ["-AppleLanguages", "(en-GB)", "-AppleLocale", "en_GB"] + size.launchArguments
        app.launch()
    }

    /// Launches with `scenario` at `size` and waits for Today.
    func auditLaunchOnToday(_ scenario: String, size: AuditTextSize, file: StaticString = #filePath, line: UInt = #line) throws {
        try auditLaunch(scenario, size: size)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "Today shows after the launch (\(size.rawValue))", file: file, line: line)
    }

    /// `launchWithTheSeam` at the text size `size`: the app-lock test seam
    /// answers each system authentication request with the next of
    /// `results`.
    func auditLaunchWithTheSeam(_ scenario: String, results: [String], size: AuditTextSize) throws {
        app.terminate()
        removeDeletionFault()
        try? FileManager.default.removeItem(at: appLockLog)
        try FileManager.default.createDirectory(at: appLockScript.deletingLastPathComponent(), withIntermediateDirectories: true)
        scriptAppLock(results)
        app.launchEnvironment["MIDMORNING_APP_LOCK_SCRIPT"] = appLockScript.path
        try auditLaunch(scenario, size: size)
    }

    // MARK: The audit

    /// One issue of an audit, as the log and the failure message show it.
    struct AuditFinding {
        let screen: String
        let size: AuditTextSize
        let dark: Bool
        let type: XCUIAccessibilityAuditType
        let compact: String
        let detail: String
        let elementType: XCUIElement.ElementType?
        let label: String?
        let identifier: String?
        let frame: CGRect?
        /// The element can take a tap (false for a disabled control).
        var enabled = true
        /// The element is content of a list or a scroll view, and a part of
        /// it is under a bar (the navigation bar, a pinned section header,
        /// the toolbar, the bar of the confirming button or the keyboard),
        /// or off the screen.
        var underABar = false
        /// The element is an item of a navigation bar or of the bottom
        /// toolbar (a title or a bar button).
        var inABar = false
        /// For a contrast issue: the lowest contrast of the texts and the
        /// images inside the element's frame, or of the element itself when
        /// it holds none, in a screenshot (`measuredContrast`).
        var measured: Double?
        /// For a contrast issue: each part that the test measured, with its
        /// contrast ("<label>" 4.2:1).
        var measuredParts: [String] = []
        /// For an issue with no element: the labels of the content texts
        /// that were under a bar when the audit ran (`auditTextUnderBars`).
        var textUnderBars: [String] = []
        /// For an issue with no element: the issue's other fields, which
        /// XCTest does not make public (`auditIssueFields`), for the log.
        var fields = ""
        /// The issue has no `XCUIElement`, and `label` and `frame` come from
        /// its accessibility element (`auditAXElement`).
        var viaAX = false
        /// For an issue with no element: the labels of the items of the
        /// bottom toolbar on the page ("Programme", "Reviews", "Settings").
        var toolbarItems: [String] = []
        /// For a hit-area issue (`smallControls`): the system control that
        /// holds the element (a segmented control, a date picker, a
        /// switch), or nil.
        var container: XCUIElement.ElementType?

        /// The issue has a place on the screen to measure and to compare.
        var hasFrame: Bool { frame.map { !$0.isNull && !$0.isInfinite && $0.width > 0 && $0.height > 0 } ?? false }

        var typeName: String { compact == AutomatedChecks.hitAreaCompact ? "hit area" : AutomatedChecks.auditTypeName(type) }

        var text: String {
            let element = elementType.map { "element \($0.rawValue) \"\(label ?? "")\" at \(frame.map { "\($0.integral)" } ?? "?")" }
                ?? (viaAX ? "no element; its accessibility element \"\(label ?? "")\" at \(frame.map { "\($0.integral)" } ?? "?")" : "no element")
            var ratio = measured.map { String(format: " (measured %.1f:1 in a screenshot", $0) } ?? ""
            if !ratio.isEmpty { ratio += measuredParts.allSatisfy({ $0.hasPrefix("the whole element") }) ? ")" : ", the lowest of \(measuredParts.joined(separator: ", ")))" }
            let under = elementType == nil ? " (content text under a bar: \(textUnderBars.isEmpty ? "none" : textUnderBars.joined(separator: " | ")); the issue's fields: \(fields.isEmpty ? "none" : fields))" : ""
            return "\(screen) (\(size.rawValue)\(dark ? ", dark mode" : "")): \(typeName): \(compact): \(element): \(detail)\(ratio)\(under)"
        }

        /// A short name of the issue for the log line of a second sighting.
        var shortText: String { "\(typeName): \(compact): \"\(label ?? "")\"" }
    }

    static func auditTypeName(_ type: XCUIAccessibilityAuditType) -> String {
        let names: [(XCUIAccessibilityAuditType, String)] = [
            (.contrast, "contrast"), (.elementDetection, "elementDetection"), (.hitRegion, "hitRegion"),
            (.sufficientElementDescription, "sufficientElementDescription"), (.dynamicType, "dynamicType"),
            (.textClipped, "textClipped"), (.trait, "trait"),
        ]
        return names.first { type.contains($0.0) }?.1 ?? "label"
    }

    /// The key of a screen at a text size, in light or dark mode, for the
    /// pinned counts (`AuditElementlessExclusion.pins`): "the support sheet
    /// (default text size)".
    static func auditPinKey(_ screen: String, size: AuditTextSize, dark: Bool) -> String {
        "\(screen) (\(size.rawValue)\(dark ? ", dark" : ""))"
    }

    /// An issue that is not a fault of the app, and why.
    struct AuditExclusion {
        let reason: String
        let matches: (AuditFinding) -> Bool
    }

    /// The one-line text fields that hold a short value: a number of at
    /// most three digits (the age, the height and the weight on onboarding
    /// screen 2 and the re-screen, and the weight on the weigh-in screen),
    /// or one word (the close-the-day screen). The name of each field shows
    /// in full above it: the question, or the field's own label.
    static let shortValueFields: Set<String> = [
        "How old are you?", "Height in centimetres", "Height in feet", "Height in inches",
        "Weight in kilograms", "Weight in stone", "Weight in pounds", "Weight", "Stone", "Pounds",
        "One word for how today felt",
    ]

    /// The description of a hit-area issue (`smallControls`).
    static let hitAreaCompact = "Hit area under 44 by 44 points"

    /// The issues that the audits exclude. Each one is not a fault of the
    /// app, and each entry tells why. No entry takes every issue of a type.
    /// An issue with no frame is not in this list: only an entry of
    /// `auditElementlessExclusions` can take it. A contrast issue of an
    /// element under a bar is not in this list either: `auditPage` keeps it
    /// open until an audit page shows the element clear of the bars.
    static let auditExclusions: [AuditExclusion] = [
        AuditExclusion(reason: """
            Each text and each image inside the element's frame contrasts at 3:1 or more with the fill behind it. \
            The test measures each of them in a screenshot just after the audit (`measuredContrast`) and takes the \
            lowest; it measures the element itself only when it holds no text and no image. product-rules \
            "Accessibility everywhere" sets 3:1 for secondary text and for every glyph that carries meaning, and \
            sets no limit for primary text: the test uses 3:1 for all text until Ash decides (mm-t45.17). The \
            audit uses other limits: it reports "Contrast nearly passed" from 3:1 to 4.5:1, and it can report \
            "Contrast failed" on a row whose label is black on white when a system part of the row (a disclosure \
            chevron, the track of a switch) is lighter. A part below 3:1 still fails the test.
            """) { $0.type.contains(.contrast) && $0.hasFrame && !$0.underABar && ($0.measured ?? 0) >= 3 },
        AuditExclusion(reason: """
            The control is disabled (for example "Save" on the weigh-in screen before a weight is typed). WCAG 2 \
            (1.4.3) sets no contrast for the text of an inactive control, and product-rules sets none for it. The \
            same control is measured again when it is active.
            """) { $0.type.contains(.contrast) && $0.elementType != nil && !$0.enabled },
        AuditExclusion(reason: """
            A title or a button of the system navigation bar or toolbar. iOS sets the text size of a bar item: it \
            does not grow it at the accessibility sizes, and it shows the item in the Large Content Viewer (touch \
            and hold) at those sizes. iOS also shortens a title that has no room beside the bar buttons; the \
            title's label keeps the full text, which VoiceOver reads.
            """) { ($0.type.contains(.dynamicType) || $0.type.contains(.textClipped)) && $0.inABar },
        AuditExclusion(reason: """
            The hour-and-minute wheels of the system date picker (the audit names `_UIDatePickerWheelsTimeLabel`) in \
            the record's time control. iOS draws the wheels at a fixed text size at every Dynamic Type size; the app \
            cannot make them grow. For VoiceOver the control is one adjustable element, "Time", whose value reads the \
            date and the time (RecordTimeControl.swift), and the date segments above the wheels scale.
            """) { $0.type.contains(.dynamicType) && $0.detail.contains("_UIDatePickerWheels") },
        AuditExclusion(reason: """
            The label is an e-mail address: the contact address that the privacy notice must show (data-and-privacy, \
            "The privacy notice"). The audit wants a label in words, but the address is the text on the screen, and \
            VoiceOver reads it as an address.
            """) { $0.type.contains(.sufficientElementDescription) && ($0.label ?? "").range(of: "^[^@ ]+@[^@ ]+\\.[a-z]+$", options: .regularExpression) != nil },
        AuditExclusion(reason: """
            A one-line system text field (a SwiftUI TextField). The audit reports each one at each text size, \
            because a one-line field does not wrap. These fields hold a short value (a number of at most three \
            digits, or one word), the field grows with the text size, and the name of the field shows in full above \
            it.
            """) { $0.type.contains(.textClipped) && $0.elementType == .textField && shortValueFields.contains($0.label ?? "") },
    ] + auditHitAreaExclusions

    /// The reason of a contrast issue whose element a bar covered in part
    /// on this page, when an earlier audit page showed the same element
    /// clear of the bars.
    static let underABarShownReason = """
        The element is content that scrolls, and a part of it is under a bar or off the screen when the audit runs. \
        The audit then measures the bar's material over the text, not the text on its own background. An earlier \
        audit page showed the same element clear of the bars, and the audit checked it there.
        """

    /// The reason of a contrast issue that stays open: a bar covered a part
    /// of its element, and no audit page showed the element clear yet.
    static let underABarPendingReason = """
        The element is content that scrolls, and a part of it is under a bar or off the screen when the audit runs, \
        so the audit measured the bar's material over the text. The issue stays open until an audit page shows the \
        element clear of the bars. If no page of the walk does, the issue fails the test at the end of the walk.
        """

    /// An issue with no frame that a person looked at (8 October 2026,
    /// iOS 27.0 simulator) and found is not a fault of the app: of the
    /// named type, with the named description, on a page of a screen that
    /// `pins` names. Each entry also needs its own evidence on the page
    /// (`evidence`).
    ///
    /// `pins` gives, for each screen at each text size
    /// (`auditPinKey`), the most issues that the entry takes on one audit
    /// page: the highest count in the full runs of 8 and 9 October 2026
    /// (before and after the review fixes; the walks of the runs stopped
    /// on different pages). A page
    /// with more of them fails the test, with each issue past the count.
    /// So a new issue of the same kind on the same screen does not hide
    /// under the entry. Raise a count only after a person looked at the
    /// screen of that page (`audit-shots` in `OUT_DIR`).
    ///
    /// An issue whose accessibility element gives a label and a frame
    /// (`viaAX`) is not for these entries: the frame-based checks decide it
    /// (the measured contrast, and the Dynamic Type comparison).
    struct AuditElementlessExclusion {
        let types: [XCUIAccessibilityAuditType]
        let compact: [String]
        let pins: [String: Int]
        let reason: String
        let evidence: (AuditFinding) -> Bool

        func matches(_ finding: AuditFinding, pinKey: String) -> Bool {
            finding.elementType == nil && !finding.hasFrame
                && pins[pinKey] != nil
                && types.contains { finding.type.contains($0) }
                && compact.contains(finding.compact)
                && evidence(finding)
        }
    }

    /// The audit reads text from the pixels of the screen. From iOS 26 the
    /// navigation bar, the bar of the confirming button ("Continue",
    /// "Done") and the keyboard show the content under them blurred or
    /// faded (the scroll-edge effect; the glass of the keyboard). The audit
    /// can read that copy as text with no element.
    static let barCopyReason = """
        The audit read the blurred or faded copy of the content under a bar (the scroll-edge effect of the \
        navigation bar and of the bar of the confirming button from iOS 26, or the glass of the keyboard) as text \
        with no element and no frame. That copy is not text of the app: the same text shows clear on another \
        audit page, where the audit checks its element. The test takes this entry only when a content text was \
        under a bar as the audit started (the log names it), and only up to the pinned count of the page. A \
        person looked at the screens on 8 October 2026: for example "Friday" blurred under "Your start" on \
        onboarding screen 3 at AX5.
        """

    static let auditElementlessExclusions: [AuditElementlessExclusion] = [
        AuditElementlessExclusion(
            types: [.contrast], compact: ["Contrast nearly passed"],
            pins: [
                "Programme (default text size)": 7, "Settings (default text size)": 5,
                "Today with entries and a gap band (default text size)": 1, "onboarding screen 2 (default text size)": 6,
                "onboarding screen 3 (default text size)": 2, "onboarding screen 4 (default text size)": 3,
                "the close-the-day screen (default text size)": 2, "the exclusion page (default text size)": 8,
                "the export screen (default text size)": 2, "the privacy notice (default text size)": 5,
                "the restart re-screen (default text size)": 5, "the support sheet (default text size)": 12,
                "the weekly review (default text size)": 1, "the weigh-in screen with no weigh-in day (default text size)": 7,
            ],
            reason: """
                The audit itself measured this text at 3:1 or more: "Contrast nearly passed" says that the text passes \
                at a larger font size, and WCAG 2 sets 3:1 for large text (4.5:1 for other text). product-rules sets \
                3:1 (mm-t45.17 holds the decision on primary text). The audit gives no element and no frame, so the \
                test cannot measure the text itself, and the pinned count of the page limits the entry. (On the \
                exclusion page and the support sheet these are the "Call" and "Copy number" controls of the numbers, \
                blue on white, 3.5:1 in a screenshot.)
                """) { _ in true },
        AuditElementlessExclusion(
            types: [.elementDetection, .dynamicType, .textClipped],
            compact: ["Potentially inaccessible text", "Dynamic Type font sizes are unsupported", "Dynamic Type font sizes are partially unsupported",
                      "Text clipped"],
            pins: [
                "Settings (default text size)": 1, "Today with entries and a gap band (default text size)": 1,
                "Today with entries and a gap band (AX5)": 4, "Today with the stage 1 card (AX5)": 4,
                // At AX5 on Today: the faded copy of the rows under the
                // pinned day heading and "Add an entry".
                "Today with the missed planned meal prompt (AX5)": 8, "Today with \"Close the day\" (AX5)": 4,
                "Today with the plan card (AX5)": 2,
                "onboarding screen 3 (default text size)": 1, "onboarding screen 3 (AX5)": 6,
                "the Reminders group (AX5)": 2, "the edit screen (AX5)": 1, "the new-entry screen (AX5)": 1,
                "the not-right-now page (AX5)": 1, "the privacy notice (default text size)": 1, "the privacy notice (AX5)": 1,
                "the restart re-screen (AX5)": 1, "the support sheet (default text size)": 7, "the support sheet (AX5)": 2,
                "the weekly review (default text size)": 2, "the weekly review (AX5)": 1,
                "the weigh-in screen on the weigh-in day (AX5)": 2, "the weigh-in screen with no weigh-in day (AX5)": 2,
            ],
            reason: barCopyReason) { !$0.textUnderBars.isEmpty },
        AuditElementlessExclusion(
            types: [.dynamicType], compact: ["Dynamic Type font sizes are partially unsupported"],
            pins: [
                "Today with entries and a gap band (default text size)": 1, "Today with \"Close the day\" (default text size)": 1,
                "Today with the plan card (default text size)": 1, "Today with the pinned note (default text size)": 1,
            ],
            reason: """
                The items of Today's bottom toolbar ("Programme", "Reviews", "Settings"). iOS sets the text size of a bar \
                item: it does not grow it at the accessibility sizes, and it shows the item in the Large Content Viewer \
                (touch and hold). At AX5 the audit gives this issue with an element for "Programme" and "Reviews", and the \
                entry for bar items takes it; at the default size it gives it with no element. Today is the only screen \
                with a bottom toolbar, and the only screen with this issue at the default size. The test takes this entry \
                only on a page that shows the toolbar (8 October 2026, iOS 27.0 simulator).
                """) { !$0.toolbarItems.isEmpty && $0.size == .standard },
    ]

    /// A real fault of the app that a bead holds. The test reports each
    /// issue that an entry matches as an expected failure
    /// (`XCTExpectFailure`) that names the bead, so the result bundle shows
    /// it and the suite still passes. Each entry names the screens and the
    /// elements, so that a new fault does not hide under it. An entry for
    /// issues with no frame also pins the most issues that it takes on one
    /// audit page of each screen (`pins`, as in
    /// `AuditElementlessExclusion`): an issue past the count fails the
    /// test. Remove the entry when the bead closes.
    struct AuditKnownDefect {
        let bead: String
        let reason: String
        var pins: [String: Int]? = nil
        let matches: (AuditFinding) -> Bool
    }

    static let auditKnownDefects: [AuditKnownDefect] = [
        AuditKnownDefect(bead: "mm-t45.18", reason: """
            The audit reports "Contrast failed" with no element and no frame on these screens, so the test cannot \
            measure it or say what it is. A person looked at the screens (8 October 2026): the placeholders of the \
            text fields (1.7:1), the disclosure chevrons of Settings, and the faded copy of the content under the bars \
            are the likely parts. On four states of Today no content text was under a bar and no screen has a \
            placeholder or a chevron, so these causes do not tell what the audit measured there. The bead holds the \
            work to find each one. The pinned count of each page limits the entry.
            """, pins: [
                "onboarding screen 2 (default text size)": 3, "onboarding screen 3 (default text size)": 3,
                "onboarding screen 4 (default text size)": 1, "the restart re-screen (default text size)": 2,
                "Settings (default text size)": 2, "the Reminders group (default text size)": 2,
                "the privacy notice (default text size)": 1, "the support sheet (default text size)": 4,
                "the weekly review (default text size)": 2, "Today with entries and a gap band (default text size)": 1,
                "Today with \"Close the day\" (default text size)": 1, "Today with the plan card (default text size)": 1,
                "Today with the pinned note (default text size)": 1,
            ]) { finding in
            finding.elementType == nil && !finding.hasFrame && finding.type.contains(.contrast) && finding.compact == "Contrast failed"
        },
        AuditKnownDefect(bead: "mm-t12b.29", reason: """
            The app does not use the AccentColor asset, so a bordered button shows the system blue on its own light \
            tint, at 2.8:1: the Where chips on the new-entry and edit screens, and "Get support" on the store-open \
            fault screen.
            """) { finding in
            let chips: Set<String> = ["Home", "Work", "Out", "Travelling", "Add a place"]
            let onEntryScreen = finding.screen.hasPrefix("the new-entry screen") || finding.screen.hasPrefix("the edit screen")
            let onFaultScreen = finding.screen.hasPrefix("the store-open fault screen")
            return finding.type.contains(.contrast) && finding.elementType == .button && (finding.measured ?? 3) < 3
                && ((onEntryScreen && chips.contains(finding.label ?? "")) || (onFaultScreen && finding.label == "Get support"))
        },
    ] + auditHitAreaKnownDefects

    /// The findings of the current test that no exclusion took.
    private static var auditFailures: [String] = []

    /// A Dynamic Type issue at either text size, or a clipped-text issue at
    /// the default size, with the screen of its element. The test decides
    /// each one at the end, from the same element at the other size
    /// (`auditAtEachTextSize`).
    private static var auditScalingChecks: [(finding: AuditFinding, screen: String)] = []

    /// The elements ("<screen>|<label>") with a clipped-text issue at AX5.
    private static var auditClippedAtLargest: Set<String> = []

    /// The tallest height of each label on each screen at each text size:
    /// "<size>|<screen>" to label to height.
    private static var auditHeights: [String: [String: CGFloat]] = [:]

    /// Writes `line` to `accessibility-audit.log` in `OUT_DIR`.
    func auditLog(_ line: String) {
        guard let out = ProcessInfo.processInfo.environment["OUT_DIR"] else { return }
        let url = URL(fileURLWithPath: out).appendingPathComponent("accessibility-audit.log")
        let data = Data((line + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }

    /// One text or control on the screen, from `auditReadScreen`.
    struct AuditItem: Equatable {
        let label: String
        let frame: CGRect
        /// The item is inside a list or a scroll view.
        let inContent: Bool
    }

    /// The labels of the content items in `items` that show clear of the
    /// bars: the middle of each is between the navigation bar (or the
    /// pinned section header under it) and the bar at the bottom (the
    /// toolbar, the bar of the confirming button or the keyboard), or the
    /// item is a part of the pinned section header. An item under a bar is
    /// in the window, but the person cannot see it, and the walk must not
    /// take it as audited: on onboarding screen 3 at AX5 the "Quiet hours"
    /// rows were under the bar of "Continue" on page 3, so the walk took
    /// them as shown, and no audit page showed them (8 October 2026).
    /// A screen with no list and no scroll view (the app-lock cover) uses
    /// all its items.
    func auditLabels(_ items: [AuditItem]) -> Set<String> {
        let clear = auditClearArea()
        let content = items.filter(\.inContent)
        return Set((content.isEmpty ? items : content).filter { clear.showsMiddle(of: $0.label, $0.frame) }.map(\.label))
    }

    /// Reads the screen in one snapshot. Keeps the height of each element
    /// with a label in the tree for `screen` at `size`, and returns the
    /// texts and controls on the screen with their places, to see if a
    /// scroll moved the content. A scroll bar is left out: its label tells
    /// the number of pages, not the content.
    func auditReadScreen(_ screen: String, size: AuditTextSize) -> [AuditItem] {
        guard let snapshot = try? app.snapshot() else { return [] }
        var items: [AuditItem] = []
        let window = app.windows.firstMatch.frame
        let key = "\(size.rawValue)|\(screen)"
        var heights = Self.auditHeights[key] ?? [:]
        func walk(_ element: XCUIElementSnapshot, inContent: Bool) {
            // The height of each element in the tree, on the screen or not:
            // a list keeps the rows near the screen in the tree, and the
            // audit itself can move the list past a row between two reads.
            if !element.label.isEmpty, element.frame.height > 0 {
                heights[element.label] = max(heights[element.label] ?? 0, element.frame.height)
            }
            if !element.label.isEmpty, element.frame.intersects(window), !Self.isScrollBar(element.label),
               [.staticText, .button, .textField, .textView, .switch, .datePicker, .image].contains(element.elementType) {
                items.append(AuditItem(label: element.label, frame: element.frame.integral, inContent: inContent))
            }
            let container = [.scrollView, .collectionView, .table].contains(element.elementType)
            element.children.forEach { walk($0, inContent: inContent || container) }
        }
        walk(snapshot, inContent: false)
        Self.auditHeights[key] = heights
        return items
    }

    /// The scroll bars of a scroll view are elements ("Vertical scroll bar,
    /// 3 pages").
    static func isScrollBar(_ label: String) -> Bool {
        label.hasPrefix("Vertical scroll bar") || label.hasPrefix("Horizontal scroll bar")
    }

    /// Scrolls the content up by `fraction` (70 percent) of the part of the
    /// screen that is clear of the bars, with a slow drag at `x` (the left
    /// margin), so that the drag never starts on a control or on a bar. The
    /// part that stays lets an element that a bar covered on one page show
    /// clear on the next, for the contrast audit. At AX5 the audit does not
    /// measure contrast, so it scrolls 85 percent. A negative `fraction`
    /// scrolls the content down, to show what is above.
    func auditScrollDown(fraction: CGFloat = 0.7, x: CGFloat = 8) {
        let clear = auditClearArea()
        let window = app.windows.firstMatch.frame
        let top = max(clear.top, window.minY) + 10
        let bottom = min(clear.bottom, window.maxY) - 10
        guard bottom - top > 60 else { return }
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let distance = (bottom - top) * abs(fraction)
        let from = fraction >= 0 ? bottom : top
        let to = fraction >= 0 ? bottom - distance : top + distance
        origin.withOffset(CGVector(dx: x, dy: from))
            .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: x, dy: to)), withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    /// The contrast of the element in `frame` (points) in `image`, with the
    /// luminance formula of WCAG 2. The test measures inside the frame,
    /// clear of the rounded ends of a button and of the edges, so that the
    /// background outside a button does not count. The background is the
    /// median pixel (the fill of the row or of the button). The text is the
    /// 0.5th percentile (dark text) or the 99.5th percentile (light text),
    /// so that a few pixels at the edge of a glyph do not count. The result
    /// is the higher of the two ratios. For example (8 October 2026): black
    /// text on white 21:1, the secondary text 8A8A8E on white 3.4:1, a
    /// section header 85858B on F2F2F7 3.3:1, white on the system blue
    /// 3.5:1, and the system blue on its own light tint 2.8:1. A frame that
    /// holds two texts gives the contrast of the darker one only, so the
    /// audit measures each text and image of an element on its own
    /// (`measureContrast`).
    func measuredContrast(in frame: CGRect, of image: CGImage, scale: CGFloat) -> Double? {
        let inner = frame.insetBy(dx: min(16, frame.width / 4), dy: frame.height * 0.2)
        let rect = CGRect(x: inner.minX * scale, y: inner.minY * scale, width: inner.width * scale, height: inner.height * scale)
            .integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard !rect.isEmpty, let cropped = image.cropping(to: rect), let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let width = cropped.width, height = cropped.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn, width * height > 0 else { return nil }
        func channel(_ value: UInt8) -> Double {
            let c = Double(value) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        var luminance: [Double] = []
        luminance.reserveCapacity(width * height)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            luminance.append(0.2126 * channel(pixels[index]) + 0.7152 * channel(pixels[index + 1]) + 0.0722 * channel(pixels[index + 2]))
        }
        luminance.sort()
        let last = Double(luminance.count - 1)
        let dark = luminance[Int(last * 0.005)], background = luminance[luminance.count / 2], light = luminance[Int(last * 0.995)]
        return max((background + 0.05) / (dark + 0.05), (light + 0.05) / (background + 0.05))
    }

    /// The contrast of a flagged element: each text and each image in the
    /// element (its descendants in the accessibility tree) measured on its
    /// own, and the lowest of them. An element that holds no text and no
    /// image (a button whose label is its own text, or a combined row whose
    /// texts are not in the tree) is measured as one frame. Only the
    /// element's own descendants count: content under a bar can have a
    /// frame inside the frame of a button in the bar.
    func measureContrast(of finding: AuditFinding, in image: CGImage, scale: CGFloat, root: XCUIElementSnapshot?) -> (lowest: Double?, parts: [String]) {
        guard let frame = finding.frame else { return (nil, []) }
        var node: XCUIElementSnapshot?
        func find(_ element: XCUIElementSnapshot) {
            guard node == nil else { return }
            if element.frame.integral == frame.integral, element.label == (finding.label ?? ""),
               finding.elementType.map({ $0 == element.elementType }) ?? true {
                node = element
                return
            }
            element.children.forEach(find)
        }
        if let root, !finding.viaAX { find(root) }
        var parts: [XCUIElementSnapshot] = []
        func collect(_ element: XCUIElementSnapshot) {
            for child in element.children {
                if [.staticText, .image].contains(child.elementType), child.frame.width > 2, child.frame.height > 2,
                   child.frame.integral != frame.integral {
                    parts.append(child)
                }
                collect(child)
            }
        }
        if let node { collect(node) }
        var measured: [(String, Double)] = []
        for part in parts {
            if let ratio = measuredContrast(in: part.frame, of: image, scale: scale) {
                measured.append(("\(part.elementType == .image ? "image" : "text") \"\(part.label.prefix(40))\"", ratio))
            }
        }
        if measured.isEmpty, let ratio = measuredContrast(in: frame, of: image, scale: scale) {
            measured.append(("the whole element", ratio))
        }
        return (measured.map(\.1).min(), measured.map { String(format: "%@ %.1f:1", $0.0, $0.1) })
    }

    /// The part of the screen where content shows clear of every bar, from
    /// one snapshot (`auditClearArea`).
    struct AuditClearArea {
        /// The bottom of the navigation bar, or of the pinned section header
        /// under it.
        var top: CGFloat
        /// The top of the bar at the bottom (the items of the toolbar, the
        /// bar of the confirming button, or the keyboard), and at most 34
        /// points above the bottom of the window, over the home indicator.
        var bottom: CGFloat
        /// The top of the bar at the bottom, or the bottom of the window
        /// when the screen has no bar there. The home indicator puts no
        /// material over the content, so a text above this line and inside
        /// the window shows on its own background.
        var barBottom: CGFloat
        /// The elements that are content of a list or a scroll view.
        var content: [(label: String, frame: CGRect)]
        /// The items of the navigation bar and of the toolbar.
        var barItems: [(label: String, frame: CGRect)]
        /// The parts of the section header that is pinned under the
        /// navigation bar, for example Today's current day heading and "Add
        /// an entry". The rows scroll under it, as they do under a bar.
        var pinnedItems: [(label: String, frame: CGRect)]

        /// The element is a part of the pinned section header.
        func inPinnedHeader(_ label: String, _ frame: CGRect) -> Bool {
            pinnedItems.contains { $0.label == label && $0.frame.integral == frame.integral }
        }

        /// The element shows whole and clear of every bar: between `top` and
        /// `bottom`, or as a part of the pinned section header.
        func isClear(_ label: String, _ frame: CGRect) -> Bool {
            (frame.minY >= top - 1 && frame.maxY <= bottom + 1) || inPinnedHeader(label, frame)
        }

        /// The element shows whole and no bar covers a part of it: between
        /// `top` and `barBottom`, or as a part of the pinned section header.
        /// The contrast audit measures such an element on its own
        /// background.
        func isClearOfBars(_ label: String, _ frame: CGRect) -> Bool {
            (frame.minY >= top - 1 && frame.maxY <= barBottom + 1) || inPinnedHeader(label, frame)
        }

        /// The middle of the element is clear of every bar.
        func showsMiddle(of label: String, _ frame: CGRect) -> Bool {
            (frame.midY >= top && frame.midY <= bottom) || inPinnedHeader(label, frame)
        }
    }

    /// The part of the screen where content shows clear of every bar, and
    /// the frames of the elements that are content of a list or a scroll
    /// view, from one snapshot.
    ///
    /// The bars: the navigation bar at the top; at the bottom the toolbar,
    /// the keyboard, the bar of the full-width confirming button, and the
    /// floating items of iOS 27's bottom toolbar (Today's "Programme" and
    /// "Settings"). A section header of a list that is pinned under the
    /// navigation bar also covers the rows that scroll under it: at AX5 on
    /// Today, the current day heading and "Add an entry" cover about 40
    /// percent of the screen, and a row under them did not show on any
    /// audit page (8 October 2026). The pinned header is a direct child of
    /// the list, its top meets the navigation bar, and it holds a heading
    /// (an element with the header trait).
    func auditClearArea() -> AuditClearArea {
        let window = app.windows.firstMatch.frame
        guard let snapshot = try? app.snapshot(), window.height > 0 else {
            return AuditClearArea(top: 0, bottom: .infinity, barBottom: .infinity, content: [], barItems: [], pinnedItems: [])
        }
        var top: CGFloat = 0
        var barBottom = window.maxY
        var content: [(label: String, frame: CGRect)] = []
        var barItems: [(label: String, frame: CGRect)] = []
        // Each direct child of a list or a scroll view that holds a heading,
        // with its labelled parts: a section header that can be pinned.
        var headers: [(frame: CGRect, items: [(label: String, frame: CGRect)])] = []
        // XCTest gives the traits of a snapshot only in a private property
        // (`traitedElements`).
        let hasTraits = (snapshot as AnyObject).responds(to: NSSelectorFromString("traits"))
        func traits(_ element: XCUIElementSnapshot) -> UInt64 {
            guard hasTraits else { return 0 }
            return ((element as AnyObject).value(forKey: "traits") as? NSNumber)?.uint64Value ?? 0
        }
        func parts(of element: XCUIElementSnapshot) -> (heading: Bool, items: [(label: String, frame: CGRect)]) {
            var heading = traits(element) & Self.headerTrait != 0
            var items: [(label: String, frame: CGRect)] = element.label.isEmpty ? [] : [(element.label, element.frame)]
            for child in element.children {
                let found = parts(of: child)
                heading = heading || found.heading
                items += found.items
            }
            return (heading, items)
        }
        func walk(_ element: XCUIElementSnapshot, inContent: Bool, inBar: Bool, inToolbar: Bool) {
            let frame = element.frame
            switch element.elementType {
            case .navigationBar where frame.minY < window.height / 2 && frame.intersects(window):
                top = max(top, frame.maxY)
            case .toolbar, .keyboard:
                // A bar at the bottom. (iOS 27 also has a "Toolbar" element
                // that covers the whole window: it is not a bar.)
                if frame.height > 0, frame.height < window.height / 2, frame.minY > window.height / 3, frame.intersects(window) {
                    barBottom = min(barBottom, frame.minY)
                }
            case .button where !inContent && frame.width >= window.width - 48 && frame.minY > window.height * 0.5:
                // The full-width confirming button in a bar under the
                // content: the bar starts 16 points above the button.
                barBottom = min(barBottom, frame.minY - 16)
            default:
                // An item of iOS 27's floating bottom toolbar (inside the
                // "Toolbar" element that covers the whole window), or its
                // glass: the content under it is not clear.
                if inToolbar, frame.height >= 20, frame.height <= 100, frame.minY > window.height * 0.75, frame.intersects(window) {
                    barBottom = min(barBottom, frame.minY)
                }
            }
            if inContent, !element.label.isEmpty, !Self.isScrollBar(element.label) { content.append((element.label, frame)) }
            if inBar, !element.label.isEmpty { barItems.append((element.label, frame)) }
            let isContainer = [.scrollView, .collectionView, .table].contains(element.elementType)
            // Only a list pins a section header (a plain scroll view does not).
            if [.collectionView, .table].contains(element.elementType) {
                for child in element.children where child.frame.width >= window.width * 0.9 && child.frame.height >= 20 {
                    let found = parts(of: child)
                    if found.heading { headers.append((child.frame, found.items)) }
                }
            }
            // The items of iOS 27's floating toolbar are inside a "Toolbar"
            // element that covers the whole window.
            let isBar = element.elementType == .navigationBar || element.elementType == .toolbar
            element.children.forEach {
                walk($0, inContent: inContent || isContainer, inBar: inBar || isBar, inToolbar: inToolbar || element.elementType == .toolbar)
            }
        }
        walk(snapshot, inContent: false, inBar: false, inToolbar: false)
        let bottom = min(barBottom, window.maxY - 34)
        var pinnedItems: [(label: String, frame: CGRect)] = []
        // A header whose top meets the navigation bar, and that leaves room
        // for the content under it.
        if top > 0, let pinned = headers.first(where: { abs($0.frame.minY - top) <= 2 && $0.frame.maxY < top + (bottom - top) * 0.7 }) {
            top = pinned.frame.maxY
            pinnedItems = pinned.items
        }
        return AuditClearArea(top: top, bottom: bottom, barBottom: barBottom, content: content, barItems: barItems, pinnedItems: pinnedItems)
    }

    /// The content texts that are under the navigation bar (or the pinned
    /// section header) or under the bar at the bottom (a part of each is
    /// in the bar's area of the screen). From iOS 26, a bar blurs the
    /// content under it (the scroll-edge effect), and the audit can read
    /// that blurred copy as text with no element.
    private func auditTextUnderBars(_ clear: AuditClearArea) -> [String] {
        let window = app.windows.firstMatch.frame
        return clear.content.filter { item in
            item.frame.height > 0 && item.frame.intersects(window) && !clear.isClear(item.label, item.frame)
        }.map { "\($0.label.prefix(50))@\(Int($0.frame.minY))-\(Int($0.frame.maxY))" }
    }

    /// The scroll position of the content that shows, as VoiceOver says it
    /// after a scroll: "page 2 of 3". It is the scroll status of the front
    /// scroll view (the last one in the tree that covers a third of the
    /// window or more), from the XCTest accessibility client (attribute
    /// "XC_kAXXCAttributeScrollStatus", 8 October 2026, Xcode 27.0). Nil
    /// when the screen has no such scroll view or the status has no page.
    func auditScrollPage() -> (page: Int, of: Int)? {
        guard let root = try? app.snapshot() else { return nil }
        let window = app.windows.firstMatch.frame
        var scrollers: [XCUIElementSnapshot] = []
        func walk(_ element: XCUIElementSnapshot) {
            if [.scrollView, .collectionView, .table].contains(element.elementType), element.frame.intersects(window),
               element.frame.height >= window.height / 3 {
                scrollers.append(element)
            }
            element.children.forEach(walk)
        }
        walk(root)
        guard let scroller = scrollers.last, let status = auditAttribute("XC_kAXXCAttributeScrollStatus", of: scroller) as? String,
              let match = status.range(of: "[Pp]age ([0-9]+) of ([0-9]+)", options: .regularExpression) else { return nil }
        let numbers = status[match].split(separator: " ").compactMap { Int($0) }
        return numbers.count == 2 ? (numbers[0], numbers[1]) : nil
    }

    /// One attribute of the element in `snapshot`, read with XCTest's
    /// accessibility client (`XCUIDevice.accessibilityInterface`, class
    /// `XCAXClient_iOS`): XCTest has no public API for it. Nil when this
    /// XCTest has no such client.
    func auditAttribute(_ key: String, of snapshot: XCUIElementSnapshot) -> Any? {
        guard (snapshot as AnyObject).responds(to: NSSelectorFromString("accessibilityElement")),
              let element = (snapshot as AnyObject).value(forKey: "accessibilityElement") as? NSObject else { return nil }
        return auditAttributes([key], of: element)?[key]
    }

    /// The attributes `keys` of the accessibility element `element` (class
    /// `XCAccessibilityElement`), read with XCTest's accessibility client.
    /// Nil when this XCTest has no such client.
    func auditAttributes(_ keys: [String], of element: NSObject) -> NSDictionary? {
        let device = XCUIDevice.shared as NSObject
        guard device.responds(to: NSSelectorFromString("accessibilityInterface")),
              let client = device.value(forKey: "accessibilityInterface") as? NSObject else { return nil }
        let selector = NSSelectorFromString("attributesForElement:attributes:error:")
        guard client.responds(to: selector) else { return nil }
        // The error is an autoreleased out-parameter (`NSError **`). With a
        // plain `UnsafeMutablePointer` Swift released it once more, and the
        // test runner crashed when a call failed (8 October 2026).
        typealias Attributes = @convention(c) (NSObject, Selector, NSObject, NSArray, AutoreleasingUnsafeMutablePointer<NSError?>?) -> NSDictionary?
        let attributes = unsafeBitCast(client.method(for: selector), to: Attributes.self)
        var error: NSError?
        return attributes(client, selector, element, keys as NSArray, &error)
    }

    /// The label and the frame of the accessibility element of an issue
    /// that has no `XCUIElement`. XCTest keeps that element in the issue's
    /// private field `axElement` (for some issues it is nil too), and its
    /// accessibility client reads its label and its frame (8 October 2026,
    /// Xcode 27.0).
    func auditAXElement(of issue: XCUIAccessibilityAuditIssue) -> (label: String, frame: CGRect)? {
        let object = issue as NSObject
        guard object.responds(to: NSSelectorFromString("axElement")), let element = object.value(forKey: "axElement") as? NSObject,
              let result = auditAttributes(["XC_kAXXCAttributeLabel", "XC_kAXXCAttributeFrame"], of: element) else { return nil }
        let label = result["XC_kAXXCAttributeLabel"] as? String ?? ""
        var frame = CGRect.null
        switch result["XC_kAXXCAttributeFrame"] {
        case let value as NSValue: frame = value.cgRectValue
        case let value as NSDictionary: frame = CGRect(dictionaryRepresentation: value as CFDictionary) ?? .null
        case let value as String: frame = NSCoder.cgRect(for: value)
        default: break
        }
        return (label, frame)
    }

    /// The fields of an audit issue that XCTest does not make public, as
    /// "name=value" (each value cut at 120 characters), for the log of an
    /// issue with no element. The public fields and the nil ones are left
    /// out.
    func auditIssueFields(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let object = issue as NSObject
        let skip: Set<String> = ["element", "auditType", "compactDescription", "detailedDescription", "hash", "superclass",
                                 "description", "debugDescription", "application"]
        var parts: [String] = []
        var current: AnyClass? = type(of: object)
        while let cls = current, cls != NSObject.self {
            var count: UInt32 = 0
            if let list = class_copyPropertyList(cls, &count) {
                for index in 0..<Int(count) {
                    let name = String(cString: property_getName(list[index]))
                    guard !skip.contains(name), object.responds(to: NSSelectorFromString(name)),
                          let value = object.value(forKey: name) else { continue }
                    parts.append("\(name)=\(String(describing: value).replacingOccurrences(of: "\n", with: " ").prefix(120))")
                }
                free(list)
            }
            current = class_getSuperclass(cls)
        }
        return parts.joined(separator: "; ")
    }

    /// Where the walk of a screen ended.
    enum AuditWalkEnd {
        /// Two drags, a drag from the middle and a swipe did not move the
        /// content.
        case stopped
        /// The walk ran its `pages` audits.
        case pageCap
    }

    /// What the walk of one screen keeps from page to page (`audit`).
    struct AuditWalk {
        /// The keys of the issues with a final decision
        /// ("<type>|<compact>|<label>|<detail>"). When a later page finds
        /// the same issue again, the log gives it a line "again" and the
        /// test does not decide it again.
        var decided = Set<String>()
        /// The contrast issues of elements that a bar covered in part as
        /// the audit ran, by element (`auditElementKey`), while no audit
        /// page has shown the element clear of the bars. At the end of the
        /// walk each issue that is still here fails the test: no audit
        /// measured the element on its own background.
        var underABar: [String: AuditFinding] = [:]
        /// The elements (`auditElementKey`) that a contrast audit page
        /// showed clear of the bars.
        var shownClear = Set<String>()
        /// The labels of the content that showed, in whole or in part, in
        /// the clear part of the screen as an audit page started.
        var auditedLabels = Set<String>()
    }

    /// The key of an element from page to page: its label, its left edge,
    /// its width and its height. The top of the element changes with each
    /// scroll. Two controls with the same label, place and size (the
    /// "Call" control of each number on the support sheet) have one key:
    /// they have the same text, colours and size, so a measure of one is a
    /// measure of the other.
    static func auditElementKey(_ label: String, _ frame: CGRect) -> String {
        "\(label)|\(Int(frame.minX.rounded()))|\(Int(frame.width.rounded()))|\(Int(frame.height.rounded()))"
    }

    /// Runs the audit on the screen that shows, then scrolls down and runs
    /// it again on each page with new content, until the content stops or
    /// `pages` audits ran. An issue that two audits find gets its decision
    /// once; the log gives each later copy a line "again". Each audit also
    /// runs the label check (`unlabelledControls`) and the hit-area check
    /// (`smallControls`).
    ///
    /// The audit itself can move the content: at AX5 it put a scroll view
    /// back at its top, and it left a list some rows back (8 October 2026,
    /// iOS 27.0 simulator). So the test does not count on the place: it
    /// drags until the screen shows a label that no audit page showed, or
    /// until no drag moves the content.
    ///
    /// `last` is the label of the screen's last element (or the start of
    /// it, when `lastIsPrefix`). A walk that stops is not proof that it
    /// reached the end (on onboarding screen 3 at AX5 the drags stopped
    /// above "Quiet hours"). So after the walk the test checks that an
    /// audit page showed `last`. If none did, it scrolls to `last`, audits
    /// that page, and walks back up until it meets content that an audit
    /// page showed. A walk that ran its `pages` audits and did not reach
    /// `last` fails the test: raise `pages`.
    ///
    /// A contrast issue of an element that a bar covers in part stays open
    /// until a later page shows the element clear of the bars
    /// (`AuditWalk.underABar`). At the end of the walk, each issue that
    /// is still open fails the test.
    func audit(_ screen: String, size: AuditTextSize, dark: Bool = false, types: XCUIAccessibilityAuditType = .all, pages: Int = 1,
               last: String? = nil, lastIsPrefix: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        var walk = AuditWalk()
        var view = auditReadScreen(screen, size: size)
        var shownLabels = auditLabels(view)
        var stopView = shownLabels
        let fraction: CGFloat = size == .largest ? 0.85 : 0.7
        var drags = 0
        // At AX5 each audit put the content back at its top (8 October
        // 2026), so the walk to page n drags n - 1 times again.
        let maxDrags = max(pages, 1) * 4 + pages * pages / 2
        var lastShown = false
        var furthest: (page: Int, of: Int)?
        func noteLast(_ items: [AuditItem]) {
            if let position = auditScrollPage(), position.page >= (furthest?.page ?? 0) { furthest = position }
            guard let last, !lastShown else { return }
            let clear = auditClearArea()
            // Shown as the walk counts a label shown: its middle is clear of
            // the bars (`auditLabels`). The last element can be of any type
            // (a combined control is "other"), so this looks at the whole tree.
            if look().contains(where: { item in
                (lastIsPrefix ? item.label.hasPrefix(last) : item.label == last) && clear.showsMiddle(of: item.label, item.frame)
            }) { lastShown = true }
        }
        var end = AuditWalkEnd.pageCap
        var audited = 0
        for page in 0..<max(pages, 1) {
            if page > 0 {
                var before = view
                var newContent = false
                var stillDrags = 0
                while drags < maxDrags {
                    // A drag from the left margin. When the content does
                    // not move, the test tries a drag from the middle of
                    // the screen, then a swipe, before it takes the end.
                    let middle = app.windows.firstMatch.frame.midX
                    if stillDrags == 2 { app.swipeUp() } else { auditScrollDown(fraction: fraction, x: stillDrags == 1 ? middle : 8) }
                    drags += 1
                    // The list can still move for a moment after the drag.
                    usleep(stillDrags == 2 ? 800_000 : 600_000)
                    let now = auditReadScreen(screen, size: size)
                    if now == before {
                        stillDrags += 1
                        if stillDrags < 3 { continue }
                        auditLog("  (\(screen), \(size.rawValue): drag \(drags) did not move the content)")
                        end = .stopped
                        break
                    }
                    stillDrags = 0
                    view = now
                    // A drag that shows no new label still reaches content
                    // that an audit page showed, so it counts for the end.
                    noteLast(now)
                    let nowShown = auditLabels(now)
                    if !nowShown.isSubset(of: shownLabels) {
                        stopView = nowShown
                        shownLabels.formUnion(nowShown)
                        newContent = true
                        break
                    }
                    before = now
                }
                if !newContent {
                    if drags >= maxDrags, end != .stopped { auditLog("  (\(screen), \(size.rawValue): \(drags) drags and no new content)") }
                    if end != .stopped { end = .stopped }
                    break
                }
            }
            noteLast(view)
            let name = page == 0 ? screen : "\(screen), page \(page + 1)"
            auditPage(name, screen: screen, size: size, dark: dark, types: types, walk: &walk)
            audited += 1
        }
        if let last, !lastShown {
            if end == .pageCap {
                let message = "\(screen) (\(size.rawValue)\(dark ? ", dark mode" : "")): the walk ran its \(pages) audits and did not reach the last element \"\(last)\": raise `pages`"
                auditLog("  WALK: \(message)")
                Self.auditFailures.append(message)
            } else {
                auditLog("  (\(screen), \(size.rawValue): the walk stopped before the last element \"\(last)\"; the test scrolls to it)")
            }
            auditReachTheEnd(screen, size: size, dark: dark, types: types, last: last, lastIsPrefix: lastIsPrefix,
                             stopView: stopView, shown: shownLabels, walk: &walk)
        } else if last == nil, let furthest, furthest.page < furthest.of {
            // No last element named: the scroll status of the content
            // tells that content is still below the last audit page.
            let message = "\(screen) (\(size.rawValue)\(dark ? ", dark mode" : "")): the walk " +
                (end == .pageCap ? "ran its \(pages) audits" : "stopped") +
                " at page \(furthest.page) of \(furthest.of) of the content: " + (end == .pageCap ? "raise `pages`" : "name the screen's last element (`last`)")
            auditLog("  WALK: \(message)")
            Self.auditFailures.append(message)
        }
        if size == .largest {
            auditSweepBack(screen, size: size, dark: dark, types: types, maxDrags: max(pages, 1) * 5, walk: &walk)
        }
        // The contrast issues that stayed under a bar on every page.
        for (_, finding) in walk.underABar.sorted(by: { $0.key < $1.key }) {
            let message = "\(finding.text): no audit page showed the element clear of the bars, so no audit measured its contrast on its own background"
            auditLog("  ISSUE: \(message)")
            Self.auditFailures.append(message)
        }
        let position = furthest.map { "; the furthest audit page was page \($0.page) of \($0.of)" } ?? ""
        auditLog("  (\(screen), \(size.rawValue)\(dark ? ", dark" : ""): \(audited) audit pages\(position)\(last.map { "; the last element \"\($0)\" \(lastShown ? "shown" : "not shown by the walk")" } ?? ""))")
        if size == .largest, !dark { auditFindMissingHeights(on: screen) }
    }

    /// The walk stopped before the last element `last`. Scrolls to it and
    /// audits that page ("<screen>, the end"). Then it goes back up a page
    /// at a time from the end, and audits each page with content that no
    /// audit page showed (`shown`), until a page meets the content where
    /// the walk stopped (`stopView`): two of the same labels, or one label
    /// of more than 20 characters. (One short label, for example "No" on a
    /// form with many questions, can show on many pages.) An audit can put
    /// the content back at its top, so each step starts again from the
    /// end. Fails the test when no scroll shows `last`.
    func auditReachTheEnd(_ screen: String, size: AuditTextSize, dark: Bool, types: XCUIAccessibilityAuditType, last: String, lastIsPrefix: Bool,
                          stopView: Set<String>, shown shownBefore: Set<String>, walk: inout AuditWalk) {
        let predicate = lastIsPrefix ? NSPredicate(format: "label BEGINSWITH %@", last) : NSPredicate(format: "label == %@", last)
        let target = app.descendants(matching: .any).matching(predicate).firstMatch
        func goToTheEnd() -> Bool {
            guard scrollTo(target, maxSwipes: 20) else { return false }
            // Clear of the bar at the bottom, so that the audit sees it whole.
            auditScrollDown(fraction: 0.3)
            usleep(600_000)
            return true
        }
        guard goToTheEnd() else {
            let message = "\(screen) (\(size.rawValue)\(dark ? ", dark mode" : "")): no scroll showed the last element \"\(last)\""
            auditLog("  WALK: \(message)")
            Self.auditFailures.append(message)
            return
        }
        var shown = shownBefore
        shown.formUnion(auditLabels(auditReadScreen(screen, size: size)))
        auditPage("\(screen), the end", screen: screen, size: size, dark: dark, types: types, walk: &walk)
        let fraction: CGFloat = size == .largest ? 0.85 : 0.7
        var previous: [AuditItem] = []
        for step in 1...10 {
            guard goToTheEnd() else { break }
            for _ in 0..<step {
                auditScrollDown(fraction: -fraction)
                usleep(600_000)
            }
            let now = auditReadScreen(screen, size: size)
            if now == previous { break } // the top
            previous = now
            let content = auditLabels(now)
            let common = content.intersection(stopView)
            if !content.isSubset(of: shown) {
                auditPage("\(screen), the end, back \(step)", screen: screen, size: size, dark: dark, types: types, walk: &walk)
                shown.formUnion(content)
            }
            if common.count >= 2 || common.contains(where: { $0.count > 20 }) { break }
        }
    }

    /// At AX5 the audit itself can move a list, forward as well as back.
    /// On the support sheet it moved the list past "Opening hours are on
    /// Beat's website." and "Beat webchat" two times, so no audit page
    /// showed them (8 October 2026). So after the walk this goes back up
    /// from where the walk ended, with short, slow drags, and audits each
    /// page that shows a label that no audit page showed, not even in part
    /// (`AuditWalk.auditedLabels`) ("<screen>, back <n>"), until the
    /// content stops (the top). A short drag at the top of a sheet springs
    /// back; it does not close the sheet.
    func auditSweepBack(_ screen: String, size: AuditTextSize, dark: Bool, types: XCUIAccessibilityAuditType,
                        maxDrags: Int, walk: inout AuditWalk) {
        var before = auditReadScreen(screen, size: size)
        var audited = 0
        for _ in 0..<maxDrags {
            auditScrollDown(fraction: -0.3)
            usleep(600_000)
            let now = auditReadScreen(screen, size: size)
            if now == before { break } // the top
            before = now
            let missed = auditLabels(now).subtracting(walk.auditedLabels)
            if !missed.isEmpty {
                audited += 1
                auditLog("  (\(screen), \(size.rawValue): no audit page showed \(missed.sorted().prefix(3)); the test audits this page)")
                auditPage("\(screen), back \(audited)", screen: screen, size: size, dark: dark, types: types, walk: &walk)
                // The audit can move the content again.
                before = auditReadScreen(screen, size: size)
            }
        }
    }

    /// The decision about one issue (`auditDecide`).
    enum AuditDecision {
        case excluded(String)
        case knownFault(AuditKnownDefect)
        case compare
        case issue(String)
    }

    /// Decides one issue: an exclusion, a known fault, a check at the end
    /// of the test (`compare`), or a failure. `taken` counts, on this
    /// page, the issues that each pinned entry took, and an entry takes
    /// no more than its pinned count (`AuditElementlessExclusion.pins`).
    func auditDecide(_ finding: AuditFinding, pinKey: String, size: AuditTextSize, dark: Bool, taken: inout [String: Int]) -> AuditDecision {
        if let exclusion = Self.auditExclusions.first(where: { $0.matches(finding) }) {
            return .excluded(exclusion.reason)
        }
        var overCount: [String] = []
        for (index, exclusion) in Self.auditElementlessExclusions.enumerated() where exclusion.matches(finding, pinKey: pinKey) {
            let key = "elementless \(index)"
            let pin = exclusion.pins[pinKey] ?? 0
            if taken[key, default: 0] < pin {
                taken[key, default: 0] += 1
                return .excluded(exclusion.reason)
            }
            overCount.append("entry \(index + 1) of auditElementlessExclusions takes at most \(pin) on one page of \(pinKey)")
        }
        for defect in Self.auditKnownDefects where defect.matches(finding) {
            guard let pins = defect.pins else { return .knownFault(defect) }
            guard let pin = pins[pinKey] else { continue }
            let key = "defect \(defect.bead)"
            if taken[key, default: 0] < pin {
                taken[key, default: 0] += 1
                return .knownFault(defect)
            }
            overCount.append("\(defect.bead) takes at most \(pin) on one page of \(pinKey)")
        }
        if !dark, finding.hasFrame,
           finding.type.contains(.dynamicType) || (size == .standard && finding.type.contains(.textClipped)),
           let label = finding.label, !label.isEmpty, (finding.frame?.height ?? 0) > 0 {
            return .compare
        }
        return .issue(overCount.isEmpty ? finding.text : "\(finding.text) (more of these on the page than the pinned count: \(overCount.joined(separator: "; ")))")
    }

    /// Runs the audit once on the page that shows (`name`), and decides
    /// each issue: an exclusion, a known fault, a check at the end of the
    /// test, or a failure. A contrast issue of an element that a bar
    /// covers in part stays open in `walk` (`AuditWalk.underABar`). Each
    /// issue with no element keeps the page's screenshot in
    /// `OUT_DIR/audit-shots` and in the result bundle. Each issue gets one
    /// line in the log.
    func auditPage(_ name: String, screen: String, size: AuditTextSize, dark: Bool, types: XCUIAccessibilityAuditType, walk: inout AuditWalk) {
        // The screen as the audit starts. The audit can move the content
        // (at AX5 it put a scroll view back at its top), so the texts under
        // the bars, and the elements clear of the bars, come from this
        // look, not from the look after the audit.
        let screenBefore = XCUIScreen.main.screenshot()
        let clearBefore = auditClearArea()
        let underBars = auditTextUnderBars(clearBefore)
        for item in clearBefore.content where item.frame.maxY > clearBefore.top && item.frame.minY < clearBefore.bottom {
            walk.auditedLabels.insert(item.label)
        }
        walk.auditedLabels.formUnion(clearBefore.pinnedItems.map(\.label))
        var findings: [AuditFinding] = []
        do {
            try app.performAccessibilityAudit(for: types) { issue in
                let element = issue.element
                let ax = element == nil ? self.auditAXElement(of: issue) : nil
                var finding = AuditFinding(
                    screen: name, size: size, dark: dark, type: issue.auditType, compact: issue.compactDescription,
                    detail: issue.detailedDescription, elementType: element?.elementType, label: element?.label ?? ax?.label,
                    identifier: element?.identifier, frame: element?.frame ?? ax?.frame, enabled: element?.isEnabled ?? true)
                if element == nil {
                    finding.fields = self.auditIssueFields(issue)
                    finding.viaAX = ax != nil
                }
                findings.append(finding)
                // The test reports each issue itself, below, so that one
                // failure lists every issue with its element. This return
                // value only stops the audit's own report.
                return true
            }
        } catch {
            Self.auditFailures.append("\(name) (\(size.rawValue)): the audit did not run: \(error)")
            return
        }
        let clear = auditClearArea()
        let screenshot = XCUIScreen.main.screenshot()
        if findings.contains(where: { $0.type.contains(.contrast) && $0.hasFrame }), let image = screenshot.image.cgImage {
            let scale = CGFloat(image.width) / max(app.windows.firstMatch.frame.width, 1)
            let root = try? app.snapshot()
            for index in findings.indices where findings[index].type.contains(.contrast) && findings[index].hasFrame {
                let result = measureContrast(of: findings[index], in: image, scale: scale, root: root)
                findings[index].measured = result.lowest
                findings[index].measuredParts = result.parts
            }
        }
        let window = app.windows.firstMatch.frame
        let toolbarItems = clear.barItems.filter { $0.frame.minY > window.height * 0.8 && $0.frame.maxY <= window.maxY }.map(\.label)
        for index in findings.indices {
            if findings[index].elementType == nil {
                findings[index].textUnderBars = underBars
                findings[index].toolbarItems = toolbarItems
            }
            guard findings[index].hasFrame, let frame = findings[index].frame, let label = findings[index].label else { continue }
            // An issue with only an accessibility element: its frame says
            // if it is under a bar; it is content when it is not a bar item.
            let isContent = clear.content.contains { $0.label == label && $0.frame.integral == frame.integral }
                || (findings[index].viaAX && !clear.barItems.contains { $0.frame.integral == frame.integral })
            findings[index].underABar = isContent && (!clear.isClearOfBars(label, frame) || !frame.intersects(window) || frame.maxY > window.maxY + 1)
            findings[index].inABar = clear.barItems.contains { $0.label == label && $0.frame.integral == frame.integral }
        }
        if !dark {
            findings += unlabelledControls(on: name, size: size)
            findings += smallControls(on: name, size: size)
        }
        let elementless = findings.filter { $0.elementType == nil }.count
        auditLog("AUDIT \(name) (\(size.rawValue)\(dark ? ", dark" : "")): \(findings.count) issues\(elementless > 0 ? ", \(elementless) with no element" : "")")
        let pinKey = Self.auditPinKey(screen, size: size, dark: dark)
        var taken: [String: Int] = [:]
        var failed = false
        var elementlessIndex = 0
        for finding in findings {
            // An issue with no element has no label to tell two of them
            // apart, so each one keeps its own key: the page and its number.
            var key = "\(finding.type.rawValue)|\(finding.compact)|\(finding.label ?? "-")|\(finding.detail)"
            if finding.elementType == nil {
                elementlessIndex += 1
                key += "|\(name)|\(elementlessIndex)"
            }
            if size == .largest, finding.type.contains(.textClipped), let label = finding.label {
                Self.auditClippedAtLargest.insert("\(screen)|\(label)")
            }
            guard !walk.decided.contains(key) else {
                auditLog("  again: \(finding.shortText) (decided on an earlier page)")
                continue
            }
            // A contrast issue of an element that a bar covers in part: the
            // audit measured the bar over the text. It waits for a page that
            // shows the element clear.
            if finding.type.contains(.contrast), finding.underABar, let label = finding.label, let frame = finding.frame {
                let element = Self.auditElementKey(label, frame)
                if walk.shownClear.contains(element) {
                    auditLog("  excluded: \(finding.text) [\(Self.underABarShownReason)]")
                    walk.decided.insert(key)
                } else {
                    if walk.underABar[element] == nil { walk.underABar[element] = finding }
                    auditLog("  open: \(finding.text) [\(Self.underABarPendingReason)]")
                }
                continue
            }
            walk.decided.insert(key)
            switch auditDecide(finding, pinKey: pinKey, size: size, dark: dark, taken: &taken) {
            case .excluded(let reason):
                auditLog("  excluded: \(finding.text) [\(reason)]")
            case .knownFault(let defect):
                auditLog("  known fault \(defect.bead): \(finding.text)")
                // An expected failure still stops a test that has
                // `continueAfterFailure` false, so the test goes on
                // through this one record.
                let stops = continueAfterFailure
                continueAfterFailure = true
                XCTExpectFailure("\(defect.bead): \(defect.reason)") {
                    XCTFail(finding.text)
                }
                continueAfterFailure = stops
            case .compare:
                // Decided at the end of the test, from the same element
                // at the other text size (`auditAtEachTextSize`).
                auditLog("  to compare: \(finding.text)")
                Self.auditScalingChecks.append((finding, screen))
            case .issue(let text):
                auditLog("  ISSUE: \(text)")
                Self.auditFailures.append(text)
                failed = true
            }
        }
        // The contrast audit checked each element that showed clear of the
        // bars as it started. Such an element closes its open issue from an
        // earlier page: the audit flagged it here (and the test decided
        // that issue above), or found nothing wrong with it.
        if types.contains(.contrast) {
            let flaggedUnderABar = Set(findings.filter { $0.type.contains(.contrast) && $0.underABar }.compactMap { finding in
                finding.label.flatMap { label in finding.frame.map { Self.auditElementKey(label, $0) } }
            })
            for item in clearBefore.content where item.frame.height > 0 && item.frame.maxY <= window.maxY + 1 && clearBefore.isClearOfBars(item.label, item.frame) {
                let element = Self.auditElementKey(item.label, item.frame)
                guard !flaggedUnderABar.contains(element) else { continue }
                walk.shownClear.insert(element)
                if let open = walk.underABar.removeValue(forKey: element) {
                    auditLog("  closed: \(open.shortText) of \(open.screen): \"\(item.label)\" shows clear of the bars on \(name), and the contrast audit checked it there")
                }
            }
        }
        let environment = ProcessInfo.processInfo.environment
        if failed || elementless > 0 || environment["AUDIT_SHOTS"] == "1" {
            // The screen of each audit with an issue, and of each audit
            // with an issue that has no element (excluded or not), so that
            // a person can see what the audit read: as the audit started,
            // and after it. The result bundle keeps both;
            // `OUT_DIR/audit-shots` keeps the ones with no element.
            var folders = environment["AUDIT_SHOTS_DIR"].map { [$0] } ?? []
            if elementless > 0, let out = environment["OUT_DIR"] { folders.append(out + "/audit-shots") }
            let base = "\(name) (\(size.rawValue)\(dark ? ", dark" : ""))"
            for (image, when) in [(screenBefore, "before the audit"), (screenshot, "after the audit")] {
                let shot = XCTAttachment(screenshot: image)
                shot.name = "\(base), \(when)"
                shot.lifetime = .keepAlways
                add(shot)
                let file = (shot.name ?? "audit").replacingOccurrences(of: "/", with: "-") + ".png"
                for folder in folders {
                    try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
                    try? image.pngRepresentation.write(to: URL(fileURLWithPath: folder).appendingPathComponent(file))
                }
            }
            if elementless > 0 { auditLog("  (the screen of \(name) is in audit-shots/\(base), before the audit.png and after the audit.png)") }
        }
    }

    /// The default-size audit of `screen` flagged some elements for the
    /// Dynamic Type check, and the AX5 walk must see each of them. When the
    /// audit moved the list, the walk can miss a row. So this scrolls back
    /// up with short, slow drags until the walk has seen each one, or until
    /// the content no longer moves (the top). A short drag at the top of a
    /// sheet springs back; it does not close the sheet.
    func auditFindMissingHeights(on screen: String) {
        let key = "\(AuditTextSize.largest.rawValue)|\(screen)"
        func missing() -> Set<String> {
            Set(Self.auditScalingChecks.filter { $0.screen == screen }.compactMap(\.finding.label))
                .filter { Self.auditHeights[key]?[$0] == nil }
        }
        guard !missing().isEmpty else { return }
        var before = auditReadScreen(screen, size: .largest)
        for _ in 0..<20 {
            guard !missing().isEmpty else { return }
            let clear = auditClearArea()
            let window = app.windows.firstMatch.frame
            let top = max(clear.top, window.minY) + 10
            let bottom = min(clear.bottom, window.maxY) - 10
            guard bottom - top > 60 else { return }
            let origin = app.coordinate(withNormalizedOffset: .zero)
            origin.withOffset(CGVector(dx: 8, dy: top))
                .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: 8, dy: top + (bottom - top) * 0.3)), withVelocity: .slow, thenHoldForDuration: 0.1)
            usleep(800_000)
            let now = auditReadScreen(screen, size: .largest)
            if now == before { break }
            before = now
        }
        if !missing().isEmpty { auditLog("  (\(screen), AX5: the walk did not see \(missing().sorted()))") }
    }

    /// The height of a button at the default text size when the 44-point
    /// minimum of its hit area (`minimumHitArea`) sets it: the label alone,
    /// or the label in a list row (44 points and the row's insets, 31
    /// points: "Beat webchat" on the support sheet, the notification line
    /// on Today, 8 October 2026).
    static let minimumHitAreaHeights: [CGFloat] = [44, 75]

    /// Two frames of the same control: each edge within one point. The
    /// frames of a SwiftUI menu and of the system button inside it can
    /// differ by a fraction of a point ("Day options" at y 675.99 and the
    /// button inside it at y 676.0, 8 October 2026), so `integral` gives
    /// them different frames.
    static func sameFrame(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= 1 && abs(a.minY - b.minY) <= 1 && abs(a.width - b.width) <= 1 && abs(a.height - b.height) <= 1
    }

    /// product-rules "Accessibility everywhere": "Every control MUST have a
    /// VoiceOver label." The audit does not report a text field that has a
    /// placeholder and no label, but VoiceOver reads no name for it when it
    /// holds a value. So each control that VoiceOver stops on, outside the
    /// keyboard, must have a label of its own. A segmented control and a
    /// compact date picker are containers: VoiceOver stops on each segment
    /// and on the picker's button, and each of those must have a label. A
    /// SwiftUI toggle holds an inner switch with no label; VoiceOver stops
    /// on the toggle, which must have a label. A wheel of a system date
    /// picker has no label of its own (VoiceOver reads its value); the
    /// record's time control hides its wheels and is one element, "Time".
    /// A SwiftUI menu ("Day options") shows as two buttons with the same
    /// frame: the menu with its label, and the system button inside it with
    /// none. The label of the menu names that control.
    func unlabelledControls(on screen: String, size: AuditTextSize) -> [AuditFinding] {
        guard let snapshot = try? app.snapshot() else { return [] }
        let controls: Set<XCUIElement.ElementType> = [
            .button, .switch, .toggle, .textField, .secureTextField, .textView, .slider, .stepper,
            .link, .menuButton, .searchField,
        ]
        let window = app.windows.firstMatch.frame
        var labelledFrames: [CGRect] = []
        // The labelled buttons in the bottom 120 points: the items of
        // Today's bottom toolbar ("Programme", "Reviews").
        var bottomBarFrames: [CGRect] = []
        func collect(_ element: XCUIElementSnapshot) {
            if controls.contains(element.elementType), !element.label.isEmpty {
                labelledFrames.append(element.frame)
                if element.elementType == .button, element.frame.minY >= window.maxY - 120 { bottomBarFrames.append(element.frame) }
            }
            element.children.forEach(collect)
        }
        collect(snapshot)
        var found: [AuditFinding] = []
        func walk(_ element: XCUIElementSnapshot, inLabelledSwitch: Bool) {
            if element.elementType == .keyboard { return }
            let isInnerSwitch = element.elementType == .switch && inLabelledSwitch
            if controls.contains(element.elementType), !isInnerSwitch, element.label.isEmpty, element.frame.width > 0,
               element.frame.intersects(window), !labelledFrames.contains(where: { Self.sameFrame($0, element.frame) }) {
                // The test takes only a button in the bottom 120 points, in
                // one row with the labelled items of the toolbar.
                let inTheToolbarRow = element.frame.minY >= window.maxY - 120
                    && bottomBarFrames.contains { abs($0.midY - element.frame.midY) <= 12 }
                if size == .largest, element.elementType == .button, inTheToolbarRow {
                    // At AX5 the bottom toolbar of Today has no room for all
                    // its items, and iOS adds its own overflow button ("•••")
                    // with a menu of the other items (8 October 2026, iOS
                    // 27.0 simulator). The app does not make that button and
                    // cannot set its label. At the default size every item of
                    // the toolbar shows, and this check covers each one.
                    auditLog("  (\(screen) (AX5): the toolbar's own overflow button at \(element.frame.integral) has no label; iOS makes it)")
                } else {
                    found.append(AuditFinding(
                        screen: screen, size: size, dark: false, type: [], compact: "Control with no label",
                        detail: "the control has no accessibility label (placeholder \"\(element.placeholderValue ?? "")\", value \"\(element.value as? String ?? "")\", identifier \"\(element.identifier)\")",
                        elementType: element.elementType, label: element.label, identifier: element.identifier, frame: element.frame))
                }
            }
            let labelledSwitch = inLabelledSwitch || (element.elementType == .switch && !element.label.isEmpty)
            element.children.forEach { walk($0, inLabelledSwitch: labelledSwitch) }
        }
        walk(snapshot, inLabelledSwitch: false)
        return found
    }

    /// product-rules "Accessibility everywhere": "Every control MUST have a
    /// hit area of at least 44 by 44 points." The audit's hit-region check
    /// reported nothing on any screen (8 October 2026), so this check
    /// measures each control itself. Each enabled control on the page that
    /// VoiceOver stops on, outside the navigation bar, the toolbar and the
    /// keyboard, must have a frame of at least 44 by 44 points. The frame
    /// of a SwiftUI button is its tap target: a frame on the button's label
    /// gives both the size (`minimumHitArea` in Appearance.swift). The
    /// system bars are left out: iOS sets the size of a bar item. A control
    /// with no label inside a labelled control of the same frame (the
    /// system button inside a SwiftUI menu) is the same control. Each issue
    /// goes through the same decisions as an audit issue:
    /// `auditHitAreaExclusions` takes a system control whose size iOS sets,
    /// with its reason, and `auditHitAreaKnownDefects` takes a fault that a
    /// bead holds.
    func smallControls(on screen: String, size: AuditTextSize) -> [AuditFinding] {
        guard let snapshot = try? app.snapshot() else { return [] }
        let controls: Set<XCUIElement.ElementType> = [
            .button, .switch, .toggle, .textField, .secureTextField, .textView, .slider, .stepper,
            .link, .menuButton, .popUpButton, .searchField,
        ]
        // The system controls that hold other controls (`AuditFinding.container`).
        let systemContainers: Set<XCUIElement.ElementType> = [.segmentedControl, .datePicker, .picker, .pickerWheel, .switch, .stepper]
        let window = app.windows.firstMatch.frame
        var labelledFrames: [CGRect] = []
        func collect(_ element: XCUIElementSnapshot) {
            if controls.contains(element.elementType), !element.label.isEmpty { labelledFrames.append(element.frame) }
            element.children.forEach(collect)
        }
        collect(snapshot)
        // XCTest cuts the frame of an element at the edge of its scroll view
        // ("When are the hardest times of day?" at 338 by 10 points, at the
        // top of a page of the weekly review). So a control in a list or a
        // scroll view counts only when it shows whole, clear of the bars; a
        // later page shows the rest. A control outside them does not scroll.
        let clear = auditClearArea()
        var found: [AuditFinding] = []
        func walk(_ element: XCUIElementSnapshot, container: XCUIElement.ElementType?, inContent: Bool) {
            let type = element.elementType
            if [.navigationBar, .toolbar, .keyboard, .statusBar].contains(type) { return }
            let frame = element.frame
            let sameAsLabelled = element.label.isEmpty && labelledFrames.contains { Self.sameFrame($0, frame) }
            let whole = inContent ? clear.isClear(element.label, frame) && frame.minY >= window.minY && frame.maxY <= window.maxY
                : frame.minY >= window.minY && frame.maxY <= window.maxY
            if controls.contains(type), !sameAsLabelled, element.isEnabled, frame.width > 0, frame.height > 0, whole,
               frame.width < 43.5 || frame.height < 43.5 {
                found.append(AuditFinding(
                    screen: screen, size: size, dark: false, type: [], compact: Self.hitAreaCompact,
                    detail: String(format: "the control is %.1f by %.1f points%@", frame.width, frame.height,
                                   container.map { " (inside a system \(Self.elementTypeName($0)))" } ?? ""),
                    elementType: type, label: element.label, identifier: element.identifier, frame: frame, container: container))
            }
            let next = systemContainers.contains(type) ? type : container
            let isContainer = [.scrollView, .collectionView, .table].contains(type)
            element.children.forEach { walk($0, container: next, inContent: inContent || isContainer) }
        }
        walk(snapshot, container: nil, inContent: false)
        return found
    }

    /// A name for the element types that hold other controls.
    static func elementTypeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .segmentedControl: return "segmented control"
        case .datePicker: return "date picker"
        case .picker: return "picker"
        case .pickerWheel: return "picker wheel"
        case .switch: return "switch"
        case .stepper: return "stepper"
        default: return "element \(type.rawValue)"
        }
    }

    /// The hit-area issues of system controls whose size iOS sets, and why
    /// each one is not a fault of the app (`smallControls`).
    static let auditHitAreaExclusions: [AuditExclusion] = [
        AuditExclusion(reason: """
            A system switch (a SwiftUI Toggle). The tap target of a toggle is its switch, and iOS sets the size of \
            the switch: 63 by 28 points on the iOS 27.0 simulator, at every text size. SwiftUI gives no way to make \
            it larger. The toggle element around the switch holds its label, and VoiceOver and Voice Control use \
            that element; at the accessibility text sizes it is as high as its label.
            """) { $0.compact == hitAreaCompact && ($0.elementType == .switch || $0.container == .switch) },
        AuditExclusion(reason: """
            A segment of a system segmented control (a SwiftUI Picker with the segmented style: the day segments of \
            the record's time control, the unit controls). iOS sets the height of a segmented control, 32 points on \
            the iOS 27.0 simulator, and SwiftUI gives no way to change it. Each segment is as wide as its share of \
            the row.
            """) { $0.compact == hitAreaCompact && $0.container == .segmentedControl },
        AuditExclusion(reason: """
            A part of a system date picker (the compact button that opens the picker, or a wheel). iOS sets the size \
            of these parts, and SwiftUI gives no way to change it.
            """) { $0.compact == hitAreaCompact && ($0.container == .datePicker || $0.container == .pickerWheel || $0.container == .picker) },
    ]

    /// The hit-area issues that a bead holds (`smallControls`).
    static let auditHitAreaKnownDefects: [AuditKnownDefect] = [
        AuditKnownDefect(bead: "mm-t45.20", reason: """
            A button with the system bordered or bordered-prominent style at the regular control size is 34.3 \
            points high at the default text size. A 44-point label makes the fill around it larger too, so the change \
            needs a design decision. The entry names each such button on its screen.
            """) { finding in
            guard finding.compact == hitAreaCompact, finding.elementType == .button, let frame = finding.frame,
                  frame.height >= 30, frame.height < 43.5, frame.width >= 43.5 else { return false }
            let label = finding.label ?? ""
            func on(_ screens: String...) -> Bool { screens.contains { finding.screen == $0 || finding.screen.hasPrefix($0 + ", ") } }
            if on("the new-entry screen", "the edit screen") { return ["Home", "Work", "Out", "Travelling", "Add a place"].contains(label) }
            if finding.screen.hasPrefix("Today") { return label == "Add an entry" }
            if on("the plan builder") { return label == "Save" }
            if on("the app-lock cover") { return ["Unlock", "Delete from this device"].contains(label) }
            if on("the store-open fault screen") { return ["Try again", "Get support"].contains(label) }
            // The full-width confirming button of a form or a page
            // (FullWidthConfirmButton.swift).
            return ["Continue", "Done", "Start"].contains(label) && frame.width >= 300
        },
        AuditKnownDefect(bead: "mm-t45.21", reason: """
            A system control in a Form row is less high than 44 points at the default text size: a one-line text \
            field (SwiftUI TextField) is 22 points high, and a menu picker (SwiftUI Picker with the menu style) is \
            34.3 points high. The row around it is higher, but the control's own frame is its tap target. A taller \
            control makes each form row taller, so the change needs a design decision. The entry names each such \
            control on its screen.
            """) { finding in
            guard finding.compact == hitAreaCompact, let frame = finding.frame, frame.width >= 300, frame.height < 43.5 else { return false }
            let label = finding.label ?? ""
            func on(_ screens: String...) -> Bool { screens.contains { finding.screen == $0 || finding.screen.hasPrefix($0 + ", ") } }
            if finding.elementType == .textField, frame.height >= 20 {
                if on("onboarding screen 2", "the restart re-screen") {
                    return ["How old are you?", "Height in centimetres", "Height in feet", "Height in inches",
                            "Weight in kilograms", "Weight in stone", "Weight in pounds"].contains(label)
                }
                if on("the weigh-in screen on the weigh-in day") { return ["Weight", "Stone", "Pounds"].contains(label) }
                if on("the close-the-day screen") { return label == "One word for how today felt" }
                // Each question of the weekly review ends with a question mark.
                if on("the weekly review") { return label.hasSuffix("?") }
                return false
            }
            if finding.elementType == .button, frame.height >= 30 {
                let pickers: [String]
                if on("Settings") { pickers = ["Day starts at", "Weigh-in day", "Unit", "Lock after"] }
                else if on("the Reminders group") { pickers = ["Remind me again in"] }
                else if on("the weigh-in screen on the weigh-in day", "the weigh-in screen on a day that is not the weigh-in day") { pickers = ["Weigh-in day", "Unit"] }
                else { pickers = [] }
                return pickers.contains { label.hasPrefix($0 + ", ") }
            }
            return false
        },
    ]

    /// Runs `body` at each text size, then fails once with every issue that
    /// no exclusion took.
    ///
    /// Dynamic Type and clipped-text issues are decided here. The audit
    /// reports "Dynamic Type font sizes are partially unsupported" on
    /// SwiftUI text that does scale (for example a row in a Form), at both
    /// sizes. So the test finds the same element (the same label on the
    /// same screen) at the default size and at AX5. If it is at least 1.5
    /// times as tall at AX5, its text scales with Dynamic Type. A button
    /// whose default height is the 44-point minimum of its hit area
    /// (`minimumHitAreaHeights`) must be at least 10 points taller at AX5:
    /// its frame grows only when its text is higher than 44 points. A clipped-
    /// text issue at the default size ("may be clipped at larger Dynamic
    /// Type sizes") is decided by the AX5 audit of the same element: the
    /// issue fails the test if that audit also reports clipped text, or if
    /// the AX5 walk did not see the element. A clipped-text issue at AX5
    /// always fails the test.
    func auditAtEachTextSize(_ sizes: [AuditTextSize] = AuditTextSize.allCases, file: StaticString = #filePath, line: UInt = #line,
                             _ body: (AuditTextSize) throws -> Void) rethrows {
        Self.auditFailures = []
        Self.auditScalingChecks = []
        Self.auditClippedAtLargest = []
        Self.auditHeights = [:]
        auditLog("TEST \(name)")
        for size in sizes {
            try body(size)
        }
        for (finding, screen) in Self.auditScalingChecks {
            let label = finding.label ?? ""
            let standard = Self.auditHeights["\(AuditTextSize.standard.rawValue)|\(screen)"]?[label]
            let largest = Self.auditHeights["\(AuditTextSize.largest.rawValue)|\(screen)"]?[label]
            let heights = "\(standard.map { "\(Int($0))" } ?? "no") points high at the default size and \(largest.map { "\(Int($0))" } ?? "no") points high at AX5"
            var verdict: String?
            if finding.type.contains(.dynamicType) {
                if let standard, let largest, largest >= standard * 1.5 {
                    verdict = "the element is \(heights), so its text scales with Dynamic Type"
                } else if let standard, let largest, finding.elementType == .button,
                          Self.minimumHitAreaHeights.contains(where: { abs(standard - $0) <= 1.5 }), largest >= standard + 10 {
                    verdict = """
                        the element is \(heights). At the default size its height is the 44-point minimum of its hit area \
                        (minimumHitArea), not the height of its text (about 22 points). The frame grows only when the text \
                        is higher than 44 points, so its text is more than twice as high at AX5
                        """
                }
            } else if largest != nil, !Self.auditClippedAtLargest.contains("\(screen)|\(label)") {
                verdict = "the AX5 audit of the same element (\(heights)) reports no clipped text"
            }
            if let verdict {
                auditLog("  excluded: \(finding.text) [\(verdict)]")
            } else {
                auditLog("  ISSUE: \(finding.text) (the element is \(heights))")
                Self.auditFailures.append("\(finding.text) (the element is \(heights))")
            }
        }
        let failures = Self.auditFailures
        Self.auditFailures = []
        Self.auditScalingChecks = []
        XCTAssertEqual(failures.count, 0, "the accessibility audit found \(failures.count) issues:\n" + failures.joined(separator: "\n"), file: file, line: line)
    }

    // MARK: Helpers for the walks

    /// Answers `question` with `choice` on a long form (onboarding screen 2,
    /// the re-screen, the review). At AX5 a question can be taller than the
    /// space between the bars, so this finds the answer row under the
    /// question and shows only the row.
    func auditAnswer(_ question: String, _ choice: String, bar: String?, file: StaticString = #filePath, line: UInt = #line) {
        guard let row = reveal(bar: bar, maxDrags: 30, { self.answerRow(choice, under: question, in: $0) }) else {
            XCTFail("\"\(question)\" shows \"\(choice)\"", file: file, line: line)
            return
        }
        tap(row.frame)
    }

    /// Onboarding screen 2 with answers that exclude nothing, or with the
    /// age and weight given. The questions first, so that the keyboard
    /// does not hide them.
    func auditCompleteScreen2(age: String = "30", weight: String = "65", file: StaticString = #filePath, line: UInt = #line) {
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] {
            auditAnswer(question, "No", bar: "Continue", file: file, line: line)
        }
        fill("How old are you?", age, file: file, line: line)
        fill("Height in centimetres", "170", file: file, line: line)
        fill("Weight in kilograms", weight, file: file, line: line)
        tapConfirm(file: file, line: line)
        dismissKeyboardTipBesideAFullWidthControl()
    }

    /// Opens Settings from Today.
    func auditOpenSettings(file: StaticString = #filePath, line: UInt = #line) {
        tapToolbar("Settings")
        assertScreen("Settings", file: file, line: line)
    }

    /// Taps the button `label` after a scroll to it, and waits for the
    /// screen `title`.
    func auditOpen(_ label: String, screen title: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(scrollTo(button, maxSwipes: 20), "\"\(label)\" shows", file: file, line: line)
        button.tap()
        assertScreen(title, file: file, line: line)
    }

    /// Taps the row `label` on a long form and checks that it is then
    /// selected. At AX5 a tap just after a drag can miss, so it tries again.
    func auditChoose(_ label: String, bar: String? = "Continue", file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<3 {
            guard let row = reveal(bar: bar, maxDrags: 30, { self.first(.button, label, in: $0) }) else { break }
            tap(row.frame)
            usleep(500_000)
            if first(.button, label, in: look())?.isSelected == true { return }
        }
        XCTFail("the screen shows \"\(label)\", and a tap selects it", file: file, line: line)
    }

    /// The new-entry and edit screens put the keyboard up in "What" as they
    /// open. The keyboard then covers the end of the form ("Delete entry",
    /// the Context section) on every page, and the contrast audit cannot
    /// measure it (8 October 2026). A tap outside the field does not take
    /// the keyboard down. So this opens "Add a place" and types Return in
    /// its empty field: the field closes with no place added
    /// (`WhereChipsView.commitNewPlace`), and the keyboard goes down. Then
    /// it goes back to the top of the screen.
    func auditHideTheKeyboard(on screen: String, size: AuditTextSize, file: StaticString = #filePath, line: UInt = #line) {
        guard app.keyboards.firstMatch.waitForExistence(timeout: 3) else { return }
        let addAPlace = app.buttons["Add a place"].firstMatch
        XCTAssertTrue(auditReveal(addAPlace), "\(screen) shows \"Add a place\" (\(size.rawValue))", file: file, line: line)
        addAPlace.tap()
        let field = app.textViews["Add a place"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "\"Add a place\" opens a field (\(size.rawValue))", file: file, line: line)
        field.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "on \(screen) the keyboard goes down after Return in an empty \"Add a place\" (\(size.rawValue))", file: file, line: line)
        XCTAssertTrue(addAPlace.waitForExistence(timeout: 3), "the field closed with no place added, and \"Add a place\" shows again", file: file, line: line)
        auditScrollToTheTop(screen, size: size)
    }

    /// Short, slow drags down until the content stops: the top of the
    /// screen. A short drag at the top of a sheet springs back; it does
    /// not close the sheet.
    func auditScrollToTheTop(_ screen: String, size: AuditTextSize) {
        var before = auditReadScreen(screen, size: size)
        for _ in 0..<20 {
            auditScrollDown(fraction: -0.3)
            usleep(600_000)
            let now = auditReadScreen(screen, size: size)
            if now == before { return }
            before = now
        }
    }

    // MARK: The audits of each screen

    /// The most audits on one screen: the first view and each page with new
    /// content. At AX5 a screen is much longer.
    func auditPages(_ size: AuditTextSize, standard: Int = 4, largest: Int = 10) -> Int {
        size == .standard ? standard : largest
    }

    /// The audit types at `size`. At AX5 the contrast audit is left out: the
    /// colours do not change with the text size, so the contrast audit runs
    /// at the default size, and again in dark mode
    /// (`testAuditContrastInDarkMode`).
    func auditTypes(_ size: AuditTextSize) -> XCUIAccessibilityAuditType {
        size == .standard ? .all : XCUIAccessibilityAuditType.all.subtracting(.contrast)
    }

    /// Today: the current day with two entries and the gap band between
    /// them, the "Weekly review" line, and the previous day, collapsed
    /// (`review`).
    func testAuditTodayWithEntriesAndAGapBand() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("review", size: size)
            audit("Today with entries and a gap band", size: size, types: auditTypes(size), pages: auditPages(size))
        }
    }

    /// Today with a planned meal: the Lunch row with its matched entry
    /// (`planMatched`), and the Lunch row with the missed planned meal
    /// prompt, "Skipped" and "Add it" (`planMissed`). Then "Close the day"
    /// and its screen (`or-plan`), the plan card (`or-plancard`), the stage
    /// 1 card (`or-secondday`) and the pinned note (`or-pinned`). The
    /// stage 2 opening card is on Today in `review`
    /// (`testAuditTodayWithEntriesAndAGapBand`).
    func testAuditTodayWithPlannedMealsCardsAndTheNote() throws {
        try auditAtEachTextSize { size in
            for (scenario, screen) in [("planMatched", "Today with a matched planned meal"),
                                       ("planMissed", "Today with the missed planned meal prompt"),
                                       ("or-plan", "Today with \"Close the day\""),
                                       ("or-plancard", "Today with the plan card"),
                                       ("or-secondday", "Today with the stage 1 card"),
                                       ("or-pinned", "Today with the pinned note")] {
                try auditLaunchOnToday(scenario, size: size)
                if scenario == "or-pinned" {
                    // weekly-review spec, "Accessibility of the review": the
                    // pinned note is one element whose label is its text.
                    XCTAssertTrue(scrollTo(element(labelled: "Eat breakfast"), maxSwipes: 6), "the pinned note is one element with the label \"Eat breakfast\" (\(size.rawValue))")
                    for _ in 0..<6 { app.swipeDown() }
                }
                audit(screen, size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 8))
                if scenario == "or-plan" {
                    // The close-the-day screen (reminders, mm-t24.22 item 7).
                    let closeTheDay = app.buttons["Close the day"].firstMatch
                    XCTAssertTrue(scrollTo(closeTheDay, maxSwipes: 12), "Today shows \"Close the day\"")
                    closeTheDay.tap()
                    XCTAssertTrue(app.navigationBars["Close the day"].waitForExistence(timeout: 8), "the close-the-day screen shows")
                    audit("the close-the-day screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 10))
                }
            }
        }
    }

    /// The new-entry screen from "Add an entry", and the edit screen from a
    /// tap on the "Toast and tea" row (`review`).
    func testAuditNewEntryAndEditScreens() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("review", size: size)
            let add = app.buttons["Add an entry"].firstMatch
            XCTAssertTrue(add.waitForExistence(timeout: 8))
            add.tap()
            XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "the new-entry screen shows")
            dismissKeyboardTip()
            auditHideTheKeyboard(on: "the new-entry screen", size: size)
            audit("the new-entry screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 8))
            app.navigationBars.buttons["Cancel"].firstMatch.tap()
            XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 8))
            if size == .largest {
                // A new-entry screen from the top, for the chips.
                add.tap()
                XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "the new-entry screen shows")
                assertTheWhereChipsWrap()
                app.navigationBars.buttons["Cancel"].firstMatch.tap()
                XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForNonExistence(timeout: 8))
            }
            let row = element(labelContaining: "Toast and tea")
            XCTAssertTrue(scrollTo(row, maxSwipes: 12), "Today shows \"Toast and tea\"")
            row.tap()
            XCTAssertTrue(app.buttons["Delete entry"].firstMatch.waitForExistence(timeout: 8) || app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 2), "the edit screen shows")
            dismissKeyboardTip()
            auditHideTheKeyboard(on: "the edit screen", size: size)
            audit("the edit screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 8))
        }
    }

    /// "Earlier days" and one earlier day (`review`).
    func testAuditEarlierDays() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("review", size: size)
            tapDayMenu("Earlier days")
            assertScreen("Earlier days")
            audit("Earlier days", size: size, types: auditTypes(size), pages: auditPages(size))
            app.cells.firstMatch.tap()
            XCTAssertTrue(app.buttons["Previous day"].waitForExistence(timeout: 8), "one earlier day shows")
            audit("one earlier day", size: size, types: auditTypes(size), pages: auditPages(size, standard: 2, largest: 6))
        }
    }

    /// The plan builder at "Today's plan" with the Lunch slot planned
    /// (`planMatched`).
    func testAuditPlanBuilder() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("planMatched", size: size)
            tapDayMenu("Today's plan")
            assertScreen("Today's plan")
            audit("the plan builder", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
        }
    }

    /// Settings with each group (Record, Weigh-in, Privacy, About), the
    /// Reminders group's screen, the privacy notice and Diagnostics
    /// (`week1`).
    func testAuditSettingsScreens() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            if size == .standard { assertEachSwitchHasALabelAndAState(on: "Settings") }
            audit("Settings", size: size, types: auditTypes(size), pages: auditPages(size, standard: 6, largest: 16))
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            auditOpen("Reminders", screen: "Reminders")
            audit("the Reminders group", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
            goBack()
            assertScreen("Settings")
            auditOpen("Privacy", screen: "Privacy notice")
            audit("the privacy notice", size: size, types: auditTypes(size), pages: auditPages(size, standard: 6, largest: 16))
            goBack()
            assertScreen("Settings")
            auditOpen("Diagnostics", screen: "Diagnostics")
            audit("Diagnostics", size: size, types: auditTypes(size), pages: auditPages(size))
        }
    }

    /// settings spec, "Accessibility of the settings screen": "Every control
    /// on the settings screen MUST have a VoiceOver label ... Every switch
    /// MUST read its state." VoiceOver reads a switch's label, "switch", and
    /// its value, "on" or "off". So each switch has a label and the value
    /// "1" or "0". The test scrolls through the screen and goes back to the
    /// top.
    func assertEachSwitchHasALabelAndAState(on screen: String, file: StaticString = #filePath, line: UInt = #line) {
        var seen: [String: String] = [:]
        for scroll in 0..<8 {
            if scroll > 0 { auditScrollDown() }
            for item in look() where item.type == .switch && item.frame.width > 0 && !item.label.isEmpty {
                seen[item.label] = item.value ?? ""
            }
        }
        XCTAssertFalse(seen.isEmpty, "\(screen) shows switches", file: file, line: line)
        for (label, value) in seen {
            XCTAssertTrue(["0", "1"].contains(value), "on \(screen), the switch \"\(label)\" reads its state (\"\(value)\")", file: file, line: line)
        }
        for _ in 0..<8 { app.swipeDown() }
    }

    /// The Programme screen, the stage screen "Getting started" and the
    /// card screen "Why write it down" (`week1`).
    func testAuditProgrammeStageAndCardScreens() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            audit("Programme", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            let stage = element(labelBeginningWith: "Getting started")
            XCTAssertTrue(scrollTo(stage, maxSwipes: 12))
            stage.tap()
            assertScreen("Getting started")
            audit("the stage screen", size: size, types: auditTypes(size), pages: auditPages(size))
            // The audit scrolled down; the stage screen opens again at its top.
            goBack()
            assertScreen("Programme")
            XCTAssertTrue(scrollTo(stage, maxSwipes: 12))
            stage.tap()
            assertScreen("Getting started")
            auditOpen("Why write it down", screen: "Why write it down")
            audit("the card screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
        }
    }

    /// The weigh-in screen on the weigh-in day with the message for a weight
    /// below the range (`week1`, 5 kg, which saves nothing), on a day that
    /// is not the weigh-in day, where it shows the refusal text
    /// (`or-weighin`), and with no weigh-in day, where it shows "Choose a
    /// weigh-in day" (`review`).
    func testAuditWeighInScreen() throws {
        try auditAtEachTextSize { size in
            for (scenario, screen) in [("week1", "the weigh-in screen on the weigh-in day"),
                                       ("or-weighin", "the weigh-in screen on a day that is not the weigh-in day"),
                                       ("review", "the weigh-in screen with no weigh-in day")] {
                try auditLaunchOnToday(scenario, size: size)
                tapToolbar("Programme")
                assertScreen("Programme")
                let stage = element(labelBeginningWith: "Getting started")
                XCTAssertTrue(scrollTo(stage, maxSwipes: 12))
                stage.tap()
                assertScreen("Getting started")
                auditOpen("Weigh-in", screen: "Weigh-in")
                if scenario == "week1" {
                    let weight = app.textFields["Weight"].firstMatch
                    XCTAssertTrue(weight.waitForExistence(timeout: 5), "the weigh-in screen shows the weight input")
                    weight.tap()
                    dismissKeyboardTip()
                    weight.typeText("5")
                    let save = app.buttons["Save"].firstMatch
                    XCTAssertTrue(scrollTo(save, maxSwipes: 8))
                    save.tap()
                    XCTAssertTrue(element(labelBeginningWith: "That number is outside the range").waitForExistence(timeout: 5), "5 kg shows the message for a weight outside the range")
                    // The walk goes down from the page that shows, so it
                    // starts at the top, above "Save".
                    auditScrollToTheTop(screen, size: size)
                }
                audit(screen, size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
            }
        }
    }

    /// The "Reviews" list, the weekly review, the GP suggestion page and
    /// the not-right-now page (`review`).
    func testAuditWeeklyReviewAndItsPages() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("review", size: size)
            tapToolbar("Reviews")
            assertScreen("Reviews")
            audit("the Reviews list", size: size, types: auditTypes(size), pages: auditPages(size, standard: 2, largest: 6))
            goBack()
            assertScreen("Today")
            openTheDueReview()
            // weekly-review spec, "Accessibility of the review": each summary
            // sentence is one element whose label is the sentence.
            let summary = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Days with an entry: ", ".")).firstMatch
            XCTAssertTrue(summary.waitForExistence(timeout: 5), "the first summary sentence is one element, \"Days with an entry: <n>.\" (\(size.rawValue))")
            audit("the weekly review", size: size, types: auditTypes(size), pages: auditPages(size, standard: 8, largest: 24))
            try auditLaunchOnToday("review", size: size)
            openTheDueReview()
            tapGettingWorse()
            XCTAssertTrue(element(labelled: "It might help to see your GP").waitForExistence(timeout: 8), "the GP suggestion page shows")
            audit("the GP suggestion page", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
            try auditLaunchOnToday("review", size: size)
            openTheDueReview()
            auditAnswer(Self.selfHarmQuestion, "Yes", bar: "Done")
            auditAnswer(Self.selfHarmStep2Question, "Yes", bar: "Done")
            XCTAssertTrue(element(labelled: "This may not be right for you now").waitForExistence(timeout: 8), "the not-right-now page shows")
            audit("the not-right-now page", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
        }
    }

    /// The export screen from Settings (`week1`).
    func testAuditExportScreen() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            auditOpen("Export", screen: "Export")
            audit("the export screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 10))
        }
    }

    /// The support sheet from Today (`week1`).
    func testAuditSupportSheet() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("week1", size: size)
            getSupport(on: "Today").tap()
            assertScreen("Get support")
            audit("the support sheet", size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
            if size == .largest {
                app.navigationBars["Get support"].buttons["Close"].tap()
                XCTAssertTrue(app.navigationBars["Get support"].waitForNonExistence(timeout: 5))
                getSupport(on: "Today").tap()
                assertScreen("Get support")
                assertEachNumberAboveItsControls(on: "the support sheet")
            }
        }
    }

    /// Onboarding screens 1 to 4 (no store).
    func testAuditOnboardingScreens() throws {
        try auditAtEachTextSize { size in
            try auditLaunch(nil, size: size)
            let firstContinue = app.buttons["Continue"].firstMatch
            XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows")
            if size == .largest { assertContinueBelowTheLastLineOfScreen1() }
            audit("onboarding screen 1", size: size, types: auditTypes(size), pages: auditPages(size, standard: 2, largest: 10))
            XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
            firstContinue.tap()
            assertScreen("A few questions first")
            audit("onboarding screen 2", size: size, types: auditTypes(size), pages: auditPages(size, standard: 6, largest: 20))
            try auditLaunch(nil, size: size)
            XCTAssertTrue(firstContinue.waitForExistence(timeout: 20))
            XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
            firstContinue.tap()
            assertScreen("A few questions first")
            auditCompleteScreen2()
            assertScreen("Your start")
            // onboarding spec, "VoiceOver on the example": the example row
            // is one element, "13:05, Toast and tea" (mm-t14.8).
            let example = element(labelled: "13:05, Toast and tea")
            XCTAssertTrue(scrollTo(example, maxSwipes: 12), "screen 3 shows the example row as one element, \"13:05, Toast and tea\" (\(size.rawValue))")
            // The walk goes down from the page that shows, so it starts at
            // the top: at AX5 the scroll to the example passed the text above
            // it, and no audit page of the walk showed that text (9 October
            // 2026).
            auditScrollToTheTop("onboarding screen 3", size: size)
            audit("onboarding screen 3", size: size, types: auditTypes(size), pages: auditPages(size, standard: 5, largest: 20), last: "End")
            auditChoose("I won't be weighing")
            tapConfirm()
            assertScreen("Permissions")
            audit("onboarding screen 4", size: size, types: auditTypes(size), pages: auditPages(size, standard: 3, largest: 12))
        }
    }

    /// The exclusion page (age 17) and the caution sheet (170 cm and 54
    /// kg) from onboarding screen 2 (no store).
    func testAuditExclusionPageAndCautionSheet() throws {
        try auditAtEachTextSize { size in
            for (age, weight, screen, heading) in [("17", "65", "the exclusion page", "Not right now"),
                                                   ("30", "54", "the caution sheet", "Your height and weight put you close")] {
                try auditLaunch(nil, size: size)
                let firstContinue = app.buttons["Continue"].firstMatch
                XCTAssertTrue(firstContinue.waitForExistence(timeout: 20))
                XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
                firstContinue.tap()
                assertScreen("A few questions first")
                auditCompleteScreen2(age: age, weight: weight)
                XCTAssertTrue(element(labelBeginningWith: heading).waitForExistence(timeout: 8), "\(screen) shows")
                audit(screen, size: size, types: auditTypes(size), pages: auditPages(size, standard: 4, largest: 12))
                assertTheGPParagraphShowsItsText(on: screen, size: size)
            }
        }
    }

    /// safeguarding spec, "The GP paragraph": the page shows the paragraph
    /// in an editor. The audit cannot see an editor that draws no text: on
    /// 8 October 2026 the editor of the exclusion page and of the caution
    /// sheet showed no text at all (a `fixedSize` on the editor), and every
    /// audit passed. So Vision reads the text that the screen draws in the
    /// editor's frame, and the first words of the editor's value must be in
    /// it.
    ///
    /// The editor gets its height from a hidden copy of the text
    /// (GPParagraphView.swift). If the line heights of the editor and of
    /// that copy are not the same, the last lines scroll inside the editor,
    /// and the first words still show. So the test then drags the page
    /// until the bottom of the editor shows clear of the bars, and the
    /// paragraph's last words must be in the text that Vision reads there.
    func assertTheGPParagraphShowsItsText(on screen: String, size: AuditTextSize, file: StaticString = #filePath, line: UInt = #line) {
        let editor = app.textViews["The GP paragraph"].firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "\(screen) shows the GP paragraph (\(size.rawValue))", file: file, line: line)
        // Slow drags until the top of the editor shows under the navigation
        // bar. An editor off the screen has no finite frame, so the test
        // drags down the page first, and back up when the content stops.
        // (A swipe down at the top of a sheet closes it, so the drags up
        // are short and stop as soon as the editor shows.)
        let window = app.windows.firstMatch.frame
        let barBottom = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : 0
        var down = true
        var before = auditReadScreen(screen, size: size)
        for _ in 0..<30 {
            let frame = editor.frame
            let top = frame.minY
            if top.isFinite, top >= barBottom + 4, top < window.maxY - 200 { break }
            if top.isFinite, top < barBottom + 4 {
                auditScrollDown(fraction: -0.25)
            } else if top.isFinite {
                auditScrollDown(fraction: 0.4)
            } else {
                auditScrollDown(fraction: down ? 0.5 : -0.4)
            }
            usleep(600_000)
            let now = auditReadScreen(screen, size: size)
            if now == before { down.toggle() }
            before = now
        }
        let value = editor.value as? String ?? ""
        let words = value.split(separator: " ").prefix(4).map(String.init)
        XCTAssertFalse(words.isEmpty, "the GP paragraph on \(screen) holds text", file: file, line: line)
        let visible = editor.frame.intersection(window)
        let drawn = visible.isEmpty ? "" : recordPlanDrawnText(in: visible).map(\.text).joined(separator: " ")
        // At AX5 the first words can fill the visible part, so two words are enough.
        let wanted = words.prefix(size == .largest ? 2 : 4).joined(separator: " ")
        let normalise: (String) -> String = { $0.replacingOccurrences(of: "\u{2019}", with: "'").lowercased() }
        XCTAssertTrue(normalise(drawn).contains(normalise(wanted)),
                      "on \(screen) (\(size.rawValue)) the GP paragraph's editor draws its text: Vision read \"\(drawn.prefix(160))\" in \(visible.integral), and the text begins \"\(wanted)\"",
                      file: file, line: line)

        // The end of the paragraph: drag until the bottom of the editor
        // shows clear of the bars, with room above it for the last lines.
        for _ in 0..<20 {
            let bottom = editor.frame.maxY
            let clear = auditClearArea()
            if bottom.isFinite, bottom <= clear.bottom - 4, bottom >= clear.top + 120 { break }
            if bottom.isFinite, bottom < clear.top + 120 {
                auditScrollDown(fraction: -0.25)
            } else {
                auditScrollDown(fraction: 0.3)
            }
            usleep(600_000)
        }
        let clear = auditClearArea()
        let band = CGRect(x: window.minX, y: clear.top, width: window.width, height: max(0, clear.bottom - clear.top))
        let end = editor.frame.intersection(band)
        let endWords = value.split(separator: " ").suffix(3).joined(separator: " ")
        // Vision gives the lines in no fixed order: top to bottom here.
        let drawnEnd = end.isEmpty ? "" : recordPlanDrawnText(in: end).sorted { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }.map(\.text).joined(separator: " ")
        let plainWords: (String) -> String = { text in
            normalise(text).unicodeScalars.map { CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) || $0 == "'" ? String($0) : " " }
                .joined().split(separator: " ").joined(separator: " ")
        }
        XCTAssertTrue(editor.frame.maxY <= clear.bottom - 4 && !end.isEmpty,
                      "on \(screen) (\(size.rawValue)) the bottom of the GP paragraph's editor shows clear of the bars (the editor at \(editor.frame.integral), the clear part from \(Int(clear.top)) to \(Int(clear.bottom)))",
                      file: file, line: line)
        XCTAssertTrue(plainWords(drawnEnd).contains(plainWords(endWords)),
                      "on \(screen) (\(size.rawValue)) the GP paragraph's editor shows the end of the paragraph: Vision read \"\(drawnEnd.suffix(160))\" in \(end.integral), and the text ends \"\(endWords)\"",
                      file: file, line: line)
    }

    /// The restart re-screen from "Start week 1 again" (`week1`).
    func testAuditRestartRescreen() throws {
        try auditAtEachTextSize { size in
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            auditOpen("Start week 1 again", screen: "A few questions first")
            audit("the restart re-screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 6, largest: 20))
        }
    }

    /// The app-lock cover at launch (`lock-week1`; the seam cancels the
    /// request), safe mode (the third launch in a row that stopped before
    /// Today, `week1`), and the store-open fault screen (`corrupt`).
    func testAuditCoverSafeModeAndStoreFault() throws {
        try auditAtEachTextSize { size in
            try auditLaunchWithTheSeam("lock-week1", results: ["cancel"], size: size)
            XCTAssertTrue(unlockButton.waitForExistence(timeout: 20), "the cover shows \"Unlock\"")
            assertAppLockRequests(1, "the launch makes one request")
            audit("the app-lock cover", size: size, types: auditTypes(size), pages: auditPages(size, standard: 1, largest: 3))
            try auditLaunch("week1", size: size, launchMarker: "2")
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "safe mode's Today shows")
            XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
            audit("safe mode", size: size, types: auditTypes(size), pages: auditPages(size, standard: 2, largest: 6))
            try auditLaunch("corrupt", size: size)
            XCTAssertTrue(element(labelled: "Midmorning cannot open your record on this device.").waitForExistence(timeout: 20), "the store-open fault screen shows")
            audit("the store-open fault screen", size: size, types: auditTypes(size), pages: auditPages(size, standard: 2, largest: 6))
        }
    }

    // MARK: The accessibility tree: header traits

    /// `UIAccessibilityTraits.header`.
    static let headerTrait: UInt64 = 1 << 16

    /// One element of a snapshot with its accessibility traits. XCTest has
    /// no public API for the traits. The snapshot class (`XCElementSnapshot`)
    /// holds them in its property `traits`, with the bits of
    /// `UIAccessibilityTraits`, so the test reads that property.
    struct TraitedElement {
        let type: XCUIElement.ElementType
        let label: String
        let frame: CGRect
        let traits: UInt64
        var isHeader: Bool { traits & AutomatedChecks.headerTrait != 0 }
    }

    /// Every element on the screen with its traits, from one snapshot.
    func traitedElements(file: StaticString = #filePath, line: UInt = #line) -> [TraitedElement] {
        guard let root = try? app.snapshot() else {
            XCTFail("a snapshot of the screen failed", file: file, line: line)
            return []
        }
        guard (root as AnyObject).responds(to: NSSelectorFromString("traits")) else {
            XCTFail("this XCTest gives no traits on a snapshot; the header checks need them", file: file, line: line)
            return []
        }
        var all: [TraitedElement] = []
        func walk(_ element: XCUIElementSnapshot) {
            let traits = ((element as AnyObject).value(forKey: "traits") as? NSNumber)?.uint64Value ?? 0
            all.append(TraitedElement(type: element.elementType, label: element.label, frame: element.frame, traits: traits))
            element.children.forEach(walk)
        }
        walk(root)
        return all
    }

    /// Asserts that an element whose label is `label` (or begins with it,
    /// when `prefix` is true) shows and carries the header trait, so that
    /// VoiceOver reads it as a heading and its rotor stops on it. It
    /// scrolls down to find the element.
    func assertHeading(_ label: String, prefix: Bool = false, on screen: String, maxScrolls: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        func matches(_ element: TraitedElement) -> Bool {
            prefix ? element.label.hasPrefix(label) : element.label == label
        }
        var found: [TraitedElement] = []
        for scroll in 0...maxScrolls {
            if scroll > 0 { auditScrollDown() }
            found = traitedElements(file: file, line: line).filter { matches($0) && $0.frame.width > 0 }
            if !found.isEmpty { break }
        }
        XCTAssertFalse(found.isEmpty, "\(screen) shows \"\(label)\"", file: file, line: line)
        guard !found.isEmpty else { return }
        XCTAssertTrue(found.contains { $0.isHeader }, "on \(screen), \"\(label)\" is a heading for VoiceOver (header trait): \(found.map { "\($0.type.rawValue) \"\($0.label)\" traits \(String($0.traits, radix: 16))" })", file: file, line: line)
    }

    /// record spec, "The Today stack": "Each day heading MUST carry the
    /// header trait." programme spec, "The stage screen": "The title and
    /// 'Tools' MUST be headings for VoiceOver." content spec, "The card
    /// screen and the card list": "The title MUST be a heading for
    /// VoiceOver. 'One thing to do' MUST be a heading for VoiceOver."
    /// weigh-in spec, "Accessibility of the weigh-in": "With no weigh-in
    /// day, 'Choose a weigh-in day' MUST be a heading. Each weekday choice
    /// MUST have the weekday's name as its label."
    func testHeadingsOnTodayTheStageTheCardAndTheWeighIn() throws {
        try launchOnToday("review")
        let currentDay = recordPlanDayText(recordPlanCurrentDayKey())
        let previousDay = recordPlanDayText(recordPlanAdding(-1, to: recordPlanCurrentDayKey()))
        assertHeading(currentDay, prefix: true, on: "Today (the current day heading)")
        assertHeading(previousDay, prefix: true, on: "Today (the previous day heading)")

        tapToolbar("Programme")
        assertScreen("Programme")
        let stage = element(labelBeginningWith: "Getting started")
        XCTAssertTrue(scrollTo(stage))
        stage.tap()
        assertScreen("Getting started")
        assertHeading("Getting started", on: "the stage screen (its title)")
        assertHeading("Tools", on: "the stage screen")
        // programme spec, "VoiceOver on the stage screen": the title, then
        // "Opened in week 1", then the card titles, then "Tools", then
        // "Weigh-in". The tree holds the elements in the order that
        // VoiceOver reads them.
        for _ in 0..<4 { app.swipeDown() }
        let order = traitedElements().filter { $0.type == .staticText || $0.type == .button }.map(\.label)
        let wanted = ["Getting started", "Opened in week 1", "Why write it down", "Tools", "Weigh-in"]
        let places = wanted.map { label in order.firstIndex { $0 == label } }
        XCTAssertFalse(places.contains(nil), "the stage screen shows \(wanted): \(order)")
        let found = places.compactMap { $0 }
        XCTAssertEqual(found, found.sorted(), "the stage screen reads \(wanted) in that order: \(order)")

        // The weigh-in screen with no weigh-in day: the review store holds
        // "I won't be weighing".
        auditOpen("Weigh-in", screen: "Weigh-in")
        assertHeading("Choose a weigh-in day", on: "the weigh-in screen with no weigh-in day")
        // The weekday choices, Monday first and Sunday last, in the order
        // of the tree (the order in which VoiceOver reads them).
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        XCTAssertTrue(scrollTo(app.buttons["Sunday"].firstMatch), "the weigh-in screen offers \"Sunday\"")
        let shown = traitedElements().filter { $0.type == .button && weekdays.contains($0.label) }.map(\.label)
        XCTAssertEqual(shown, weekdays, "each weekday choice has the weekday's name as its label, Monday first and Sunday last")
        goBack()
        assertScreen("Getting started")

        let card = app.buttons["Why write it down"].firstMatch
        XCTAssertTrue(scrollTo(card))
        card.tap()
        assertScreen("Why write it down")
        // The card title in the content (the navigation bar holds a second
        // copy, which is a heading of its own).
        let titleInContent = traitedElements().filter { $0.label == "Why write it down" && $0.type == .staticText && $0.frame.minY > app.navigationBars.firstMatch.frame.maxY - 1 }
        XCTAssertFalse(titleInContent.isEmpty, "the card screen shows its title in the content")
        XCTAssertTrue(titleInContent.allSatisfy(\.isHeader), "the card title is a heading for VoiceOver")
        assertHeading("One thing to do", on: "the card screen")
    }

    /// The four safeguarding pages (mm-t14.38 to mm-t14.40, the heading
    /// rotor): each page heading, and "What to do instead" or "Talk to your
    /// GP", is a heading for VoiceOver. The weekly review: the self-harm
    /// question is the header of its section (mm-t32.28). Onboarding screen
    /// 2: each question with answer rows is the header of its section.
    func testSafeguardingPageAndQuestionHeadings() throws {
        try launchOnToday("review")
        openTheDueReview()
        assertHeading(Self.selfHarmQuestion, on: "the weekly review (the self-harm question)", maxScrolls: 20)
        tapGettingWorse()
        XCTAssertTrue(element(labelled: "It might help to see your GP").waitForExistence(timeout: 8), "the GP suggestion page shows")
        assertHeading("It might help to see your GP", on: "the GP suggestion page")
        assertHeading("Talk to your GP", on: "the GP suggestion page")

        try launchOnToday("review")
        openTheDueReview()
        auditAnswer(Self.selfHarmQuestion, "Yes", bar: "Done")
        auditAnswer(Self.selfHarmStep2Question, "Yes", bar: "Done")
        XCTAssertTrue(element(labelled: "This may not be right for you now").waitForExistence(timeout: 8), "the not-right-now page shows")
        assertHeading("This may not be right for you now", on: "the not-right-now page")
        assertHeading("Talk to your GP", on: "the not-right-now page")

        try openScreen2()
        for question in [Self.treatmentQuestion, Self.pregnancyQuestion, Self.selfHarmQuestion] {
            assertHeading(question, on: "onboarding screen 2", maxScrolls: 10)
        }
        auditCompleteScreen2(age: "17")
        XCTAssertTrue(element(labelled: "Not right now").waitForExistence(timeout: 8), "the exclusion page shows")
        assertHeading("Not right now", on: "the exclusion page")
        assertHeading("What to do instead", on: "the exclusion page")

        try openScreen2()
        auditCompleteScreen2(weight: "54")
        XCTAssertTrue(element(labelBeginningWith: "Your height and weight put you close").waitForExistence(timeout: 8), "the caution sheet shows")
        assertHeading("Talk to your GP", on: "the caution sheet")
    }

    // MARK: Layout at the largest text size

    /// record spec, "Where chips" (decision 92): at AX5 the chips wrap onto
    /// more lines in a flow layout, each chip shows its full width on the
    /// screen, and the Where control does not scroll to the side.
    func assertTheWhereChipsWrap(file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch.frame
        let labels = ["Home", "Work", "Out", "Travelling", "Add a place"]
        // "Add a place" comes last, so all the chips show when it shows.
        XCTAssertTrue(auditReveal(app.buttons["Add a place"].firstMatch), "at AX5 the new-entry screen shows the chip \"Add a place\"", file: file, line: line)
        let chips = look().filter { $0.type == .button && labels.contains($0.label) }
        XCTAssertEqual(Set(chips.map(\.label)), Set(labels), "at AX5 the new-entry screen shows the chips \(labels)", file: file, line: line)
        for chip in chips {
            XCTAssertGreaterThanOrEqual(chip.frame.minX, window.minX - 1, "at AX5 the chip \"\(chip.label)\" starts on the screen", file: file, line: line)
            XCTAssertLessThanOrEqual(chip.frame.maxX, window.maxX + 1, "at AX5 the chip \"\(chip.label)\" ends on the screen: the chips do not scroll to the side", file: file, line: line)
        }
        let lines = Set(chips.map { Int($0.frame.minY.rounded()) })
        XCTAssertGreaterThan(lines.count, 1, "at AX5 the chips wrap onto more than one line", file: file, line: line)
        XCTAssertEqual(app.scrollViews.matching(NSPredicate(format: "label == %@", "Where")).count, 0, "the Where control is not a scroll view", file: file, line: line)
    }

    /// Scrolls down with the audit's own drag (`auditScrollDown`) until
    /// `element` can take a tap in the part of the screen that is clear of
    /// the bars and the keyboard.
    @discardableResult
    func auditReveal(_ element: XCUIElement, maxScrolls: Int = 12) -> Bool {
        for scroll in 0...maxScrolls {
            if scroll > 0 { auditScrollDown() }
            if element.exists, element.isHittable, auditClearArea().isClear(element.label, element.frame) { return true }
        }
        return false
    }

    /// onboarding spec, "Largest text size" (mm-t14.3): at AX5 "Continue"
    /// on "What this is and isn't" stays below the last line, and the
    /// person scrolls to reach it.
    func assertContinueBelowTheLastLineOfScreen1(file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch.frame
        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertGreaterThan(continueButton.frame.minY, window.maxY, "at AX5 \"Continue\" is not on the screen before a scroll", file: file, line: line)
        let lastLine = element(labelled: "If you need a person, Get support is on every screen.")
        XCTAssertTrue(scrollTo(continueButton, maxSwipes: 20), "a scroll reaches \"Continue\"", file: file, line: line)
        XCTAssertTrue(lastLine.exists, "screen 1 shows its last line", file: file, line: line)
        XCTAssertGreaterThanOrEqual(continueButton.frame.minY, lastLine.frame.maxY, "at AX5 \"Continue\" shows below the last line", file: file, line: line)
        app.swipeDown(); app.swipeDown(); app.swipeDown(); app.swipeDown(); app.swipeDown()
    }

    /// safeguarding spec, "Largest text size" for the numbers (mm-t14.41):
    /// at AX5 each number shows above its "Call" and "Copy number"
    /// controls, not beside them. The test scrolls through the sheet and
    /// looks at each number and each control that shows together.
    func assertEachNumberAboveItsControls(on screen: String, file: StaticString = #filePath, line: UInt = #line) {
        let number = try? NSRegularExpression(pattern: "^[0-9][0-9 ]{2,}$")
        var numbersSeen = Set<String>()
        var last: [String] = []
        for _ in 0..<20 {
            let seen = look()
            let window = app.windows.firstMatch.frame
            let numbers = seen.filter { item in
                item.type == .staticText && item.frame.intersects(window)
                    && number?.firstMatch(in: item.label, range: NSRange(item.label.startIndex..., in: item.label)) != nil
            }
            let controls = seen.filter { $0.type == .button && ["Call", "Copy number"].contains($0.label) && $0.frame.intersects(window) }
            for shown in numbers {
                numbersSeen.insert(shown.label)
                for control in controls {
                    let sameLine = control.frame.minY < shown.frame.maxY - 1 && control.frame.maxY > shown.frame.minY + 1
                    XCTAssertFalse(sameLine, "on \(screen) at AX5, \"\(control.label)\" shows beside \(shown.label), not under it", file: file, line: line)
                }
            }
            let now = seen.filter { $0.type == .staticText }.map { "\($0.label)@\(Int($0.frame.minY))" }
            if now == last { break }
            last = now
            auditScrollDown()
        }
        XCTAssertGreaterThanOrEqual(numbersSeen.count, 3, "on \(screen) at AX5 the test saw the numbers: \(numbersSeen.sorted())", file: file, line: line)
    }

    // MARK: Labels the specs name

    /// weigh-in spec, "Accessibility of the weigh-in": the weight input's
    /// label is "Weight", the unit control's label is "Unit", the weigh-in
    /// day control's label is "Weigh-in day", and the chart is one element
    /// with the label "Rolling average" (`week1`: the weigh-in day, and a
    /// weigh-in a week ago).
    func testWeighInLabelsAndTheChart() throws {
        try launchOnToday("week1")
        tapToolbar("Programme")
        assertScreen("Programme")
        let stage = element(labelBeginningWith: "Getting started")
        XCTAssertTrue(scrollTo(stage))
        stage.tap()
        assertScreen("Getting started")
        auditOpen("Weigh-in", screen: "Weigh-in")
        XCTAssertTrue(app.textFields["Weight"].firstMatch.waitForExistence(timeout: 5), "the weight input's label is \"Weight\"")
        let unit = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Unit")).firstMatch
        XCTAssertTrue(scrollTo(unit), "the unit control's label is \"Unit\"")
        XCTAssertTrue(app.buttons["Save"].firstMatch.exists || scrollTo(app.buttons["Save"].firstMatch), "the weigh-in screen shows \"Save\"")
        let day = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Weigh-in day")).firstMatch
        XCTAssertTrue(scrollTo(day), "the weigh-in day control's label is \"Weigh-in day\"")
        app.swipeDown(); app.swipeDown(); app.swipeDown()
        let chart = element(labelled: "Rolling average")
        XCTAssertTrue(scrollTo(chart), "the chart is one element with the label \"Rolling average\"")
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Rolling average")).count, 1,
                       "one element has the label \"Rolling average\"")
    }

    // MARK: Contrast in dark mode

    /// product-rules "Accessibility everywhere": "That contrast MUST hold in
    /// light mode, in dark mode and with Increase Contrast on." The other
    /// audits run in light mode. This test runs the contrast audit in dark
    /// mode on the main screens, at the default text size (the strict case
    /// for contrast). A UI test cannot turn on Increase Contrast from inside
    /// XCTest; the simulator can (`xcrun simctl ui <udid> increase_contrast
    /// enabled`), and mm-t45.19 asks Ash for a pass of the script with it.
    ///
    /// The test sets dark mode with `XCUIDevice.appearance` and puts light
    /// mode back at the end. On the iOS 27.0 simulator a new simulator did
    /// not change its appearance until its first restart (8 October 2026).
    /// The test proves from a screenshot that dark mode took effect, and
    /// fails if it did not.
    func testAuditContrastInDarkMode() throws {
        XCUIDevice.shared.appearance = .dark
        addTeardownBlock { XCUIDevice.shared.appearance = .light }
        try auditAtEachTextSize([.standard]) { size in
            try auditLaunchOnToday("review", size: size)
            assertDarkMode()
            audit("Today with entries and a gap band", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("planMissed", size: size)
            audit("Today with the missed planned meal prompt", size: size, dark: true, types: .contrast, pages: 2)
            try auditLaunchOnToday("review", size: size)
            app.buttons["Add an entry"].firstMatch.tap()
            XCTAssertTrue(app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 8), "the new-entry screen shows")
            dismissKeyboardTip()
            auditHideTheKeyboard(on: "the new-entry screen", size: size)
            audit("the new-entry screen", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("planMatched", size: size)
            tapDayMenu("Today's plan")
            assertScreen("Today's plan")
            audit("the plan builder", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            audit("Settings", size: size, dark: true, types: .contrast, pages: 5)
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            audit("Programme", size: size, dark: true, types: .contrast, pages: 3)
            let stage = element(labelBeginningWith: "Getting started")
            XCTAssertTrue(scrollTo(stage))
            stage.tap()
            assertScreen("Getting started")
            auditOpen("Why write it down", screen: "Why write it down")
            audit("the card screen", size: size, dark: true, types: .contrast, pages: 3)
            goBack()
            assertScreen("Getting started")
            auditOpen("Weigh-in", screen: "Weigh-in")
            audit("the weigh-in screen", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("review", size: size)
            openTheDueReview()
            audit("the weekly review", size: size, dark: true, types: .contrast, pages: 6)
            try auditLaunchOnToday("review", size: size)
            openTheDueReview()
            tapGettingWorse()
            XCTAssertTrue(element(labelled: "It might help to see your GP").waitForExistence(timeout: 8), "the GP suggestion page shows")
            audit("the GP suggestion page", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("week1", size: size)
            getSupport(on: "Today").tap()
            assertScreen("Get support")
            audit("the support sheet", size: size, dark: true, types: .contrast, pages: 5)
            try auditLaunch(nil, size: size)
            XCTAssertTrue(app.buttons["Continue"].firstMatch.waitForExistence(timeout: 20), "onboarding screen 1 shows")
            audit("onboarding screen 1", size: size, dark: true, types: .contrast, pages: 2)
            try auditLaunchWithTheSeam("lock-week1", results: ["cancel"], size: size)
            XCTAssertTrue(unlockButton.waitForExistence(timeout: 20), "the cover shows \"Unlock\"")
            assertAppLockRequests(1, "the launch makes one request")
            audit("the app-lock cover", size: size, dark: true, types: .contrast)
        }
    }

    /// The contrast audit in dark mode on the record and settings screens
    /// that `testAuditContrastInDarkMode` leaves out: Earlier days, one
    /// earlier day, the edit screen, the close-the-day screen, the Reminders
    /// group, the privacy notice, Diagnostics, Export, the stage screen, the
    /// Reviews list, safe mode and the store-open fault screen. Each screen
    /// has the same pages as its audit in light mode. With the next test,
    /// the dark-mode audits cover each screen of the light-mode audits. They
    /// leave out only four states of Today (a matched planned meal, the plan
    /// card, the stage 1 card, the pinned note) and two states of the
    /// weigh-in screen (not the weigh-in day, no weigh-in day): these use the
    /// same rows, controls and colours as the states that the audits cover.
    func testAuditContrastInDarkModeOnTheRecordAndSettingsScreens() throws {
        XCUIDevice.shared.appearance = .dark
        addTeardownBlock { XCUIDevice.shared.appearance = .light }
        try auditAtEachTextSize([.standard]) { size in
            try auditLaunchOnToday("review", size: size)
            assertDarkMode()
            tapDayMenu("Earlier days")
            assertScreen("Earlier days")
            audit("Earlier days", size: size, dark: true, types: .contrast, pages: 4)
            app.cells.firstMatch.tap()
            XCTAssertTrue(app.buttons["Previous day"].waitForExistence(timeout: 8), "one earlier day shows")
            audit("one earlier day", size: size, dark: true, types: .contrast, pages: 2)
            try auditLaunchOnToday("review", size: size)
            let row = element(labelContaining: "Toast and tea")
            XCTAssertTrue(scrollTo(row, maxSwipes: 12), "Today shows \"Toast and tea\"")
            row.tap()
            XCTAssertTrue(app.buttons["Delete entry"].firstMatch.waitForExistence(timeout: 8) || app.switches["felt like a binge"].firstMatch.waitForExistence(timeout: 2), "the edit screen shows")
            dismissKeyboardTip()
            auditHideTheKeyboard(on: "the edit screen", size: size)
            audit("the edit screen", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("or-plan", size: size)
            let closeTheDay = app.buttons["Close the day"].firstMatch
            XCTAssertTrue(scrollTo(closeTheDay, maxSwipes: 12), "Today shows \"Close the day\"")
            closeTheDay.tap()
            XCTAssertTrue(app.navigationBars["Close the day"].waitForExistence(timeout: 8), "the close-the-day screen shows")
            audit("the close-the-day screen", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            auditOpen("Reminders", screen: "Reminders")
            audit("the Reminders group", size: size, dark: true, types: .contrast, pages: 4)
            goBack()
            assertScreen("Settings")
            auditOpen("Privacy", screen: "Privacy notice")
            audit("the privacy notice", size: size, dark: true, types: .contrast, pages: 6)
            goBack()
            assertScreen("Settings")
            auditOpen("Diagnostics", screen: "Diagnostics")
            audit("Diagnostics", size: size, dark: true, types: .contrast, pages: 4)
            try auditLaunchOnToday("week1", size: size)
            auditOpenSettings()
            auditOpen("Export", screen: "Export")
            audit("the export screen", size: size, dark: true, types: .contrast, pages: 3)
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            let stage = element(labelBeginningWith: "Getting started")
            XCTAssertTrue(scrollTo(stage, maxSwipes: 12))
            stage.tap()
            assertScreen("Getting started")
            audit("the stage screen", size: size, dark: true, types: .contrast, pages: 4)
            try auditLaunchOnToday("review", size: size)
            tapToolbar("Reviews")
            assertScreen("Reviews")
            audit("the Reviews list", size: size, dark: true, types: .contrast, pages: 2)
            try auditLaunch("week1", size: size, launchMarker: "2")
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 20), "safe mode's Today shows")
            XCTAssertFalse(app.buttons["Add an entry"].exists, "safe mode's Today is not the full Today")
            audit("safe mode", size: size, dark: true, types: .contrast, pages: 2)
            try auditLaunch("corrupt", size: size)
            XCTAssertTrue(element(labelled: "Midmorning cannot open your record on this device.").waitForExistence(timeout: 20), "the store-open fault screen shows")
            audit("the store-open fault screen", size: size, dark: true, types: .contrast, pages: 2)
        }
    }

    /// The contrast audit in dark mode on the onboarding and safeguarding
    /// screens that `testAuditContrastInDarkMode` leaves out: onboarding
    /// screens 2 to 4, the exclusion page, the caution sheet, the
    /// not-right-now page and the restart re-screen.
    func testAuditContrastInDarkModeOnTheOnboardingAndSafeguardingScreens() throws {
        XCUIDevice.shared.appearance = .dark
        addTeardownBlock { XCUIDevice.shared.appearance = .light }
        try auditAtEachTextSize([.standard]) { size in
            try auditLaunch(nil, size: size)
            assertDarkMode()
            let firstContinue = app.buttons["Continue"].firstMatch
            XCTAssertTrue(firstContinue.waitForExistence(timeout: 20), "onboarding screen 1 shows")
            XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
            firstContinue.tap()
            assertScreen("A few questions first")
            audit("onboarding screen 2", size: size, dark: true, types: .contrast, pages: 6)
            try auditLaunch(nil, size: size)
            XCTAssertTrue(firstContinue.waitForExistence(timeout: 20))
            XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
            firstContinue.tap()
            assertScreen("A few questions first")
            auditCompleteScreen2()
            assertScreen("Your start")
            audit("onboarding screen 3", size: size, dark: true, types: .contrast, pages: 5, last: "End")
            auditChoose("I won't be weighing")
            tapConfirm()
            assertScreen("Permissions")
            audit("onboarding screen 4", size: size, dark: true, types: .contrast, pages: 3)
            for (age, weight, screen, heading) in [("17", "65", "the exclusion page", "Not right now"),
                                                   ("30", "54", "the caution sheet", "Your height and weight put you close")] {
                try auditLaunch(nil, size: size)
                XCTAssertTrue(firstContinue.waitForExistence(timeout: 20))
                XCTAssertTrue(scrollTo(firstContinue, maxSwipes: 20))
                firstContinue.tap()
                assertScreen("A few questions first")
                auditCompleteScreen2(age: age, weight: weight)
                XCTAssertTrue(element(labelBeginningWith: heading).waitForExistence(timeout: 8), "\(screen) shows")
                audit(screen, size: size, dark: true, types: .contrast, pages: 4)
            }
            try auditLaunchOnToday("review", size: size)
            openTheDueReview()
            auditAnswer(Self.selfHarmQuestion, "Yes", bar: "Done")
            auditAnswer(Self.selfHarmStep2Question, "Yes", bar: "Done")
            XCTAssertTrue(element(labelled: "This may not be right for you now").waitForExistence(timeout: 8), "the not-right-now page shows")
            audit("the not-right-now page", size: size, dark: true, types: .contrast, pages: 4)
            try auditLaunchOnToday("week1", size: size)
            tapToolbar("Programme")
            assertScreen("Programme")
            auditOpen("Start week 1 again", screen: "A few questions first")
            audit("the restart re-screen", size: size, dark: true, types: .contrast, pages: 6)
        }
    }

    /// Fails unless the screen shows dark mode: the corner of the window
    /// under the status bar is near black.
    func assertDarkMode(file: StaticString = #filePath, line: UInt = #line) {
        guard let image = XCUIScreen.main.screenshot().image.cgImage else {
            XCTFail("no screenshot", file: file, line: line)
            return
        }
        let window = app.windows.firstMatch.frame
        let scale = CGFloat(image.width) / max(window.width, 1)
        let corner = colour(at: CGPoint(x: 4, y: 4), in: image, scale: scale)
        XCTAssertLessThan(corner.reduce(0, +), 0.6, """
            dark mode took effect (the colour at the top corner is \(corner)). On the iOS 27.0 simulator a new simulator \
            changes its appearance only after its first restart: restart it (xcrun simctl shutdown, then boot) and run again
            """, file: file, line: line)
    }

    // MARK: The accessibility tree: VoiceOver custom actions

    /// The names of the VoiceOver custom actions of the element in
    /// `snapshot`, in the order that the actions rotor lists them. XCTest
    /// has no public API for them. Its accessibility client
    /// (`XCUIDevice.accessibilityInterface`, class `XCAXClient_iOS`) reads
    /// the attribute "XC_kAXXCAttributeCustomActions" of the element's
    /// accessibility element (8 October 2026, Xcode 27.0). Returns nil when
    /// this XCTest has no such client, so that the test fails with a clear
    /// message and does not stop.
    func customActionNames(of snapshot: XCUIElementSnapshot) -> [String]? {
        guard (snapshot as AnyObject).responds(to: NSSelectorFromString("accessibilityElement")),
              let element = (snapshot as AnyObject).value(forKey: "accessibilityElement") as? NSObject else { return nil }
        let key = "XC_kAXXCAttributeCustomActions"
        guard let result = auditAttributes([key], of: element) else { return nil }
        let actions = result[key] as? [[String: Any]] ?? []
        return actions.compactMap { $0["CustomActionName"] as? String }
    }

    /// The first element on the screen that `matches` finds, in one
    /// snapshot. It scrolls down to find it.
    func snapshotElement(_ description: String, maxScrolls: Int = 6, file: StaticString = #filePath, line: UInt = #line,
                         matching matches: (XCUIElementSnapshot) -> Bool) -> XCUIElementSnapshot? {
        for scroll in 0...maxScrolls {
            if scroll > 0 { auditScrollDown() }
            guard let root = try? app.snapshot() else { continue }
            var found: XCUIElementSnapshot?
            func walk(_ element: XCUIElementSnapshot) {
                guard found == nil else { return }
                if matches(element), element.frame.width > 0 { found = element; return }
                element.children.forEach(walk)
            }
            walk(root)
            if let found { return found }
        }
        XCTFail("the screen shows \(description)", file: file, line: line)
        return nil
    }

    /// Asserts that the element that `matches` finds offers the VoiceOver
    /// custom actions `expected` and no other, each one as many times as
    /// `expected` names it, in any order (the attribute lists SwiftUI's
    /// actions last to first, and the spec names no order).
    ///
    /// One duplicate is known, and the test allows only that one: on the
    /// iOS 27.0 simulator the attribute lists the swipe action of a list row
    /// ("Delete") two times, with the same identifier ("Name:Delete"). It
    /// does so with or without the row's own `accessibilityAction` of that
    /// name: on 8 October 2026 the test ran with that action taken out of
    /// DaySectionView.swift, and the attribute still listed "Delete" two
    /// times. So the second copy comes from iOS, not from the app.
    /// `swipeAction` names the one action that can show two times; every
    /// other name must show exactly as many times as `expected` names it.
    func assertCustomActions(_ expected: [String], swipeAction: String? = nil, on description: String, maxScrolls: Int = 6,
                             file: StaticString = #filePath, line: UInt = #line,
                             matching matches: @escaping (XCUIElementSnapshot) -> Bool) {
        guard let element = snapshotElement(description, maxScrolls: maxScrolls, file: file, line: line, matching: matches) else { return }
        guard let names = customActionNames(of: element) else {
            XCTFail("this XCTest cannot read the custom actions of \(description)", file: file, line: line)
            return
        }
        var counted = names
        if let swipeAction, names.filter({ $0 == swipeAction }).count == 2, let index = counted.firstIndex(of: swipeAction) {
            counted.remove(at: index)
            auditLog("  (\(description): the attribute lists the swipe action \"\(swipeAction)\" two times, which iOS does; the test counts it once)")
        }
        XCTAssertEqual(counted.sorted(), expected.sorted(),
                       "\(description) (\"\(element.label)\") offers the VoiceOver actions \(expected), each once, and no other: \(names)", file: file, line: line)
    }

    /// The day heading whose label begins with `day`: a heading for
    /// VoiceOver with its menu inside it.
    func dayHeading(_ day: String) -> (XCUIElementSnapshot) -> Bool {
        { element in
            element.label.hasPrefix(day)
                && (((element as AnyObject).value(forKey: "traits") as? NSNumber)?.uint64Value ?? 0) & AutomatedChecks.headerTrait != 0
        }
    }

    /// The first heading under the navigation bar: on Today and on an
    /// earlier day, the day heading.
    func headingInTheContent() -> (XCUIElementSnapshot) -> Bool {
        let barBottom = app.navigationBars.firstMatch.frame.maxY
        return { element in
            (((element as AnyObject).value(forKey: "traits") as? NSNumber)?.uint64Value ?? 0) & AutomatedChecks.headerTrait != 0
                && element.elementType != .navigationBar && element.frame.minY >= barBottom - 1 && !element.label.isEmpty
        }
    }

    /// record spec, "The Today stack": the day heading offers "Fasting
    /// today", "Didn't record" and "Earlier days" (when the menu offers it)
    /// as custom actions, and from stage 2 "Today's plan". "Accessibility
    /// of the additions": the collapse action reads "Collapse day" when the
    /// day is expanded and "Expand day" when it is collapsed, and only a
    /// day with an entry offers it; each entry row offers "Delete".
    /// regular-eating-plan spec, "Accessibility of the plan": a planned meal
    /// row with the missed planned meal prompt offers "Skipped" and "Add
    /// it". A planned meal row with a matched entry offers "Delete", as an
    /// entry row does (mm-t12b.7).
    func testVoiceOverCustomActionsOnTodayAndAnEarlierDay() throws {
        // Stage 2, entries today and on earlier days (`review`).
        try launchOnToday("review")
        let today = recordPlanCurrentDayKey()
        // The heading combines its menu button, so VoiceOver also offers
        // the menu, "Day options", as an action.
        assertCustomActions(["Collapse day", "Fasting today", "Didn't record", "Earlier days", "Today's plan", "Day options"],
                            on: "the current day heading", matching: dayHeading(recordPlanDayText(today)))
        assertCustomActions(["Delete"], swipeAction: "Delete", on: "the entry row \"Toast and tea\"") { $0.label.contains("Toast and tea") && $0.elementType != .staticText }
        let previous = snapshotElement("the previous day heading", matching: dayHeading(recordPlanDayText(recordPlanAdding(-1, to: today))))
        if let previous {
            let names = customActionNames(of: previous) ?? []
            XCTAssertTrue(names.contains("Expand day"), "the collapsed previous day offers \"Expand day\": \(names)")
            XCTAssertFalse(names.contains("Collapse day"), "the collapsed previous day offers no \"Collapse day\": \(names)")
        }

        // An earlier day: the heading offers no control that creates an
        // entry (mm-t12b.10), and its entry row offers "Delete".
        try launchOnToday("review")
        tapDayMenu("Earlier days")
        assertScreen("Earlier days")
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.buttons["Previous day"].waitForExistence(timeout: 8), "one earlier day shows")
        assertCustomActions(["Collapse day", "Fasting today", "Didn't record", "Day options"], on: "the earlier day's heading", matching: headingInTheContent())
        assertCustomActions(["Delete"], swipeAction: "Delete", on: "the entry row \"Porridge\"") { $0.label.contains("Porridge") && $0.elementType != .staticText }

        // Stage 1, no entry today (`dayStart6`): no "Collapse day", no
        // "Today's plan" and no "Earlier days".
        try launchOnToday("dayStart6")
        assertCustomActions(["Fasting today", "Didn't record", "Day options"], on: "the heading of an empty day in stage 1", matching: headingInTheContent())

        // The missed planned meal prompt (`planMissed`) and a matched
        // planned meal (`planMatched`).
        let lunch = try recordPlanFacts("planMissed")["lunch"]!
        try launchOnToday("planMissed")
        assertCustomActions(["Skipped", "Add it"], on: "the Lunch row with the missed planned meal prompt") {
            $0.label == "Lunch, \(lunch), Skipped, or not recorded yet?"
        }
        let matched = try recordPlanFacts("planMatched")
        try launchOnToday("planMatched")
        assertCustomActions(["Delete"], swipeAction: "Delete", on: "the Lunch row with its matched entry") {
            $0.label == "Lunch, \(matched["lunch"]!), \(matched["entry"]!), Toast and tea, Home, Row with my sister"
        }
    }
}
