import UIKit
import CoreGraphics
import Export

/// Draws an `ExportDocument` as a tagged, A4 PDF with Core Graphics (export
/// spec, "Accessibility of the export": "The PDF MUST be a tagged PDF.";
/// design.md, "Export renders a tagged, flowing column at fixed sizes").
/// Lives in the app target because `Export` itself imports no UIKit
/// (`mm-t42.10`). Every text size is fixed, independent of Dynamic Type:
/// 11 pt body, 14 pt day heading, 18 pt title.
enum ExportPDFRenderer {
    enum Failure: Error { case renderFailed }

    // MARK: A4 geometry, points at 72 dpi.
    private static let pageWidth: CGFloat = 595.28
    private static let pageHeight: CGFloat = 841.89
    private static let margin: CGFloat = 48
    private static var contentWidth: CGFloat { pageWidth - margin * 2 }
    private static var contentHeight: CGFloat { pageHeight - margin * 2 }

    private static let bodyFont = UIFont.systemFont(ofSize: 11)
    private static let boldBodyFont = UIFont.boldSystemFont(ofSize: 11)
    private static let dayHeadingFont = UIFont.boldSystemFont(ofSize: 14)
    private static let titleFont = UIFont.boldSystemFont(ofSize: 18)

    private static let lineSpacing: CGFloat = 6
    private static let columnSpacing: CGFloat = 8
    private static let timeColumnWidth: CGFloat = 55
    private static let whereColumnWidth: CGFloat = 90
    private static let contextColumnWidth: CGFloat = 120

    private static func whatColumnWidth(includeContext: Bool) -> CGFloat {
        let gaps = includeContext ? 3 : 2
        return contentWidth - timeColumnWidth - whereColumnWidth - (includeContext ? contextColumnWidth : 0) - CGFloat(gaps) * columnSpacing
    }

    /// Builds the PDF's bytes. `title` is the document's metadata title and
    /// `pdfTitle`'s own value (export spec, "What the PDF never contains":
    /// "Metadata"): the Creator field is empty; the app never sets Author or
    /// Producer, so the system writes Producer alone.
    static func render(document: ExportDocument, title: String) -> Data {
        let measure: (ExportContentLine) -> Double = { Double(height(of: $0, includeContext: document.includeContext)) }
        let pages = Paginator.paginate(document: document, pageHeight: Double(contentHeight), measure: measure)

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: title,
            kCGPDFContextCreator as String: ""
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        return renderer.pdfData { context in
            for page in pages.isEmpty ? [ExportPage(lines: [])] : pages {
                context.beginPage()
                draw(page: page, in: context.cgContext, includeContext: document.includeContext)
            }
        }
    }

    // MARK: Measuring (shared by the paginator and the drawing pass, so a
    // page never draws more than it planned to fit).

    private static func height(of line: ExportContentLine, includeContext: Bool) -> CGFloat {
        switch line.kind {
        case .documentTitle:
            return textHeight(line.text, font: titleFont, width: contentWidth) + lineSpacing
        case .dayHeading, .weighInHeading:
            return textHeight(line.text, font: dayHeadingFont, width: contentWidth) + lineSpacing
        case .rangeLine, .preambleLine, .starLegendLine, .dayRunLine, .stateLine, .weighInRow:
            return textHeight(line.text, font: bodyFont, width: contentWidth) + lineSpacing
        case .columnHeadings:
            return textHeight(ExportContent.timeColumnHeading, font: boldBodyFont, width: contentWidth) + lineSpacing
        case .entryLine:
            guard let entry = line.entry else { return textHeight(line.text, font: bodyFont, width: contentWidth) + lineSpacing }
            let whatWidth = whatColumnWidth(includeContext: includeContext)
            let timeText = entry.starred ? "\(entry.clockTime) \(ExportContent.starredMark)" : entry.clockTime
            let heights = [
                textHeight(timeText, font: bodyFont, width: timeColumnWidth),
                textHeight(entry.what, font: bodyFont, width: whatWidth),
                textHeight(entry.whereText, font: bodyFont, width: whereColumnWidth),
                includeContext ? textHeight(entry.context, font: bodyFont, width: contextColumnWidth) : 0
            ]
            return (heights.max() ?? textHeight("", font: bodyFont, width: whatWidth)) + lineSpacing
        }
    }

