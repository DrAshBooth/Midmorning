import Foundation
import XCTest
import Accessibility
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
/// control a label, and the chart descriptor that the chart's one element
/// gives for the audio graph (mm-t45.16). `WeighInGate`'s own tests already
/// prove a weekday tap sets the day and that the input accepts a save with
/// no other sense needed. The UI tests in
/// `tools/skeleton-checks/HarnessUITests/AutomatedChecks+Accessibility.swift`
/// prove the labels, the heading and the text sizes on the screen. Ash does
/// no accessibility check on a device (8 October 2026).
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

    /// Scenario "VoiceOver on the chart" (mm-t45.16): "VoiceOver reads
    /// 'Rolling average' and offers the audio graph". The chart's one
    /// element gives its own chart descriptor: one series, "Rolling
    /// average", with one data point for each weigh-in, and the values and
    /// the dates read as the screen shows them.
    func testTheChartDescriptorHoldsTheLine() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let points = [
            RollingAveragePoint(dayKey: "2026-09-28", weightKg: 66.8, averageKg: 66.8),
            RollingAveragePoint(dayKey: "2026-10-05", weightKg: 66.2, averageKg: 66.5),
            RollingAveragePoint(dayKey: "2026-10-12", weightKg: 67.1, averageKg: 66.7),
        ]
        let descriptor = WeighInChartDescriptor.make(points: points, unit: .kg, calendar: calendar, title: "Rolling average", dateAxisTitle: "Date")
        XCTAssertEqual(descriptor.title, "Rolling average")
        XCTAssertEqual(descriptor.series.count, 1, "one series: the line")
        XCTAssertEqual(descriptor.series.first?.name, "Rolling average")
        XCTAssertEqual(descriptor.series.first?.isContinuous, true, "the series is a line")
        XCTAssertEqual(descriptor.series.first?.dataPoints.map { $0.yValue?.__number }, [66.8, 66.5, 66.7], "one point for each weigh-in, at its rolling average")
        let xAxis = descriptor.xAxis as? AXNumericDataAxisDescriptor
        let yAxis = descriptor.yAxis as? AXNumericDataAxisDescriptor
        XCTAssertEqual(xAxis?.title, "Date")
        XCTAssertEqual(yAxis?.title, "Rolling average")
        // The values of a data point are refined for Swift (`__number`).
        let firstX = descriptor.series.first?.dataPoints.first?.xValue.__number ?? 0
        XCTAssertEqual(xAxis?.valueDescriptionProvider(firstX), "28 September 2026", "the date in en_GB")
        XCTAssertEqual(yAxis?.valueDescriptionProvider(66.5), "66.5 kg", "the value in the person's unit")
    }

    /// With "st lb" the chart plots whole pounds, and the audio graph reads
    /// stone and pounds, as the screen does.
    func testTheChartDescriptorReadsStoneAndPounds() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let points = [RollingAveragePoint(dayKey: "2026-09-28", weightKg: 66.8, averageKg: 66.8)]
        let descriptor = WeighInChartDescriptor.make(points: points, unit: .stLb, calendar: calendar, title: "Rolling average", dateAxisTitle: "Date")
        let pounds = (66.8 / BMI.kgPerPound).rounded()
        XCTAssertEqual(descriptor.series.first?.dataPoints.map { $0.yValue?.__number }, [pounds], "one point, in whole pounds")
        let yAxis = descriptor.yAxis as? AXNumericDataAxisDescriptor
        XCTAssertEqual(yAxis?.valueDescriptionProvider(pounds), WeighInWeight.display(kg: 66.8, unit: .stLb), "the value reads as the screen shows it")
        XCTAssertLessThan(yAxis?.range.lowerBound ?? 0, yAxis?.range.upperBound ?? 0, "one point still gives the axis a range")
    }

    /// Structural (mm-t45.16): the chart view gives its one element the
    /// descriptor, after `.accessibilityElement(children: .ignore)`, so the
    /// audio graph does not depend on the descriptor that Swift Charts
    /// makes for the chart inside.
    func testTheChartsOneElementHasTheDescriptor() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning/WeighIn/WeighInChartView.swift"), encoding: .utf8)
        let element = try XCTUnwrap(text.range(of: ".accessibilityElement(children: .ignore)"), "the chart is one element")
        let descriptor = try XCTUnwrap(text.range(of: ".accessibilityChartDescriptor("), "the one element has a chart descriptor")
        XCTAssertLessThan(element.lowerBound, descriptor.lowerBound, "the descriptor comes after .accessibilityElement(children: .ignore)")
        XCTAssertTrue(text.contains("WeighInChartDescriptor.make("), "the descriptor is WeighInChartDescriptor's")
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
