import Foundation

/// One entry line in the PDF (export spec, "Each entry in the PDF"). A
/// value, not a model: the app maps `Record.RecordRow` to this before the
/// document ever forms.
public struct ExportEntryLine: Sendable, Equatable {
    public let clockTime: String
    public let starred: Bool
    public let what: String
    public let whereText: String
    public let context: String

    public init(clockTime: String, starred: Bool, what: String, whereText: String, context: String) {
        self.clockTime = clockTime
        self.starred = starred
        self.what = what
        self.whereText = whereText
        self.context = context
    }

    /// "21:40 * Crisps and half a loaf Home Row with my sister" (export
    /// spec, "Accessibility of the export": "One pass per entry" — the
    /// screen reader reads the whole item in one pass, not one column at a
    /// time). `includeContext` off stops the text at Where.
    public func accessibilityText(includeContext: Bool) -> String {
        var parts = [clockTime]
        if starred { parts.append(ExportContent.starredMark) }
        if !what.isEmpty { parts.append(what) }
        if !whereText.isEmpty { parts.append(whereText) }
        if includeContext, !context.isEmpty { parts.append(context) }
        return parts.joined(separator: " ")
    }
}

/// One record day's block in the PDF (export spec, "Days with no entries,
/// \"didn't record\" days and paused days").
public struct ExportDayBlock: Sendable, Equatable {
    public let dayKey: String
    public let heading: String
    public let didntRecord: Bool
    public let paused: Bool
    public let entries: [ExportEntryLine]

    public init(dayKey: String, heading: String, didntRecord: Bool, paused: Bool, entries: [ExportEntryLine]) {
        self.dayKey = dayKey
        self.heading = heading
        self.didntRecord = didntRecord
        self.paused = paused
        self.entries = entries
    }

    /// "Didn't record" first, then "Paused" (export spec: "A day with both
    /// states MUST show both lines, 'Didn't record' first.").
    public var stateLines: [String] {
        var lines: [String] = []
        if didntRecord { lines.append(ExportContent.didntRecordLine) }
        if paused { lines.append(ExportContent.pausedLine) }
        return lines
    }
}

/// One row of the optional weigh-in page (export spec, "The optional
/// weigh-in page"). `valueText` is already formatted in the person's unit
/// (`weigh-in`'s own display rule); this package does no unit conversion.
public struct ExportWeighInLine: Sendable, Equatable {
    public let dateText: String
    public let valueText: String

    public init(dateText: String, valueText: String) {
        self.dateText = dateText
        self.valueText = valueText
    }
}

/// The whole PDF's content, a value (export spec, "The document and the
/// paginator live in a package"). `ExportDocumentBuilder` builds one from
/// the record's rows; `Paginator` splits one into pages; the app target
/// draws one with Core Graphics. Holds no rule of its own beyond arranging
/// content into lines.
public struct ExportDocument: Sendable, Equatable {
    public let rangeText: String
    public let dayRunLine: String
    public let includeContext: Bool
    public let days: [ExportDayBlock]
    /// Empty when "Include weigh-ins" is off or no weigh-in falls in the
    /// range (export spec, "The optional weigh-in page": "When no weigh-in
    /// falls in the range, the app MUST omit the page.").
    public let weighInLines: [ExportWeighInLine]

    public init(rangeText: String, dayRunLine: String, includeContext: Bool, days: [ExportDayBlock], weighInLines: [ExportWeighInLine]) {
        self.rangeText = rangeText
        self.dayRunLine = dayRunLine
        self.includeContext = includeContext
        self.days = days
        self.weighInLines = weighInLines
    }

    /// "Record 28 August – 24 September 2026" (export spec, "What the PDF
    /// never contains": "Metadata").
    public var pdfTitle: String { "\(ExportContent.documentHeading) \(rangeText)" }

