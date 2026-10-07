import Foundation
import SwiftData

/// The one path to open the store on the device (data-and-privacy spec,
/// "File protection", "The app excludes the whole store directory from
/// backups"). SwiftData creates a missing directory with no backup
/// exclusion, so the app never lets it create the directory: it prepares
/// the directory first, on every open.
extension StoreLayout {
    /// Creates `Application Support/Record` when it does not exist yet, with
    /// `NSFileProtectionComplete`. Then sets `NSFileProtectionComplete` and
    /// backup exclusion on the directory again. The app calls this before
    /// each store open, so a directory from an earlier build that has no
    /// backup exclusion gets it at the next open. Returns the directory.
    public static func prepareStoreDirectory(applicationSupportDirectory: URL, fileManager: FileManager = .default) throws -> URL {
        let directory = storeDirectory(applicationSupportDirectory: applicationSupportDirectory)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtection.protectionClass(for: .databaseFile)]
        )
        try FileProtection.protectStoreDirectory(directory, fileManager: fileManager)
        return directory
    }
}

extension RecordStore {
    /// Prepares the store directory, then opens `Record.store` and
    /// `Local.store` in it. The App target opens the store only through
    /// this call, so every open on the device sets backup exclusion first.
    /// `readOnly` is true only in safe mode, which the launch marker
    /// chooses before this call (ruling r13-05, mm-t42.23).
    public static func openInPreparedDirectory(applicationSupportDirectory: URL, readOnly: Bool = false, fileManager: FileManager = .default) throws -> RecordStore {
        try openInPreparedDirectory(applicationSupportDirectory: applicationSupportDirectory, readOnly: readOnly, migrationPlan: RecordMigrationPlan.self, fileManager: fileManager)
    }

    /// The same open with a given migration plan, for a test that adds a
    /// test-only schema version.
    static func openInPreparedDirectory(applicationSupportDirectory: URL, readOnly: Bool, migrationPlan: any SchemaMigrationPlan.Type, fileManager: FileManager = .default) throws -> RecordStore {
        let directory = try StoreLayout.prepareStoreDirectory(applicationSupportDirectory: applicationSupportDirectory, fileManager: fileManager)
        return try RecordStore(directory: directory, readOnly: readOnly, migrationPlan: migrationPlan)
    }

    /// The container on the two store files in `directory`.
    ///
    /// An ordinary open uses the newest schema version in `migrationPlan`
    /// and the plan itself, so a store at an earlier version migrates.
    ///
    /// Safe mode's read-only open (ruling r15-01, mm-t42.28) uses the
    /// schema version that the metadata of the store files names, and no
    /// migration plan. SwiftData migrates in place, so a read-only open at
    /// a newer version than the store holds throws `NSCocoaErrorDomain`
    /// 134110 and Export is not available. At the store's own version no
    /// migration step runs, no file changes, and Export reads the record.
    /// The next ordinary open runs the migration. A read-only open throws
    /// `Failure.noKnownSchemaVersion` when no version agrees with the
    /// metadata, or when a store file is missing, so safe mode never makes
    /// a store.
    static func makeContainer(directory: URL, readOnly: Bool, migrationPlan: any SchemaMigrationPlan.Type) throws -> ModelContainer {
        let version: any RecordStoreSchemaVersion.Type
        if readOnly {
            guard let stored = migrationPlan.storeSchemaVersion(ofFilesIn: directory) else { throw Failure.noKnownSchemaVersion }
            version = stored
        } else {
            guard let newest = migrationPlan.storeSchemaVersions.last else { throw Failure.noKnownSchemaVersion }
            version = newest
        }
        let recordConfiguration = ModelConfiguration(
            "Record",
            schema: Schema(version.recordModels),
            url: directory.appendingPathComponent(storeFileNames[0]),
            allowsSave: !readOnly,
            cloudKitDatabase: .none
        )
        let localConfiguration = ModelConfiguration(
            "Local",
            schema: Schema(version.localModels),
            url: directory.appendingPathComponent(storeFileNames[1]),
            allowsSave: !readOnly,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: Schema(versionedSchema: version),
            migrationPlan: readOnly ? nil : migrationPlan,
            configurations: recordConfiguration, localConfiguration
        )
    }
}

/// The real names of the two side files in the App Group container
/// (widgets-and-intents spec, "The action queue"; data-and-privacy spec,
/// "Delete-all"). The writer, Delete-all and the backup exclusion all get
/// the path from here, so a name can never differ between them.
extension AppGroupContent {
    public static let actionQueueFileName = "queue.json"
    public static let snapshotFileName = "snapshot.json"

    public static func actionQueueURL(inAppGroupDirectory directory: URL) -> URL {
        directory.appendingPathComponent(actionQueueFileName, isDirectory: false)
    }

    public static func snapshotURL(inAppGroupDirectory directory: URL) -> URL {
        directory.appendingPathComponent(snapshotFileName, isDirectory: false)
    }
}
