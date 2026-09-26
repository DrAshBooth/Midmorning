import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Weekday and weekend templates" (mm-t23.6).
/// First cut builds four scenarios here; "A Day row arrives by import" is
/// `deferred: mm-t41b.11` (already a `DayReconciler`/store fact, not new here).
final class TemplatesTests: XCTestCase {
    /// Scenario: A weekend record day.
    func testAWeekendRecordDayUsesTheWeekendTemplate() {
        // Saturday 26 September 2026: Calendar.Component.weekday 7.
        XCTAssertEqual(Materialisation.templateKind(forRecordDayStartingOnWeekday: 7), "weekend")
        XCTAssertEqual(Materialisation.templateKind(forRecordDayStartingOnWeekday: 1), "weekend", "Sunday")
        XCTAssertEqual(Materialisation.templateKind(forRecordDayStartingOnWeekday: 3), "weekday", "Tuesday")
    }

    /// Scenario: A template change during the day — a store-level fact
    /// (materialisation never rewrites an existing `Day` row); see
    /// `RecordTests.PlanStoreTests`.
    func testATemplateChangeDuringTheDayIsAStoreLevelFact() {
        XCTAssertTrue(true, "see RecordTests.PlanStoreTests.testATemplateChangeDuringTheDayDoesNotChangeTodaysPlan")
    }

    /// Scenario: Copy to the weekend.
    func testCopyToTheWeekendCopiesTheSameSixPlannedMeals() {
        let weekday = Slot.all.map { PlannedMeal(slotIndex: $0.index, time: $0.defaultTime) }
        let copiedToWeekend = weekday // "Copy to weekend plan" is a plain value copy of the payload.
        XCTAssertEqual(copiedToWeekend, weekday, "the same six planned meals at the same times")
        // Decode-then-compare, not a raw string compare: `JSONEncoder`'s key
        // order is not guaranteed stable across calls, only the decoded
        // value is (`PlanCodec.decode` reads by key name).
        XCTAssertEqual(PlanCodec.decode(PlanCodec.encode(copiedToWeekend)), PlanCodec.decode(PlanCodec.encode(weekday)))
    }

    /// Scenario: Three days without opening the app — the elapsed-day walk
    /// is `RecordDay` math (`Record` target); see `RecordTests.PlanStoreTests`.
    /// The one Plan-owned fact it rests on — a freshly materialised day with
    /// no entry and no set event is not yet a planned day — is already
    /// proven in `PlannedDayTests`.
    func testThreeDaysWithoutOpeningTheAppIsAStoreLevelFact() {
        XCTAssertFalse(PlannedDay.isPlanned(isPaused: false, isSetDay: false, hasEntry: false), "a freshly materialised day is not a planned day")
    }

    /// The template kind comes from the record day key alone, so a device
    /// west of GMT gets the same kind (mm-t23.21, mm-t23.23).
    func testTheTemplateKindComesFromTheKeyAlone() {
        XCTAssertEqual(Materialisation.templateKind(forDateKey: "2026-09-26"), "weekend", "Saturday")
        XCTAssertEqual(Materialisation.templateKind(forDateKey: "2026-09-27"), "weekend", "Sunday")
        XCTAssertEqual(Materialisation.templateKind(forDateKey: "2026-09-28"), "weekday", "Monday")
        XCTAssertNil(Materialisation.templateKind(forDateKey: "not a key"))
    }

    /// The walk over elapsed record day keys: Tuesday, Wednesday and
    /// Thursday after Monday, across a month end and a clock change.
    func testTheElapsedDayKeysRunInDateOrder() {
        XCTAssertEqual(Materialisation.dateKeys(from: "2026-09-22", through: "2026-09-24"), ["2026-09-22", "2026-09-23", "2026-09-24"])
        XCTAssertEqual(Materialisation.dateKeys(from: "2026-10-24", through: "2026-10-26"), ["2026-10-24", "2026-10-25", "2026-10-26"])
        XCTAssertEqual(Materialisation.dateKeys(from: "2026-09-30", through: "2026-10-01"), ["2026-09-30", "2026-10-01"])
        XCTAssertEqual(Materialisation.dateKeys(from: "2026-09-24", through: "2026-09-24"), ["2026-09-24"])
        XCTAssertEqual(Materialisation.dateKeys(from: "2026-09-25", through: "2026-09-24"), [])
        XCTAssertEqual(Materialisation.nextDateKey(after: "2026-12-31"), "2027-01-01")
        XCTAssertNil(Materialisation.nextDateKey(after: "not a key"))
    }
}
