import Foundation
import XCTest
@testable import Export
@testable import Record
import RecordTestSupport

/// export spec, "The PDF is formatted like the paper record", "Each entry
/// in the PDF", "Days with no entries, \"didn't record\" days and paused
/// days", "What the PDF never contains".
@MainActor
final class ExportDocumentBuilderTests: XCTestCase {
    private func row(time: String, dayKey: String, what: String = "", starred: Bool = false, whereText: String = "", context: String = "") -> RecordRow {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .gmt
        let clock = formatter.date(from: time) ?? Date()
        return RecordRow(id: UUID(), time: clock, utcOffsetSeconds: 0, what: what, feltLikeABinge: starred, createdAt: clock, dayKey: dayKey, whereText: whereText, context: context)
    }

    // MARK: The first page

    /// Scenario: The first page.
    func testFirstPageOrderOfFrontMatter() {
        let request = ExportBuildRequest(fromDayKey: "2026-08-28", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [])
        let kinds = document.contentLines().map(\.kind)
        XCTAssertEqual(kinds[0], .documentTitle)
        XCTAssertEqual(kinds[1], .rangeLine)
        XCTAssertEqual(kinds[2], .preambleLine)
        XCTAssertEqual(kinds[3], .starLegendLine)
        XCTAssertEqual(kinds[4], .dayRunLine)
        XCTAssertEqual(kinds[5], .dayHeading(dayIndex: 0))

        let lines = document.contentLines()
        XCTAssertEqual(lines[0].text, "Record")
        XCTAssertEqual(lines[1].text, "28 August\u{2009}–\u{2009}24 September 2026")
        XCTAssertEqual(lines[2].text, "Self-recorded on a phone. Times and words are the person's own.")
        XCTAssertEqual(lines[3].text, "* felt like a binge")
        XCTAssertEqual(lines[4].text, "A day runs from 04:00 to 03:59.")
    }

    /// Scenario: A day start other than 04:00.
    func testADayStartOtherThan0400() {
        let request = ExportBuildRequest(fromDayKey: "2026-08-28", toDayKey: "2026-08-28", includeContext: true, dayStartHour: 5)
        let document = ExportDocumentBuilder.build(request: request, days: [])
        XCTAssertEqual(document.dayRunLine, "A day runs from 05:00 to 04:59.")
    }

    // MARK: Two days in order / Days flow on one page

