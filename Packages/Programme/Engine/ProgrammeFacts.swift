import Foundation

/// One entry, as a value fact (programme spec, "A pure stage engine with
/// stored openings as input": "entries as facts: id, record day, starred").
/// `savedAt` is the moment the store actually wrote the entry — its
/// `createdAt`, not its `time` — because a backdated entry's record day can
/// differ from the moment it was saved (programme spec, "Stage 2 opens after
/// five recorded days": "An entry saved for the previous record day").
public struct EntryFact: Sendable, Equatable {
    public var id: String
    public var dayKey: String
    public var starred: Bool
    public var savedAt: Date

    public init(id: String, dayKey: String, starred: Bool, savedAt: Date) {
        self.id = id
        self.dayKey = dayKey
        self.starred = starred
        self.savedAt = savedAt
    }
}

/// One planned day, as a value fact. `regular-eating-plan` decides which
/// record days are planned days; the engine only needs the key (programme
/// spec, "Stage 3 opens after seven planned days or two weeks of regular
/// eating").
public struct PlannedDayFact: Sendable, Equatable {
    public var dayKey: String

    public init(dayKey: String) {
        self.dayKey = dayKey
    }
}

/// One urge outcome, as a value fact. Any of the three outcomes opens stage
/// 4 (programme spec, "Stage 4 opens after the first urge outcome or seven
/// recorded days"); the engine does not need the outcome's own value.
public struct UrgeOutcomeFact: Sendable, Equatable {
    public var dayKey: String
    public var savedAt: Date

    public init(dayKey: String, savedAt: Date) {
        self.dayKey = dayKey
        self.savedAt = savedAt
    }
}

/// A `StageOpened` row as the engine reads it: a stage and the moment the
/// store keeps for it. The caller passes every row the Reconciler returns,
/// including one the engine will go on to ignore (programme spec, "A pure
/// stage engine with stored openings as input").
public struct StageOpenedRecord: Sendable, Equatable {
    public var stage: Int
    public var moment: Date

    public init(stage: Int, moment: Date) {
        self.stage = stage
        self.moment = moment
    }
}

/// The value facts the engine reads besides the stored openings and the card
/// answers (programme spec, "A pure stage engine with stored openings as
/// input").
public struct ProgrammeFacts: Sendable, Equatable {
    public var entries: [EntryFact]
    public var plannedDays: [PlannedDayFact]
    public var urgeOutcomes: [UrgeOutcomeFact]
    /// The moment the person completed the taking stock session, or `nil`.
    public var takingStockCompletedAt: Date?
    /// Read by `staying-on-track` (3.6); the engine keeps it but does not
    /// yet act on it in this build.
    public var finishDate: Date?

    public init(
        entries: [EntryFact] = [],
        plannedDays: [PlannedDayFact] = [],
        urgeOutcomes: [UrgeOutcomeFact] = [],
        takingStockCompletedAt: Date? = nil,
        finishDate: Date? = nil
    ) {
        self.entries = entries
        self.plannedDays = plannedDays
        self.urgeOutcomes = urgeOutcomes
        self.takingStockCompletedAt = takingStockCompletedAt
        self.finishDate = finishDate
    }
}

/// The two settings the engine reads (programme spec, "Weeks count from the
/// start day"). Every other setting stays with its owning capability.
public struct ProgrammeSettings: Sendable, Equatable {
    /// The record-day key of the chosen start day.
    public var startDay: String
    /// "Day starts at", in force.
    public var dayStart: Int

    public init(startDay: String, dayStart: Int) {
        self.startDay = startDay
        self.dayStart = dayStart
    }
}
