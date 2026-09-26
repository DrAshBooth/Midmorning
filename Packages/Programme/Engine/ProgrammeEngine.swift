import Foundation
import Constants

/// What `Programme.state` returns: the stage, the open tools, the week
/// number, the counts toward the next stage and every opening the engine
/// computed but the store does not yet hold (programme spec, "A pure stage
/// engine with stored openings as input").
public struct ProgrammeState: Sendable, Equatable {
    public var openStages: Set<Stage>
    /// The moment the engine reads for each open stage — a stored moment
    /// when one survives the ignore rules, otherwise the moment the engine
    /// computed.
    public var stageOpenedMoment: [Stage: Date]
    /// The record-day key that contains each open stage's moment, in the
    /// engine's own `calendar` and the settings' `dayStart`.
    public var stageOpenedDayKey: [Stage: String]
    /// Every opening the engine computed because no valid stored row
    /// covered it. The app MUST write each one to the store.
    public var computedOpenings: [StageOpenedRecord]
    /// The programme week from the start day, or `nil` before week 1.
    public var week: Int?
    /// The week of regular eating from the record day stage 2 opened (or,
    /// after a restart, from the new start day), or `nil` while stage 2 is
    /// closed.
    public var weekOfRegularEating: Int?
    /// The total distinct recorded days so far, for the stage 2 rule
    /// string's "You have %2$lld" (programme spec, "Reading ahead is never
    /// blocked").
    public var recordedDaysCount: Int

    public func isOpen(_ stage: Stage) -> Bool { openStages.contains(stage) }
}

/// A pending card `Record`'s `TodayCardSlot` can pick from (programme spec,
/// "A stage opening shows one card", "Two stage 1 cards come to Today", "A
/// card when the plan is not set"). `Programme` cannot import `Record`, so
/// this is its own value type; the App target maps `kind` onto `Record`'s
/// `TodayCardFact.Kind` one for one.
public struct PendingCard: Sendable, Equatable {
    public enum Kind: String, Sendable { case opening, stage1, plan }

    public var id: String
    public var kind: Kind
    public var becameDueAt: Date

    public init(id: String, kind: Kind, becameDueAt: Date) {
        self.id = id
        self.kind = kind
        self.becameDueAt = becameDueAt
    }
}

