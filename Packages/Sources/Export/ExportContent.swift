import Foundation

/// Every literal string the export screen and the PDF show, in one place
/// (export spec, "Choose a date range", "The PDF is formatted like the
/// paper record", "Days with no entries...", "Offline and out of logs").
/// The app target passes each one as a variable, never a literal, to
/// `Text`/`Button` (`literal-lint-scope`), so this file is the one home a
/// reviewer checks for wording.
public enum ExportContent {
    // MARK: Screen

    public static let screenTitle = "Export"
    public static let fromLabel = "From"
    public static let toLabel = "To"
    public static let includeWeighInsLabel = "Include weigh-ins"
    public static let includeContextLabel = "Include context"
    public static let makePDFLabel = "Make PDF"
    public static let shareDisclosureLine = "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies."
    public static let buildErrorMessage = "The PDF could not be made. Try again."

    /// export spec, "Choose a date range": defaults for the two switches.
    public static let includeWeighInsDefault = false
    public static let includeContextDefault = true

    // MARK: PDF text

    public static let documentHeading = "Record"
    public static let preambleLine = "Self-recorded on a phone. Times and words are the person's own."
    public static let starLegendLine = "* felt like a binge"
    public static let didntRecordLine = "Didn't record"
    public static let pausedLine = "Paused"
    public static let weighInsPageHeading = "Weigh-ins"
    public static let timeColumnHeading = "Time"
    public static let whatColumnHeading = "What"
    public static let whereColumnHeading = "Where"
    public static let contextColumnHeading = "Context"
    public static let starredMark = "*"

    /// export spec, "The PDF is formatted like the paper record": "A day
    /// runs from %1$@ to %2$@." filled with the day start and the minute
    /// before it, both from the en_GB formatter.
    public static func dayRunLine(dayStartHour: Int) -> String {
        let startText = String(format: "%02d:00", dayStartHour)
        let endHour = (dayStartHour + 23) % 24
        let endText = String(format: "%02d:59", endHour)
        return "A day runs from \(startText) to \(endText)."
    }
}
