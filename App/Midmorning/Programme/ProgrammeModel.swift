import Foundation
import Record
import Programme

/// The one seam the App target uses to read the live programme state
/// (`v1-programme/design.md`, "Pure seams the packages expose": "Screen
/// models are values ... Views render them and hold no rule"). Gathers
/// `Programme`'s value facts from `store`, computes the state, and persists
/// any newly computed opening. `TodayView` and `ProgrammeScreenView` both
/// call `load(store:)`.
@MainActor
enum ProgrammeModel {
    /// This build's own stages, by tool (decision 102, programme spec, "The
    /// Programme screen shows where the person is"). Stages 3 to 7 show
    /// "Comes in a later version" until their own build change lands.
    static let stagesWithToolInBuild: Set<Int> = [1, 2]

    struct Snapshot {
        let state: ProgrammeState
        let settings: ProgrammeSettings
        let facts: ProgrammeFacts
        let restartAt: Date?
        let cardAnswers: Set<String>
        let hasTemplate: Bool
        let currentRecordDay: String
        let calendar: Calendar
    }

    static func load(store: RecordStore, now: Date = Date(), calendar: Calendar = .current) -> Snapshot {
        let dayStart = (try? store.dayStartHour(effectiveOn: RecordDay.key(containing: now, calendar: calendar))) ?? RecordDay.startHour
        let currentRecordDay = RecordDay.key(containing: now, calendar: calendar, startHour: dayStart)
        let startDay = (try? store.startDayKey()) ?? currentRecordDay
        let settings = ProgrammeSettings(startDay: startDay, dayStart: dayStart)

        let entries = ((try? store.recordedEntryFacts()) ?? []).map {
            EntryFact(id: UUID().uuidString, dayKey: $0.dayKey, starred: $0.starred, savedAt: $0.savedAt)
        }
        let plannedDays = ((try? store.plannedDayKeys()) ?? []).map { PlannedDayFact(dayKey: $0) }
        let urgeOutcomes = ((try? store.urgeOutcomeFacts()) ?? []).map { UrgeOutcomeFact(dayKey: $0.dayKey, savedAt: $0.outcomeAt) }
        let facts = ProgrammeFacts(entries: entries, plannedDays: plannedDays, urgeOutcomes: urgeOutcomes, takingStockCompletedAt: nil)

        let openings = ((try? store.stageOpenedRows()) ?? []).map { StageOpenedRecord(stage: $0.stage, moment: $0.moment) }
        let restartAt = try? store.restartAt()

        let state = StageEngine.state(
            facts: facts, openings: openings, settings: settings, constants: .default,
            now: now, restartAt: restartAt ?? nil, currentRecordDay: currentRecordDay, calendar: calendar
        )

        // "When the engine computes an opening the store lacks, the app
        // MUST write that moment to the store" (programme spec, "A pure
        // stage engine with stored openings as input").
        for computed in state.computedOpenings {
            try? store.recordStageOpened(computed.stage, at: computed.moment)
        }

        let cardAnswers = (try? store.answeredCardIds()) ?? []
        let hasTemplate = (try? store.hasAnyTemplate()) ?? false

        return Snapshot(
            state: state, settings: settings, facts: facts, restartAt: restartAt ?? nil,
            cardAnswers: cardAnswers, hasTemplate: hasTemplate, currentRecordDay: currentRecordDay, calendar: calendar
        )
    }

    /// The pending cards Today's card slot can pick from (programme spec, "A
    /// stage opening shows one card", "Two stage 1 cards come to Today", "A
    /// card when the plan is not set").
    static func pendingCards(_ snapshot: Snapshot) -> [PendingCard] {
        StageEngine.pendingCards(
            state: snapshot.state, facts: snapshot.facts, cardAnswers: snapshot.cardAnswers,
            stagesWithToolInBuild: stagesWithToolInBuild, hasTemplate: snapshot.hasTemplate,
            currentRecordDay: snapshot.currentRecordDay, settings: snapshot.settings, calendar: snapshot.calendar
        )
    }

    /// Maps one `PendingCard` onto `Record`'s own `TodayCardFact`, the type
    /// `TodayCardSlot.next` picks from; `Programme` cannot import `Record`,
    /// so this mapping lives here, one for one.
    static func todayCardFact(_ card: PendingCard) -> TodayCardFact {
        let kind: TodayCardFact.Kind
        switch card.kind {
        case .opening: kind = .opening
        case .stage1: kind = .stage1
        case .plan: kind = .plan
        }
        return TodayCardFact(kind: kind, becameDueAt: card.becameDueAt)
    }

    /// The one card Today's slot shows, and its full `PendingCard` (for its
    /// id, to write the answer): the oldest pending card, unless a starred
    /// entry or an "I binged" outcome in the current record day bars it
    /// (record spec, "The Today stack"; programme spec, "No opening card
    /// after a binge in the same record day").
    static func nextTodayCard(_ snapshot: Snapshot, starredEntryOrOutcomeAt: Date?, currentRecordDay: DateInterval) -> PendingCard? {
        let cards = pendingCards(snapshot)
        guard let winner = TodayCardSlot.next(pending: cards.map(todayCardFact), starredEntryOrOutcomeAt: starredEntryOrOutcomeAt, currentRecordDay: currentRecordDay) else { return nil }
        return cards.first { todayCardFact($0) == winner }
    }
}