/// The pure stage engine (programme spec, "A pure stage engine with stored
/// openings as input"; `v1-programme/design.md`, "The programme engine is a
/// pure function with stored openings as input").
public enum Programme {
    /// `calendar` is plumbing, not a domain fact: the requirement's input
    /// list names the facts the engine reasons about; every function here
    /// that turns a moment into a record-day key or back needs a calendar,
    /// the same seam `Record`'s `RecordDay` and `Materialiser` use
    /// (`openspec/changes/programme-engine/proposal.md`, "Decisions this
    /// change makes").
    public static func state(
        facts: ProgrammeFacts,
        openings: [StageOpenedRecord],
        settings: ProgrammeSettings,
        constants: ProgrammeConstants,
        now: Date,
        restartAt: Date?,
        currentRecordDay: String,
        calendar: Calendar
    ) -> ProgrammeState {
        var moment: [Stage: Date] = [:]
        var computed: [StageOpenedRecord] = []

        func ignoreRestart(_ stage: Stage) -> Bool { stage == .takingStock }

        func storedMoment(_ stage: Stage) -> Date? {
            openings
                .filter { $0.stage == stage.rawValue }
                .filter { $0.moment <= now }
                .filter { !ignoreRestart(stage) || restartAt == nil || $0.moment >= restartAt! }
                .min { $0.moment < $1.moment }?
                .moment
        }

        func resolve(_ stage: Stage, computedMoment: Date?) {
            if let stored = storedMoment(stage) {
                moment[stage] = stored
            } else if let computedMoment, computedMoment <= now {
                moment[stage] = computedMoment
                computed.append(StageOpenedRecord(stage: stage.rawValue, moment: computedMoment))
            }
        }

        func dayKey(of stage: Stage) -> String? {
            moment[stage].map { DayKeyMath.recordDayKey(containing: $0, dayStart: settings.dayStart, calendar: calendar) }
        }

        // Stage 1: always open, from the start day (programme spec, "The
        // stage screen": "For stage 1, that record day is the start day.").
        moment[.gettingStarted] = DayKeyMath.dayStartMoment(for: settings.startDay, dayStart: settings.dayStart, calendar: calendar)

        // Stage 2: the moment the Nth distinct recorded day got its first
        // entry (programme spec, "Stage 2 opens after five recorded days").
        let recordedDaysCount = Set(facts.entries.map(\.dayKey)).count
        let stage2Trigger = nthDistinctDayEntry(facts.entries, n: constants.recordedDaysForStage2)
        resolve(.regularEating, computedMoment: stage2Trigger?.savedAt)
        let stage2Day = dayKey(of: .regularEating)

        // Stage 3: seven planned-and-recorded days (day-end moment), or the
        // 14-record-day fallback from stage 2's day (programme spec, "Stage
        // 3 opens after seven planned days or two weeks of regular eating").
        let recordedDayKeys = Set(facts.entries.map(\.dayKey))
        let plannedRecordedDayKeys = Set(facts.plannedDays.map(\.dayKey)).intersection(recordedDayKeys).sorted()
        var primaryStage3: Date?
        if plannedRecordedDayKeys.count >= constants.daysOnPlanForStage3 {
            let nth = plannedRecordedDayKeys[constants.daysOnPlanForStage3 - 1]
            primaryStage3 = DayKeyMath.nextDayStartMoment(after: nth, dayStart: settings.dayStart, calendar: calendar)
        }
        let fallbackStage3 = stage2Day.map {
            DayKeyMath.dayStartMoment(for: DayKeyMath.adding(constants.recordDaysForStage3Fallback, to: $0, calendar: calendar), dayStart: settings.dayStart, calendar: calendar)
        }
        resolve(.alternatives, computedMoment: [primaryStage3, fallbackStage3].compactMap { $0 }.min())
        let stage3Day = dayKey(of: .alternatives)

        // Stage 4: the first urge outcome, or seven recorded days with
        // stage 3 open, both counted from stage 3's own day onward — the
        // engine reads only facts dated on or after the last opening moment
        // it used (programme spec, "Stage 4 opens after the first urge
        // outcome or seven recorded days"; "A pure stage engine with stored
        // openings as input": "The scan is bounded").
        let stage4Computed: Date? = stage3Day.flatMap { day -> Date? in
            let primary = facts.urgeOutcomes
                .filter { !DayKeyMath.isBefore($0.dayKey, day) }
                .min { $0.savedAt < $1.savedAt }?.savedAt
            let fallback = nthDistinctDayEntry(
                facts.entries.filter { !DayKeyMath.isBefore($0.dayKey, day) },
                n: constants.recordedDaysForStage4Fallback
            )?.savedAt
            return [primary, fallback].compactMap { $0 }.min()
        }
        resolve(.problemSolving, computedMoment: stage4Computed)

        // Stages 5 and 7: by week of regular eating from stage 2's day,
        // except that after a restart stage 5 counts from the NEW start day
        // (programme spec, "Taking stock, the modules and staying on track
        // open by week of regular eating": "After a restart, the app MUST
        // count weeks of regular eating from the new start day").
        let stage5Basis = restartAt != nil ? settings.startDay : stage2Day
        resolve(.takingStock, computedMoment: stage5Basis.map { weekGateMoment(basis: $0, week: constants.weekOfTakingStock, dayStart: settings.dayStart, calendar: calendar) })
        resolve(.stayingOnTrack, computedMoment: stage2Day.map { weekGateMoment(basis: $0, week: constants.weekOfStayingOnTrack, dayStart: settings.dayStart, calendar: calendar) })

        // Stage 6: when the person completes taking stock (programme spec,
        // "Taking stock, the modules and staying on track open by week of
        // regular eating": "The app MUST open both modules together.").
        resolve(.modules, computedMoment: facts.takingStockCompletedAt)

        var dayKeys: [Stage: String] = [:]
        for stage in Stage.orderedByStage { dayKeys[stage] = dayKey(of: stage) }

        return ProgrammeState(
            openStages: Set(moment.keys),
            stageOpenedMoment: moment,
            stageOpenedDayKey: dayKeys,
            computedOpenings: computed,
            week: week(startDay: settings.startDay, currentRecordDay: currentRecordDay, calendar: calendar),
            weekOfRegularEating: stage2Day.map { week(startDay: $0, currentRecordDay: currentRecordDay, calendar: calendar) ?? 0 },
            recordedDaysCount: recordedDaysCount
        )
    }

