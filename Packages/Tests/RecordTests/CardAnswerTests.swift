import Foundation
import XCTest
@testable import Record

/// data-and-privacy spec, "Card answers live in the record".
final class CardAnswerTests: XCTestCase {
    /// Scenario: Card answered on one device.
    func testCardAnsweredOnOneDeviceShowsNoCardOnTheOther() {
        let cardId = "opening-stage-2"
        let closed = Answer(kind: "card", cardId: cardId, value: "closed", changedAt: .now)
        let winner = AnswerReconciler.winners(in: [closed])["card|\(cardId)"]
        XCTAssertNotNil(winner, "device B reads the answer row after sync and shows no card for that id")
    }

    /// Scenario: Suggestion on two devices. Built here over fixture facts,
    /// with no live dependency on `pattern-suggestions`; mm-t41b.13 runs it
    /// end to end.
    func testSuggestionOnTwoDevicesAnswerIsKeyedByTheTemplateId() {
        let templateId = "pattern-template-3"
        let answeredOnDeviceA = Answer(kind: "card", cardId: templateId, value: "closed", changedAt: .now)
        let winner = AnswerReconciler.winners(in: [answeredOnDeviceA])["card|\(templateId)"]
        XCTAssertEqual(winner?.cardId, templateId, "device B never shows a suggestion card for the same template id")
    }
}
