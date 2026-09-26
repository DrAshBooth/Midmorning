import Foundation
import XCTest
@testable import Record
@testable import Plan

/// record spec, "The gap band", scenario "Gap over four hours", when both
/// entries match planned meals (mm-t23.18). Today draws a matched entry on
/// its planned meal row, not as a plain entry row. The band after an entry
/// must then follow the planned meal row that holds the entry. This test
/// proves the facts that Today's row mapping reads: the band index points
/// at the 08:00 entry, and that entry is the one on the Breakfast row.
@MainActor
final class PlanTodayGapBandTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: hour, minute: minute))!
    }

    func testTwoMatchedEntriesFiveAndAHalfHoursApartHaveABandAfterTheFirstPlannedRow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try RecordStore(directory: directory)
        try store.setTemplateSlotsJSON(PlanCodec.encode([PlannedMeal(slotIndex: 0, time: "08:00"), PlannedMeal(slotIndex: 2, time: "13:00")]), kind: .weekday, changedAt: at(6))
        let offset = london.timeZone.secondsFromGMT(for: at(8))
        try store.add(time: at(8), what: "Toast", feltLikeABinge: false, createdAt: at(8), utcOffsetSeconds: offset, dayStartHour: 4)
        try store.add(time: at(13, 30), what: "Soup", feltLikeABinge: false, createdAt: at(13, 30), utcOffsetSeconds: offset, dayStartHour: 4)

        let entries = try store.entries(dayKey: "2026-09-29")
        let plan = try store.resolvedPlan(dateKey: "2026-09-29")
        let recordDay = try XCTUnwrap(plan.recordDay(calendar: london))
        let rows = PlanTodayRows.compute(
            match: plan.match(entries: entries.map { PlanEntryFact(id: $0.id, time: $0.time) }, recordDay: recordDay, calendar: london),
            entries: entries.map { PlanDayEntry(id: $0.id, time: $0.time, starred: $0.feltLikeABinge) },
            answers: [:], quietHours: PlanQuietHours(isOn: true, start: "22:00", end: "07:00"),
            recordDay: recordDay, now: at(14), calendar: london
        )
        let bandIndexes = GapBand.indexesBeforeBand(sortedTimes: entries.map(\.time), stage2Open: true, dayHasExemptState: false, isCollapsed: false, maxAwakeGapHours: 4)

        XCTAssertEqual(bandIndexes, [0], "a band follows the 08:00 entry")
        XCTAssertEqual(rows.matchedEntryIds, Set(entries.map(\.id)), "both entries sit on planned meal rows")
        XCTAssertEqual(rows.rows.first { $0.slotIndex == 0 }?.matchedEntryId, entries[0].id, "the band follows the Breakfast row")
    }
}
