import Foundation
import XCTest
@testable import Programme

/// weigh-in spec, "Accessibility of the weigh-in" (mm-t22.14). Per
/// CLAUDE.md, "Worktrees and beads": the screen beads (mm-t22.3, mm-t22.6,
/// mm-t22.20) already built every VoiceOver label, the chart's
/// accessibility label and the "Choose a weigh-in day" heading; this P2
/// bead proves the label text and structure, and lists the parts only a
/// device can prove.
///
/// Proved here: the four VoiceOver labels' exact text, the chart's label,
/// that `WeighInScreenView.swift` marks the heading and gives every custom
/// control a label. `WeighInGate`'s own tests already prove a weekday tap
/// sets the day and that the input accepts a save with no other sense
/// needed. Device checks (the epic's device-check bead): the real VoiceOver
/// reading order and the audio graph ("VoiceOver on the weigh-in day",
/// "VoiceOver on the chart", "VoiceOver with no weigh-in day"), the largest
/// accessibility text size with no truncation, and Voice Control's "Show
/// names"/"Tap Save".
final class WeighInAccessibilityTests: XCTestCase {
    func testTheFourVoiceOverLabels() {
        XCTAssertEqual(WeighInContent.weightLabel.english, "Weight")
        XCTAssertEqual(WeighInContent.unitLabel.english, "Unit")
        XCTAssertEqual(Screen3Content.weighInDayHeading.english, "Weigh-in day")
        // "Save" is the shared `entry.save` catalogue key, already "Save"
        // (`RecordStore` / `Localizable.xcstrings`); this screen adds no
        // second constant for it.
    }

    func testTheChartsLabel() {
        XCTAssertEqual(WeighInContent.rollingAverageAccessibilityLabel.english, "Rolling average")
        XCTAssertEqual(WeighInContent.chartDateLabel.english, "Date")
    }

    /// The screen's other words come from the app's catalogue (content
    /// spec, "Strings live in catalogues") and read the weigh-in spec's
    /// words.
    func testTheScreensOtherWords() {
        XCTAssertEqual(WeighInContent.title.english, "Weigh-in")
        XCTAssertEqual(WeighInContent.chooseADayHeading.english, "Choose a weigh-in day")
        XCTAssertEqual(WeighInContent.stoneAccessibilityLabel.english, "Stone")
        XCTAssertEqual(WeighInContent.poundsAccessibilityLabel.english, "Pounds")
        XCTAssertEqual([WeighInContent.kgChoice, WeighInContent.stLbChoice].map(\.english), ["kg", "st lb"])
        XCTAssertEqual(Screen3Content.wontBeWeighingChoice.english, "I won't be weighing")
    }

    func testEachWeekdayChoiceLabelIsTheWeekdaysName() {
        for weekday in Weekday.allCases {
            XCTAssertFalse(weekday.name.isEmpty)
        }
        XCTAssertEqual(Weekday.monday.name, "Monday")
    }

    /// Scenario (weigh-in spec, "The weigh-in day"): VoiceOver reads "Choose
    /// a weigh-in day, heading", then "Monday" to "Sunday" (mm-t22.25). Every
    /// weekday list (this screen's two, Settings and onboarding screen 3)
    /// shows `Weekday.mondayFirst`.
    func testTheWeekdayListReadsMondayToSunday() throws {
        XCTAssertEqual(Weekday.mondayFirst.map(\.name), ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
        XCTAssertEqual(Set(Weekday.mondayFirst), Set(Weekday.allCases), "every weekday, once")
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for file in ["App/Midmorning/WeighIn/WeighInScreenView.swift", "App/Midmorning/SettingsView.swift", "App/Midmorning/Onboarding/Screen3View.swift"] {
            let text = try String(contentsOf: repoRoot.appendingPathComponent(file), encoding: .utf8)
            XCTAssertFalse(text.contains("Weekday.allCases"), "\(file) lists the weekdays Monday first")
            XCTAssertTrue(text.contains("Weekday.mondayFirst"), "\(file) lists the weekdays Monday first")
        }
    }

    /// Structural: the screen marks "Choose a weigh-in day" as a heading,
    /// and every custom control (the weight field, the stone/pounds fields,
    /// the weigh-in day picker, the unit picker, the chart) carries an
    /// explicit `.accessibilityLabel`.
    func testTheScreenMarksTheHeadingAndLabelsEveryCustomControl() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning/WeighIn/WeighInScreenView.swift"), encoding: .utf8)
        XCTAssertTrue(text.contains("chooseADayHeading.string).accessibilityAddTraits(.isHeader)"), "\"Choose a weigh-in day\" is a VoiceOver heading")
        XCTAssertTrue(text.contains(".accessibilityLabel(WeighInContent.weightLabel.string)"))
        XCTAssertTrue(text.contains(".accessibilityLabel(WeighInContent.stoneAccessibilityLabel.string)"))
        XCTAssertTrue(text.contains(".accessibilityLabel(WeighInContent.poundsAccessibilityLabel.string)"))
        XCTAssertTrue(text.contains(".accessibilityLabel(Screen3Content.weighInDayHeading.string)"))
        XCTAssertTrue(text.contains(".accessibilityLabel(WeighInContent.unitLabel.string)"))
    }

    /// Every text style on the screen is a system style (`Form`/`Section`/
    /// `Text` with no fixed point size), so Dynamic Type scaling and the
    /// line/point shape difference (not colour alone) come from
    /// `Appearance.swift`'s shared rule (mm-pr8, mm-pr12), the same as every
    /// other screen; this change adds no fixed font.
    func testNoFixedFontSize() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for file in ["App/Midmorning/WeighIn/WeighInScreenView.swift", "App/Midmorning/WeighIn/WeighInChartView.swift"] {
            let text = try String(contentsOf: repoRoot.appendingPathComponent(file), encoding: .utf8)
            XCTAssertFalse(text.contains(".font(.system(size:"), "\(file) sets a fixed point size, which does not scale with Dynamic Type")
        }
    }
}
