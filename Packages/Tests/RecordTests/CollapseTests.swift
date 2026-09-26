import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "Collapse a day to a count" (mm-t12.25).
@MainActor
final class CollapseTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    // MARK: Default and kept states (pure)

    /// Scenario: Default states. The current day defaults expanded, the
    /// previous day defaults collapsed, with no kept choice for either.
    func testDefaultStates() {
        XCTAssertTrue(CollapseDefault.isExpanded(role: .current, kept: nil))
        XCTAssertFalse(CollapseDefault.isExpanded(role: .previous, kept: nil))
    }

    /// Scenario: Default state of an earlier day. A day before the previous
    /// record day defaults expanded.
    func testDefaultStateOfAnEarlierDay() {
        XCTAssertTrue(CollapseDefault.isExpanded(role: .earlier, kept: nil))
    }

    /// A kept choice always wins over the role's default, for every role.
    func testKeptChoiceWinsOverTheDefault() {
        XCTAssertFalse(CollapseDefault.isExpanded(role: .current, kept: .collapsed))
        XCTAssertTrue(CollapseDefault.isExpanded(role: .previous, kept: .expanded))
        XCTAssertFalse(CollapseDefault.isExpanded(role: .earlier, kept: .collapsed))
    }

    // MARK: Store-backed scenarios

    /// Scenario: Collapse the current day, and Scenario: One entry. The
    /// count line reads the store's own entry count.
    func testCollapseReadsTheStoresEntryCount() throws {
        let store = try makeTemporaryStore()
        for i in 0..<8 {
            try store.add(time: at(8, i), what: "Entry \(i)", feltLikeABinge: false, createdAt: at(8, i), utcOffsetSeconds: 3600)
        }
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600, schedule: .standard)
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 8)

        let oneEntryStore = try makeTemporaryStore()
        try oneEntryStore.add(time: at(9, 0), what: "Toast", feltLikeABinge: false, createdAt: at(9, 0), utcOffsetSeconds: 3600)
        XCTAssertEqual(try oneEntryStore.entryCount(dayKey: dayKey), 1)
    }

    /// Scenario: Expand, and Scenario: Save into a collapsed day. Setting
    /// the choice to expanded is exactly what a save into a collapsed day
    /// must also do, per "the app MUST expand that day. The app MUST then
    /// keep the expanded state as the last choice".
    func testExpandAndSaveIntoACollapsedDayBothKeepExpanded() throws {
        let store = try makeTemporaryStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600, schedule: .standard)
        try store.setCollapseChoice(.collapsed, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .collapsed)

        // Saving an entry into a collapsed day expands it (the view calls
        // this after `add`, since the store itself holds no day-role rule).
        try store.setCollapseChoice(.expanded, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .expanded)
    }

    /// Scenario: Save into a collapsed day, and Scenario: Save into the
    /// previous day (mm-t12b.6). This is the composition `TodayView` runs
    /// after `NewEntryView` saves: it reads the kept choice, asks
    /// `choiceAfterSave` and keeps the answer. The expanded state survives
    /// the app opening again on the same record day.
    func testSaveIntoACollapsedDayExpandsItAndKeepsTheChoice() throws {
        let directory = try makeTemporaryDirectory()

        // The previous day, Thursday 24 September, with no kept choice: it
        // shows collapsed by default. The current day was collapsed by the
        // person.
        let previousKey = "2026-09-24"
        let currentKey = "2026-09-25"
        do {
            let store = try RecordStore(directory: directory)
            try store.add(time: at(12, 0), what: "Lunch", feltLikeABinge: false, createdAt: at(12, 0), utcOffsetSeconds: 3600)
            try store.setCollapseChoice(.collapsed, dateKey: currentKey)
            try store.add(time: at(9, 0, day: 25), what: "Toast", feltLikeABinge: false, createdAt: at(9, 0, day: 25), utcOffsetSeconds: 3600)

            for (key, role) in [(previousKey, RecordDayRole.previous), (currentKey, .current)] {
                let saved = try store.add(time: key == previousKey ? at(23, 30) : at(10, 0, day: 25), what: "Tea", feltLikeABinge: false, createdAt: at(1, 0, day: 25), utcOffsetSeconds: 3600)
                XCTAssertEqual(saved.dayKey, key)
                let kept = try store.collapseChoice(dateKey: saved.dayKey)
                XCTAssertFalse(CollapseDefault.isExpanded(role: role, kept: kept), "\(key) shows collapsed before the save")
                if let choice = CollapseDefault.choiceAfterSave(role: role, kept: kept) {
                    try store.setCollapseChoice(choice, dateKey: saved.dayKey)
                }
                XCTAssertTrue(CollapseDefault.isExpanded(role: role, kept: try store.collapseChoice(dateKey: key)), "\(key) shows expanded after the save")
            }
        }
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.collapseChoice(dateKey: previousKey), .expanded)
        XCTAssertTrue(CollapseDefault.isExpanded(role: .previous, kept: try reopened.collapseChoice(dateKey: previousKey)))
        XCTAssertEqual(try reopened.collapseChoice(dateKey: currentKey), .expanded)
    }

    /// A save into a day that already shows expanded writes no choice.
    func testSaveIntoAnExpandedDayKeepsNoNewChoice() {
        XCTAssertNil(CollapseDefault.choiceAfterSave(role: .current, kept: nil))
        XCTAssertNil(CollapseDefault.choiceAfterSave(role: .previous, kept: .expanded))
        XCTAssertEqual(CollapseDefault.choiceAfterSave(role: .previous, kept: nil), .expanded)
        XCTAssertEqual(CollapseDefault.choiceAfterSave(role: .current, kept: .collapsed), .expanded)
    }

    /// Scenario: Empty day. A day with no entries has no collapse control,
    /// which the view reads directly from a zero entry count.
    func testEmptyDayHasNoEntries() throws {
        let store = try makeTemporaryStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600, schedule: .standard)
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 0)
    }

    /// Scenario: Kept choice after the app opens again. The choice survives
    /// closing and reopening the store, because it is a `LocalSetting` row.
    func testKeptChoiceSurvivesReopeningTheStore() throws {
        let directory = try makeTemporaryDirectory()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600, schedule: .standard)
        do {
            let store = try RecordStore(directory: directory)
            try store.setCollapseChoice(.expanded, dateKey: dayKey)
        }
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.collapseChoice(dateKey: dayKey), .expanded)
    }

    /// A later choice for the same day replaces the earlier one; the store
    /// keeps one choice per day, not a history.
    func testALaterChoiceReplacesTheEarlierOne() throws {
        let store = try makeTemporaryStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600, schedule: .standard)
        try store.setCollapseChoice(.expanded, dateKey: dayKey)
        try store.setCollapseChoice(.collapsed, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .collapsed)
    }
}
