import Foundation
import SwiftData
import XCTest
@testable import Record
import Export
import Programme
import RecordTestSupport

/// A model type that only the test-only second schema version holds.
@Model
final class TestOnlySchemaV2Addition {
    var id: UUID = UUID()

    init(id: UUID = UUID()) {
        self.id = id
    }
}

/// A test-only second schema version: V1's types and one new type. The app
/// ships one schema version (`RecordMigrationPlan`), so this version stays
/// in the test target.
enum TestOnlyRecordSchemaV2: RecordStoreSchemaVersion {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var recordModels: [any PersistentModel.Type] { RecordSchemaV1.recordModels + [TestOnlySchemaV2Addition.self] }
    static var localModels: [any PersistentModel.Type] { RecordSchemaV1.localModels }
}

/// The plan of a later build that adds `TestOnlyRecordSchemaV2`.
enum TestOnlyTwoVersionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RecordSchemaV1.self, TestOnlyRecordSchemaV2.self] }
    static var stages: [MigrationStage] { [.lightweight(fromVersion: RecordSchemaV1.self, toVersion: TestOnlyRecordSchemaV2.self)] }
}

/// data-and-privacy spec, "Launch safety", with ruling r15-01 (mm-t42.28,
/// 7 October 2026): in safe mode the app finds the schema version that the
/// store's metadata names, and opens the store read-only at that version
/// with no migration. So Export works and no store file changes. The next
/// ordinary launch runs the migration.
///
/// The store here is one that the V1 build wrote. The later build is
/// `TestOnlyTwoVersionMigrationPlan`, so the store needs a migration.
/// `AppLockRootView` opens through the same
/// `RecordStore.openInPreparedDirectory(readOnly:)` with
/// `RecordMigrationPlan`.
@MainActor
final class SafeModeSchemaVersionTests: XCTestCase {
    private let moment = Date(timeIntervalSince1970: 1_790_000_000) // 2026-09-21
    private var root: URL!
    private var directory: URL { StoreLayout.storeDirectory(applicationSupportDirectory: root) }
    private var markerURL: URL { StoreLayout.launchMarkerURL(applicationSupportDirectory: root) }

    override func setUpWithError() throws {
        root = try makeTemporaryDirectory()
    }