    /// Scenario: Two days in order.
    func testTwoDaysInOrder() {
        let day1 = ExportDayInput(dayKey: "2026-09-21", entries: [row(time: "08:00", dayKey: "2026-09-21")], states: [])
        let day2 = ExportDayInput(dayKey: "2026-09-22", entries: [row(time: "08:00", dayKey: "2026-09-22")], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-21", toDayKey: "2026-09-22", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day1, day2])
        XCTAssertEqual(document.days.map(\.heading), ["Monday 21 September 2026", "Tuesday 22 September 2026"])
    }

    /// Scenario: A range of one day.
    func testARangeOfOneDayHoldsThatDayAndNoOther() {
        let day = ExportDayInput(dayKey: "2026-09-21", entries: [row(time: "08:00", dayKey: "2026-09-21")], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-21", toDayKey: "2026-09-21", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days.count, 1)
        XCTAssertEqual(document.days[0].dayKey, "2026-09-21")
    }

    // MARK: Entry after midnight

    /// Scenario: Entry after midnight.
    func testEntryAfterMidnightStaysUnderItsStoredDayKey() {
        let entry = row(time: "00:30", dayKey: "2026-09-24", what: "Late snack")
        let earlier = row(time: "20:00", dayKey: "2026-09-24", what: "Dinner")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [earlier, entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].entries.map(\.clockTime), ["20:00", "00:30"], "the caller (RecordStore.entries) already sorts by time; the builder keeps that order")
    }

    // MARK: The day start changed after a save

    /// Scenario: The day start changed after a save. The builder never
    /// recomputes a stored day key from `dayStartHour`; it only uses
    /// `dayStartHour` for the front-matter line.
    func testChangingTheDayStartNeverMovesAStoredEntry() {
        let entry = row(time: "04:30", dayKey: "2026-09-25", what: "Breakfast")
        let day = ExportDayInput(dayKey: "2026-09-25", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-25", toDayKey: "2026-09-25", includeContext: true, dayStartHour: 5)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].heading, "Friday 25 September 2026")
        XCTAssertEqual(document.days[0].entries.count, 1)
    }

    // MARK: Context left out

    /// Scenario: Context left out.
    func testContextLeftOutHasNoContextHeadingOrText() {
        let entry = row(time: "08:00", dayKey: "2026-09-24", what: "Toast", context: "Row with my sister")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: false, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        let headingsLine = document.contentLines().first { if case .columnHeadings = $0.kind { return true } else { return false } }
        XCTAssertNotNil(headingsLine)
        XCTAssertFalse(headingsLine!.text.contains("Context"))
        let entryLine = document.contentLines().first { if case .entryLine = $0.kind { return true } else { return false } }
        XCTAssertEqual(entryLine?.entry?.accessibilityText(includeContext: false), "08:00 Toast")
        XCTAssertFalse((entryLine?.entry?.accessibilityText(includeContext: false) ?? "").contains("Row with my sister"))
    }

    func testContextIncludedShowsTheHeadingAndText() {
        let entry = row(time: "08:00", dayKey: "2026-09-24", what: "Toast", context: "Row with my sister")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        let headingsLine = document.contentLines().first { if case .columnHeadings = $0.kind { return true } else { return false } }
        XCTAssertTrue(headingsLine!.text.contains("Context"))
    }

    // MARK: Days with no entries, "didn't record" and paused

    /// Scenario: Empty day.
    func testEmptyDayShowsHeadingAndNothingElse() {
        let request = ExportBuildRequest(fromDayKey: "2026-09-22", toDayKey: "2026-09-22", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [])
        XCTAssertEqual(document.days.count, 1)
        XCTAssertEqual(document.days[0].heading, "Tuesday 22 September 2026")
        XCTAssertTrue(document.days[0].stateLines.isEmpty)
        XCTAssertTrue(document.days[0].entries.isEmpty)
        let dayLines = document.contentLines().filter { $0.dayIndex == 0 }
        XCTAssertEqual(dayLines.count, 1, "only the heading itself; no state line, no column headings, no entries")
    }

    /// Scenario: "Didn't record" day.
    func testDidntRecordDay() {
        let day = ExportDayInput(dayKey: "2026-09-22", entries: [], states: [.didntRecord])
        let request = ExportBuildRequest(fromDayKey: "2026-09-22", toDayKey: "2026-09-22", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].stateLines, ["Didn't record"])
    }

    /// Scenario: Paused day with entries.
    func testPausedDayWithEntriesShowsStateThenEntries() {
        let entries = [row(time: "08:00", dayKey: "2026-09-24"), row(time: "13:05", dayKey: "2026-09-24")]
        let day = ExportDayInput(dayKey: "2026-09-24", entries: entries, states: [.paused])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].stateLines, ["Paused"])
        XCTAssertEqual(document.days[0].entries.count, 2)
    }

    func testBothStatesShowDidntRecordFirst() {
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [], states: [.paused, .didntRecord])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].stateLines, ["Didn't record", "Paused"])
    }

    // MARK: Each entry in the PDF

    /// Scenario: A starred entry.
    func testAStarredEntry() {
        let entry = row(time: "21:40", dayKey: "2026-09-24", what: "Crisps and half a loaf", starred: true, whereText: "Home", context: "Row with my sister")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        let built = document.days[0].entries[0]
        XCTAssertEqual(built.clockTime, "21:40")
        XCTAssertTrue(built.starred)
        XCTAssertEqual(built.what, "Crisps and half a loaf")
        XCTAssertEqual(built.whereText, "Home")
        XCTAssertEqual(built.context, "Row with my sister")
    }

    /// Scenario: One pass per entry.
    func testOnePassAccessibilityTextForAStarredEntry() {
        let entry = ExportEntryLine(clockTime: "21:40", starred: true, what: "Crisps and half a loaf", whereText: "Home", context: "Row with my sister")
        XCTAssertEqual(entry.accessibilityText(includeContext: true), "21:40 * Crisps and half a loaf Home Row with my sister")
    }

    /// Scenario: An unstarred entry with What only.
    func testAnUnstarredEntryWithWhatOnly() {
        let entry = row(time: "13:05", dayKey: "2026-09-24", what: "Toast and tea")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        let built = document.days[0].entries[0]
        XCTAssertEqual(built.clockTime, "13:05")
        XCTAssertFalse(built.starred)
        XCTAssertEqual(built.what, "Toast and tea")
        XCTAssertEqual(built.whereText, "")
        XCTAssertEqual(built.context, "")
    }

    /// Scenario: An entry saved the next morning. The builder shows the
    /// entry's own clock time; it carries no creation-moment label at all.
    func testAnEntrySavedTheNextMorningShowsNoCreationLabel() {
        let entry = row(time: "23:30", dayKey: "2026-09-24", what: "Late snack")
        let day = ExportDayInput(dayKey: "2026-09-24", entries: [entry], states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].entries[0].clockTime, "23:30")
    }

    // MARK: What the PDF never contains

    /// Scenario: A day with fifteen entries.
    func testFifteenEntriesShowNoCount() {
        let entries = (0..<15).map { i in row(time: String(format: "%02d:00", i), dayKey: "2026-09-24", starred: i < 3) }
        let day = ExportDayInput(dayKey: "2026-09-24", entries: entries, states: [])
        let request = ExportBuildRequest(fromDayKey: "2026-09-24", toDayKey: "2026-09-24", includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertEqual(document.days[0].entries.count, 15)
        // The value type carries no count field at all; there is nothing a
        // renderer could show, so this is a structural guarantee.
    }

    /// Scenario: A deleted entry — proven from the real store, since
    /// `RecordStore.entries(dayKey:)` is what filters a deleted version out
    /// before the builder ever sees it.
    func testADeletedEntryNeverReachesTheDocument() throws {
        let store = try makeTemporaryStore()
        let saved = try store.add(time: Date(timeIntervalSince1970: 1_758_531_900), what: "Crisps", feltLikeABinge: false, createdAt: .now, utcOffsetSeconds: 0, dayStartHour: 4)
        try store.delete(entryId: saved.id, deletedAt: .now.addingTimeInterval(60))
        let rows = try store.entries(dayKey: saved.dayKey)
        XCTAssertTrue(rows.isEmpty)
        let day = ExportDayInput(dayKey: saved.dayKey, entries: rows, states: [])
        let request = ExportBuildRequest(fromDayKey: saved.dayKey, toDayKey: saved.dayKey, includeContext: true, dayStartHour: 4)
        let document = ExportDocumentBuilder.build(request: request, days: [day])
        XCTAssertTrue(document.days[0].entries.isEmpty)
    }
}
