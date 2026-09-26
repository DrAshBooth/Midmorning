import XCTest
@testable import Programme

/// Safeguarding spec, "The self-harm item" (mm-t14.16).
final class SelfHarmItemTests: XCTestCase {
    func testNo() {
        XCTAssertEqual(SelfHarmItem.outcome(first: .no, second: nil), .noFollowUp)
        XCTAssertFalse(SelfHarmItem.showsSecondQuestion(after: .no))
    }

    func testRatherNotSay() {
        XCTAssertEqual(SelfHarmItem.outcome(first: .ratherNotSay, second: nil), .noFollowUp)
        XCTAssertFalse(SelfHarmItem.showsSecondQuestion(after: .ratherNotSay))
    }

    func testThoughtsWithoutAMethod() {
        XCTAssertTrue(SelfHarmItem.showsSecondQuestion(after: .yes))
        XCTAssertEqual(SelfHarmItem.outcome(first: .yes, second: .no), .supportLine)
        XCTAssertEqual(SelfHarmItem.supportLine, "That deserves a person. Samaritans are there any time, on 116 123.")
    }

    func testThoughtsWithAMethod() {
        XCTAssertEqual(SelfHarmItem.outcome(first: .yes, second: .yes), .excludes)
    }
}
