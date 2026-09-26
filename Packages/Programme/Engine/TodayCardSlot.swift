import Foundation

/// A card Today's card slot can show (record spec, "The Today stack").
public protocol TodayCardCandidate {
    var becameDueAt: Date { get }
    /// True only for the stage 7 lapse card, the maintenance plan card that
    /// `staying-on-track` shows. That card can show in the same record day
    /// as a starred entry or an "I binged" outcome.
    var showsInABarredRecordDay: Bool { get }
}

extension PendingCard: TodayCardCandidate {
    /// No card that this build makes is the stage 7 lapse card.
    public var showsInABarredRecordDay: Bool { false }
}

/// Picks the one card the slot shows (record spec, "The Today stack"): the
/// oldest pending card, unless a starred entry or an "I binged" outcome in
/// the current record day bars every card but the stage 7 lapse card. The
/// bar is `PinnedNoteHold`'s own predicate.
public enum TodayCardSlot {
    public static func next<Card: TodayCardCandidate>(
        pending: [Card],
        starredEntryOrOutcomeAt: Date?,
        currentRecordDay: DateInterval
    ) -> Card? {
        let barred = PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: starredEntryOrOutcomeAt, currentRecordDay: currentRecordDay)
        let eligible = pending.filter { $0.showsInABarredRecordDay || !barred }
        return eligible.min { $0.becameDueAt < $1.becameDueAt }
    }
}
