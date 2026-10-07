import Foundation
import Record
import AppLock
import Constants

/// The seeded stores for `HarnessUITests/AutomatedChecks+RemindersExport.swift`
/// (rulings r13-19 and r16-01; device-check beads mm-t24.22, mm-t41.15 and
/// mm-t42.14). `main.swift` sends each of these names here. Every scenario
/// writes through `RecordStore`, as the app does, and turns the app lock
/// off.
///
/// - `stage1Morning` and `stage1Evening`: week 1 of the programme (stage 1),
///   seeded in a fixed-offset time zone (`Etc/GMT±N`) where the local time
///   at the seed is 10:xx or 19:xx. The seeder writes the zone identifier to
///   `<stores>/<scenario>.timezone`, and the test launches the app with
///   `TZ` set to that zone. So a check of the time of day ("after 17:00",
///   "the close-the-day reminder at 21:45 is still to come") does not
///   depend on the hour of the run. The start day is the current record
///   day, the person "won't be weighing", and the current record day holds
///   one entry, "Toast and tea", at 05:00 local time. Today then has one
///   reminder still to come: close the day at 21:45 (stage 1, no entry
///   after 17:00). The midday reminder does not fire (an entry before
///   midday), and stage 1 has no planned meal and no morning plan reminder.
/// - `stage1Paused`: as `stage1Morning`, and the reminders are paused
///   ("Reminders are paused." and "Turn reminders on" in Settings,
///   Reminders), so the scheduler schedules nothing.
/// - `stage2Evening`: week 2, seeded in a fixed-offset zone where the local
///   time at the seed is 19:xx. The start day is eight record days ago, and
///   each earlier record day holds one entry, so stage 2 is open. Today's
///   plan is set: Breakfast 08:00, Lunch 13:00, Mid-afternoon 16:00 and
///   Evening meal 21:30. Today holds no entry. So today's reminders still
///   to come are the Evening meal at 21:30 and close the day at 21:45.
/// - `reminderSettings`: as `week1`, in the Mac's time zone, with a
///   reminder time, quiet hours and device settings that are not the
///   defaults (mm-t24.38): "Set today's plan time" 08:10, "Close the day
///   time" 21:15, "Weigh-in reminder time" 07:50, "Weekly review time"
///   18:40, quiet hours on from 21:30 to 06:40, the midday reminder off,
///   "Say what each reminder is for" on and "Remind me again in" 30
///   minutes.
/// - `unfinishedOnboarding`: a store where onboarding is not done, with a
///   launch failure count of 3 from earlier launches. The app opens on
///   onboarding screen 1, so a launch ends before Today until the person
///   taps "Start" on screen 4.
@MainActor
enum RemindersExportScenarios {
    nonisolated static let names: Set<String> = ["stage1Morning", "stage1Evening", "stage1Paused", "stage2Evening", "reminderSettings", "unfinishedOnboarding"]

    /// Seeds `scenario` and stops the process when `scenario` is one of
    /// `names`. Returns for any other name. `main.swift` calls this in one
    /// line, before its own scenarios.
    nonisolated static func seedAndExitIfNamed(_ scenario: String, storeURL: URL) {
        guard names.contains(scenario) else { return }
        MainActor.assumeIsolated {
            do {
                try seed(scenario, storeURL: storeURL)
            } catch {
                FileHandle.standardError.write(Data("Seeder: \(error)\n".utf8))
                exit(1)
            }
        }
        exit(0)
    }

