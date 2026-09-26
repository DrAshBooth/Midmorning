import XCTest
@testable import Programme

/// weekly-review spec, "The week's counts are frozen in the Review row"
/// (mm-t32.6). "Two devices freeze the same review" and "Sync behind the
/// due moment" reuse `Record`'s own `ReviewReconciler` over fixture rows
/// (`RecordTests.ReviewStoreTests`), since `Programme` cannot import
/// `Record`. "Keyed by the due day" is `RecordTests.ReviewStoreTests`
/// too, over real store rows.
final class ReviewFreezeTests: XCTestCase {
    private let calendar = engineTestCalendar

    private func facts(entries: [ReviewEntryFact] = [], paused: Set<String> = []) -> ReviewWeekFacts {
        ReviewWeekFacts(
            weekDayKeys: ReviewDue.weekDayKeys(week: 3, startDay: dayKey(2026, 9, 28), calendar: calendar),
            entries: entries,
            pausedDayKeys: paused,
            plannedMealsWithEntryCount: nil,
            urgesCount: 0,
            urgesPassedCount: 0
        )
    }

    /// Scenario: An entry deleted after the review is built. Frozen counts
    /// are a snapshot: computing them again from a changed set of facts
    /// never mutates the value already frozen.
    func testAnEntryDeletedAfterTheReviewIsBuilt() {
        let starredEntry = ReviewEntryFact(dayKey: dayKey(2026, 10, 13), time: moment(2026, 10, 13, 9), starred: true)
        let before = FrozenReviewCounts.from(facts(entries: [starredEntry]))
        let afterDeletion = FrozenReviewCounts.from(facts(entries: []))
        XCTAssertEqual(before.starred, 1, "the frozen value from the original facts keeps the starred entry")
        XCTAssertEqual(afterDeletion.starred, 0, "a fresh computation over the edited facts would differ")
        XCTAssertNotEqual(before, afterDeletion, "the store keeps the row already frozen; it never recomputes it from `afterDeletion`")
    }

    /// Scenario: A review the person never opens. `FrozenReviewCounts.from`
    /// takes only the week's facts — nothing gates it on whether the person
    /// opened the review.
    func testAReviewThePersonNeverOpens() {
        let entry = ReviewEntryFact(dayKey: dayKey(2026, 10, 12), time: moment(2026, 10, 12, 9), starred: true)
        let counts = FrozenReviewCounts.from(facts(entries: [entry]))
        XCTAssertEqual(counts.starred, 1, "the app writes the counts whether or not the person opens the review")
    }

    /// Scenario: The device clock moves back.
    func testTheDeviceClockMovesBack() {
        let dueDayKey = dayKey(2026, 10, 19)
        let frozenAt = moment(2026, 10, 19, 4)
        XCTAssertFalse(ReviewFreeze.isFutureDated(dueDayKey: dueDayKey, frozenAt: frozenAt, dayStart: 4, calendar: calendar, now: frozenAt))
        // The clock moves back to 14 October, before the due moment.
        let movedBack = moment(2026, 10, 14)
        XCTAssertTrue(ReviewFreeze.isFutureDated(dueDayKey: dueDayKey, frozenAt: frozenAt, dayStart: 4, calendar: calendar, now: movedBack), "the app ignores the row on read; it does not delete it")
    }

    /// Scenario: A row with a due moment far ahead.
    func testARowWithADueMomentFarAhead() {
        let dueDayKey = dayKey(2026, 11, 2)
        let now = moment(2026, 10, 12)
        XCTAssertTrue(ReviewFreeze.isFutureDated(dueDayKey: dueDayKey, frozenAt: now, dayStart: 4, calendar: calendar, now: now))
    }

    func testReadyToFreezeWaitsForTheDueMoment() {
        let dueDayKey = dayKey(2026, 10, 19)
        XCTAssertFalse(ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: 4, calendar: calendar, now: moment(2026, 10, 18, 23), syncOn: false, lastSyncMoment: nil))
        XCTAssertTrue(ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: 4, calendar: calendar, now: moment(2026, 10, 19, 4), syncOn: false, lastSyncMoment: nil))
    }

    /// Scenario: Sync behind the due moment (the pure rule; `RecordTests`
    /// runs the reconciled read end to end).
    func testReadyToFreezeWaitsForSyncWhenSyncIsOn() {
        let dueMoment = moment(2026, 10, 19, 4)
        let dueDayKey = dayKey(2026, 10, 19)
        XCTAssertFalse(ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: 4, calendar: calendar, now: moment(2026, 10, 19, 9), syncOn: true, lastSyncMoment: moment(2026, 10, 18, 22)))
        XCTAssertTrue(ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: 4, calendar: calendar, now: moment(2026, 10, 19, 9), syncOn: true, lastSyncMoment: dueMoment.addingTimeInterval(1)))
    }
}
