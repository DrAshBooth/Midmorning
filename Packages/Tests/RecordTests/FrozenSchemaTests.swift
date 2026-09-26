import Foundation
import SwiftData
import XCTest
@testable import Record
import RecordTestSupport

/// data-and-privacy spec, "CKRecord types and model names are neutral", and
/// "The schema is frozen and grows by addition only".
final class FrozenSchemaTests: XCTestCase {
    /// Scenario: Kind field.
    func testKindField() {
        let avoidedFood = ListItem(kind: "avoidedFood", text: "Bread", changedAt: .now)
        let worksheet = Sheet(kind: "worksheet", changedAt: .now)
        XCTAssertEqual(avoidedFood.kind, "avoidedFood")
        XCTAssertEqual(worksheet.kind, "worksheet")
        let bannedWords = ["eating", "weight", "urge", "body", "binge", "diet", "screen"]
        for name in [ListItem.self, Sheet.self].map(String.init(describing:)) {
            XCTAssertTrue(bannedWords.allSatisfy { !name.lowercased().contains($0) }, "\(name) names no banned concept")
        }
    }

    /// Scenario: Entity name test.
    func testEntityNameTestListsExactlyTheSixteenNames() {
        let entityNames = Set(Schema(RecordSchema.models).entities.map(\.name))
        XCTAssertEqual(entityNames, RecordSchema.neutralModelNames)
        XCTAssertEqual(entityNames.count, 16)
    }

    /// Scenario: Typealias in the code.
    func testTypealiasInTheCode() {
        let entry: Entry = Item(id: UUID())
        XCTAssertTrue(type(of: entry) == Item.self)
        let version: EntryVersion = ItemVersion(entryId: UUID(), changedAt: .now, dayKey: "2026-09-25", time: .now, utcOffsetSeconds: 0, what: "", feltLikeABinge: false, createdAt: .now)
        XCTAssertTrue(type(of: version) == ItemVersion.self)
        let modelNames = Set(RecordSchema.models.map { String(describing: $0) })
        XCTAssertEqual(modelNames, RecordSchema.neutralModelNames, "no @Model class carries a name outside the sixteen")
    }

    /// Scenario: Frozen names. Simulates a rename by dropping the frozen
    /// name for one field from a hand-built "current" snapshot standing in
    /// for a renamed live schema, and asserts the checker fails and names
    /// the field.
    func testFrozenNamesCatchesARename() throws {
        let frozen = try FrozenSchema.load()
        var renamedCurrent = frozen
        let type = renamedCurrent["ItemVersion"]!.removeValue(forKey: "what")!
        renamedCurrent["ItemVersion"]!["whatText"] = type // the rename

        let violations = FrozenSchema.violations(current: renamedCurrent, frozen: frozen)
        XCTAssertEqual(violations, [
            "ItemVersion.what: field missing from the schema (a rename or a delete)",
            "ItemVersion.whatText: field String not in the frozen file"
        ], "the test fails and names the field")
    }

    /// A retype keeps every name, so a names-only check would pass it. The
    /// frozen file holds each field's type, so the checker fails and names
    /// the field.
    func testFrozenTypesCatchARetype() throws {
        let frozen = try FrozenSchema.load()
        XCTAssertEqual(frozen["Measure"]?["weightKg"], "Double")
        var retyped = frozen
        retyped["Measure"]!["weightKg"] = "String"
        XCTAssertEqual(FrozenSchema.violations(current: retyped, frozen: frozen), ["Measure.weightKg: type String, frozen as Double"])
    }

    /// Making a required field optional, or an optional field required, is
    /// a change of the field, not an addition.
    func testFrozenTypesCatchAnOptionalityChange() throws {
        let frozen = try FrozenSchema.load()
        XCTAssertEqual(frozen["ItemVersion"]?["dayKey"], "String")
        XCTAssertEqual(frozen["Review"]?["frozenAt"], "Date?")
        var changed = frozen
        changed["ItemVersion"]!["dayKey"] = "String?"
        changed["Review"]!["frozenAt"] = "Date"
        XCTAssertEqual(FrozenSchema.violations(current: changed, frozen: frozen), [
            "ItemVersion.dayKey: type String?, frozen as String",
            "Review.frozenAt: type Date, frozen as Date?"
        ])
    }

