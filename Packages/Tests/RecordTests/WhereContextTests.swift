import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// record spec, "Where chips" (mm-t12.16), "The Context field" (mm-t12.17),
/// "The new-entry screen's controls" (mm-t12b.4) and "Today shows Where and
/// Context" (mm-t12.18).
@MainActor
final class WhereContextTests: XCTestCase {
    private func london(_ hour: Int, _ minute: Int, day: Int = 25) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    // MARK: Where chips

    /// Scenario: Save with a fixed chip.
    func testSaveWithAFixedChip() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: WhereChip.home.rawValue)
        XCTAssertEqual(row.what, "Toast and tea")
        XCTAssertEqual(row.whereText, "Home")
    }

    /// Scenario: Save with no Where.
    func testSaveWithNoWhere() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600)
        XCTAssertEqual(row.whereText, "")
    }

    /// Scenario: Add a custom place.
    func testAddACustomPlace() throws {
        let store = try makeTemporaryStore()
        try store.touchCustomPlace("Mum's", at: london(13, 5))
        try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Mum's")
        let custom = try store.customPlaces()
        XCTAssertEqual(custom, ["Mum's"])
    }

    /// Scenario: Clear a chip.
    func testClearAChip() {
        let afterFirstTap = WhereSelection.afterTap(current: nil, tapped: "Work")
        XCTAssertEqual(afterFirstTap, "Work")
        let afterSecondTap = WhereSelection.afterTap(current: afterFirstTap, tapped: "Work")
        XCTAssertNil(afterSecondTap)
    }

    /// Scenario: Ninth custom place.
    func testNinthCustomPlaceDropsTheLeastRecentlyUsed() {
        let base = Date(timeIntervalSince1970: 0)
        var rows = (0..<8).map { i in
            ListItem(kind: "customPlace", text: "Place \(i)", changedAt: base.addingTimeInterval(Double(i) * 60))
        }
        rows.append(ListItem(kind: "customPlace", text: "Gym", changedAt: base.addingTimeInterval(9 * 60)))
        let ordered = CustomPlaces.ordered(rows)
        XCTAssertEqual(ordered.first, "Gym")
        XCTAssertEqual(ordered.count, 8)
        XCTAssertFalse(ordered.contains("Place 0"), "the least recently used place is gone")
    }

    /// Scenario: No suggestion from a previous entry. The store never
    /// suggests a previous entry's fields; `customPlaces()` only ever
    /// returns names the person explicitly kept as places, never a bare
    /// What or Context.
    func testCustomPlacesNeverIncludeWhatOrContext() throws {
        let store = try makeTemporaryStore()
        try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Mum's", context: "Row with my sister")
        try store.touchCustomPlace("Mum's", at: london(13, 5))
        XCTAssertEqual(try store.customPlaces(), ["Mum's"], "only the kept place, never the What or the Context")
    }

    /// A fixed chip's name is never kept as a custom place.
    func testAFixedChipIsNeverKeptAsACustomPlace() throws {
        let store = try makeTemporaryStore()
        try store.touchCustomPlace("Home", at: london(13, 5))
        XCTAssertEqual(try store.customPlaces(), [])
    }

    // MARK: The Context field

    /// Scenario: Star on changes one label, and Scenario: Star off.
    func testStarTogglesOnlyTheContextLabel() {
        XCTAssertEqual(ContextLabel.text(starOn: false), "Context")
        XCTAssertEqual(ContextLabel.text(starOn: true), "What was going on just before?")
    }

    /// Scenario: Starred entry with an empty Context.
    func testStarredEntryWithAnEmptyContext() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast", feltLikeABinge: true, createdAt: london(13, 5), utcOffsetSeconds: 3600, context: "")
        XCTAssertEqual(row.context, "")
        XCTAssertTrue(row.feltLikeABinge)
    }

    /// Scenario: Context with white space.
    func testContextWithWhiteSpaceIsTrimmed() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, context: "  Row with my sister ")
        XCTAssertEqual(row.context, "Row with my sister")
    }

    // MARK: The new-entry screen's controls

    /// Scenario: Order of the controls.
    func testOrderOfTheControls() {
        XCTAssertEqual(NewEntryField.order, [.what, .whereField, .star, .context, .time])
    }

    /// Scenario: The time control in the morning.
    func testTimeControlInTheMorning() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let friday = calendar.startOfDay(for: london(0, 0, day: 25))
        let resolved = NewEntryTime.resolve(segmentDate: friday, hour: 7, minute: 30, dayStartHour: 4, calendar: calendar)
        XCTAssertEqual(resolved, london(7, 30, day: 25))
    }

    /// Scenario: Last night's time after midnight.
    func testLastNightsTimeAfterMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let thursday = calendar.startOfDay(for: london(0, 0, day: 24))
        let resolved = NewEntryTime.resolve(segmentDate: thursday, hour: 23, minute: 30, dayStartHour: 4, calendar: calendar)
        XCTAssertEqual(resolved, london(23, 30, day: 24))
    }

    /// Scenario: A time before the day start.
    func testATimeBeforeTheDayStart() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let thursday = calendar.startOfDay(for: london(0, 0, day: 24))
        let resolved = NewEntryTime.resolve(segmentDate: thursday, hour: 1, minute: 30, dayStartHour: 4, calendar: calendar)
        XCTAssertEqual(resolved, london(1, 30, day: 25), "a time before the day start sits on the date after the segment")
        let dayKey = RecordDay.key(for: resolved, utcOffsetSeconds: 3600, startHour: 4)
        XCTAssertEqual(dayKey, "2026-09-24", "Today shows it under Thursday 24 September")
    }

    // MARK: Today shows Where and Context

    /// Scenario: Entry with Where and Context.
    func testEntryWithWhereAndContext() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Home", context: "Row with my sister")
        XCTAssertEqual(row.accessibilityLabel, "13:05, Toast and tea, Home, Row with my sister")
    }

    /// Scenario: Entry with an empty What and a Where.
    func testEntryWithAnEmptyWhatAndAWhere() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Out")
        XCTAssertEqual(row.accessibilityLabel, "13:05, Out")
    }

    // MARK: Accessibility of the additions

    /// Scenario: Label of a full row.
    func testLabelOfAFullRow() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "Toast and tea", feltLikeABinge: true, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Home", context: "Row with my sister")
        XCTAssertEqual(row.accessibilityLabel, "13:05, Toast and tea, Home, Row with my sister, felt like a binge")
    }

    /// Scenario: Label of a row with Where only.
    func testLabelOfARowWithWhereOnly() throws {
        let store = try makeTemporaryStore()
        let row = try store.add(time: london(13, 5), what: "", feltLikeABinge: false, createdAt: london(13, 5), utcOffsetSeconds: 3600, whereText: "Out")
        XCTAssertEqual(row.accessibilityLabel, "13:05, Out")
    }
}
