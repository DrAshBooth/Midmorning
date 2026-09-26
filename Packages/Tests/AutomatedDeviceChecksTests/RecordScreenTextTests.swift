import Foundation
import XCTest
import Constants
import Record

/// Ruling r13-19 (mm-t43.30): the text check on mm-t12b.1 from mm-t11.39
/// (commit f6b57d3), "record strings now come from Localizable.xcstrings".
/// Each test names the words that the check asked Ash to look for, proves
/// them from the catalogue, and proves that the screen's App file shows
/// them. The logic under the words (the star, the Where on save, the
/// collapse, the day states) has its own tests in RecordTests.
final class RecordScreenTextTests: XCTestCase {
    /// "the new-entry and edit screens show 'felt like a binge', 'Context',
    /// and 'What was going on just before?' while the star is on".
    func testTheNewEntryAndEditScreensShowTheStarAndTheContextLabel() throws {
        XCTAssertEqual(ScreenText.english(.key("entry.feltLikeABinge")), "felt like a binge")
        XCTAssertEqual(ScreenText.english(ContextLabel.text(starOn: false)), "Context")
        XCTAssertEqual(ScreenText.english(ContextLabel.text(starOn: true)), "What was going on just before?")
        for screen in ["NewEntryView.swift", "EditEntryView.swift"] {
            try ScreenText.assertScreen(screen, shows: ["Toggle(\"entry.feltLikeABinge\"", "ContextLabel.text(starOn: feltLikeABinge)"])
        }
    }

    /// "the Where chips show Home, Work, Out and Travelling".
    func testTheWhereChipsShowTheFourFixedPlaces() throws {
        XCTAssertEqual(WhereChip.fixed.map { ScreenText.english($0.label) }, ["Home", "Work", "Out", "Travelling"])
        XCTAssertEqual(ScreenText.english(.key("entry.where.addAPlace")), "Add a place")
        try ScreenText.assertScreen("WhereChipsView.swift", shows: ["ForEach(WhereChip.fixed", "chip.label.string", "\"entry.where.addAPlace\""])
        for screen in ["NewEntryView.swift", "EditEntryView.swift"] {
            try ScreenText.assertScreen(screen, shows: ["WhereChipsView("])
        }
    }

    /// "a failed save shows 'Could not save. Try again.'".
    func testAFailedSaveShowsTheSaveFailureLine() throws {
        XCTAssertEqual(ScreenText.english(SaveOutcome.failureMessage), "Could not save. Try again.")
        for screen in ["NewEntryView.swift", "EditEntryView.swift"] {
            try ScreenText.assertScreen(screen, shows: ["Text(SaveOutcome.failureMessage.string)"])
        }
    }

    /// "Today shows 'Didn't record', 'Paused' (previous day) and 'Fasting'
    /// state lines".
    func testTodayShowsTheThreeStateLines() throws {
        XCTAssertEqual(ScreenText.english(.key("today.stateLine.didntRecord")), "Didn't record")
        XCTAssertEqual(ScreenText.english(.key("today.stateLine.paused")), "Paused")
        XCTAssertEqual(ScreenText.english(.key("today.stateLine.fasting")), "Fasting")
        try ScreenText.assertScreen("DaySection.swift", shows: [
            ".key(\"today.stateLine.didntRecord\")",
            "role == .current ? nil : .key(\"today.stateLine.paused\")",
            ".key(\"today.stateLine.fasting\")",
        ])
        try ScreenText.assertScreen("DaySectionView.swift", shows: ["if let stateLine = section.stateLine", "Text(stateLine.string)"])
    }

    /// "'1 entry' and '3 entries' on a collapsed day".
    func testACollapsedDayShowsItsCount() throws {
        XCTAssertEqual(ScreenText.english(.key("today.collapsed.entries %lld", .count(1))), "1 entry")
        XCTAssertEqual(ScreenText.english(.key("today.collapsed.entries %lld", .count(3))), "3 entries")
        try ScreenText.assertScreen("DaySectionView.swift", shows: ["CatalogueText.key(\"today.collapsed.entries %lld\", .count(count))"])
    }

    /// "', night' after the current day heading between 00:00 and the day
    /// start".
    func testTheCurrentDayHeadingShowsNightBeforeTheDayStart() throws {
        XCTAssertEqual(ScreenText.english(.key("today.heading.night", .verbatim("Friday 25 September"))), "Friday 25 September, night")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let recordDay = DateInterval(
            start: calendar.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 4))!,
            end: calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 4))!
        )
        let at0200 = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 2))!
        let at2300 = calendar.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 23))!
        XCTAssertTrue(RecordDay.isNight(at0200, inRecordDay: recordDay, calendar: calendar), "02:00 is after 00:00 and before the day start")
        XCTAssertFalse(RecordDay.isNight(at2300, inRecordDay: recordDay, calendar: calendar), "23:00 is before 00:00")
        try ScreenText.assertScreen("DayHeading.swift", shows: ["CatalogueText.key(\"today.heading.night\""])
        try ScreenText.assertScreen("DaySection.swift", shows: ["role == .current && RecordDay.isNight("])
    }

    /// "VoiceOver reads an entry row with 'felt like a binge'". The words
    /// that VoiceOver reads are the row's label.
    func testAStarredRowsLabelEndsWithFeltLikeABinge() throws {
        let row = RecordRow(
            id: UUID(), time: Date(timeIntervalSince1970: 1_790_000_000), utcOffsetSeconds: 3600,
            what: "Toast and tea", feltLikeABinge: true, createdAt: Date(), dayKey: "2026-09-21",
            whereText: "Home", context: "Row with my sister"
        )
        XCTAssertEqual(ScreenText.english(row.accessibilityLabel), "\(row.clockTime), Toast and tea, Home, Row with my sister, felt like a binge")
        try ScreenText.assertScreen("TodayView.swift", shows: [".accessibilityLabel(entry.accessibilityLabel.string)"])
    }

    /// "VoiceOver reads ... a gap band as 'Gap of more than 4 hours'".
    func testTheGapBandsLabel() throws {
        XCTAssertEqual(ScreenText.english(GapBand.accessibilityLabel(maxAwakeGapHours: 4)), "Gap of more than 4 hours")
        try ScreenText.assertScreen("TodayView.swift", shows: ["GapBand.accessibilityLabel(maxAwakeGapHours: ProgrammeConstants.default.maxAwakeGapHours)"])
    }
}
