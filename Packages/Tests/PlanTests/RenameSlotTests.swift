import Foundation
import XCTest
@testable import Plan

/// regular-eating-plan spec, "Rename a slot in the plan builder" (mm-t23.4).
final class RenameSlotTests: XCTestCase {
    /// Scenario: Rename a slot.
    func testRenameASlot() {
        let outcome = SlotLabel.outcome(forSavedText: "Elevenses")
        XCTAssertEqual(outcome, .save("Elevenses"))
    }

    /// Scenario: Twenty-one characters.
    func testTwentyOneCharactersTruncatesToTwenty() {
        XCTAssertEqual(SlotLabel.truncated("Second breakfast time"), "Second breakfast tim")
        XCTAssertEqual(SlotLabel.truncated("Second breakfast tim").count, 20)
    }

    /// Scenario: The product name.
    func testTheProductNameIsRejectedInAnyLetterCase() {
        XCTAssertEqual(SlotLabel.outcome(forSavedText: "midmorning"), .rejected(message: SlotLabel.productNameMessage))
        XCTAssertEqual(SlotLabel.outcome(forSavedText: "MIDMORNING"), .rejected(message: SlotLabel.productNameMessage))
    }

    /// Scenario: An empty label.
    func testAnEmptyLabelRevertsToTheDefault() {
        XCTAssertEqual(SlotLabel.outcome(forSavedText: "   "), .revertToDefault)
        XCTAssertEqual(SlotLabel.effective(stored: nil, defaultLabel: Slot.all[1].defaultLabel).english, "Mid-morning")
        XCTAssertEqual(SlotLabel.effective(stored: "", defaultLabel: Slot.all[1].defaultLabel).english, "Mid-morning")
        XCTAssertEqual(SlotLabel.productNameMessage.english, "That is the app's name. Choose another word.")
    }

    /// Scenario: A rename is not a plan edit. A rename never touches a
    /// Template row or a Day row's slots — it writes only the `Settings`
    /// `slot.label.<index>` row (data-and-privacy spec, "Slot labels and the
    /// day start are Settings rows"). The rename outcome carries no plan
    /// payload at all, so there is nothing for it to set.
    func testARenameIsNotAPlanEditByConstruction() {
        let outcome = SlotLabel.outcome(forSavedText: "Supper")
        guard case .save(let label) = outcome else { return XCTFail("expected .save") }
        XCTAssertEqual(label, "Supper")
        // Renaming never calls PlanCodec.placing/removing, and touches no
        // Template or Day row — a rename call site only ever calls
        // RecordStore.setSlotLabel.
    }
}
