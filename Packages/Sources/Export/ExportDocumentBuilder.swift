import Foundation
import Record

/// One record day's facts, as `RecordStore` already reads them, ready for
/// `ExportDocumentBuilder` to arrange into a day block. A day with no
/// entries and no active state is simply absent from `days`.
public struct ExportDayInput: Sendable {
    public let dayKey: String
    public let entries: [RecordRow]
    public let states: Set<DayStateKind>

    public init(dayKey: String, entries: [RecordRow], states: Set<DayStateKind>) {
        self.dayKey = dayKey
        self.entries = entries
        self.states = states
    }
}

/// The person's choices on the export screen (export spec, "Choose a date
/// range").
public struct ExportBuildRequest: Sendable {
    public let fromDayKey: String
    public let toDayKey: String
    public let includeContext: Bool
    public let dayStartHour: Int

    public init(fromDayKey: String, toDayKey: String, includeContext: Bool, dayStartHour: Int) {
        self.fromDayKey = fromDayKey
        self.toDayKey = toDayKey
        self.includeContext = includeContext
        self.dayStartHour = dayStartHour
    }
}

/// Builds the whole `ExportDocument` from the record's rows (export spec,
/// "The PDF is formatted like the paper record", "Days with no entries,
/// \"didn't record\" days and paused days", "The optional weigh-in page").
/// A pure function: the app target reads `RecordStore` and hands the result
/// here; every scenario becomes a test with fixed rows, no live store.
public enum ExportDocumentBuilder {
    public static func build(request: ExportBuildRequest, days: [ExportDayInput], weighInLines: [ExportWeighInLine] = []) -> ExportDocument {
        let dayLookup = Dictionary(uniqueKeysWithValues: days.map { ($0.dayKey, $0) })
        let blocks = ExportDayKey.range(from: request.fromDayKey, to: request.toDayKey).map { key -> ExportDayBlock in
            let input = dayLookup[key]
            let entries = (input?.entries ?? []).map { row in
                ExportEntryLine(clockTime: row.clockTime, starred: row.feltLikeABinge, what: row.what, whereText: row.whereText, context: row.context)
            }
            return ExportDayBlock(
                dayKey: key,
                heading: ExportDayKey.dayHeading(key),
                didntRecord: input?.states.contains(.didntRecord) ?? false,
                paused: input?.states.contains(.paused) ?? false,
                entries: entries
            )
        }
        return ExportDocument(
            rangeText: ExportDayKey.rangeText(from: request.fromDayKey, to: request.toDayKey),
            dayRunLine: ExportContent.dayRunLine(dayStartHour: request.dayStartHour),
            includeContext: request.includeContext,
            days: blocks,
            weighInLines: weighInLines
        )
    }
}
