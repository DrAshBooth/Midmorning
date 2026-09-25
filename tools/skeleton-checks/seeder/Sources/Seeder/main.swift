import Foundation
import RecordCore

// Usage: Seeder <store-url> <scenario>
// Writes entries through RecordStore.add, as the app does, in Europe/London.
let args = CommandLine.arguments
let url = URL(fileURLWithPath: args[1])
let scenario = args.count > 2 ? args[2] : "today"
var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "Europe/London")!
let now = Date()
let offset = cal.timeZone.secondsFromGMT(for: now)
@MainActor func at(_ dayOffset: Int, _ h: Int, _ m: Int) -> Date {
    let base = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now))!
    return cal.date(bySettingHour: h, minute: m, second: 0, of: base)!
}
nonisolated(unsafe) var seed: [(Date, String, Bool)] = []
switch scenario {
case "today":
    // Entries saved out of time order, one starred, one with an empty What,
    // two on the previous record day, one after midnight on it.
    seed = [
        (at(0, 13, 5), "Toast and tea", true),
        (at(0, 8, 10), "Porridge", false),
        (at(0, 10, 45), "", false),
        (at(0, 15, 30), "Apple and a coffee", false),
        (at(-1, 19, 20), "Pasta", false),
        (at(0, 1, 15), "Cereal", true),   // 01:15 today belongs to yesterday's record day
    ]
case "long":
    // A long day, so a new entry lands below the fold.
    seed = (0..<18).map { i in (at(0, 5 + i / 2, (i % 2) * 30), "Entry \(i + 1)", false) }
default:
    seed = []
}
MainActor.assumeIsolated {
    let store = try! RecordStore(url: url)
    for (i, (time, what, star)) in seed.enumerated() {
        _ = try! store.add(time: time, what: what, feltLikeABinge: star,
                           createdAt: now.addingTimeInterval(Double(i)), utcOffsetSeconds: offset)
    }
    print("seeded \(seed.count) entries into \(url.path)")
}