    private static func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return font.lineHeight }
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: max(width, 1), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return bounds.height.rounded(.up)
    }

    // MARK: Drawing

    private static func draw(page: ExportPage, in cg: CGContext, includeContext: Bool) {
        var y: CGFloat = margin
        var listIsOpen = false

        func closeListIfOpen() {
            if listIsOpen {
                CGPDFContextEndTag(cg)
                listIsOpen = false
            }
        }

        for line in page.lines {
            let lineHeight = height(of: line, includeContext: includeContext)
            switch line.kind {
            case .entryLine:
                if !listIsOpen {
                    CGPDFContextBeginTag(cg, .list, languageProperties() as CFDictionary)
                    listIsOpen = true
                }
            default:
                closeListIfOpen()
            }

            switch line.kind {
            case .documentTitle:
                CGPDFContextBeginTag(cg, .header1, languageProperties() as CFDictionary)
                drawText(line.text, font: titleFont, in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight))
                CGPDFContextEndTag(cg)
            case .dayHeading where line.isContinuation:
                // The copy of the heading that `Paginator` repeats on a page
                // that continues the day: drawn for the eye, but outside any
                // tag, so the tag tree holds one H2 per day (export spec,
                // "Accessibility of the export"). A structure element cannot
                // cross a page: Core Graphics closes every open tag when the
                // page ends (tested on macOS, 26 September 2026, mm-t42.26),
                // so each page still opens its own list.
                drawText(line.text, font: dayHeadingFont, in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight))
            case .dayHeading:
                CGPDFContextBeginTag(cg, .header2, languageProperties() as CFDictionary)
                drawText(line.text, font: dayHeadingFont, in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight))
                CGPDFContextEndTag(cg)
            case .weighInHeading:
                drawText(line.text, font: dayHeadingFont, in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight))
            case .rangeLine, .preambleLine, .starLegendLine, .dayRunLine, .stateLine:
                drawText(line.text, font: bodyFont, in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight))
            case .columnHeadings:
                drawColumnHeadings(at: y, includeContext: includeContext)
            case .weighInRow:
                if let weighIn = line.weighIn {
                    drawText(weighIn.dateText, font: bodyFont, in: CGRect(x: margin, y: y, width: contentWidth * 0.6, height: lineHeight))
                    drawText(weighIn.valueText, font: bodyFont, in: CGRect(x: margin + contentWidth * 0.6, y: y, width: contentWidth * 0.4, height: lineHeight))
                }
            case .entryLine:
                if let entry = line.entry {
                    let actualText = entry.accessibilityText(includeContext: includeContext)
                    var properties = languageProperties()
                    properties[CGPDFTagProperty.actualText] = actualText as CFString
                    CGPDFContextBeginTag(cg, .listItem, properties as CFDictionary)
                    drawEntry(entry, at: y, height: lineHeight, includeContext: includeContext)
                    CGPDFContextEndTag(cg)
                }
            }

            y += lineHeight
        }

        closeListIfOpen()
    }

    private static func languageProperties() -> [CGPDFTagProperty: Any] {
        // export spec, "Accessibility of the export": "When the system's PDF
        // renderer can write the tag, the PDF MUST declare the language
        // en-GB." Verified on a built app per the change's own device check
        // (the spec's own "spike"); there is no separate document-level
        // language key in CGPDFContext, only this per-tag property.
        [CGPDFTagProperty.languageText: "en-GB" as CFString]
    }

    private static func drawColumnHeadings(at y: CGFloat, includeContext: Bool) {
        var x = margin
        drawText(ExportContent.timeColumnHeading, font: boldBodyFont, in: CGRect(x: x, y: y, width: timeColumnWidth, height: boldBodyFont.lineHeight))
        x += timeColumnWidth + columnSpacing
        let whatWidth = whatColumnWidth(includeContext: includeContext)
        drawText(ExportContent.whatColumnHeading, font: boldBodyFont, in: CGRect(x: x, y: y, width: whatWidth, height: boldBodyFont.lineHeight))
        x += whatWidth + columnSpacing
        drawText(ExportContent.whereColumnHeading, font: boldBodyFont, in: CGRect(x: x, y: y, width: whereColumnWidth, height: boldBodyFont.lineHeight))
        x += whereColumnWidth + columnSpacing
        if includeContext {
            drawText(ExportContent.contextColumnHeading, font: boldBodyFont, in: CGRect(x: x, y: y, width: contextColumnWidth, height: boldBodyFont.lineHeight))
        }
    }

    private static func drawEntry(_ entry: ExportEntryLine, at y: CGFloat, height: CGFloat, includeContext: Bool) {
        var x = margin
        let timeText = entry.starred ? "\(entry.clockTime) \(ExportContent.starredMark)" : entry.clockTime
        drawText(timeText, font: bodyFont, in: CGRect(x: x, y: y, width: timeColumnWidth, height: height))
        x += timeColumnWidth + columnSpacing
        let whatWidth = whatColumnWidth(includeContext: includeContext)
        drawText(entry.what, font: bodyFont, in: CGRect(x: x, y: y, width: whatWidth, height: height))
        x += whatWidth + columnSpacing
        drawText(entry.whereText, font: bodyFont, in: CGRect(x: x, y: y, width: whereColumnWidth, height: height))
        x += whereColumnWidth + columnSpacing
        if includeContext {
            drawText(entry.context, font: bodyFont, in: CGRect(x: x, y: y, width: contextColumnWidth, height: height))
        }
    }

    /// Every entry uses one text style, with no colour and no fill (export
    /// spec, "The PDF is formatted like the paper record"): plain black
    /// text (`UIColor.black`, not the app's own accent colour) on every
    /// draw call.
    private static func drawText(_ text: String, font: UIFont, in rect: CGRect) {
        guard !text.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }
}
