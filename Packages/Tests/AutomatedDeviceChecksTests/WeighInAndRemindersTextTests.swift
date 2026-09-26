import Foundation
import XCTest
import Constants
import Programme

/// Ruling r13-19 (mm-t43.30): text checks on mm-t22.16 and mm-t24.22 whose
/// words and rule a test can prove from the repository.
final class WeighInAndRemindersTextTests: XCTestCase {
    /// mm-t22.16, mm-t22.24 (commit 0d231f3): "On the weigh-in screen with
    /// 'st lb', enter 10 st 25 lb and tap Save. Make sure that 'That number
    /// is outside the range the app accepts. Check it and try again.' shows
    /// and that the app saves nothing. Enter 10 st 13 lb. Make sure that
    /// the app saves it."
    ///
    /// This test proves the rule (the parser refuses 25 lb and accepts 13
    /// lb) and the words. The part "shows the refusal and returns before
    /// the save" is proved from the source text only.
    /// `AutomatedChecks.testAPoundsValueOutOfRangeSavesNothing` does the
    /// save on the simulator and proves that nothing saves.
    func testAPoundsValueOutOfRangeShowsTheRefusal() throws {
        XCTAssertEqual(TypedMeasureParser.weightKg(stone: "10", pounds: "25"), .partOutOfRange)
        let valid = try XCTUnwrap(TypedMeasureParser.weightKg(stone: "10", pounds: "13").value)
        XCTAssertEqual(WeighInWeight.validate(kg: valid), .valid(kg: valid), "10 st 13 lb is a weight the app saves")
        XCTAssertEqual(ScreenText.english(WeighInWeight.belowRangeMessage), "That number is outside the range the app accepts. Check it and try again.")
        let screen = try ScreenText.source("WeighIn/WeighInScreenView.swift")
        let refusal = try XCTUnwrap(ScreenText.range(of: """
            case .partOutOfRange:
                belowRangeMessage = WeighInWeight.belowRangeMessage.string
                return
            """, in: screen), "\"st lb\" out of range shows the refusal and returns before the save")
        let save = try XCTUnwrap(ScreenText.range(of: "try? store.saveWeighIn(", in: screen))
        XCTAssertLessThan(refusal.lowerBound, save.lowerBound)
        try ScreenText.assertScreen("WeighIn/WeighInScreenView.swift", shows: ["if let belowRangeMessage { Text(verbatim: belowRangeMessage)"])
    }

    /// mm-t24.22, mm-t24.35 (commit 535403b) and mm-t24.37 items 1 and 2
    /// (commit 8e50d26): a reminder time or a planned meal inside quiet
    /// hours shows "This time is in quiet hours. The reminder will not be
    /// sent." With quiet hours off, the line goes.
    ///
    /// This test proves the rule (`QuietHours.contains`) and the words. That
    /// each screen calls the rule and shows the line is proved from the
    /// source text only.
    func testATimeInQuietHoursShowsTheLine() throws {
        XCTAssertEqual(ScreenText.english(.key("settings.reminders.quietHoursNotSent")), "This time is in quiet hours. The reminder will not be sent.")
        // mm-t24.35: quiet hours 21:00 to 06:00, "Close the day time" 21:45.
        XCTAssertTrue(QuietHours(isOn: true, start: "21:00", end: "06:00").contains("21:45"))
        // mm-t24.37 item 1: "Set today's plan time" 23:00, quiet hours 22:00 to 07:00, then off.
        XCTAssertTrue(QuietHours(isOn: true, start: "22:00", end: "07:00").contains("23:00"))
        XCTAssertFalse(QuietHours(isOn: false, start: "22:00", end: "07:00").contains("23:00"))
        // mm-t24.37 item 2: a planned meal at 22:30, on and off.
        XCTAssertTrue(QuietHours(isOn: true, start: "22:00", end: "07:00").contains("22:30"))
        XCTAssertFalse(QuietHours(isOn: false, start: "22:00", end: "07:00").contains("22:30"))
        try ScreenText.assertScreen("RemindersSettingsView.swift", shows: [
            "QuietHours(isOn: quietHoursOn, start: ClockTime.string(from: quietHoursStart), end: ClockTime.string(from: quietHoursEnd))",
            "if quietHours.contains(ClockTime.string(from: time)) { Text(\"settings.reminders.quietHoursNotSent\")",
        ] + ["setTodaysPlanTime", "closeTheDayTime", "weighInTime", "weeklyReviewTime"].map { "quietHoursLine(for: \($0))" })
        try ScreenText.assertScreen("PlanBuilderView.swift", shows: ["if quietHours.contains(meal.time) {", "Text(\"settings.reminders.quietHoursNotSent\")"])
    }
}
