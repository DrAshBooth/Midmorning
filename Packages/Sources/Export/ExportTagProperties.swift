import CoreGraphics
import Foundation

/// The properties of each tag in the export PDF (export spec,
/// "Accessibility of the export": "When the system's PDF renderer can write
/// the tag, the PDF MUST declare the language en-GB."; "Each item's text
/// MUST read, in order: the time, the asterisk when starred, the What, the
/// Where, the Context."). `ExportPDFRenderer` (App target) gives these
/// properties to `CGPDFContextBeginTag`.
///
/// The keys are the raw strings of `CGPDFTagProperty`. A Swift dictionary
/// with `CGPDFTagProperty` keys, cast to `CFDictionary`, holds each key as
/// a boxed Swift value. Core Graphics then finds no key, and writes neither
/// `/Lang` nor `/ActualText` (bug mm-t45.13, found on the iOS 27.0
/// simulator on 7 October 2026). Core Graphics has no key for the
/// language of the whole document, so each tag declares it.
public enum ExportTagProperties {
    /// The language of every tag.
    public static let language = "en-GB"

    /// The language, and the `actualText` of a list item when there is one.
    public static func properties(actualText: String? = nil) -> CFDictionary {
        var properties: [String: Any] = [CGPDFTagProperty.languageText.rawValue as String: language]
        if let actualText {
            properties[CGPDFTagProperty.actualText.rawValue as String] = actualText
        }
        return properties as CFDictionary
    }
}