    /// The live schema reports an optional attribute with a `?`, the same
    /// shape as the frozen file.
    func testTheLiveSchemaWritesOptionalTypesWithAQuestionMark() {
        let current = FrozenSchema.currentFields()
        XCTAssertEqual(current["Day"]?["setAt"], "Date?")
        XCTAssertEqual(current["Measure"]?["weightKg"], "Double")
        XCTAssertEqual(current["Session"]?["entryId"], "UUID?")
    }

    /// Scenario: Field added. Adding an optional field to the frozen
    /// snapshot together with the same field in "current" keeps them equal:
    /// no violation, matching "updates the frozen file in the same commit".
    func testFieldAddedWithTheFrozenFileUpdatedInTheSameCommitPasses() throws {
        let frozen = try FrozenSchema.load()
        var withNewField = frozen
        withNewField["Item"]!["note"] = "String?"
        let currentAfterAddingTheField = withNewField
        XCTAssertTrue(FrozenSchema.violations(current: currentAfterAddingTheField, frozen: withNewField).isEmpty)
        XCTAssertEqual(FrozenSchema.violations(current: currentAfterAddingTheField, frozen: frozen), ["Item.note: field String? not in the frozen file"], "until the file is updated, the addition fails")
    }

    /// The live schema matches the committed frozen file exactly, right now.
    func testLiveSchemaMatchesTheFrozenFile() throws {
        let frozen = try FrozenSchema.load()
        let current = FrozenSchema.currentFields()
        XCTAssertEqual(FrozenSchema.violations(current: current, frozen: frozen), [])
    }

    /// Scenario: One schema version in V1.
    func testOneSchemaVersionInV1() {
        XCTAssertEqual(RecordMigrationPlan.schemas.count, 1)
        XCTAssertEqual(ObjectIdentifier(RecordMigrationPlan.schemas[0]), ObjectIdentifier(RecordSchemaV1.self))
        XCTAssertEqual(RecordSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertTrue(RecordMigrationPlan.stages.isEmpty, "no migration stage exists yet")
    }

    /// Scenario: Every earlier version opens. V1 is the first TestFlight
    /// schema, so its own fixture is the one this test opens; a later change
    /// adds one fixture per further version, through the same harness.
    @MainActor
    func testEveryEarlierSchemaVersionOpens() throws {
        let directory = try makeTemporaryDirectory()

        // Write a V1 fixture directly against RecordSchemaV1.
        do {
            let configuration = ModelConfiguration(schema: Schema(versionedSchema: RecordSchemaV1.self), url: directory.appendingPathComponent("fixture.store"))
            let container = try ModelContainer(for: Schema(versionedSchema: RecordSchemaV1.self), migrationPlan: RecordMigrationPlan.self, configurations: configuration)
            let context = ModelContext(container)
            let entryId = UUID()
            context.insert(Item(id: entryId))
            context.insert(ItemVersion(entryId: entryId, changedAt: .now, dayKey: "2026-09-25", time: .now, utcOffsetSeconds: 0, what: "Porridge", feltLikeABinge: false, createdAt: .now))
            try context.save()
        }

        // Open the fixture again through the migration plan the app ships.
        let configuration = ModelConfiguration(schema: Schema(versionedSchema: RecordSchemaV1.self), url: directory.appendingPathComponent("fixture.store"))
        let reopened = try ModelContainer(for: Schema(versionedSchema: RecordSchemaV1.self), migrationPlan: RecordMigrationPlan.self, configurations: configuration)
        let context = ModelContext(reopened)
        let versions = try context.fetch(FetchDescriptor<ItemVersion>())
        XCTAssertEqual(versions.count, 1)
        XCTAssertEqual(versions.first?.what, "Porridge", "every entry is on Today")
    }
}
