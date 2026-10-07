import Foundation
import Record
import AppLock
import Constants

/// The seeded store for the export page checks in
/// `HarnessUITests/AutomatedChecks+PrintTmp.swift` (rulings r13-19 and
/// r16-01, epic mm-t45; device-check bead mm-t42.14, comment of mm-t42.22,
/// mm-t42.25 and mm-t42.26). The store is written in the Mac's own time
/// zone, as `AutomatedScenarios` writes its stores. The app lock is off and
/// onboarding is done, so the app opens on Today.
///
/// - `exportPages`: entries on the record days from 6 days ago to the
///   current record day, so the default export range is these seven days
///   (export spec: "When the earliest record day with an entry is later,
///   'From' MUST default to that day"). Each day in the range holds
///   entries or a state, so no day heading has nothing under it:
///   - 6 days ago: 27 entries (05:00 to 11:30). The heading group of the
///     next day comes near the foot of page 1 (see below).
///   - 5 days ago: "Pause for today" and 45 entries (05:00 to 16:00, one
///     each 15 minutes). This long day continues on the next page.
///   - 4 days ago: "Didn't record", no entry.
///   - 3 days ago: 12 entries, and the one weigh-in of the store, 70.4 kg.
///   - 2 days ago: "Pause for today" and 2 entries.
///   - 1 day ago: 20 entries.
///   - The current record day: 2 entries, at 05:00 and 05:15 (the seeder
///     runs after 09:00).
///   Each entry has a short What ("Toast 12") and a Where ("Home"), so that
///   each entry is one line in the PDF. No text holds "Paused",
///   "Weigh-ins" or "kg".
///
/// The page foot. The text sizes of the PDF are fixed (11, 14 and 18 pt,
/// no Dynamic Type), so the page breaks do not change from run to run. On
/// the iOS 27.0 simulator, an entry line, a state line and the column
/// headings are 20 pt high, a day heading 23 pt, and the title block of
/// page 1 is 108 pt. The A4 page holds 745.89 pt of lines. After the 27
/// entries of 6 days ago, page 1 has about 55 pt free. The heading of
/// 5 days ago (23 pt) and its "Paused" line (20 pt) fit in that space, but
/// with its column headings and first entry (83 pt) they do not. A
/// paginator that breaks only when a line does not fit ends page 1 with
/// "Paused". The paginator of mm-t42.25 moves the whole group to page 2.
/// The UI test measures this free space in the PDF, so it fails, and does
/// not pass with no effect, if the sizes change.
@MainActor
enum ExportPagesScenarios {
    nonisolated static let names: Set<String> = ["exportPages"]

    /// The number of entries of each day, from 6 days ago to the current
    /// record day. The UI test uses the same numbers.
    static let entriesPerDay = [27, 45, 0, 12, 2, 20, 2]

    /// Seeds `scenario` and stops the process when `scenario` is one of
    /// `names`. Returns for any other name. `main.swift` calls this in one
    /// line.
    nonisolated static func seedAndExitIfNamed(_ scenario: String, storeURL: URL) {
        guard names.contains(scenario) else { return }
        MainActor.assumeIsolated {
            do {
                try seed(storeURL: storeURL)
                print("seeded \(scenario) at \(storeURL.deletingLastPathComponent().path)")
            } catch {
                FileHandle.standardError.write(Data("Seeder: \(error)\n".utf8))
                exit(1)
            }
        }
        exit(0)
    }

    static func seed(storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try RecordStore(directory: directory)
        let calendar = Calendar.current
        let now = Date()
        let today = RecordDay.interval(containing: now, calendar: calendar, schedule: .standard)
        func dayStart(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today.start)! }
        func key(_ offset: Int) -> String { RecordDay.key(containing: dayStart(offset).addingTimeInterval(3600), calendar: calendar, schedule: .standard) }
        // The two entries of the current record day are at 05:00 and 05:15.
        let earliestRun = dayStart(0).addingTimeInterval(5 * 3600)
        guard now >= earliestRun else {
            throw SeedError.tooEarly(ClockTime.string(from: earliestRun, calendar: calendar))
        }

        try store.setOnboardingCompleted(true)
        try store.setLocalSettingValue("false", key: AppLockSettingsKeys.enabled)
        try store.setInstallMoment(dayStart(-7))
        try store.setStartDayKey(key(-6))
        try store.setWeighInDayChoice(.weekday(calendar.component(.weekday, from: dayStart(-3))))

        let foods = ["Porridge", "Toast", "Apple", "Soup", "Rice", "Tea"]
        var created = now.addingTimeInterval(-3600)
        for (index, count) in entriesPerDay.enumerated() {
            let offset = index - 6
            for entry in 0..<count {
                // 05:00, then one each 15 minutes: one hour after the 04:00
                // day start.
                let time = dayStart(offset).addingTimeInterval(3600 + Double(entry) * 900)
                created = created.addingTimeInterval(1)
                try store.add(time: time, what: "\(foods[entry % foods.count]) \(entry + 1)", feltLikeABinge: entry % 7 == 3,
                              createdAt: created, utcOffsetSeconds: calendar.timeZone.secondsFromGMT(for: time), whereText: "Home")
            }
        }
        try store.setDayState(.paused, on: true, dateKey: key(-5), changedAt: created)
        try store.setDayState(.didntRecord, on: true, dateKey: key(-4), changedAt: created)
        try store.setDayState(.paused, on: true, dateKey: key(-2), changedAt: created)
        _ = try store.saveWeighIn(dateKey: key(-3), weightKg: 70.4, unit: "kg", at: dayStart(-3).addingTimeInterval(4 * 3600))
    }
}
