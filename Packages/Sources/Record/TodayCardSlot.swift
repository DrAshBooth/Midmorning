import Foundation

/// A pending card the Today stack's card slot can show (record spec, "The
/// Today stack"). A fixture fact until `programme-engine` (2.1) and its
/// siblings supply the live rows; `TodayCardSlot.next` is a pure function
/// over these so the ordering rule is provable today.
public struct TodayCardFact: Sendable, Equatable {
    public enum Kind: String, Sendable {
        case opening, suggestion, stage1, plan, focus, week13, maintenancePlan
    }

    public let kind: Kind
    public let becameDueAt: Date

    public init(kind: Kind, becameDueAt: Date) {
        self.kind = kind
        self.becameDueAt = becameDueAt
    }
}

/// Picks the one card the slot shows (record spec, "The Today stack"): the
/// oldest pending card, unless a starred entry or an "I binged" outcome in
/// the current record day bars every card but the stage 7 lapse card
/// (`maintenancePlan`), which `staying-on-track` can still show in that same
/// record day.
public enum TodayCardSlot {
    public static func next(
        pending: [TodayCardFact],
        starredEntryOrOutcomeAt: Date?,
        currentRecordDay: DateInterval
    ) -> TodayCardFact? {
        let barred = starredEntryOrOutcomeAt.map(currentRecordDay.contains) ?? false
        let eligible = pending.filter { $0.kind == .maintenancePlan || !barred }
        return eligible.min { $0.becameDueAt < $1.becameDueAt }
    }
}
