import Foundation
import XCTest
import Constants
import Record

/// Ruling r13-19 (mm-t43.30): the text check on mm-t14.28 from mm-t11.39
/// (commit f6b57d3): "onboarding screen 3 reads 'Today, <weekday date>'
/// and 'Tomorrow, <weekday date>' and 'A day runs from 04:00 to 03:59.'
/// from Localizable.xcstrings". The test proves the three lines from the
/// catalogue. That `Screen3View.swift` shows them is proved from the source
/// text only; `AutomatedChecks.testOnboardingScreen3` finds them on the
/// screen.
final class OnboardingScreenTextTests: XCTestCase {
    func testScreen3ShowsTheStartDayChoicesAndTheDayBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let thursdayMorning = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 9))!
        XCTAssertEqual(ScreenText.english(StartDayChoice.label(for: .today, now: thursdayMorning, calendar: calendar, schedule: .standard)),
                       "Today, Thursday 24 September")
        XCTAssertEqual(ScreenText.english(StartDayChoice.label(for: .tomorrow, now: thursdayMorning, calendar: calendar, schedule: .standard)),
                       "Tomorrow, Friday 25 September")
        XCTAssertEqual(ScreenText.english(DayBoundaryLine.text(startHour: 4)), "A day runs from 04:00 to 03:59.")
        try ScreenText.assertScreen("Onboarding/Screen3View.swift", shows: [
            "Text(StartDayChoice.label(for: .today,",
            "Text(StartDayChoice.label(for: .tomorrow,",
            "Text(DayBoundaryLine.text(startHour: dayStartHour).string)",
        ])
    }
}
