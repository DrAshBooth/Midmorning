import XCTest
@testable import Programme

/// Safeguarding spec, "The not-right-now page" (mm-t14.22). Only "The record
/// stays" is built here; every other scenario needs a trigger `mm-t22`
/// (weigh-in), `mm-t32` (weekly-review) or `mm-t21` (programme-engine) build
/// later, over this same content, as fixture facts.
final class NotRightNowPageTests: XCTestCase {
    /// "The record stays": the page's content states no closing of the
    /// record, every open tool or export; nothing here disables them.
    func testTheRecordStays() {
        XCTAssertEqual(NotRightNowPage.recordStaysLine, "Your record stays here, and you can keep adding to it.")
    }

    func testOrderIsSelfHarmWeightPregnancyTreatment() {
        let ordered = NotRightNowPage.ordered([.treatment, .pregnancy, .weight, .selfHarm])
        XCTAssertEqual(ordered, [.selfHarm, .weight, .pregnancy, .treatment])
    }

    func testRemindersPausedOnlyWithWeightReason() {
        XCTAssertEqual(NotRightNowPage.remindersLine(for: [.selfHarm]), NotRightNowPage.remindersStayOnLine)
        XCTAssertEqual(NotRightNowPage.remindersLine(for: [.weight]), NotRightNowPage.remindersPausedLine)
    }

    func testPregnancyAndTreatmentReuseTheExclusionPageParagraphs() {
        XCTAssertEqual(NotRightNowPage.paragraph(for: .pregnancy), ExclusionPage.paragraph(for: .pregnancy))
        XCTAssertEqual(NotRightNowPage.paragraph(for: .treatment), ExclusionPage.paragraph(for: .treatment))
    }

    func testAgeNeverAppliesAtARescreen() {
        XCTAssertNil(NotRightNowPage.paragraph(for: .age))
    }
}
