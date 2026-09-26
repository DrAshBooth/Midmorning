import Foundation

/// The frozen counts a Review row keeps, written once, at freeze time
/// (weekly-review spec, "The week's counts are frozen in the Review row").
/// `plan` is `nil` when the week held no planned day, the same "leave the
/// part out" case the summary uses.
public struct FrozenReviewCounts: Sendable, Equatable, Codable {
    public var daysWithEntry: Int
    public var starred: Int
    public var plan: Int?
    public var paused: Int
    public var urges: Int
    public var urgesPassed: Int

    public init(daysWithEntry: Int, starred: Int, plan: Int?, paused: Int, urges: Int, urgesPassed: Int) {
        self.daysWithEntry = daysWithEntry
        self.starred = starred
        self.plan = plan
        self.paused = paused
        self.urges = urges
        self.urgesPassed = urgesPassed
    }

    /// The counts a freshly built review of `facts` freezes: the same
    /// numbers the summary reads, taken once and never recomputed
    /// ("An entry the person edits or deletes later MUST NOT change the
    /// row.").
    public static func from(_ facts: ReviewWeekFacts) -> FrozenReviewCounts {
        FrozenReviewCounts(
            daysWithEntry: ReviewSummary.daysWithEntryCount(facts),
            starred: ReviewSummary.starredCount(facts),
            plan: facts.plannedMealsWithEntryCount,
            paused: ReviewSummary.pausedCount(facts),
            urges: facts.urgesCount,
            urgesPassed: facts.urgesPassedCount
        )
    }
}

/// Whether a Review row is future-dated: its due moment or its own freeze
/// moment is later than the device clock (weekly-review spec, "The week's
/// counts are frozen in the Review row": "A Review row whose due moment or
/// freeze moment is later than the device clock is future-dated."). A
/// future-dated row is ignored on read, never deleted.
public enum ReviewFreeze {
    public static func isFutureDated(dueDayKey: String, frozenAt: Date, dayStart: Int, calendar: Calendar, now: Date) -> Bool {
        let due = DayKeyMath.dayStartMoment(for: dueDayKey, dayStart: dayStart, calendar: calendar)
        return due > now || frozenAt > now
    }

    /// Whether the review due at `dueDayKey` is ready to freeze now: the
    /// device clock has passed its due moment, and — when sync is on — the
    /// device's last sync moment is later than the due moment too ("A
    /// device with sync on MUST also wait until its last sync moment is
    /// later than the due moment.").
    public static func readyToFreeze(dueDayKey: String, dayStart: Int, calendar: Calendar, now: Date, syncOn: Bool, lastSyncMoment: Date?) -> Bool {
        let due = DayKeyMath.dayStartMoment(for: dueDayKey, dayStart: dayStart, calendar: calendar)
        guard now >= due else { return false }
        guard syncOn else { return true }
        guard let lastSyncMoment else { return false }
        return lastSyncMoment > due
    }
}
