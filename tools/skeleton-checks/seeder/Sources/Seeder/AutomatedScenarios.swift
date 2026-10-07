import Foundation
import Record
import AppLock
import Constants

/// The seeded stores for `HarnessUITests/AutomatedChecks.swift` (ruling
/// r13-19, mm-t43.30). Each scenario writes through `RecordStore`, as the
/// app does, in the Mac's own time zone. The simulator uses the same time
/// zone. Every scenario turns the app lock off and marks onboarding as
/// done, so that the app opens on Today.
///
/// - `week1`: week 1 of the programme. The start day is the current record
///   day, and the weigh-in day is the current record day's weekday. One
///   entry today ("Toast and tea"), and one weigh-in of 70.4 kg one week
///   ago. No profile, so "Start week 1 again" asks the re-screen first.
/// - `review`: week 2. The start day is eight record days ago, so the
///   week 1 review is due and stage 2 is open (entries on nine days). The
///   previous record day holds three entries and "Pause for today". The
///   current record day holds two entries ("Toast and tea" and "Rice and
///   beans") more than 4 hours apart, so a gap band shows between them. A
///   profile from nine days ago, so "Start week 1 again" asks no re-screen.
/// - `corrupt`: a `Record.store` file that is not a store, so the store
///   cannot open.
///
/// No seeded entry is after the moment of the seed. On the current record
/// day, "Toast and tea" in `week1` is at 05:00 and the two `review` entries
/// are at 08:00 and 13:30, or earlier when that time is not yet past. The
/// seeder stops with an error before 09:00 (5 hours after the day start),
/// because the gap band then has no room before now.
enum SeedError: Error, CustomStringConvertible {
    case tooEarly(String)

    var description: String {
        switch self {
        case .tooEarly(let time):
            return "The seeded stores need a current record day of 5 hours. Run the checks at \(time) or later."
        }
    }
}

@MainActor
enum AutomatedScenarios {
    static let names: Set<String> = Set(["week1", "review", "corrupt"])
        .union(RecordPlanScenarios.names)
        .union(OnboardingReviewScenarios.names)

    static func seed(_ scenario: String, storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if scenario == "corrupt" {
            try Data("This file is not a store.".utf8).write(to: storeURL)
            print("seeded corrupt store at \(storeURL.path)")
            return
        }
        let store = try RecordStore(directory: directory)
        let calendar = Calendar.current
        let now = Date()
        let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
        func dayStart(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today.start)! }
        func key(_ offset: Int) -> String { RecordDay.key(containing: dayStart(offset).addingTimeInterval(3600), calendar: calendar, schedule: .standard) }
        // The current record day must be 5 hours old, so that each current-day
        // entry and the gap band fit before now.
        let earliestRun = dayStart(0).addingTimeInterval(5 * 3600)
        guard now >= earliestRun else {
            throw SeedError.tooEarly(ClockTime.string(from: earliestRun, calendar: calendar))
        }
        var created = now.addingTimeInterval(-3600)
        func add(_ offset: Int, hours: Double, _ what: String) throws {
            try add(at: dayStart(offset).addingTimeInterval(hours * 3600), what)
        }
        func add(at time: Date, _ what: String) throws {
            created = created.addingTimeInterval(1)
            try store.add(time: time, what: what, feltLikeABinge: false, createdAt: created,
                          utcOffsetSeconds: calendar.timeZone.secondsFromGMT(for: time))
        }
        /// `hours` after the current day start, or one minute before now
        /// when that time is not yet past.
        func notAfterNow(_ hours: Double) -> Date {
            min(dayStart(0).addingTimeInterval(hours * 3600), now.addingTimeInterval(-60))
        }

        try store.setOnboardingCompleted(true)
        try store.setLocalSettingValue("false", key: AppLockSettingsKeys.enabled)

        switch scenario {
        case "week1":
            try store.setInstallMoment(dayStart(-1))
            try store.setStartDayKey(key(0))
            try store.setWeighInDayChoice(.weekday(calendar.component(.weekday, from: today.start)))
            try add(at: notAfterNow(1), "Toast and tea")
            _ = try store.saveWeighIn(dateKey: key(-7), weightKg: 70.4, unit: "kg", at: dayStart(-7).addingTimeInterval(4 * 3600))
        case "review":
            try store.setInstallMoment(dayStart(-9))
            try store.setStartDayKey(key(-8))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try store.setProfile(heightCm: 170, onboardingBMI: 22, cautionFlag: false, askedAt: dayStart(-9), changedAt: dayStart(-9))
            for offset in -8...(-2) {
                try add(offset, hours: 4, "Porridge")
            }
            try add(-1, hours: 4, "Porridge")
            try add(-1, hours: 8.5, "Soup")
            try add(-1, hours: 14, "Pasta")
            try store.setDayState(.paused, on: true, dateKey: key(-1), changedAt: created)
            // 08:00 and 13:30 after 13:31. Earlier in the day, the second
            // entry is one minute before now and the first is 5 hours 30
            // minutes before it, but not before 04:30. The gap is then at
            // least 4 hours 29 minutes, more than the 4 hours of the band.
            let second = notAfterNow(9.5)
            let first = max(second.addingTimeInterval(-5.5 * 3600), dayStart(0).addingTimeInterval(0.5 * 3600))
            try add(at: first, "Toast and tea")
            try add(at: second, "Rice and beans")
        case _ where OnboardingReviewScenarios.names.contains(scenario):
            try OnboardingReviewScenarios.seed(scenario, store: store, now: now, calendar: calendar)
        default:
            try RecordPlanScenarios.seed(scenario, store: store, now: now, calendar: calendar, directory: directory)
        }
        print("seeded \(scenario) at \(directory.path)")
    }
}
