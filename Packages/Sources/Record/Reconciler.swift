import Foundation

/// Picks one winner per natural key on read. Never deletes a row: every
/// function here takes an array and returns a value or a map; nothing here
/// mutates or removes an input (data-and-privacy spec, "The Reconciler never
/// deletes a row").
public enum Reconciler {
    /// The generic rule most models share: the row with the later
    /// `changedAt` wins its key, whole row. On an exact tie the function
    /// keeps the first row it saw for that key, which is deterministic for a
    /// fixed input order but not itself a spec-stated tie-break; only
    /// `EntryWinner` and `ReviewWinner` have a spec-stated tie-break.
    public static func latestWins<Row, Key: Hashable>(_ rows: [Row], key: (Row) -> Key, changedAt: (Row) -> Date) -> [Key: Row] {
        var winners: [Key: Row] = [:]
        for row in rows {
            let k = key(row)
            if let existing = winners[k] {
                if changedAt(row) > changedAt(existing) { winners[k] = row }
            } else {
                winners[k] = row
            }
        }
        return winners
    }

    /// Whether a losing row can now be deleted: 90 days older than the
    /// device clock, and 90 days older than the latest sync moment. Both
    /// tests must pass (data-and-privacy spec, "Entries are append-only
    /// versions"; "The Reconciler never deletes a row").
    public static func canDeleteLosingRow(changedAt: Date, now: Date, latestSyncMoment: Date, retentionDays: Int = 90) -> Bool {
        let cutoff = -Double(retentionDays) * 86400
        return changedAt.timeIntervalSince(now) <= cutoff && changedAt.timeIntervalSince(latestSyncMoment) <= cutoff
    }
}

/// The winner rule for `ItemVersion` (data-and-privacy spec, "Entries are
/// append-only versions"): later `changedAt`; then star on; then longer
/// `what`; then lexically greater `what`; then greater version id.
public enum EntryWinner {
    /// The winning version of one entry's versions, or `nil` for an empty array.
    public static func pick(_ versions: [ItemVersion]) -> ItemVersion? {
        versions.max { lhs, rhs in isBetter(rhs, than: lhs) }
    }

    /// The winner per entry id, grouping `versions` by `entryId`.
    public static func winners(in versions: [ItemVersion]) -> [UUID: ItemVersion] {
        Dictionary(grouping: versions, by: \.entryId).compactMapValues(pick)
    }

    /// True when `candidate` beats `current` by the full tie-break chain.
    static func isBetter(_ candidate: ItemVersion, than current: ItemVersion) -> Bool {
        if candidate.changedAt != current.changedAt { return candidate.changedAt > current.changedAt }
        if candidate.feltLikeABinge != current.feltLikeABinge { return candidate.feltLikeABinge }
        if candidate.what.count != current.what.count { return candidate.what.count > current.what.count }
        if candidate.what != current.what { return candidate.what > current.what }
        return candidate.id.uuidString > current.id.uuidString
    }
}

/// One row per (`dateKey`, `kind`); winner: later `changedAt`.
public enum DayStateReconciler {
    struct Key: Hashable { let dateKey: String; let kind: String }
    public static func winners(in rows: [DayState]) -> [String: DayState] {
        let byCompositeKey = Reconciler.latestWins(rows, key: { Key(dateKey: $0.dateKey, kind: $0.kind) }, changedAt: \.changedAt)
        return Dictionary(uniqueKeysWithValues: byCompositeKey.map { ("\($0.key.dateKey)|\($0.key.kind)", $0.value) })
    }
}

/// One row per `kind`; winner: later `changedAt`.
public enum TemplateReconciler {
    public static func winners(in rows: [Template]) -> [String: Template] {
        Reconciler.latestWins(rows, key: \.kind, changedAt: \.changedAt)
    }
}

