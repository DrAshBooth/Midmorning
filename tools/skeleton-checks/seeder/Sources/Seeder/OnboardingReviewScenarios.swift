import Foundation
import Record

/// The seeded stores for `HarnessUITests/AutomatedChecks+OnboardingReview.swift`
/// (rulings r13-19 and r16-01; mm-t43.32 and mm-t43.33). `AutomatedScenarios`
/// turns the app lock off and marks onboarding as done before it calls this
/// file. Each scenario writes through `RecordStore`, as the app does, in the
/// Mac's own time zone. An entry is saved at its own time (its `createdAt`),
/// so the programme counts each recorded day from that moment.
///
/// - `or-tomorrow`: the start day is the next record day, so the Programme
///   screen shows "Starts tomorrow".
/// - `or-secondday`: week 1, on the second recorded day (one entry on the
///   previous record day and one today). Today shows the stage 1 card "Why
///   write it down" with "Read" and "Close".
/// - `or-plancard`: week 2. Stage 2 opened three record days ago, its
///   opening card is closed, and no plan is set. Today shows the plan card
///   "Your plan isn't set yet. It takes about two minutes.".
/// - `or-plan`: as `or-plancard`, with a plan: Breakfast at about two hours
///   before the seed, and at the latest 20:00. Its window ended, so Today
///   shows the missed planned meal prompt, and "Close the day" beside
///   "Pause for today".
/// - `or-pinned`: week 3. The review of week 1 is finished with the pinned
///   note "Eat breakfast"; the review of week 2 is due.
/// - `or-tworuns`: week 3. The reviews of weeks 1 and 2 are finished, each
///   with its own answers; the pinned note is "Plan lunch". A profile from
///   16 days ago, so "Start week 1 again" asks no re-screen.
/// - `or-deterioration`: week 6. Weeks 2 to 5 hold 2, 3, 4 and 5 starred
///   entries, so the app freezes those counts and the review of week 5
///   opens with the GP suggestion page (the deterioration rule).
/// - `or-weighin`: week 2. The weigh-in day is the weekday of five record
///   days ago, and that day holds a weigh-in, so the review of week 1 shows
///   "Weigh-in: done on <weekday>.".
@MainActor
enum OnboardingReviewScenarios {
    static let names: Set<String> = [
        "or-tomorrow", "or-secondday", "or-plancard", "or-plan", "or-pinned", "or-tworuns", "or-deterioration", "or-weighin",
    ]

