import XCTest
@testable import Programme

/// weekly-review spec, "The one thing to change and the pinned note",
/// decision 90 (mm-t32.10). Only the hold itself is a pure function; the
/// text plumbing ("A pinned note appears", "The next review replaces it",
/// "The next review leaves it empty", "Edit from Today") is
/// `RecordTests.ReviewStoreTests` over the real store.
final class PinnedNoteHoldTests: XCTestCase {
    private let calendar = engineTestCalendar

    private func recordDay(_ dayKey: String) -> DateInterval {
        let start = DayKeyMath.dayStartMoment(for: dayKey, dayStart: 4, calendar: calendar)
        let end = DayKeyMath.dayStartMoment(for: DayKeyMath.adding(1, to: dayKey, calendar: calendar), dayStart: 4, calendar: calendar)
        return DateInterval(start: start, end: end)
    }

    /// Scenario: A starred entry holds the pinned note.
    func testAStarredEntryHoldsThePinnedNote() {
        let savedAt = moment(2026, 10, 12, 22, 10)
        XCTAssertTrue(PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: savedAt, currentRecordDay: recordDay(dayKey(2026, 10, 12))))
        XCTAssertFalse(PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: savedAt, currentRecordDay: recordDay(dayKey(2026, 10, 13))), "the pinned note comes back the first time Today appears on the next record day")
    }

    /// Scenario: A binge outcome holds the pinned note (fixture fact;
    /// `mm-t31.19` runs it end to end once `urge-toolkit` lands).
    func testABingeOutcomeHoldsThePinnedNote() {
        let outcomeAt = moment(2026, 10, 12, 23, 0)
        XCTAssertTrue(PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: outcomeAt, currentRecordDay: recordDay(dayKey(2026, 10, 12))))
    }

    func testNoHoldWithNoStarredEntryOrOutcome() {
        XCTAssertFalse(PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: nil, currentRecordDay: recordDay(dayKey(2026, 10, 12))))
    }
}
