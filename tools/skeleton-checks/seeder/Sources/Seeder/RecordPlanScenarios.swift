import Foundation
import Record
import Constants

/// The seeded stores for `HarnessUITests/AutomatedChecks+RecordPlan.swift`
/// (rulings r13-19 and r16-01, mm-t43.32): the record checks of mm-t12b.1
/// and the plan checks of mm-t23.15. `AutomatedScenarios.seed` makes the
/// store, marks onboarding as done and turns the app lock off, and then
/// calls `seed` here for these names.
///
/// Each time in a scenario comes from the moment of the seed, so that no
/// entry is after now and every planned meal falls in the current record
/// day. A scenario that needs a clock time in a test writes it to
/// `<stores>/<scenario>.json` (`facts`), beside the scenario's folder. The
/// test reads that file; the app never sees it.
///
/// The scenarios with stage 2 open have a stored stage 2 opening on the
/// record day 3 days ago, an answer to its opening card, no weekly review
/// due, and quiet hours off (so that a missed planned meal prompt does not
/// depend on the time of the run).
///
/// - `fifteen`: stage 1. Fifteen entries on the current record day, 12
///   minutes apart, the last one minute before now ("Entry 1" to "Entry 15").
/// - `fifteenPlan`: stage 2. One planned meal, Lunch, at the moment of the
///   seed (fact `lunch`), and fifteen entries that end 61 minutes before it,
///   so that no entry is in its window.
/// - `bands`: stage 2. Entries at 08:00 ("Porridge") and 13:30 ("Soup") on
///   each of the four record days before the current one. Stage 2 opened on
///   the second of them (facts `before`, `opened`, `after`, `previous`).
///   The current record day has no entry.
/// - `planMatched`: stage 2. Lunch 30 minutes before the seed (fact
///   `lunch`), and an entry 5 minutes after Lunch (fact `entry`): What
///   "Toast and tea", Where "Home", Context "Row with my sister".
/// - `planBand`: stage 2. Breakfast and Lunch at least 4 hours 29 minutes
///   apart (facts `breakfast` and `lunch`), each with an entry at its own
///   time ("Porridge" and "Soup").
/// - `planStar`: stage 2. A starred entry "Biscuits" one minute before the
///   seed (fact `entry`), Lunch 5 minutes after it and Mid-afternoon 20
///   minutes after it (facts `lunch` and `midAfternoon`).
/// - `planMissed`: stage 2. Lunch 2 hours 15 minutes before the seed (fact
///   `lunch`), with no entry, and an entry "Apple" 15 minutes before the seed
///   (fact `entry`) that matches no planned meal.
/// - `planEarly`: stage 2. "Day starts at" 07:00 in force from 2 record days
///   ago, and Breakfast at 06:00 in the weekday and the weekend plans.
/// - `dayStart6`: stage 1, no entry. "Day starts at" 06:00 in force from 2
///   record days ago, so that it is in force on the current record day in
///   every time zone.
/// - `planStrings`: stage 2. A weekday plan with Mid-morning at 10:30, Lunch
///   at 12:30 and Evening meal at 17:00: 2 meals and 1 snack, and a gap of 4
///   hours 30 minutes. The weekend plan is empty.
///
/// The plan scenarios put the same plan in the weekday and the weekend
/// templates (except `planStrings`), so the current record day has it on
/// any day of the week.
@MainActor
enum RecordPlanScenarios {
    static let names: Set<String> = [
        "fifteen", "fifteenPlan", "bands", "planMatched", "planBand", "planStar", "planMissed", "planEarly", "planStrings", "dayStart6",
    ]

    static func seed(_ scenario: String, store: RecordStore, now: Date, calendar: Calendar, directory: URL) throws {
        let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
        func dayStart(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today.start)! }
        func key(_ offset: Int) -> String { RecordDay.key(containing: dayStart(offset).addingTimeInterval(3600), calendar: calendar, schedule: .standard) }
        func clock(_ date: Date) -> String { ClockTime.string(from: date, calendar: calendar) }
        // The seed moment to the minute, as the store keeps an entry's time.
        let minute = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
        func minutes(_ count: Double) -> Date { minute.addingTimeInterval(count * 60) }

