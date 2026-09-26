import Foundation

/// One page of the PDF: an ordered slice of `document.contentLines()`
/// (export spec, "The document and the paginator live in a package").
public struct ExportPage: Sendable, Equatable {
    public let lines: [ExportContentLine]

    public init(lines: [ExportContentLine]) {
        self.lines = lines
    }
}

/// Splits an `ExportDocument` into pages of at most `pageHeight`, repeating
/// a day's heading on every page that continues it (export spec, "The
/// document and the paginator live in a package": "The paginator MUST
/// decide where each page ends and which day heading each page repeats.").
/// Imports no UIKit: `measure` is the app's own line-height function, built
/// on `UIFont`/`NSAttributedString`, so this type stays testable with a stub
/// measurer under `swift test` on macOS, where UIKit does not exist.
///
/// Three rules decide where a page ends:
/// - A heading never ends a page. A day heading, its state lines and its
///   column headings stay on the same page as the line after them (the
///   first entry, or the whole day when it has no entries), so no page
///   shows a bare heading that reads as an empty day (export spec: a day
///   with no entries and no state "MUST show its heading and nothing under
///   it").
/// - The "Weigh-ins" heading always starts a new page (export spec, "The
///   optional weigh-in page": "the PDF MUST add a last page with the
///   heading 'Weigh-ins'"), so no weight value prints under the record.
/// - A page that continues a day, or the weigh-in list, starts with a copy
///   of that heading, marked `isContinuation`.
public enum Paginator {
    public static func paginate(document: ExportDocument, pageHeight: Double, measure: (ExportContentLine) -> Double) -> [ExportPage] {
        let lines = document.contentLines()
        guard !lines.isEmpty else { return [] }

        var pages: [[ExportContentLine]] = [[]]
        var heightUsed: Double = 0
        var openHeading: ExportContentLine?

        func append(_ line: ExportContentLine) {
            pages[pages.count - 1].append(line)
            heightUsed += measure(line)
        }

        func startPage() {
            pages.append([])
            heightUsed = 0
        }

        var start = 0
        while start < lines.count {
            let unit = keepTogetherUnit(in: lines, from: start)
            let first = unit[unit.startIndex]
            let unitHeight = unit.reduce(0) { $0 + measure($1) }
            let pageIsEmpty = pages[pages.count - 1].isEmpty

            if first.kind == .weighInHeading {
                if !pageIsEmpty { startPage() }
            } else if !pageIsEmpty, heightUsed + unitHeight > pageHeight {
                startPage()
                if let heading = openHeading, continues(heading, with: first) {
                    append(heading.asContinuation)
                }
            }

            for line in unit { append(line) }
            if first.isDayHeading || first.kind == .weighInHeading { openHeading = first }
            start = unit.endIndex
        }

        return pages.filter { !$0.isEmpty }.map(ExportPage.init(lines:))
    }

    /// The lines from `start` that must share one page: a run of
    /// keep-with-next lines of one day (or of the weigh-in page), plus the
    /// line after the run when it belongs to the same day. A line that
    /// keeps with nothing is a unit of one.
    static func keepTogetherUnit(in lines: [ExportContentLine], from start: Int) -> ArraySlice<ExportContentLine> {
        var end = start
        while end + 1 < lines.count, lines[end].keepsWithNext, lines[end].sharesSection(with: lines[end + 1]) {
            end += 1
        }
        return lines[start...end]
    }

    /// Whether `line`, placed first on a new page, continues the section
    /// that `heading` opened.
    static func continues(_ heading: ExportContentLine, with line: ExportContentLine) -> Bool {
        if heading.kind == .weighInHeading { return line.kind == .weighInRow }
        return !line.isDayHeading && line.dayIndex != nil && line.dayIndex == heading.dayIndex
    }
}