/// One row per `dateKey`; winner: later `changedAt` for the plan payload.
/// "Set" is sticky: once any device's row for the day carries `setAt`, the
/// winner carries it too, even when a later plan edit's row does not
/// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and
/// lists").
public enum DayReconciler {
    public static func winners(in rows: [Day]) -> [String: Day] {
        let groups = Dictionary(grouping: rows, by: \.dateKey)
        return groups.compactMapValues { group -> Day? in
            guard let payloadWinner = Reconciler.latestWins(group, key: { _ in 0 }, changedAt: \.changedAt).values.first else { return nil }
            let sticky = group.filter { $0.setAt != nil }.min { $0.setAt! < $1.setAt! }
            guard let sticky, payloadWinner.setAt == nil else { return payloadWinner }
            return Day(
                id: payloadWinner.id,
                dateKey: payloadWinner.dateKey,
                slotsJSON: payloadWinner.slotsJSON,
                windowBeforeMinutes: payloadWinner.windowBeforeMinutes,
                windowAfterMinutes: payloadWinner.windowAfterMinutes,
                changedAt: payloadWinner.changedAt,
                setAt: sticky.setAt,
                setBy: sticky.setBy
            )
        }
    }
}

/// One row per (`kind`, `dateKey`, `slotIndex`) for a planned-meal answer, or
/// per (`kind`, `cardId`) for a card answer; winner: later `changedAt`
/// (data-and-privacy spec, "Conflict rules for the plan, weigh-ins and
/// lists"; "Card answers live in the record").
public enum AnswerReconciler {
    static func naturalKey(_ answer: Answer) -> String {
        answer.kind == "plannedMeal" ? "plannedMeal|\(answer.dateKey)|\(answer.slotIndex)" : "\(answer.kind)|\(answer.cardId)"
    }

    public static func winners(in rows: [Answer]) -> [String: Answer] {
        Reconciler.latestWins(rows, key: naturalKey, changedAt: \.changedAt)
    }
}

/// Programme's opening moments live as `Answer` rows of kind "stageOpened",
/// keyed by the stage number in `cardId` (there is no seventeenth model; the
/// stage-opened natural key is small and keyed, like a card answer). Winner:
/// the earliest moment, not the latest — the opposite rule from every other
/// `Answer` kind (data-and-privacy spec, "The Reconciler never deletes a
/// row": "For the stage-opened rows the natural key is the stage and the
/// winner is the row with the earliest moment").
public enum StageOpenedReconciler {
    public static let kind = "stageOpened"

    /// The winning stage-opened row for `stage`, ignoring a row dated later
    /// than `now`, and — for stage 5 only — a row earlier than `restartAt`.
    /// Every row stays in the store; this only picks what the engine reads.
    public static func winner(stage: Int, in rows: [Answer], now: Date, restartAt: Date? = nil) -> Answer? {
        rows
            .filter { $0.kind == kind && $0.cardId == String(stage) }
            .filter { $0.changedAt <= now }
            .filter { stage != 5 || restartAt == nil || $0.changedAt >= restartAt! }
            .min { $0.changedAt < $1.changedAt }
    }
}

/// One row per `dateKey`; winner: later `changedAt`, whole row. The store
/// never keeps two weigh-ins for one weigh-in day and never averages two
/// versions (data-and-privacy spec, "Conflict rules for the plan, weigh-ins
/// and lists").
public enum MeasureReconciler {
    public static func winners(in rows: [Measure]) -> [String: Measure] {
        Reconciler.latestWins(rows, key: \.dateKey, changedAt: \.changedAt)
    }
}

/// One row per `id`; winner: later `changedAt`. Two devices' new items with
/// different ids both survive (a union, not a conflict). The merged list
/// orders by `position`, then `changedAt` (data-and-privacy spec, "Conflict
/// rules for the plan, weigh-ins and lists").
public enum ListItemReconciler {
    public static func merged(_ rows: [ListItem]) -> [ListItem] {
        Reconciler.latestWins(rows, key: \.id, changedAt: \.changedAt)
            .values
            .filter { !$0.deleted }
            .sorted { lhs, rhs in
                if lhs.position != rhs.position { return lhs.position < rhs.position }
                return lhs.changedAt < rhs.changedAt
            }
    }
}