    /// A record that the V1 build wrote: one entry, one day state, one
    /// weigh-in and one device value.
    private func writeTheV1BuildsRecord() throws {
        // The pool ends the V1 build's container here, so SQLite closes
        // both files before a test reads their bytes.
        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root)
            try store.add(time: moment, what: "Toast and tea", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0, dayStartHour: 5)
            try store.setDayState(.fasting, on: true, dateKey: "2026-09-21", changedAt: moment)
            _ = try store.saveWeighIn(dateKey: "2026-09-21", weightKg: 72.4, unit: "kg", at: moment)
            try store.setLocalSettingValue("kept", key: "test.value")
        }
        waitUntilTheWriteAheadLogsAreEmpty()
    }

    /// The bytes of the two store files and their write-ahead logs. The
    /// `-shm` index is left out: SQLite changes it for a read too.
    private func storeBytes() -> [String: Data] {
        var bytes: [String: Data] = [:]
        for name in ["Record.store", "Record.store-wal", "Local.store", "Local.store-wal"] {
            bytes[name] = try? Data(contentsOf: directory.appendingPathComponent(name))
        }
        return bytes
    }

    /// SQLite copies the write-ahead log into the main file when the last
    /// ordinary connection closes. The test waits for that copy before it
    /// reads the bytes (2 seconds at most).
    private func waitUntilTheWriteAheadLogsAreEmpty() {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            let logs = storeBytes().filter { $0.key.hasSuffix("-wal") }.values
            if logs.allSatisfy(\.isEmpty) { return }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private func storedVersion(_ plan: any SchemaMigrationPlan.Type = TestOnlyTwoVersionMigrationPlan.self) -> Schema.Version? {
        plan.storeSchemaVersion(ofFilesIn: directory)?.versionIdentifier
    }

    /// The export of 21 September, made with the same reads as
    /// `ExportComposer` and `ExportScreenView`.
    private func exportOf21September(from store: RecordStore) throws -> ExportDocument {
        XCTAssertEqual(try store.earliestEntryDayKey(), "2026-09-21")
        _ = try store.dayStartSchedule()
        let dayStartHour = try store.dayStartHour(effectiveOn: "2026-09-21")
        let unit = WeightUnit(rawValue: try store.weighInUnit()) ?? .kg
        let days = [ExportDayInput(dayKey: "2026-09-21", entries: try store.entries(dayKey: "2026-09-21"), states: try store.dayStates(dateKey: "2026-09-21"))]
        let weighInLines = ExportWeighInPageBuilder.lines(from: try store.weighIns(), fromDayKey: "2026-09-21", toDayKey: "2026-09-21", unit: unit)
        let request = ExportBuildRequest(fromDayKey: "2026-09-21", toDayKey: "2026-09-21", includeContext: true, dayStartHour: dayStartHour)
        return ExportDocumentBuilder.build(request: request, days: days, weighInLines: weighInLines)
    }

    /// The metadata of the V1 build's store names V1, in the app's plan
    /// and in the later build's plan. Reading the metadata changes no file.
    func testTheStoreMetadataNamesTheVersionTheStoreHolds() throws {
        try writeTheV1BuildsRecord()
        let before = storeBytes()

        XCTAssertEqual(storedVersion(RecordMigrationPlan.self), RecordSchemaV1.versionIdentifier)
        XCTAssertEqual(storedVersion(), RecordSchemaV1.versionIdentifier)

        XCTAssertEqual(storeBytes(), before)
    }

    /// Why safe mode opens at the store's own version: SwiftData migrates
    /// in place, so a read-only open at the newer version throws
    /// (`NSCocoaErrorDomain` 134110, as the probe on 26 September found),
    /// and no file changes.
    func testAReadOnlyOpenAtTheNewerVersionThrows() throws {
        try writeTheV1BuildsRecord()
        let before = storeBytes()
        let record = ModelConfiguration("Record", schema: Schema(TestOnlyRecordSchemaV2.recordModels), url: directory.appendingPathComponent("Record.store"), allowsSave: false, cloudKitDatabase: .none)
        let local = ModelConfiguration("Local", schema: Schema(TestOnlyRecordSchemaV2.localModels), url: directory.appendingPathComponent("Local.store"), allowsSave: false, cloudKitDatabase: .none)

        XCTAssertThrowsError(try autoreleasepool {
            try ModelContainer(for: Schema(versionedSchema: TestOnlyRecordSchemaV2.self), migrationPlan: TestOnlyTwoVersionMigrationPlan.self, configurations: record, local)
        })

        XCTAssertEqual(storeBytes(), before, "no migration step writes to the store")
    }

    /// Scenario "Safe mode with a pending migration" (ruling r15-01): the
    /// read-only open uses V1 and no migration, Export reads the record,
    /// every write fails, and neither file changes.
    func testSafeModeReadsAStoreThatNeedsAMigration() throws {
        try writeTheV1BuildsRecord()
        let before = storeBytes()

        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)

            XCTAssertTrue(store.isReadOnly)
            XCTAssertEqual(store.container.schema.version, RecordSchemaV1.versionIdentifier, "the open uses the version that the store holds")
            let document = try exportOf21September(from: store)
            XCTAssertEqual(document.days.first?.entries.map(\.what), ["Toast and tea"])
            XCTAssertEqual(document.weighInLines.count, 1)
            XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
            XCTAssertThrowsError(try store.add(time: moment, what: "Soup", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0, dayStartHour: 5))
            XCTAssertThrowsError(try store.setLocalSettingValue("changed", key: "test.value"))
            XCTAssertThrowsError(try store.incrementLaunchFailureCount())
        }

        XCTAssertEqual(storeBytes(), before, "no migration step and no write changes a store file")
        XCTAssertEqual(storedVersion(), RecordSchemaV1.versionIdentifier, "the store still needs the migration")
    }

    /// "The next ordinary launch runs the migration": the ordinary open
    /// migrates the store to V2 and keeps the record. A safe-mode open
    /// after that uses V2.
    func testTheNextOrdinaryOpenRunsTheMigration() throws {
        try writeTheV1BuildsRecord()
        try autoreleasepool {
            _ = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
        }

        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
            XCTAssertFalse(store.isReadOnly)
            XCTAssertEqual(store.container.schema.version, TestOnlyRecordSchemaV2.versionIdentifier)
            XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
            XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
            let context = ModelContext(store.container)
            context.insert(TestOnlySchemaV2Addition())
            try context.save()
        }
        XCTAssertEqual(storedVersion(), TestOnlyRecordSchemaV2.versionIdentifier, "the migration ran")

        let safeMode = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
        XCTAssertEqual(safeMode.container.schema.version, TestOnlyRecordSchemaV2.versionIdentifier)
        XCTAssertEqual(try exportOf21September(from: safeMode).days.first?.entries.map(\.what), ["Toast and tea"])
        XCTAssertEqual(try ModelContext(safeMode.container).fetchCount(FetchDescriptor<TestOnlySchemaV2Addition>()), 1)
    }

    /// The launches after an update to the build with V2, as
    /// `AppLockRootView.openStoreAndController` makes them. Two launches
    /// end in the migration before Today appears. The third launch is in
    /// safe mode: its read-only open at V1 succeeds, so safe mode's Today
    /// appears and clears the marker. The fourth launch is ordinary and
    /// runs the migration.
    func testAfterTwoFailedMigrationsSafeModeShowsTodayAndTheNextLaunchMigrates() throws {
        try writeTheV1BuildsRecord()
        let plan = TestOnlyTwoVersionMigrationPlan.self
        // Launches 1 and 2 end in the migration. A crash leaves no store
        // open, so the test makes no open for them.
        LaunchSession(markerURL: markerURL).begin()
        LaunchSession(markerURL: markerURL).begin()
        let before = storeBytes()

        let third = LaunchSession(markerURL: markerURL)
        XCTAssertTrue(third.begin().launchOutcome.enterSafeMode)
        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: plan)
            third.countLaunchFailureIfNeeded(in: store)
            XCTAssertEqual(try exportOf21September(from: store).days.first?.entries.map(\.what), ["Toast and tea"])
            // Safe mode's Today appears.
            third.clearAfterTodayAppears()
        }
        XCTAssertEqual(storeBytes(), before, "safe mode changes no store file")
        XCTAssertEqual(storedVersion(), RecordSchemaV1.versionIdentifier)

        let fourth = LaunchSession(markerURL: markerURL)
        XCTAssertFalse(fourth.begin().launchOutcome.enterSafeMode, "safe mode's Today cleared the marker")
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: plan)
        fourth.countLaunchFailureIfNeeded(in: store)

        XCTAssertEqual(storedVersion(), TestOnlyRecordSchemaV2.versionIdentifier, "the ordinary launch ran the migration")
        XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        // The failure that launch 2 found is lost, because launch 2 stopped
        // in the open before the count: bead mm-t42.30.
        XCTAssertGreaterThanOrEqual(try store.diagnosticsCounts(contentVersion: 1).launchFailures, 1, "the failure that safe mode kept in the marker")
    }
}