        var created = now.addingTimeInterval(-3600)
        func add(at time: Date, _ what: String, starred: Bool = false, whereText: String = "", context: String = "") throws {
            created = created.addingTimeInterval(1)
            try store.add(time: time, what: what, feltLikeABinge: starred, createdAt: created,
                          utcOffsetSeconds: calendar.timeZone.secondsFromGMT(for: time), whereText: whereText, context: context)
        }
        /// One plan in both templates. `meals` is (slot index, "HH:mm").
        func plan(_ meals: [(Int, String)], weekendToo: Bool = true) throws {
            let json = "[" + meals.sorted { $0.0 < $1.0 }.map { "{\"slot\":\($0.0),\"time\":\"\($0.1)\"}" }.joined(separator: ",") + "]"
            try store.setTemplateSlotsJSON(json, kind: .weekday, changedAt: created)
            try store.setTemplateSlotsJSON(weekendToo ? json : "[]", kind: .weekend, changedAt: created)
        }
        func stage2() throws {
            try store.setInstallMoment(dayStart(-7))
            try store.setStartDayKey(key(-6))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try store.recordStageOpened(2, at: dayStart(-3).addingTimeInterval(5 * 3600), dayKey: key(-3))
            try store.setCardAnswer("Close", id: "opening.2", changedAt: created)
            try store.setQuietHoursOn(false, changedAt: created)
        }
        var facts: [String: String] = [:]

        switch scenario {
        case "fifteen":
            try store.setInstallMoment(dayStart(-1))
            try store.setStartDayKey(key(0))
            try store.setWeighInDayChoice(.wontBeWeighing)
            for number in 1...15 {
                try add(at: minutes(-1 - Double(15 - number) * 12), "Entry \(number)")
            }
        case "fifteenPlan":
            try stage2()
            try plan([(2, clock(minute))])
            facts["lunch"] = clock(minute)
            for number in 1...15 {
                try add(at: minutes(-61 - Double(15 - number) * 12), "Entry \(number)")
            }
        case "bands":
            try stage2()
            try store.setCardAnswer("Close", id: "plancard.3", changedAt: created)
            for offset in -4...(-1) {
                try add(at: dayStart(offset).addingTimeInterval(4 * 3600), "Porridge")
                try add(at: dayStart(offset).addingTimeInterval(9.5 * 3600), "Soup")
            }
            facts = ["before": key(-4), "opened": key(-3), "after": key(-2), "previous": key(-1), "current": key(0)]
        case "planMatched":
            try stage2()
            let lunch = minutes(-30)
            try plan([(2, clock(lunch))])
            try add(at: lunch.addingTimeInterval(5 * 60), "Toast and tea", whereText: "Home", context: "Row with my sister")
            facts = ["lunch": clock(lunch), "entry": clock(lunch.addingTimeInterval(5 * 60))]
        case "planBand":
            try stage2()
            // As in `review`: 08:00 and 13:30 after 13:31; earlier in the
            // day, the second is one minute before now and the first is 5
            // hours 30 minutes before it, but not before 04:30.
            let lunch = min(dayStart(0).addingTimeInterval(9.5 * 3600), minutes(-1))
            let breakfast = max(lunch.addingTimeInterval(-5.5 * 3600), dayStart(0).addingTimeInterval(0.5 * 3600))
            try plan([(0, clock(breakfast)), (2, clock(lunch))])
            try add(at: breakfast, "Porridge")
            try add(at: lunch, "Soup")
            facts = ["breakfast": clock(breakfast), "lunch": clock(lunch)]
        case "planStar":
            try stage2()
            let entry = minutes(-1)
            try plan([(2, clock(entry.addingTimeInterval(5 * 60))), (3, clock(entry.addingTimeInterval(20 * 60)))])
            try add(at: entry, "Biscuits", starred: true)
            facts = ["entry": clock(entry), "lunch": clock(entry.addingTimeInterval(5 * 60)), "midAfternoon": clock(entry.addingTimeInterval(20 * 60))]
        case "planMissed":
            try stage2()
            let lunch = minutes(-135)
            try plan([(2, clock(lunch))])
            try add(at: minutes(-15), "Apple")
            facts = ["lunch": clock(lunch), "entry": clock(minutes(-15))]
        case "planEarly":
            try stage2()
            // Effective from the record day after 05:00 three days ago.
            try store.setDayStartHour(7, now: dayStart(-3).addingTimeInterval(3600), calendar: calendar, changedAt: created)
            try plan([(0, "06:00")])
        case "dayStart6":
            try store.setInstallMoment(dayStart(-3))
            try store.setStartDayKey(key(-2))
            try store.setWeighInDayChoice(.wontBeWeighing)
            // Effective from the record day after 05:00 three days ago.
            try store.setDayStartHour(6, now: dayStart(-3).addingTimeInterval(3600), calendar: calendar, changedAt: created)
        case "planStrings":
            try stage2()
            try plan([(1, "10:30"), (2, "12:30"), (4, "17:00")], weekendToo: false)
        default:
            return
        }
        if !facts.isEmpty {
            let file = directory.deletingLastPathComponent().appendingPathComponent("\(scenario).json")
            try JSONSerialization.data(withJSONObject: facts, options: [.sortedKeys]).write(to: file)
        }
    }
}
