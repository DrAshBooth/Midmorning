import XCTest
@testable import Programme

/// Safeguarding spec, "The GP paragraph" (mm-t14.25). "Copy after an edit"
/// and "Edit not kept" are the pure part of "Copy"; the pasteboard write,
/// its 60-second expiry, the Universal Clipboard exclusion and the largest
/// text size are device checks, because `swift test` cannot drive
/// `UIPasteboard`.
final class GPParagraphTests: XCTestCase {
    func testStandardText() {
        XCTAssertEqual(GPParagraph.text(for: .standard), GPParagraph.standard)
    }

    func testSelfHarmVariantAddsOneSentence() {
        let text = GPParagraph.text(for: .selfHarm)
        XCTAssertTrue(text.hasPrefix(GPParagraph.standard))
        XCTAssertTrue(text.hasSuffix(GPParagraph.selfHarmAddition))
    }

    func testUnder18Variant() {
        XCTAssertEqual(GPParagraph.text(for: .under18), "I'd like to talk about my eating. Is there someone for people my age I can see?")
    }

    /// "Copy": with no edit, the bundled text goes to the pasteboard.
    func testCopyWithoutAnEdit() {
        XCTAssertEqual(GPParagraphCopy.textToCopy(bundled: GPParagraph.standard, edited: nil), GPParagraph.standard)
    }

    /// "Copy after an edit": the edited text, not the bundled one, is copied.
    func testCopyAfterAnEdit() {
        let edited = String(GPParagraph.standard.split(separator: ".").dropLast().joined(separator: ".") + ".")
        XCTAssertEqual(GPParagraphCopy.textToCopy(bundled: GPParagraph.standard, edited: edited), edited)
        XCTAssertNotEqual(edited, GPParagraph.standard)
    }

    /// "Edit not kept": with no `edited` state carried over (the screen
    /// closed and reopened), the field shows the bundled paragraph again.
    func testEditNotKept() {
        XCTAssertEqual(GPParagraphCopy.textToCopy(bundled: GPParagraph.standard, edited: nil), GPParagraph.standard)
    }

    func testFixedTimings() {
        XCTAssertEqual(GPParagraphCopy.pasteboardExpirySeconds, 60)
        XCTAssertEqual(GPParagraphCopy.copiedLabelDurationSeconds, 2)
        XCTAssertEqual(GPParagraphCopy.copiedConfirmationLine, "Copied. It clears in a minute.")
    }
}
