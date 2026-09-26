import XCTest

/// The helper under every text check (ruling r13-19, mm-t43.30): a snippet
/// that only a comment holds does not count as a call on the screen.
final class ScreenTextTests: XCTestCase {
    func testALineCommentAndADocCommentDoNotCount() {
        let swift = """
        /// Shows "Delete this entry?" before it deletes.
        // Text("Old words")
        Text("New words") // Text("Trailing words")
        """
        let text = ScreenText.normalised(ScreenText.withoutComments(swift))
        XCTAssertFalse(text.contains("Delete this entry?"))
        XCTAssertFalse(text.contains("Old words"))
        XCTAssertFalse(text.contains("Trailing words"))
        XCTAssertTrue(text.contains(#"Text("New words")"#))
    }

    func testABlockCommentDoesNotCount() {
        let swift = """
        /* Text("Old words") /* nested */ still a comment */
        Text("New words")
        """
        let text = ScreenText.normalised(ScreenText.withoutComments(swift))
        XCTAssertFalse(text.contains("Old words"))
        XCTAssertFalse(text.contains("still a comment"))
        XCTAssertTrue(text.contains(#"Text("New words")"#))
    }

    func testTwoSlashesInAStringStay() {
        let swift = #"""
        Link("Privacy notice", destination: URL(string: "https://midmorning.uk/privacy")!)
        Text("A \"quoted // word\" stays")
        let body = """
            // not a comment in a multi-line string
            """
        """#
        let text = ScreenText.normalised(ScreenText.withoutComments(swift))
        XCTAssertTrue(text.contains("https://midmorning.uk/privacy"))
        XCTAssertTrue(text.contains(#"A \"quoted // word\" stays"#))
        XCTAssertTrue(text.contains("// not a comment in a multi-line string"))
    }
}