/// One row per `id`; winner: later `changedAt`.
public enum SheetReconciler {
    public static func winners(in rows: [Sheet]) -> [UUID: Sheet] {
        Reconciler.latestWins(rows, key: \.id, changedAt: \.changedAt)
    }
}

/// One row per (`kind`, `dueDateKey`); winner: the row with the earliest
/// `frozenAt` among the frozen rows. An unfrozen row is not yet a winner —
/// no device has crossed the due moment on a later sync, so there is nothing
/// to freeze yet (data-and-privacy spec, "Day states, sessions and
/// reviews").
public enum ReviewReconciler {
    struct Key: Hashable { let kind: String; let dueDateKey: String }

    public static func winners(in rows: [Review]) -> [String: Review] {
        let frozen = rows.filter { $0.frozenAt != nil }
        let byKey = Dictionary(grouping: frozen, by: { Key(kind: $0.kind, dueDateKey: $0.dueDateKey) })
        var result: [String: Review] = [:]
        for (key, group) in byKey {
            if let winner = group.min(by: { $0.frozenAt! < $1.frozenAt! }) {
                result["\(key.kind)|\(key.dueDateKey)"] = winner
            }
        }
        return result
    }
}

/// One row per `installId`; winner: later `changedAt`.
public enum DeviceReconciler {
    public static func winners(in rows: [Device]) -> [UUID: Device] {
        Reconciler.latestWins(rows, key: \.installId, changedAt: \.changedAt)
    }
}

/// `Profile` has one fixed id; winner: later `changedAt`, whole row
/// (data-and-privacy spec, "The app reads iCloud before onboarding").
public enum ProfileReconciler {
    public static func winner(in rows: [Profile]) -> Profile? {
        rows.max { $0.changedAt < $1.changedAt }
    }
}

/// One row per `key`; winner: later `changedAt`, whole row (data-and-privacy
/// spec, "Slot labels and the day start are Settings rows").
public enum SettingsReconciler {
    public static func winners(in rows: [Settings]) -> [String: Settings] {
        Reconciler.latestWins(rows, key: \.key, changedAt: \.changedAt)
    }
}

/// A `Session` row keeps its own identity; devices never overwrite one
/// another's row. Readers treat the earliest-started, still-open session of
/// a record day as the open one, and every other open session of that day
/// closes silently at the day end (data-and-privacy spec, "Day states,
/// sessions and reviews").
public enum SessionOpenPicker {
    static let sentinelOutcome = "closedAutomatically"

    /// The open session of `dayKey`: the earliest-started row whose
    /// `outcome` is still empty.
    public static func open(in sessions: [Session], dayKey: String) -> Session? {
        sessions
            .filter { $0.startDayKey == dayKey && $0.outcome.isEmpty }
            .min { $0.startedAt < $1.startedAt }
    }

    /// Every other still-open session of `dayKey`, silently closed at
    /// `dayEnd`. Returns new values; it does not mutate `sessions`.
    public static func silentlyClosedAtDayEnd(in sessions: [Session], dayKey: String, dayEnd: Date) -> [Session] {
        guard let openSession = open(in: sessions, dayKey: dayKey) else { return [] }
        return sessions
            .filter { $0.startDayKey == dayKey && $0.outcome.isEmpty && $0.id != openSession.id }
            .map { session in
                Session(
                    id: session.id,
                    startedAt: session.startedAt,
                    startDayKey: session.startDayKey,
                    outcome: sentinelOutcome,
                    outcomeAt: dayEnd,
                    outcomeDayKey: dayKey,
                    entryId: session.entryId
                )
            }
    }
}
