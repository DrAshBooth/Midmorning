import Foundation
import XCTest
@testable import Record
@testable import Programme

/// record spec, "The Today stack" (mm-t12.15).
final class TodayStackTests: XCTestCase {
    /// Scenario: Reviews in the bottom toolbar, over the fixture fact that
    /// the first weekly review is due (decision 95); `weekly-review` (3.2)
    /// wires the live fact.
    func testReviewsInTheBottomToolbar() {
        XCTAssertEqual(BottomToolbar.items(reviewsDue: true), [.programme, .reviews, .settings])
    }

    /// Before the first weekly review becomes due, the toolbar shows no "Reviews".
    func testNoReviewsBeforeTheFirstOneIsDue() {
        XCTAssertEqual(BottomToolbar.items(reviewsDue: false), [.programme, .settings])
    }

    /// Scenario: Empty day, no cards. An empty current record day has no
    /// entries and no pending card.
    func testEmptyDayNoCards() {
        let calendar: Calendar = {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = TimeZone(identifier: "Europe/London")!
            return c
        }()
        let today = RecordDay.interval(containing: Date(timeIntervalSince1970: 1_758_700_800), calendar: calendar, schedule: .standard)
        XCTAssertNil(TodayCardSlot.next(pending: [PendingCard](), starredEntryOrOutcomeAt: nil, currentRecordDay: today))
    }
}
