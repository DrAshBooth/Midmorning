import CoreGraphics
import CoreText
import Foundation
import XCTest
@testable import Export

/// export spec, "Accessibility of the export" (bug mm-t45.13): Core
/// Graphics writes the language and the ActualText of a tag only when the
/// keys of its properties are the raw strings. The test writes a tagged PDF
/// with `CGPDFContext`, as `ExportPDFRenderer` (App target) does, and reads
/// its tag tree back.
final class ExportTagPropertiesTests: XCTestCase {
    /// The type, the language and the ActualText of each structure element,
    /// in the order of the tag tree.
    private func tagTree(of url: URL) throws -> [(type: String, language: String?, actualText: String?)] {
        let document = try XCTUnwrap(CGPDFDocument(url as CFURL))
        let catalog = try XCTUnwrap(document.catalog)
        func text(_ dictionary: CGPDFDictionaryRef, _ key: String) -> String? {
            var value: CGPDFStringRef?
            guard CGPDFDictionaryGetString(dictionary, key, &value), let value else { return nil }
            return CGPDFStringCopyTextString(value) as String?
        }
        func elements(in object: CGPDFObjectRef) -> [(type: String, language: String?, actualText: String?)] {
            var array: CGPDFArrayRef?
            if CGPDFObjectGetValue(object, .array, &array), let array {
                return (0..<CGPDFArrayGetCount(array)).flatMap { index -> [(type: String, language: String?, actualText: String?)] in
                    var item: CGPDFObjectRef?
                    guard CGPDFArrayGetObject(array, index, &item), let item else { return [] }
                    return elements(in: item)
                }
            }
            var dictionary: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(object, .dictionary, &dictionary), let dictionary else { return [] }
            var name: UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(dictionary, "S", &name), let name else { return [] }
            var kids: CGPDFObjectRef?
            let below = CGPDFDictionaryGetObject(dictionary, "K", &kids) ? kids.map(elements(in:)) ?? [] : []
            return [(String(cString: name), text(dictionary, "Lang"), text(dictionary, "ActualText"))] + below
        }
        var root: CGPDFDictionaryRef?
        var top: CGPDFObjectRef?
        guard CGPDFDictionaryGetDictionary(catalog, "StructTreeRoot", &root), let root,
              CGPDFDictionaryGetObject(root, "K", &top), let top else { return [] }
        return elements(in: top)
    }

    func testEachTagDeclaresEnGBAndAListItemKeepsItsActualText() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ExportTagPropertiesTests-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: url) }
        var box = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let context = try XCTUnwrap(CGContext(url as CFURL, mediaBox: &box, nil))
        let font = CTFontCreateWithName("Helvetica" as CFString, 11, nil)
        func draw(_ string: String, at y: CGFloat) {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]))
            context.textPosition = CGPoint(x: 48, y: y)
            CTLineDraw(line, context)
        }
        context.beginPDFPage(nil)
        CGPDFContextBeginTag(context, .header1, ExportTagProperties.properties())
        draw("Record", at: 780)
        CGPDFContextEndTag(context)
        CGPDFContextBeginTag(context, .header2, ExportTagProperties.properties())
        draw("Thursday 24 September 2026", at: 750)
        CGPDFContextEndTag(context)
        CGPDFContextBeginTag(context, .list, ExportTagProperties.properties())
        let entry = ExportEntryLine(clockTime: "21:40", starred: true, what: "Crisps and half a loaf", whereText: "Home", context: "Row with my sister")
        CGPDFContextBeginTag(context, .listItem, ExportTagProperties.properties(actualText: entry.accessibilityText(includeContext: true)))
        draw("21:40 *", at: 720)
        draw("Crisps and half a loaf", at: 720)
        CGPDFContextEndTag(context)
        CGPDFContextEndTag(context)
        context.endPDFPage()
        context.closePDF()

        let tree = try tagTree(of: url).filter { $0.type != "Document" }
        XCTAssertEqual(tree.map(\.type), ["H1", "H2", "L", "LI"])
        for element in tree {
            XCTAssertEqual(element.language, "en-GB", "the \(element.type) declares the language en-GB")
        }
        XCTAssertEqual(tree.last?.actualText, "21:40 * Crisps and half a loaf Home Row with my sister", "scenario \"One pass per entry\": the list item keeps its text")
    }
}
