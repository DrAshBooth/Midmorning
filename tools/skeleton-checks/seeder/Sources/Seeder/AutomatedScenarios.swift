import Foundation
import Record
import AppLock

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
///   current record day holds entries at 08:00 and 13:30, so a gap band
///   shows between them.
/// - `corrupt`: a `Record.store` file that is not a store, so the store
///   cannot open.
@MainActor
enum AutomatedScenarios {
    static let names: Set<String> = ["week1", "review", "corrupt"]

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
        var created = now.addingTimeInterval(-3600)
        func add(_ offset: Int, hours: Double, _ what: String) throws {
            let time = dayStart(offset).addingTimeInterval(hours * 3600)
            created = created.addingTimeInterval(1)
            try store.add(time: time, what: what, feltLikeABinge: false, createdAt: created,
                          utcOffsetSeconds: calendar.timeZone.secondsFromGMT(for: time))
        }

        try store.setOnboardingCompleted(true)
        try store.setLocalSettingValue("false", key: AppLockSettingsKeys.enabled)

        switch scenario {
        case "week1":
            try store.setInstallMoment(dayStart(-1))
            try store.setStartDayKey(key(0))
            try store.setWeighInDayChoice(.weekday(calendar.component(.weekday, from: today.start)))
            try add(0, hours: 1, "Toast and tea")
            _ = try store.saveWeighIn(dateKey: key(-7), weightKg: 70.4, unit: "kg", at: dayStart(-7).addingTimeInterval(4 * 3600))
        case "review":
            try store.setInstallMoment(dayStart(-9))
            try store.setStartDayKey(key(-8))
            try store.setWeighInDayChoice(.wontBeWeighing)
            for offset in -8...(-2) {
                try add(offset, hours: 4, "Porridge")
            }
            try add(-1, hours: 4, "Porridge")
            try add(-1, hours: 8.5, "Soup")
            try add(-1, hours: 14, "Pasta")
            try store.setDayState(.paused, on: true, dateKey: key(-1), changedAt: created)
            try add(0, hours: 4, "Toast and tea")
            try add(0, hours: 9.5, "Rice and beans")
        default:
            break
        }
        print("seeded \(scenario) at \(directory.path)")
    }
}
