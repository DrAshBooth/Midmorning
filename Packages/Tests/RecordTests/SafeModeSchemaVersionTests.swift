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

/// The stop in the test-only migration.
struct TestOnlyMigrationStop: Error {}

/// The same later build, with a migration that stops in `Record.store`,
/// the file that holds the rows. SwiftData migrates the two store files
/// one at a time, in an order that changes from run to run, and calls the
/// stage once for each file. So `Local.store` migrates when it comes
/// first, and stays at V1 when `Record.store` comes first.
enum TestOnlyMigrationStopsInRecordStorePlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RecordSchemaV1.self, TestOnlyRecordSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.custom(
            fromVersion: RecordSchemaV1.self,
            toVersion: TestOnlyRecordSchemaV2.self,
            willMigrate: { context in
                if context.container.configurations.contains(where: { $0.url.lastPathComponent == "Record.store" }) {
                    throw TestOnlyMigrationStop()
                }
            },
            didMigrate: nil
        )]
    }
}

/// data-and-privacy spec, "Launch safety", with ruling r15-01 (mm-t42.28,
/// 7 October 2026): in safe mode the app finds the schema version that the
/// store's metadata names, and opens the store read-only at that version
/// with no migration. So Export works and no store file changes. The next
/// ordinary launch runs the migration.
///
/// The store here is one that the V1 build wrote. The later build is
/// `TestOnlyTwoVersionMigrationPlan`, so the store needs a migration. Some
/// tests stop the migration after one of the two store files, so the two
/// files hold different versions; safe mode then opens each file at its
/// own version.
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
            try store.setCollapseChoice(.collapsed, dateKey: "2026-09-21")
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

    /// The version that the metadata of one store file names.
    private func fileVersion(_ name: String, _ plan: any SchemaMigrationPlan.Type = TestOnlyTwoVersionMigrationPlan.self) -> Schema.Version? {
        plan.storeSchemaVersion(ofFileAt: directory.appendingPathComponent(name))?.versionIdentifier
    }

    /// Migrates one store file to V2 and leaves the other file at V1, as a
    /// launch that stops after the first file of the migration does. The
    /// container holds the other configuration in memory, so it does not
    /// open the other file.
    private func migrateOnlyOneFile(_ name: String) throws {
        func configuration(_ configurationName: String, models: [any PersistentModel.Type], file: String) -> ModelConfiguration {
            file == name
                ? ModelConfiguration(configurationName, schema: Schema(models), url: directory.appendingPathComponent(file), cloudKitDatabase: .none)
                : ModelConfiguration(configurationName, schema: Schema(models), isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        try autoreleasepool {
            _ = try ModelContainer(
                for: Schema(versionedSchema: TestOnlyRecordSchemaV2.self),
                migrationPlan: TestOnlyTwoVersionMigrationPlan.self,
                configurations: configuration("Record", models: TestOnlyRecordSchemaV2.recordModels, file: "Record.store"),
                configuration("Local", models: TestOnlyRecordSchemaV2.localModels, file: "Local.store")
            )
        }
        waitUntilTheWriteAheadLogsAreEmpty()
    }

    /// The safe-mode open of a store whose migration stopped after one
    /// file: the read-only open uses each file's own version, Export reads
    /// the record, the app lock's `Local.store` values read, every write
    /// fails, and neither file changes.
    private func assertSafeModeReadsTheHalfMigratedStore(recordVersion: Schema.Version, file: StaticString = #filePath, line: UInt = #line) throws {
        let before = storeBytes()
        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)

            XCTAssertTrue(store.isReadOnly, file: file, line: line)
            XCTAssertEqual(store.container.schema.version, recordVersion, "Record.store opens at its own version", file: file, line: line)
            let document = try exportOf21September(from: store)
            XCTAssertEqual(document.days.first?.entries.map(\.what), ["Toast and tea"], file: file, line: line)
            XCTAssertEqual(document.weighInLines.count, 1, file: file, line: line)
            XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept", "Local.store opens at its own version", file: file, line: line)
            XCTAssertEqual(try store.collapseChoice(dateKey: "2026-09-21"), .collapsed, file: file, line: line)
            XCTAssertThrowsError(try store.add(time: moment, what: "Soup", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 0, dayStartHour: 5), file: file, line: line)
            XCTAssertThrowsError(try store.setLocalSettingValue("changed", key: "test.value"), file: file, line: line)
            XCTAssertThrowsError(try store.setCollapseChoice(.expanded, dateKey: "2026-09-21"), file: file, line: line)
            XCTAssertThrowsError(try store.incrementLaunchFailureCount(), file: file, line: line)
            XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept", "a write that fails changes nothing", file: file, line: line)
        }
        XCTAssertEqual(storeBytes(), before, "no migration step and no write changes a store file", file: file, line: line)
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

    /// SwiftData migrates the two store files one at a time, and each file
    /// keeps its migration on its own. Here the launch stopped after
    /// `Local.store` migrated, so `Record.store` holds V1 and `Local.store`
    /// holds V2. Safe mode opens each file at its own version, so its Today
    /// shows Export. The next ordinary open migrates `Record.store`.
    func testSafeModeReadsAStoreWhoseMigrationStoppedAfterLocalStore() throws {
        try writeTheV1BuildsRecord()
        try migrateOnlyOneFile("Local.store")
        XCTAssertEqual(fileVersion("Record.store"), RecordSchemaV1.versionIdentifier)
        XCTAssertEqual(fileVersion("Local.store"), TestOnlyRecordSchemaV2.versionIdentifier)
        XCTAssertNil(storedVersion(), "the two files hold different versions")

        try assertSafeModeReadsTheHalfMigratedStore(recordVersion: RecordSchemaV1.versionIdentifier)
        XCTAssertEqual(fileVersion("Record.store"), RecordSchemaV1.versionIdentifier, "the store still needs the migration")

        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
        XCTAssertEqual(storedVersion(), TestOnlyRecordSchemaV2.versionIdentifier, "the ordinary open migrated Record.store")
        XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
    }

    /// The other order: the launch stopped after `Record.store` migrated,
    /// so `Record.store` holds V2 and `Local.store` holds V1.
    func testSafeModeReadsAStoreWhoseMigrationStoppedAfterRecordStore() throws {
        try writeTheV1BuildsRecord()
        try migrateOnlyOneFile("Record.store")
        XCTAssertEqual(fileVersion("Record.store"), TestOnlyRecordSchemaV2.versionIdentifier)
        XCTAssertEqual(fileVersion("Local.store"), RecordSchemaV1.versionIdentifier)

        try assertSafeModeReadsTheHalfMigratedStore(recordVersion: TestOnlyRecordSchemaV2.versionIdentifier)
        XCTAssertEqual(fileVersion("Local.store"), RecordSchemaV1.versionIdentifier, "the store still needs the migration")

        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
        XCTAssertEqual(storedVersion(), TestOnlyRecordSchemaV2.versionIdentifier, "the ordinary open migrated Local.store")
        XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
    }

    /// Scenario "Store at an unknown schema version" for one file: here a
    /// later build migrated only `Record.store`, and this build holds only
    /// V1. The plan holds no version that agrees with `Record.store`, so
    /// the safe-mode open throws and neither file changes.
    func testSafeModeThrowsWhenOneFileIsAtAnUnknownVersion() throws {
        try writeTheV1BuildsRecord()
        try migrateOnlyOneFile("Record.store")
        let before = storeBytes()

        XCTAssertThrowsError(try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: RecordMigrationPlan.self)) { error in
            guard case RecordStore.Failure.noKnownSchemaVersion = error else { return XCTFail("\(error)") }
        }

        XCTAssertEqual(storeBytes(), before)
    }

    /// The launches after an update to the build with V2, as
    /// `AppLockRootView.openStoreAndController` makes them. On launches 1
    /// and 2 the ordinary open runs the migration, and the migration stops
    /// in `Record.store`. Then `Record.store` holds V1, and `Local.store`
    /// holds V1 or V2, because SwiftData chooses the order of the two
    /// files. Neither launch shows Today. The third launch is in safe
    /// mode: its read-only open uses each file's own version, so safe
    /// mode's Today appears with Export and clears the marker. The fourth
    /// launch is ordinary and runs the migration again. Here the stop does
    /// not come back (for example, the system stopped the app), so the
    /// migration ends.
    func testAfterTwoFailedMigrationsSafeModeShowsTodayAndTheNextLaunchMigrates() throws {
        try writeTheV1BuildsRecord()
        for launchNumber in 1...2 {
            let launch = LaunchSession(markerURL: markerURL)
            XCTAssertFalse(launch.begin().launchOutcome.enterSafeMode, "launch \(launchNumber)")
            XCTAssertThrowsError(try autoreleasepool {
                _ = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: TestOnlyMigrationStopsInRecordStorePlan.self)
            }, "launch \(launchNumber) stops in the migration")
        }
        waitUntilTheWriteAheadLogsAreEmpty()
        XCTAssertEqual(fileVersion("Record.store"), RecordSchemaV1.versionIdentifier, "the migration stopped in Record.store")
        XCTAssertNotNil(fileVersion("Local.store"))
        let before = storeBytes()

        let third = LaunchSession(markerURL: markerURL)
        XCTAssertTrue(third.begin().launchOutcome.enterSafeMode)
        try autoreleasepool {
            let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: true, migrationPlan: TestOnlyMigrationStopsInRecordStorePlan.self)
            third.countLaunchFailureIfNeeded(in: store)
            XCTAssertEqual(try exportOf21September(from: store).days.first?.entries.map(\.what), ["Toast and tea"])
            XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
            // Safe mode's Today appears.
            third.clearAfterTodayAppears()
        }
        XCTAssertEqual(storeBytes(), before, "safe mode changes no store file")
        XCTAssertEqual(fileVersion("Record.store"), RecordSchemaV1.versionIdentifier)

        let fourth = LaunchSession(markerURL: markerURL)
        XCTAssertFalse(fourth.begin().launchOutcome.enterSafeMode, "safe mode's Today cleared the marker")
        let store = try RecordStore.openInPreparedDirectory(applicationSupportDirectory: root, readOnly: false, migrationPlan: TestOnlyTwoVersionMigrationPlan.self)
        fourth.countLaunchFailureIfNeeded(in: store)

        XCTAssertEqual(storedVersion(), TestOnlyRecordSchemaV2.versionIdentifier, "the ordinary launch ran the migration")
        XCTAssertEqual(try store.entries(dayKey: "2026-09-21").map(\.what), ["Toast and tea"])
        XCTAssertEqual(try store.localSettingValue(key: "test.value"), "kept")
        // The failure that launch 2 found is lost, because launch 2 stopped
        // in the open before the count: bead mm-t42.30. When that bead is
        // done, this count is exactly 2.
        XCTAssertGreaterThanOrEqual(try store.diagnosticsCounts(contentVersion: 1).launchFailures, 1, "the failure that safe mode kept in the marker")
    }
}