    static func seed(_ scenario: String, storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        let zoneFile = directory.deletingLastPathComponent().appendingPathComponent("\(scenario).timezone")
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.removeItem(at: zoneFile)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try RecordStore(directory: directory)
        let now = Date()
        try store.setLocalSettingValue("false", key: AppLockSettingsKeys.enabled)

        switch scenario {
        case "stage1Morning", "stage1Evening", "stage1Paused":
            let zone = zoneWhereTheHourIs(scenario == "stage1Evening" ? 19 : 10, at: now)
            try Data(zone.identifier.utf8).write(to: zoneFile)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
            let key = { (offset: Int) in
                RecordDay.key(containing: calendar.date(byAdding: .day, value: offset, to: today.start)!.addingTimeInterval(3600), calendar: calendar, schedule: .standard)
            }
            try store.setOnboardingCompleted(true)
            try store.setInstallMoment(calendar.date(byAdding: .day, value: -1, to: today.start)!)
            try store.setStartDayKey(key(0))
            try store.setWeighInDayChoice(.wontBeWeighing)
            // 05:00 local time: one hour after the 04:00 day start.
            let breakfast = today.start.addingTimeInterval(3600)
            try store.add(time: breakfast, what: "Toast and tea", feltLikeABinge: false, createdAt: now.addingTimeInterval(-60),
                          utcOffsetSeconds: zone.secondsFromGMT(for: breakfast))
            if scenario == "stage1Paused" {
                try store.pauseReminders(at: now.addingTimeInterval(-3600), changedAt: now.addingTimeInterval(-3600))
            }
            print("seeded \(scenario) at \(directory.path) in \(zone.identifier)")
        case "stage2Evening":
            let zone = zoneWhereTheHourIs(19, at: now)
            try Data(zone.identifier.utf8).write(to: zoneFile)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
            let dayStart = { (offset: Int) in calendar.date(byAdding: .day, value: offset, to: today.start)! }
            let key = { (offset: Int) in RecordDay.key(containing: dayStart(offset).addingTimeInterval(3600), calendar: calendar, schedule: .standard) }
            try store.setOnboardingCompleted(true)
            try store.setInstallMoment(dayStart(-9))
            try store.setStartDayKey(key(-8))
            try store.setWeighInDayChoice(.wontBeWeighing)
            try store.setProfile(heightCm: 170, onboardingBMI: 22, cautionFlag: false, askedAt: dayStart(-9), changedAt: dayStart(-9))
            // Stage 2 opens after five recorded days: one entry on each of
            // the eight earlier record days, at 08:00 local time.
            for offset in -8...(-1) {
                let time = dayStart(offset).addingTimeInterval(4 * 3600)
                try store.add(time: time, what: "Porridge", feltLikeABinge: false, createdAt: time,
                              utcOffsetSeconds: zone.secondsFromGMT(for: time))
            }
            // Today's plan, set this morning: Breakfast 08:00, Lunch 13:00,
            // Mid-afternoon 16:00 and Evening meal 21:30. No entry today.
            let plan = #"[{"slot":0,"time":"08:00"},{"slot":2,"time":"13:00"},{"slot":3,"time":"16:00"},{"slot":4,"time":"21:30"}]"#
            let constants = ProgrammeConstants.default
            try store.setDayPlan(dateKey: key(0), slotsJSON: plan, windowBeforeMinutes: constants.plannedMealWindowBeforeMinutes,
                                 windowAfterMinutes: constants.plannedMealWindowAfterMinutes,
                                 setAt: dayStart(0).addingTimeInterval(3 * 3600), setBy: "device", changedAt: dayStart(0).addingTimeInterval(3 * 3600))
            print("seeded \(scenario) at \(directory.path) in \(zone.identifier)")
        case "reminderSettings":
            let calendar = Calendar.current
            let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
            try store.setOnboardingCompleted(true)
            try store.setInstallMoment(calendar.date(byAdding: .day, value: -1, to: today.start)!)
            try store.setStartDayKey(RecordDay.key(containing: now, calendar: calendar, schedule: .standard))
            try store.setWeighInDayChoice(.weekday(calendar.component(.weekday, from: today.start)))
            let earlier = now.addingTimeInterval(-3600)
            try store.setReminderTime("08:10", .setTodaysPlan, changedAt: earlier)
            try store.setReminderTime("21:15", .closeTheDay, changedAt: earlier)
            try store.setReminderTime("07:50", .weighIn, changedAt: earlier)
            try store.setReminderTime("18:40", .weeklyReview, changedAt: earlier)
            try store.setQuietHoursOn(true, changedAt: earlier)
            try store.setQuietHoursStart("21:30", changedAt: earlier)
            try store.setQuietHoursEnd("06:40", changedAt: earlier)
            try store.setReminderSwitch(false, .midday)
            try store.setExplicitWordingOn(true)
            try store.setRemindAgainMinutes(30)
            print("seeded \(scenario) at \(directory.path)")
        case "unfinishedOnboarding":
            for _ in 0..<3 { try store.incrementLaunchFailureCount() }
            print("seeded \(scenario) at \(directory.path)")
        default:
            break
        }
    }

    /// A fixed-offset zone where the local hour at `moment` is `hour`.
    /// `Etc/GMT-N` is N hours east of UTC; the offsets run from -12 to +14.
    nonisolated static func zoneWhereTheHourIs(_ hour: Int, at moment: Date) -> TimeZone {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var offset = (hour - utc.component(.hour, from: moment) + 48) % 24
        if offset > 14 { offset -= 24 }
        let identifier = offset == 0 ? "Etc/GMT" : (offset > 0 ? "Etc/GMT-\(offset)" : "Etc/GMT+\(-offset)")
        return TimeZone(identifier: identifier)!
    }
}
