import Foundation
import XCTest
@testable import Record

/// record spec, "The gap band" (mm-t12.26). Each scenario runs over a
/// fixture `stage2Open` fact, since `programme-engine` (2.1) is not built
/// yet; `mm-t21.23` wires the live stage into `GapBand`.
final class GapBandTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: hour, minute: minute))!
    }

    /// Scenario: Gap over four hours.
    func testGapOverFourHoursShowsABand() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(8, 0), at(13, 30)],
            stage2Open: true, dayHasExemptState: false, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [0])
    }

    /// Scenario: Gap of exactly four hours.
    func testGapOfExactlyFourHoursShowsNoBand() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(8, 0), at(12, 0)],
            stage2Open: true, dayHasExemptState: false, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [])
    }

    /// Scenario: Before stage 2.
    func testBeforeStage2ShowsNoBand() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(8, 0), at(13, 30)],
            stage2Open: false, dayHasExemptState: false, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [])
    }

    /// Scenario: Gap since the last entry. No band shows after the day's
    /// last entry, whatever the current time is: the function never sees a
    /// "now" input, so there is nothing after the last entry to band.
    func testGapSinceTheLastEntryShowsNoBandAfterIt() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(13, 0)],
            stage2Open: true, dayHasExemptState: false, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [], "one entry has no gap to band, whatever the current time is")
    }

    /// Scenario: "Didn't record" day.
    func testDidntRecordDayShowsNoBand() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(8, 0), at(20, 0)],
            stage2Open: true, dayHasExemptState: true, isCollapsed: false, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [])
    }

    /// mm-pr9, and record spec "Accessibility of the additions": the band's
    /// VoiceOver label, filled from MAX_AWAKE_GAP_HOURS.
    func testAccessibilityLabelFillsTheConstant() {
        XCTAssertEqual(GapBand.accessibilityLabel(maxAwakeGapHours: 4).english, "Gap of more than 4 hours")
        XCTAssertEqual(GapBand.accessibilityLabel(maxAwakeGapHours: 1).english, "Gap of more than 1 hour")
    }

    /// A collapsed day shows no band, whatever its gaps.
    func testCollapsedDayShowsNoBand() {
        let indexes = GapBand.indexesBeforeBand(
            sortedTimes: [at(8, 0), at(13, 30)],
            stage2Open: true, dayHasExemptState: false, isCollapsed: true, maxAwakeGapHours: 4
        )
        XCTAssertEqual(indexes, [])
    }
}
