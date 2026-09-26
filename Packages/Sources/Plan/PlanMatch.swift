import Foundation

/// One candidate entry for matching: enough to compare against a window
/// (regular-eating-plan spec, "The window of a planned meal"). `Plan` never
/// sees a whole `Record` entry, only its id and time, so it stays
/// independent of `Record`'s own types (design.md, "Pure seams the packages
/// expose").
public struct PlanEntryFact: Sendable, Equatable {
    public let id: UUID
    public let time: Date

    public init(id: UUID, time: Date) {
        self.id = id
        self.time = time
    }
}

/// Matches a record day's entries to its planned-meal windows
/// (regular-eating-plan spec, "The window of a planned meal").
public enum PlanMatching {
    /// The matched entry id per slot index. The earliest unmatched entry
    /// inside each window matches that planned meal; an entry matches at
    /// most one planned meal (windows never overlap once adjusted, so this
    /// is safe to compute independently per window).
    public static func match(windows: [PlannedMealWindow], entries: [PlanEntryFact]) -> [Int: UUID] {
        var result: [Int: UUID] = [:]
        var used: Set<UUID> = []
        for window in windows.sorted(by: { $0.time < $1.time }) {
            let candidates = entries
                .filter { !used.contains($0.id) && window.contains($0.time) }
                .sorted { $0.time < $1.time }
            guard let earliest = candidates.first else { continue }
            result[window.slotIndex] = earliest.id
            used.insert(earliest.id)
        }
        return result
    }
}
