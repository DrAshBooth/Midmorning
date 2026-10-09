import XCTest
@testable import Record

/// Ruling r20-01 (mm-t45.12), reminders spec, "A tap on a reminder opens
/// its screen from Today": "When the new-entry screen shows unsaved text,
/// the app MUST keep that screen and its text in front." `NewEntryView`
/// gives its fields to `NewEntryDraft.holdsADraft`. With a draft, a
/// reminder tap waits until the screen closes. With no draft, the screen
/// closes and the reminder's screen opens.
final class NewEntryDraftTests: XCTestCase {
    private func draft(what: String = "", context: String = "", whereSelection: String? = nil, pendingPlace: String? = nil, star: Bool = false) -> Bool {
        NewEntryDraft.holdsADraft(what: what, context: context, whereSelection: whereSelection, pendingPlace: pendingPlace, feltLikeABinge: star)
    }

    /// The screen as "Add an entry" opens it holds no draft.
    func testAnEmptyScreenHoldsNoDraft() {
        XCTAssertFalse(draft())
        XCTAssertFalse(draft(pendingPlace: ""), "an open \"Add a place\" with no text")
    }

    /// Spaces and line breaks only are not a draft.
    func testOnlySpacesAreNotADraft() {
        XCTAssertFalse(draft(what: "  ", context: "\n", pendingPlace: " "))
    }

    /// The scenario "A tap over a new entry with a draft": "Toast and" in
    /// What.
    func testTextInWhatIsADraft() {
        XCTAssertTrue(draft(what: "Toast and"))
    }

    func testTextInContextIsADraft() {
        XCTAssertTrue(draft(context: "Tired"))
    }

    func testTextInAddAPlaceIsADraft() {
        XCTAssertTrue(draft(pendingPlace: "Mum's"))
    }

    func testASelectedWhereIsADraft() {
        XCTAssertTrue(draft(whereSelection: "Home"))
    }

    func testTheStarOnIsADraft() {
        XCTAssertTrue(draft(star: true))
    }
}
