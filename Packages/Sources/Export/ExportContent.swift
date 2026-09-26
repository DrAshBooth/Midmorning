import Foundation
import Constants
import Record

/// Every fixed string the export screen and the PDF show, in one place
/// (export spec, "Choose a date range", "The PDF is formatted like the
/// paper record", "Days with no entries...", "Offline and out of logs").
/// Each one is a key in the app's string catalogue, never English (content
/// spec, "Strings live in catalogues"): the App target fills it with
/// `CatalogueText.string`, and a test fills it from the same catalogue.
public enum ExportContent {
    // MARK: Screen

    public static let screenTitle: CatalogueText = .key("export.title")
    public static let fromLabel: CatalogueText = .key("export.from")
    public static let toLabel: CatalogueText = .key("export.to")
    public static let includeWeighInsLabel: CatalogueText = .key("export.includeWeighIns")
    public static let includeContextLabel: CatalogueText = .key("export.includeContext")
    public static let makePDFLabel: CatalogueText = .key("export.makePDF")
    public static let shareDisclosureLine: CatalogueText = .key("export.shareDisclosure")
    public static let buildErrorMessage: CatalogueText = .key("export.buildError")

    /// export spec, "Choose a date range": defaults for the two switches.
    public static let includeWeighInsDefault = false
    public static let includeContextDefault = true

    // MARK: PDF text

    public static let documentHeading: CatalogueText = .key("export.pdf.heading")
    public static let preambleLine: CatalogueText = .key("export.pdf.preamble")
    public static let starLegendLine: CatalogueText = .key("export.pdf.starLegend")
    public static let didntRecordLine: CatalogueText = .key("export.pdf.didntRecord")
    public static let pausedLine: CatalogueText = .key("export.pdf.paused")
    public static let weighInsPageHeading: CatalogueText = .key("export.pdf.weighIns")
    public static let timeColumnHeading: CatalogueText = .key("export.pdf.column.time")
    public static let whatColumnHeading: CatalogueText = .key("export.pdf.column.what")
    public static let whereColumnHeading: CatalogueText = .key("export.pdf.column.where")
    public static let contextColumnHeading: CatalogueText = .key("export.pdf.column.context")
    /// The star mark beside a starred entry's time: a symbol, not a word,
    /// the same as the "*" at the start of `starLegendLine`.
    public static let starredMark = "*"

    /// "Record 28 August – 24 September 2026": the PDF's metadata title
    /// (export spec, "What the PDF never contains": "Metadata").
    public static func pdfTitle(rangeText: String) -> CatalogueText {
        .key("export.pdf.title", .verbatim(rangeText))
    }

    /// export spec, "The PDF is formatted like the paper record": "A day
    /// runs from %1$@ to %2$@." filled with the day start and the minute
    /// before it. The onboarding screen shows the same line, so both read
    /// `record`'s one `DayBoundaryLine`.
    public static func dayRunLine(dayStartHour: Int) -> CatalogueText {
        DayBoundaryLine.text(startHour: dayStartHour)
    }
}