    /// The programme week of `currentRecordDay` counted from `startDay`, or
    /// `nil` before week 1 (programme spec, "Weeks count from the start
    /// day").
    public static func week(startDay: String, currentRecordDay: String, calendar: Calendar) -> Int? {
        let days = DayKeyMath.daysBetween(startDay, currentRecordDay, calendar: calendar)
        guard days >= 0 else { return nil }
        return days / 7 + 1
    }

    /// The pending cards `TodayCardSlot` can pick from: the opening cards of
    /// every open stage whose tool this build has, the two stage 1 cards
    /// while stage 2 is closed, and the plan card while no template exists.
    public static func pendingCards(
        state: ProgrammeState,
        facts: ProgrammeFacts,
        cardAnswers: Set<String>,
        stagesWithToolInBuild: Set<Int>,
        hasTemplate: Bool,
        currentRecordDay: String,
        settings: ProgrammeSettings,
        calendar: Calendar
    ) -> [PendingCard] {
        var result: [PendingCard] = []

        for stage in Stage.orderedByStage where stage != .gettingStarted {
            guard stagesWithToolInBuild.contains(stage.rawValue) else { continue }
            let id = "opening.\(stage.rawValue)"
            guard !cardAnswers.contains(id), let due = state.stageOpenedMoment[stage] else { continue }
            result.append(PendingCard(id: id, kind: .opening, becameDueAt: due))
        }

        if !state.isOpen(.regularEating) {
            if let why = nthDistinctDayEntry(facts.entries, n: 2), !cardAnswers.contains("stage1.why") {
                result.append(PendingCard(id: "stage1.why", kind: .stage1, becameDueAt: why.savedAt))
            }
            if let cycle = nthDistinctDayEntry(facts.entries, n: 4), !cardAnswers.contains("stage1.cycle") {
                result.append(PendingCard(id: "stage1.cycle", kind: .stage1, becameDueAt: cycle.savedAt))
            }
        }

        if !hasTemplate, let stage2Day = state.stageOpenedDayKey[.regularEating] {
            let day10 = DayKeyMath.adding(10, to: stage2Day, calendar: calendar)
            let day3 = DayKeyMath.adding(3, to: stage2Day, calendar: calendar)
            if !DayKeyMath.isBefore(currentRecordDay, day10), !cardAnswers.contains("plancard.10") {
                result.append(PendingCard(id: "plancard.10", kind: .plan, becameDueAt: DayKeyMath.dayStartMoment(for: day10, dayStart: settings.dayStart, calendar: calendar)))
            } else if !DayKeyMath.isBefore(currentRecordDay, day3), !cardAnswers.contains("plancard.3") {
                result.append(PendingCard(id: "plancard.3", kind: .plan, becameDueAt: DayKeyMath.dayStartMoment(for: day3, dayStart: settings.dayStart, calendar: calendar)))
            }
        }

        return result
    }

    /// The moment week `week` of a basis day begins: `(week - 1) * 7` days
    /// after `basis`'s own day start.
    private static func weekGateMoment(basis: String, week: Int, dayStart: Int, calendar: Calendar) -> Date {
        DayKeyMath.dayStartMoment(for: DayKeyMath.adding((week - 1) * 7, to: basis, calendar: calendar), dayStart: dayStart, calendar: calendar)
    }
}

/// The entry that made the `n`th distinct `dayKey` recorded, in save order —
/// the shared shape behind the stage 2 gate, the stage 4 fallback and the
/// two stage 1 cards (programme spec, "Stage 2 opens after five recorded
/// days": "The app MUST count a record day as recorded from the moment it
/// gets its first entry").
func nthDistinctDayEntry(_ entries: [EntryFact], n: Int) -> EntryFact? {
    guard n > 0 else { return nil }
    var seen = Set<String>()
    for entry in entries.sorted(by: { $0.savedAt < $1.savedAt }) {
        if seen.insert(entry.dayKey).inserted, seen.count == n {
            return entry
        }
    }
    return nil
}
