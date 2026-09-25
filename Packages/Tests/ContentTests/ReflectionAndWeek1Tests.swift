import XCTest
@testable import Content

/// "the reflection.1 to reflection.3 strings" (mm-t11.31) and "the week1.1
/// to week1.3 strings" (mm-t11.32).
final class ReflectionAndWeek1Tests: XCTestCase {
    func testReflectionQuestionsText() {
        XCTAssertEqual(Shipped.bundle.string(id: "reflection.1")?.text, "What did you notice this week?")
        XCTAssertEqual(Shipped.bundle.string(id: "reflection.2")?.text, "What made things harder?")
        XCTAssertEqual(Shipped.bundle.string(id: "reflection.3")?.text, "What helped?")
    }

    func testWeek1QuestionsText() {
        XCTAssertEqual(Shipped.bundle.string(id: "week1.1")?.text, "What do you want to be different by week 12?")
        XCTAssertEqual(Shipped.bundle.string(id: "week1.2")?.text, "What is hardest at the moment?")
        XCTAssertEqual(Shipped.bundle.string(id: "week1.3")?.text, "When are the hardest times of day?")
    }

    /// Scenario: A placeholder in a question
    func testAPlaceholderInAReflectionQuestionFailsAndNamesIt() {
        let entry = StringEntry(id: "reflection.1", text: "What did you notice in week {weekNumber}?")
        let issues = ContentChecks.noRuntimePlaceholder(in: entry)
        XCTAssertEqual(issues.map(\.id), ["reflection.1"])
    }

    func testShippedReflectionAndWeek1QuestionsHoldNoPlaceholder() {
        for id in ["reflection.1", "reflection.2", "reflection.3", "week1.1", "week1.2", "week1.3"] {
            let entry = Shipped.bundle.string(id: id)!
            XCTAssertEqual(ContentChecks.noRuntimePlaceholder(in: entry), [], id)
            XCTAssertTrue(entry.text.hasSuffix("?"), "\(id) is a question")
        }
    }

    func testReflectionAndWeek1QuestionsHoldNoForbiddenWord() {
        let entries = Shipped.bundle.strings.filter { $0.id.hasPrefix("reflection.") || $0.id.hasPrefix("week1.") }
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(entries), [])
    }
}
