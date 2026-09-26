import XCTest
@testable import Programme

/// Safeguarding spec, "The support sheet" (mm-t14.24). "Call Samaritans",
/// "Cancel the call", "Call Beat in Scotland", "Copy a number" and "Beat
/// webchat" drive real system APIs (the call flow, the pasteboard, an
/// `SFSafariViewController`) that the App target's device check proves;
/// these tests prove the content and order those controls read from.
final class SupportSheetTests: XCTestCase {
    func testTheList() {
        XCTAssertEqual(SupportSheet.defaultOrder, [.beatHelpline, .beatWebchat, .samaritans, .lifelineNI, .nhs111, .emergency999, .talkToYourGP])
        XCTAssertEqual(SupportSheet.beatNumbers.count, 4)
        XCTAssertEqual(SupportSheet.beatNumbers.map(\.number), ["0808 801 0677", "0808 801 0432", "0808 801 0433", "0808 801 0434"])
    }

    func testFromASelfHarmReason() {
        let order = SupportSheet.order(fromSelfHarmReason: true)
        XCTAssertEqual(order.first, .samaritans)
        XCTAssertEqual(Set(order), Set(SupportSheet.defaultOrder))
    }

    /// Safeguarding spec, "The self-harm item", scenario "Thoughts without a
    /// method" (mm-t14.29): under the support line the screen shows every
    /// item of the sheet inline, with Samaritans first.
    func testInlineItemsUnderTheSupportLine() {
        XCTAssertEqual(SupportSheet.inlineOrder, SupportSheet.order(fromSelfHarmReason: true))
        XCTAssertEqual(SupportSheet.inlineOrder, [.samaritans, .beatHelpline, .beatWebchat, .lifelineNI, .nhs111, .emergency999, .talkToYourGP])
        XCTAssertEqual(Set(SupportSheet.inlineOrder), Set(SupportSheet.Item.allCases))
    }

    func testSamaritansContent() {
        XCTAssertEqual(SupportSheet.samaritansNumber, "116 123")
        XCTAssertEqual(SupportSheet.samaritansWelshNumber, "0808 164 0123")
    }

    func testOffline() {
        // The sheet's content is entirely bundled: no network call builds it.
        XCTAssertFalse(SupportSheet.beatWebchatURLString.isEmpty)
        XCTAssertEqual(SupportSheet.lifelineNumber, "0808 808 8000")
        XCTAssertEqual(SupportSheet.nhs111Number, "111")
    }

    func testTheCallWarningNamesNoPhoneBill() {
        XCTAssertFalse(SupportSheet.callRecentsWarning.lowercased().contains("bill"))
    }

    func testCompensationLineAboveTheGPParagraph() {
        // "The sentence in Get support" (mm-t14.18): the compensation
        // sentence is a fixed constant this sheet shows above the GP
        // paragraph; the view orders them, this proves the sentence itself.
        XCTAssertEqual(SupportSheet.compensationLine, "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first.")
    }
}