    static func seed(_ scenario: String, store: RecordStore, now: Date, calendar: Calendar) throws {
        let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
        func dayStart(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today.start)! }
        func key(_ offset: Int) -> String {
            RecordDay.key(containing: dayStart(offset).addingTimeInterval(3600), calendar: calendar, schedule: .standard)
        }
        /// An entry `hours` after the day start of record day `offset`, or
        /// one minute before now when that time is not yet past. It is saved
        /// at its own time.
        func add(_ offset: Int, hours: Double, _ what: String, starred: Bool = false) throws {
            let time = min(dayStart(offset).addingTimeInterval(hours * 3600), now.addingTimeInterval(-60))
            try store.add(time: time, what: what, feltLikeABinge: starred, createdAt: time,
                          utcOffsetSeconds: calendar.timeZone.secondsFromGMT(for: time))
        }
        /// A profile asked at the day start of record day `offset`. A profile
        /// from less than 84 record days ago means that "Start week 1 again"
        /// asks no re-screen.
        func profile(_ offset: Int) throws {
            try store.setProfile(heightCm: 170, onboardingBMI: 22, cautionFlag: false, askedAt: dayStart(offset), changedAt: dayStart(offset))
        }
        /// A finished weekly review of `week`, as "Done" writes it, with the
        /// frozen counts that the app writes when the review becomes due.
        func finishedReview(week: Int, startOffset: Int, weekOneAnswers: [String]?, reflection: [String], oneThing: String, starred: Int) throws {
            let dueOffset = startOffset + 7 * week
            var payload: [String: Any] = [
                "finished": true,
                "frozenCounts": ["daysWithEntry": 7, "starred": starred, "paused": 0, "urges": 0, "urgesPassed": 0],
                "reflectionAnswers": reflection,
                "oneThingToChange": oneThing,
                "runStartDay": key(startOffset),
            ]
            if let weekOneAnswers { payload["weekOneAnswers"] = weekOneAnswers }
            let json = String(data: try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]), encoding: .utf8)!
            _ = try store.upsertReview(
                kind: .weeklyReview, dueDateKey: key(dueOffset), frozenAt: dayStart(dueOffset).addingTimeInterval(3600),
                answersJSON: json, selfHarmAnswered: true, pinnedNote: oneThing,
                changedAt: dayStart(dueOffset).addingTimeInterval(2 * 3600), calendar: calendar
            )
        }
        /// Stage 2 opens on the fifth recorded day: entries on `days` record
        /// days from `firstOffset`, one per day.
        func onePerDay(from firstOffset: Int, days: Int) throws {
            for offset in firstOffset..<(firstOffset + days) {
                try add(offset, hours: 4, "Porridge")
            }
        }
        func closeCard(_ id: String) throws {
            try store.setCardAnswer("Close", id: id, changedAt: now.addingTimeInterval(-7200))
        }

        switch scenario {
        case "or-tomorrow":
            try store.setInstallMoment(dayStart(0))
            try store.setStartDayKey(key(1))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try profile(0)
        case "or-secondday":
            try store.setInstallMoment(dayStart(-1))
            try store.setStartDayKey(key(-1))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try profile(-1)
            try add(-1, hours: 4, "Porridge")
            try add(0, hours: 1, "Toast and tea")
        case "or-plancard", "or-plan":
            // Entries on record days -7 to -3: stage 2 opens on day -3, so
            // the plan card of day 3 is due today.
            try store.setInstallMoment(dayStart(-8))
            try store.setStartDayKey(key(-7))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try profile(-8)
            try onePerDay(from: -7, days: 5)
            try closeCard("opening.2")
            if scenario == "or-plan" {
                // Breakfast (slot 0) at about two hours before now, on a
                // five-minute step: its 90-minute window has ended. At the
                // latest 20:00, so that the window ends before quiet hours
                // (22:00) and the prompt shows also on a late run.
                let planned = min(now.addingTimeInterval(-2 * 3600), dayStart(0).addingTimeInterval(16 * 3600))
                let parts = calendar.dateComponents([.hour, .minute], from: planned)
                let time = String(format: "%02d:%02d", parts.hour!, parts.minute! / 5 * 5)
                let json = "[{\"slot\":0,\"time\":\"\(time)\"}]"
                try store.setTemplateSlotsJSON(json, kind: .weekday, changedAt: dayStart(-2))
                try store.setTemplateSlotsJSON(json, kind: .weekend, changedAt: dayStart(-2))
            }
        case "or-pinned", "or-tworuns":
            try store.setInstallMoment(dayStart(-16))
            try store.setStartDayKey(key(-15))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try profile(-16)
            try onePerDay(from: -15, days: 15)
            try closeCard("opening.2")
            try closeCard("plancard.10")
            try finishedReview(week: 1, startOffset: -15, weekOneAnswers: ["Eat without guilt", "Evenings", "After work"],
                               reflection: ["Week one notice", "Week one harder", "Week one helped"], oneThing: "Eat breakfast", starred: 0)
            if scenario == "or-tworuns" {
                try finishedReview(week: 2, startOffset: -15, weekOneAnswers: nil,
                                   reflection: ["Week two notice", "Week two harder", "Week two helped"], oneThing: "Plan lunch", starred: 0)
            }
        case "or-deterioration":
            // Week n covers record days start + 7(n - 1) to start + 7n - 1.
            let start = -36
            try store.setInstallMoment(dayStart(start - 1))
            try store.setStartDayKey(key(start))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try profile(start - 1)
            try onePerDay(from: start, days: 36)
            for (week, starred) in [(2, 2), (3, 3), (4, 4), (5, 5)] {
                let firstDay = start + 7 * (week - 1)
                for index in 0..<starred {
                    try add(firstDay + index, hours: 10, "Crisps", starred: true)
                }
            }
            try closeCard("opening.2")
            try closeCard("plancard.10")
        case "or-weighin":
            try store.setInstallMoment(dayStart(-9))
            try store.setStartDayKey(key(-8))
            try store.setWeighInDayChoice(.weekday(calendar.component(.weekday, from: dayStart(-5))))
            try profile(-9)
            try add(-8, hours: 4, "Porridge")
            try add(-5, hours: 4, "Porridge")
            _ = try store.saveWeighIn(dateKey: key(-5), weightKg: 70.4, unit: "kg", at: dayStart(-5).addingTimeInterval(3 * 3600))
        default:
            break
        }
    }
}
