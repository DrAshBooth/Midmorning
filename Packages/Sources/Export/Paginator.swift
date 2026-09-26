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
public enum Paginator {
    public static func paginate(document: ExportDocument, pageHeight: Double, measure: (ExportContentLine) -> Double) -> [ExportPage] {
        let lines = document.contentLines()
        guard !lines.isEmpty else { return [] }

        var pages: [[ExportContentLine]] = [[]]
        var heightUsed: Double = 0
        var openDayHeading: ExportContentLine?

        func append(_ line: ExportContentLine) {
            pages[pages.count - 1].append(line)
            heightUsed += measure(line)
        }

        for line in lines {
            let lineHeight = measure(line)
            if !pages[pages.count - 1].isEmpty, heightUsed + lineHeight > pageHeight {
                pages.append([])
                heightUsed = 0
                // export spec: "When a day continues on a new page, the PDF
                // MUST repeat the day's heading on that page."
                if let heading = openDayHeading, !line.isDayHeading, line.dayIndex == heading.dayIndex {
                    append(heading)
                }
            }
            append(line)
            if line.isDayHeading { openDayHeading = line }
        }

        return pages.filter { !$0.isEmpty }.map(ExportPage.init(lines:))
    }
}
