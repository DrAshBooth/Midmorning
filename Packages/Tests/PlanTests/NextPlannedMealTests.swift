import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "The next-planned-meal line" (mm-t23.12).
final class NextPlannedMealTests: XCTestCase {
    private let dayStartHour = 4
    private func minutes(_ time: String) -> Int { PlanOrdering.minutesAfterDayStart(time: time, dayStartHour: dayStartHour) }

    private let lunch = PlanMealFact(label: "Lunch", time: "13:00", kind: .meal)
    private let midAfternoon = PlanMealFact(label: "Mid-afternoon", time: "16:00", kind: .snack)
    private let breakfastTomorrow = PlanMealFact(label: "Breakfast", time: "08:00", kind: .meal)

    /// Scenario: Skip lunch.
    func testSkipLunch() {
        let next = NextPlannedMeal.find(orderedTodayMeals: [lunch, midAfternoon], afterMinutesIntoDay: minutes("13:00"), dayStartHour: dayStartHour, firstOfNextDay: nil)
        XCTAssertEqual(next, midAfternoon)
        XCTAssertEqual(NextPlannedMeal.line(for: next!), "Mid-afternoon at 16:00 still happens.")
    }

    /// Scenario: Skip lunch from the reminder.
    func testSkipLunchFromTheReminder() {
        let next = NextPlannedMeal.find(orderedTodayMeals: [lunch, midAfternoon], afterMinutesIntoDay: minutes("13:05"), dayStartHour: dayStartHour, firstOfNextDay: nil)
        XCTAssertEqual(next, midAfternoon)
    }

    /// Scenario: Skip the last planned meal of the day.
    func testSkipTheLastPlannedMealOfTheDay() {
        let eveningSnack = PlanMealFact(label: "Evening snack", time: "21:00", kind: .snack)
        let next = NextPlannedMeal.find(orderedTodayMeals: [eveningSnack], afterMinutesIntoDay: minutes("21:00"), dayStartHour: dayStartHour, firstOfNextDay: breakfastTomorrow)
        XCTAssertEqual(next, breakfastTomorrow)
        XCTAssertEqual(NextPlannedMeal.line(for: next!), "Breakfast at 08:00 still happens.")
    }

    /// Scenario: A starred entry between planned meals.
    func testAStarredEntryBetweenPlannedMeals() {
        // 14:45 matches no window; the new-entry screen shows nothing, and
        // Today's next call uses the entry's own moment.
        let next = NextPlannedMeal.find(orderedTodayMeals: [lunch, midAfternoon], afterMinutesIntoDay: minutes("14:45"), dayStartHour: dayStartHour, firstOfNextDay: nil)
        XCTAssertEqual(next, midAfternoon)
    }

    /// Scenario: A starred entry that matches a planned meal. The next
    /// planned meal after a match MUST NOT be the meal the entry matches —
    /// the caller excludes the matched slot before calling `find`.
    func testAStarredEntryThatMatchesAPlannedMeal() {
        let todayExcludingTheMatchedSlot = [midAfternoon] // Lunch removed: it is the matched slot
        let next = NextPlannedMeal.find(orderedTodayMeals: todayExcludingTheMatchedSlot, afterMinutesIntoDay: minutes("13:10"), dayStartHour: dayStartHour, firstOfNextDay: nil)
        XCTAssertEqual(next, midAfternoon, "Mid-afternoon; nothing on the Lunch row")
    }

    /// Scenario: The next planned meal arrives.
    func testTheNextPlannedMealArrivesHidesTheLine() {
        let todayExcludingTheMatchedSlot: [PlanMealFact] = [] // Mid-afternoon now matched too
        let next = NextPlannedMeal.find(orderedTodayMeals: todayExcludingTheMatchedSlot, afterMinutesIntoDay: minutes("16:05"), dayStartHour: dayStartHour, firstOfNextDay: nil)
        XCTAssertNil(next, "the entry matches Mid-afternoon and Today hides the line")
    }

    /// Scenario: The window ends. Once Mid-afternoon's own window ends
    /// unmatched, it becomes the missed-planned-meal prompt's concern, not
    /// the next-planned-meal line's.
    func testTheWindowEndsHandsOffToTheMissedPrompt() {
        let calendar = Calendar(identifier: .gregorian)
        let windowEnd = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 17, minute: 30))!
        let now = windowEnd
        let midAfternoonMissed = MissedPlannedMeal(slotIndex: 3, windowEnd: windowEnd, hasMatchedEntry: false, hasSkippedAnswer: false, hasLaterEntry: false, laterSlotAnswered: false, windowEndsInQuietHours: false)
        XCTAssertTrue(MissedMealPrompt.isMissed(midAfternoonMissed, now: now), "the missed planned meal prompt now applies")
    }
}