    /// The document flattened into one ordered list of content lines, the
    /// shape `Paginator` and the app's renderer both walk (export spec, "The
    /// PDF is formatted like the paper record": "The days MUST flow as one
    /// column across the pages.").
    public func contentLines() -> [ExportContentLine] {
        var lines: [ExportContentLine] = []
        lines.append(ExportContentLine(kind: .documentTitle, text: ExportContent.documentHeading))
        lines.append(ExportContentLine(kind: .rangeLine, text: rangeText))
        lines.append(ExportContentLine(kind: .preambleLine, text: ExportContent.preambleLine))
        lines.append(ExportContentLine(kind: .starLegendLine, text: ExportContent.starLegendLine))
        lines.append(ExportContentLine(kind: .dayRunLine, text: dayRunLine))

        for (index, day) in days.enumerated() {
            lines.append(ExportContentLine(kind: .dayHeading(dayIndex: index), text: day.heading))
            for state in day.stateLines {
                lines.append(ExportContentLine(kind: .stateLine(dayIndex: index), text: state))
            }
            if !day.entries.isEmpty {
                lines.append(ExportContentLine(kind: .columnHeadings(dayIndex: index), text: columnHeadingsText))
                for entry in day.entries {
                    lines.append(ExportContentLine(kind: .entryLine(dayIndex: index), text: entry.clockTime, entry: entry))
                }
            }
        }

        if !weighInLines.isEmpty {
            lines.append(ExportContentLine(kind: .weighInHeading, text: ExportContent.weighInsPageHeading))
            for row in weighInLines {
                lines.append(ExportContentLine(kind: .weighInRow, text: "\(row.dateText) \(row.valueText)", weighIn: row))
            }
        }

        return lines
    }

    private var columnHeadingsText: String {
        includeContext
            ? "\(ExportContent.timeColumnHeading) \(ExportContent.whatColumnHeading) \(ExportContent.whereColumnHeading) \(ExportContent.contextColumnHeading)"
            : "\(ExportContent.timeColumnHeading) \(ExportContent.whatColumnHeading) \(ExportContent.whereColumnHeading)"
    }
}

/// One line the paginator measures and the renderer draws (export spec,
/// "The document and the paginator live in a package": "The `measure`
/// parameter MUST be a function that returns a line's height.").
public struct ExportContentLine: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case documentTitle
        case rangeLine
        case preambleLine
        case starLegendLine
        case dayRunLine
        case dayHeading(dayIndex: Int)
        case stateLine(dayIndex: Int)
        case columnHeadings(dayIndex: Int)
        case entryLine(dayIndex: Int)
        case weighInHeading
        case weighInRow
    }

    public let kind: Kind
    public let text: String
    public let entry: ExportEntryLine?
    public let weighIn: ExportWeighInLine?
    /// True for a heading that `Paginator` repeats at the top of a page
    /// that continues its day or the weigh-in page (export spec, "The PDF
    /// is formatted like the paper record": "When a day continues on a new
    /// page, the PDF MUST repeat the day's heading on that page."). The
    /// renderer draws it but does not tag it as a second H2 (export spec,
    /// "Accessibility of the export": "The PDF MUST tag each day heading as
    /// an H2.").
    public let isContinuation: Bool

    public init(kind: Kind, text: String, entry: ExportEntryLine? = nil, weighIn: ExportWeighInLine? = nil, isContinuation: Bool = false) {
        self.kind = kind
        self.text = text
        self.entry = entry
        self.weighIn = weighIn
        self.isContinuation = isContinuation
    }

    /// This heading, marked as the copy `Paginator` repeats on a new page.
    public var asContinuation: ExportContentLine {
        ExportContentLine(kind: kind, text: text, entry: entry, weighIn: weighIn, isContinuation: true)
    }

    /// The day this line belongs to, or `nil` for a line that appears once
    /// (the title block, a weigh-in line). `Paginator` uses this to decide
    /// which heading to repeat.
    public var dayIndex: Int? {
        switch kind {
        case .dayHeading(let i), .stateLine(let i), .columnHeadings(let i), .entryLine(let i): return i
        default: return nil
        }
    }

    public var isDayHeading: Bool {
        if case .dayHeading = kind { return true }
        return false
    }

    /// A line that `Paginator` keeps on the same page as the line after
    /// it: a day heading, a state line, the column headings and the
    /// "Weigh-ins" heading. None of them may end a page on its own.
    var keepsWithNext: Bool {
        switch kind {
        case .dayHeading, .stateLine, .columnHeadings, .weighInHeading: return true
        default: return false
        }
    }

    /// Whether `next` belongs to the same day, or to the same weigh-in
    /// page, as this line.
    func sharesSection(with next: ExportContentLine) -> Bool {
        if let dayIndex { return next.dayIndex == dayIndex }
        return kind == .weighInHeading && next.kind == .weighInRow
    }
}
