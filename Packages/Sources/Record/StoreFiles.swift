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

    /// The containers that read the two store files. `local` is nil when
    /// `record` reads both files, which is every open except one case in
    /// safe mode.
    struct StoreContainers {
        /// Reads `Record.store`. It also reads `Local.store` when `local`
        /// is nil.
        let record: ModelContainer
        /// Reads `Local.store` in safe mode when the two files hold
        /// different schema versions.
        let local: ModelContainer?
    }

    /// The containers on the two store files in `directory`.
    ///
    /// An ordinary open uses the newest schema version in `migrationPlan`
    /// and the plan itself, so a store at an earlier version migrates. One
    /// container reads both files.
    ///
    /// Safe mode's read-only open (ruling r15-01, mm-t42.28) uses the
    /// schema version that the metadata of the store files names, and no
    /// migration plan. SwiftData migrates in place, so a read-only open at
    /// a newer version than the store holds throws `NSCocoaErrorDomain`
    /// 134110 and Export is not available. At the store's own version no
    /// migration step runs, no file changes, and Export reads the record.
    /// The next ordinary open runs the migration.
    ///
    /// SwiftData migrates the two files one at a time, so a launch that
    /// stops in a migration can leave one file at the newer version and
    /// the other at the earlier version. Then safe mode opens each file at
    /// its own version, in a container of its own: Core Data finds a
    /// store's version from the hashes of all the types of both files, so
    /// one container cannot read two files at two versions. Each of the
    /// two containers holds its file's version with the other
    /// configuration in memory, so it reads nothing from the other file.
    ///
    /// A read-only open throws `Failure.noKnownSchemaVersion` when no
    /// version in the plan agrees with the metadata of a file, or when a
    /// store file is missing, so safe mode never makes a store.
    static func makeContainers(directory: URL, readOnly: Bool, migrationPlan: any SchemaMigrationPlan.Type) throws -> StoreContainers {
        let recordURL = directory.appendingPathComponent(storeFileNames[0])
        let localURL = directory.appendingPathComponent(storeFileNames[1])
        guard readOnly else {
            guard let newest = migrationPlan.storeSchemaVersions.last else { throw Failure.noKnownSchemaVersion }
            return StoreContainers(
                record: try makeContainer(version: newest, recordURL: recordURL, localURL: localURL, readOnly: false, migrationPlan: migrationPlan),
                local: nil
            )
        }
        guard let versions = migrationPlan.storeFileSchemaVersions(in: directory) else { throw Failure.noKnownSchemaVersion }
        if versions.areTheSame {
            return StoreContainers(
                record: try makeContainer(version: versions.record, recordURL: recordURL, localURL: localURL, readOnly: true, migrationPlan: nil),
                local: nil
            )
        }
        return StoreContainers(
            record: try makeContainer(version: versions.record, recordURL: recordURL, localURL: nil, readOnly: true, migrationPlan: nil),
            local: try makeContainer(version: versions.local, recordURL: nil, localURL: localURL, readOnly: true, migrationPlan: nil)
        )
    }

    /// One container at `version` with the two configurations. A
    /// configuration with no URL is in memory: it holds no row and is not
    /// a file. It allows saves, because SwiftData cannot open an in-memory
    /// store read-only. `RecordStore` writes no row to it: it writes
    /// `Record.store`'s types through the container that reads
    /// `Record.store`, and `LocalSetting` through the container that reads
    /// `Local.store`.
    private static func makeContainer(
        version: any RecordStoreSchemaVersion.Type, recordURL: URL?, localURL: URL?,
        readOnly: Bool, migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws -> ModelContainer {
        func configuration(_ name: String, models: [any PersistentModel.Type], url: URL?) -> ModelConfiguration {
            guard let url else {
                return ModelConfiguration(name, schema: Schema(models), isStoredInMemoryOnly: true, allowsSave: true, cloudKitDatabase: .none)
            }
            return ModelConfiguration(name, schema: Schema(models), url: url, allowsSave: !readOnly, cloudKitDatabase: .none)
        }
        return try ModelContainer(
            for: Schema(versionedSchema: version),
            migrationPlan: migrationPlan,
            configurations: configuration("Record", models: version.recordModels, url: recordURL),
            configuration("Local", models: version.localModels, url: localURL)
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
