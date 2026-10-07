import Foundation
import Record
import AppLock

/// The seeded store for `HarnessUITests/AutomatedChecks+ReminderTaps.swift`
/// (rulings r13-19 and r16-01, mm-t45.9). The other reminder tap tests use
/// `week1`, `review`, `or-pinned` and `or-deterioration`, which are seeded
/// in the Mac's own time zone, because the app that a tap on a reminder
/// starts gets no `TZ`. The scenario writes through `RecordStore`, as the
/// app does, turns the app lock off and marks onboarding as done.
///
/// - `tap-night`: week 1 of the programme (stage 1), seeded in a
///   fixed-offset time zone (`Etc/GMT±N`) where the local time at the seed
///   is 00:xx. The seeder writes the zone identifier to
///   `<stores>/tap-night.timezone`, and the test launches the app with `TZ`
///   set to that zone. So the current record day started at 04:00 on the
///   previous calendar date, and it ends at 04:00, more than 3 hours after
///   the seed. That record day holds one entry, "Soup", at 13:00 local time
///   (no entry after 17:00, so its close-the-day reminder fired at 21:45).
///   The start day is that record day, and the person "won't be weighing".
@MainActor
enum ReminderTapScenarios {
    nonisolated static let names: Set<String> = ["tap-night"]

    /// Seeds `scenario` and stops the process when `scenario` is one of
    /// `names`. Returns for any other name. `main.swift` calls this in one
    /// line.
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

        let zone = RemindersExportScenarios.zoneWhereTheHourIs(0, at: now)
        try Data(zone.identifier.utf8).write(to: zoneFile)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
        let key = RecordDay.key(containing: today.start.addingTimeInterval(3600), calendar: calendar, schedule: .standard)
        try store.setOnboardingCompleted(true)
        try store.setInstallMoment(calendar.date(byAdding: .day, value: -1, to: today.start)!)
        try store.setStartDayKey(key)
        try store.setWeighInDayChoice(.wontBeWeighing)
        // 13:00 local time: nine hours after the 04:00 day start.
        let lunch = today.start.addingTimeInterval(9 * 3600)
        try store.add(time: lunch, what: "Soup", feltLikeABinge: false, createdAt: lunch,
                      utcOffsetSeconds: zone.secondsFromGMT(for: lunch))
        print("seeded \(scenario) at \(directory.path) in \(zone.identifier), record day \(key)")
    }
}
