import Foundation
import XCTest
@testable import Record

/// record spec, "Save is quiet", Scenario: Save on a long day (mm-t23.17).
/// After a save, Today scrolls to the id of the row that shows the saved
/// entry. `DaySection` gives each row the same `scrollId`.
final class TodayRowIdTests: XCTestCase {
    private let entryId = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!

    /// An entry that matches no planned meal has its own row.
    func testAnUnmatchedEntryScrollsToItsOwnRow() {
        XCTAssertEqual(
            TodayRowId.scrollId(forEntry: entryId, dateKey: "2026-09-26", matchedSlotIndex: nil),
            "2026-09-26/entry-6F9619FF-8B86-D011-B42D-00C04FC964FF"
        )
        XCTAssertEqual(
            TodayRowId.scrollId(forEntry: entryId, dateKey: "2026-09-26", matchedSlotIndex: nil),
            TodayRowId.scrollId(dateKey: "2026-09-26", rowId: TodayRowId.entry(entryId)),
            "the save target and the row's own id agree"
        )
    }

    /// An entry that matches a planned meal shows on that meal's row.
    func testAMatchedEntryScrollsToThePlannedMealRow() {
        XCTAssertEqual(
            TodayRowId.scrollId(forEntry: entryId, dateKey: "2026-09-26", matchedSlotIndex: 2),
            TodayRowId.scrollId(dateKey: "2026-09-26", rowId: TodayRowId.planned(slotIndex: 2))
        )
    }

    /// The current day and the previous day can each show a row for slot
    /// 2; their ids differ, so the scroll finds the right day.
    func testTheSameSlotOnTwoDaysHasTwoIds() {
        XCTAssertNotEqual(
            TodayRowId.scrollId(dateKey: "2026-09-25", rowId: TodayRowId.planned(slotIndex: 2)),
            TodayRowId.scrollId(dateKey: "2026-09-26", rowId: TodayRowId.planned(slotIndex: 2))
        )
    }

    /// The id is a String, the same type as the rows' ids, never the
    /// entry's UUID (the defect that mm-t23.17 names).
    func testTheIdIsNotTheBareUUID() {
        let id = TodayRowId.scrollId(forEntry: entryId, dateKey: "2026-09-26", matchedSlotIndex: nil)
        XCTAssertNotEqual(id, entryId.uuidString)
        XCTAssertTrue(id.hasSuffix(TodayRowId.entry(entryId)))
    }
}
