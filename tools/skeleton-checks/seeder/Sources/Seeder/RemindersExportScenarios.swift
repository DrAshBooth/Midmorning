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
///   seeded in a fixed-offset time zone (`Etc/GMT±N`). The seeder writes the
///   zone identifier to `<stores>/<scenario>.timezone`, and the test
///   launches the app with `TZ` set to that zone. So the app's time of day
///   ("after 17:00", "the close-the-day reminder at 21:45 is still to
///   come") does not depend on the hour of the run. For `stage1Evening` the
///   local time at the seed is 19:xx. For `stage1Morning` it is between
///   06:00 and 16:59 (`zoneForTheReminderCounts`). The start day is the
///   current record day, the person "won't be weighing", and the current
///   record day holds one entry, "Toast and tea", at 05:00 local time.
///   Today then has one reminder still to come: close the day at 21:45
///   (stage 1, no entry after 17:00). The midday reminder does not fire (an
///   entry before midday), and stage 1 has no planned meal and no morning
///   plan reminder.
/// - `stage1Paused`: as `stage1Morning`, and the reminders are paused
///   ("Reminders are paused." and "Turn reminders on" in Settings,
///   Reminders), so the scheduler schedules nothing.
/// - `stage2Evening`: week 2, seeded in a fixed-offset zone where the local
///   time at the seed is 17:xx (`zoneForTheReminderCounts`), so the tests
///   have more than 4 hours before 21:30 local time. The start day is eight record days ago, and
///   each earlier record day holds one entry, so stage 2 is open. Today's
///   plan is set: Breakfast 08:00, Lunch 13:00, Mid-afternoon 16:00 and
///   Evening meal 21:30. Today holds no entry. So today's reminders still
///   to come are the Evening meal at 21:30 and close the day at 21:45.
/// - `stage2Morning`: as `stage2Evening`, but seeded in a fixed-offset zone
///   where the local time at the seed is between 06:00 and 16:59 (10:xx when
///   the Mac's zone allows it; `zoneForTheReminderCounts`). The seeder
///   chooses the zone so that the seeded day's 21:30 is more than 4 hours
///   ahead in the Mac's zone (in the UK, at any hour of a run), where the
///   notification daemon reads the app's floating reminder times. So a
///   test that reads the pending request of the Evening meal at 21:30 does
///   not depend on the hour of the run. Today's reminders still to come
///   include the Evening meal at 21:30 and close the day at 21:45.
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
    nonisolated static let names: Set<String> = ["stage1Morning", "stage1Evening", "stage1Paused", "stage2Evening", "stage2Morning", "reminderSettings", "unfinishedOnboarding"]

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
            let zone = scenario == "stage1Evening"
                ? zoneWhereTheHourIs(19, at: now)
                : zoneForTheReminderCounts(localHours: 6...16, preferring: 10, reminderHour: 21, minute: 45, at: now)
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
        case "stage2Evening", "stage2Morning":
            let zone = scenario == "stage2Evening"
                ? zoneForTheReminderCounts(localHours: 17...19, preferring: 17, reminderHour: 21, minute: 30, at: now)
                : zoneForTheReminderCounts(localHours: 6...16, preferring: 10, reminderHour: 21, minute: 30, at: now)
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
            // Today's plan, set at 05:00 local time (before the earliest
            // local time of the seed, 06:00): Breakfast 08:00, Lunch 13:00,
            // Mid-afternoon 16:00 and Evening meal 21:30. No entry today.
            let plan = #"[{"slot":0,"time":"08:00"},{"slot":2,"time":"13:00"},{"slot":3,"time":"16:00"},{"slot":4,"time":"21:30"}]"#
            let constants = ProgrammeConstants.default
            try store.setDayPlan(dateKey: key(0), slotsJSON: plan, windowBeforeMinutes: constants.plannedMealWindowBeforeMinutes,
                                 windowAfterMinutes: constants.plannedMealWindowAfterMinutes,
                                 setAt: dayStart(0).addingTimeInterval(3600), setBy: "device", changedAt: dayStart(0).addingTimeInterval(3600))
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

    /// The zone for a scenario whose tests count "Pending reminders". The
    /// app gives each reminder a floating time (year, month, day, hour and
    /// minute, with no zone), and the notification daemon reads that time
    /// in the simulator's zone, which is the Mac's zone (`TimeZone.current`
    /// here). So of the fixed-offset zones where the local hour at `moment`
    /// is in `localHours`, this takes the one where the seeded day's
    /// `reminderHour`:`minute` is latest in the Mac's zone, and of those the
    /// one nearest to `preferred`. For `6...16` and 21:30 or 21:45, that
    /// time is then ahead in the Mac's zone by at least 5 hours 30 minutes
    /// minus the Mac's offset from UTC: until 16:00 plus that offset, the
    /// Mac's day still has that time ahead, and from then a zone east of
    /// the Mac is on the next day. So in the UK (offset 0 or 1 hour) it is
    /// always more than 4 hours ahead. Only in a Mac zone 6 or more hours
    /// ahead of UTC can a run late in the day come too near; then
    /// `requireTheSeededDaysTimeIsAheadForTheDaemon` stops the test with a
    /// message. For `17...19` and 21:30 no zone puts the seeded day after
    /// the Mac's day in the UK, so after 21:30 in the Mac's zone that time
    /// is behind.
    nonisolated static func zoneForTheReminderCounts(localHours: ClosedRange<Int>, preferring preferred: Int, reminderHour: Int, minute: Int, at moment: Date) -> TimeZone {
        var candidates: [(zone: TimeZone, reminder: Date, distance: Int)] = []
        for offset in -12...14 {
            let identifier = offset == 0 ? "Etc/GMT" : (offset > 0 ? "Etc/GMT-\(offset)" : "Etc/GMT+\(-offset)")
            guard let zone = TimeZone(identifier: identifier) else { continue }
            var local = Calendar(identifier: .gregorian)
            local.timeZone = zone
            let hour = local.component(.hour, from: moment)
            guard localHours.contains(hour) else { continue }
            var components = local.dateComponents([.year, .month, .day], from: moment)
            components.hour = reminderHour
            components.minute = minute
            var mac = Calendar(identifier: .gregorian)
            mac.timeZone = .current
            guard let reminder = mac.date(from: components) else { continue }
            candidates.append((zone, reminder, abs(hour - preferred)))
        }
        let best = candidates.max { a, b in
            a.reminder != b.reminder ? a.reminder < b.reminder : a.distance > b.distance
        }
        return best?.zone ?? zoneWhereTheHourIs(preferred, at: moment)
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
