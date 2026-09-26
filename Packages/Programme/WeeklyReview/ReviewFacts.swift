import Foundation

/// One entry as the weekly review reads it (weekly-review spec, "The summary
/// built from the record"). `dayKey` is the entry's own saved record-day
/// key; the review never recomputes it ("The app MUST NOT compute an
/// entry's record day again at review time.").
public struct ReviewEntryFact: Sendable, Equatable {
    public var dayKey: String
    public var time: Date
    public var starred: Bool

    public init(dayKey: String, time: Date, starred: Bool) {
        self.dayKey = dayKey
        self.time = time
        self.starred = starred
    }
}

/// The value facts one week's review summary reads (weekly-review spec,
/// "The summary built from the record"). The caller (the App target)
/// gathers these from `RecordStore` and `Plan`'s match, since `Programme`
/// imports neither.
public struct ReviewWeekFacts: Sendable, Equatable {
    /// The week's seven record-day keys, in order (`ReviewDue.weekDayKeys`).
    public var weekDayKeys: [String]
    /// Every entry whose own `dayKey` falls in `weekDayKeys`.
    public var entries: [ReviewEntryFact]
    /// A record day the person set "didn't record", or with the state
    /// fasting — left out of the gap calculation.
    public var exemptDayKeys: Set<String>
    public var pausedDayKeys: Set<String>
    /// `nil` when the week held no planned day at all ("When week n has no
    /// planned day, the app MUST leave the plan part out.").
    public var plannedMealsWithEntryCount: Int?
    public var urgesCount: Int
    public var urgesPassedCount: Int
    /// The record day a weigh-in was done this week, or `nil` (no weigh-in
    /// day chosen, no weigh-in yet, or "I won't be weighing").
    public var weighInDoneDayKey: String?
    /// The close-the-day word for a day key, when not empty.
    public var closeTheDayWordsByDayKey: [String: String]
    /// The frozen starred count of week n − 1, or `nil` in the review of
    /// week 1.
    public var previousWeekFrozenStarred: Int?

    public init(
        weekDayKeys: [String],
        entries: [ReviewEntryFact] = [],
        exemptDayKeys: Set<String> = [],
        pausedDayKeys: Set<String> = [],
        plannedMealsWithEntryCount: Int? = nil,
        urgesCount: Int = 0,
        urgesPassedCount: Int = 0,
        weighInDoneDayKey: String? = nil,
        closeTheDayWordsByDayKey: [String: String] = [:],
        previousWeekFrozenStarred: Int? = nil
    ) {
        self.weekDayKeys = weekDayKeys
        self.entries = entries
        self.exemptDayKeys = exemptDayKeys
        self.pausedDayKeys = pausedDayKeys
        self.plannedMealsWithEntryCount = plannedMealsWithEntryCount
        self.urgesCount = urgesCount
        self.urgesPassedCount = urgesPassedCount
        self.weighInDoneDayKey = weighInDoneDayKey
        self.closeTheDayWordsByDayKey = closeTheDayWordsByDayKey
        self.previousWeekFrozenStarred = previousWeekFrozenStarred
    }

    /// The record day of the week's weigh-in that the summary shows, or
    /// `nil` (weekly-review spec, "The summary built from the record").
    /// The store keeps each weigh-in after "I won't be weighing" (weigh-in
    /// spec), so the choice in force decides: "When the person chose 'I
    /// won't be weighing', the app MUST leave the weigh-in part out. The
    /// part MUST stay out of every review and check-in until the person
    /// chooses a weigh-in day." `weighInDayChosen` is `true` only while the
    /// setting holds a weekday.
    public static func weighInDoneDayKey(weighInDayKeys: [String], weekDayKeys: [String], weighInDayChosen: Bool) -> String? {
        guard weighInDayChosen else { return nil }
        let week = Set(weekDayKeys)
        return weighInDayKeys.first { week.contains($0) }
    }
}
