import Foundation
import SwiftData
import XCTest
@testable import Record

/// data-and-privacy spec, "Rows reference each other by key".
final class RelationshipTests: XCTestCase {
    /// Scenario: No relationships.
    func testNoModelDeclaresARelationship() {
        for entity in Schema(RecordSchema.models + RecordSchema.localModels).entities {
            for property in entity.properties {
                XCTAssertFalse(property is Schema.Relationship, "\(entity.name).\(property.name) is a SwiftData relationship")
            }
        }
    }

    /// Scenario: Entry on a note. A Feeling fat note links an entry by id;
    /// the screen resolves the entry on read, not through a relationship.
    func testEntryOnANoteHoldsTheEntrysId() {
        let entryId = UUID()
        let note = Sheet(kind: "feelingFatNote", entryId: entryId, changedAt: .now)
        XCTAssertEqual(note.entryId, entryId)
    }

    /// Scenario: Edit after a conflict. Two versions of a list item exist;
    /// an edit writes into the winning version's row.
    func testEditAfterAConflictWritesIntoTheWinningRow() {
        let id = UUID()
        let deviceA = ListItem(id: id, kind: "alternative", text: "Ring Sam", changedAt: Date(timeIntervalSince1970: 100))
        let deviceB = ListItem(id: id, kind: "alternative", text: "Ring Sam (B)", changedAt: Date(timeIntervalSince1970: 200))
        let winnerBeforeEdit = ListItemReconciler.merged([deviceA, deviceB]).first!
        XCTAssertEqual(winnerBeforeEdit.id, deviceB.id)
        XCTAssertEqual(winnerBeforeEdit.text, "Ring Sam (B)")

        // The edit targets the winning row's id, not a stale local copy.
        let edited = ListItem(id: winnerBeforeEdit.id, kind: "alternative", text: "Ring Sam at 6", position: winnerBeforeEdit.position, changedAt: Date(timeIntervalSince1970: 300))
        let winnerAfterEdit = ListItemReconciler.merged([deviceA, deviceB, edited]).first!
        XCTAssertEqual(winnerAfterEdit.text, "Ring Sam at 6")
        XCTAssertEqual(winnerAfterEdit.id, id, "the edit landed on the same winning row, not a new one")
    }
}
