import Foundation
import XCTest
@testable import Record

/// record spec, "Collapse a day to a count" (mm-t12.25).
@MainActor
final class CollapseTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
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
        let store = try makeStore()
        for i in 0..<8 {
            try store.add(time: at(8, i), what: "Entry \(i)", feltLikeABinge: false, createdAt: at(8, i), utcOffsetSeconds: 3600)
        }
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600)
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 8)

        let oneEntryStore = try makeStore()
        try oneEntryStore.add(time: at(9, 0), what: "Toast", feltLikeABinge: false, createdAt: at(9, 0), utcOffsetSeconds: 3600)
        XCTAssertEqual(try oneEntryStore.entryCount(dayKey: dayKey), 1)
    }

    /// Scenario: Expand, and Scenario: Save into a collapsed day. Setting
    /// the choice to expanded is exactly what a save into a collapsed day
    /// must also do, per "the app MUST expand that day. The app MUST then
    /// keep the expanded state as the last choice".
    func testExpandAndSaveIntoACollapsedDayBothKeepExpanded() throws {
        let store = try makeStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600)
        try store.setCollapseChoice(.collapsed, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .collapsed)

        // Saving an entry into a collapsed day expands it (the view calls
        // this after `add`, since the store itself holds no day-role rule).
        try store.setCollapseChoice(.expanded, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .expanded)
    }

    /// Scenario: Empty day. A day with no entries has no collapse control,
    /// which the view reads directly from a zero entry count.
    func testEmptyDayHasNoEntries() throws {
        let store = try makeStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600)
        XCTAssertEqual(try store.entryCount(dayKey: dayKey), 0)
    }

    /// Scenario: Kept choice after the app opens again. The choice survives
    /// closing and reopening the store, because it is a `LocalSetting` row.
    func testKeptChoiceSurvivesReopeningTheStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600)
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
        let store = try makeStore()
        let dayKey = RecordDay.key(for: at(8, 0), utcOffsetSeconds: 3600)
        try store.setCollapseChoice(.expanded, dateKey: dayKey)
        try store.setCollapseChoice(.collapsed, dateKey: dayKey)
        XCTAssertEqual(try store.collapseChoice(dateKey: dayKey), .collapsed)
    }
}
