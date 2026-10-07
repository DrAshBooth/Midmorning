import Foundation
import SwiftData
import CoreData

/// The sixteen neutral model names (data-and-privacy spec, "CKRecord types
/// and model names are neutral"). The schema entity-name test asserts the
/// live schema's entity names equal this set exactly.
public enum RecordSchema {
    public static let neutralModelNames: Set<String> = [
        "Item", "ItemVersion", "DayState", "Template", "Day", "Answer",
        "Measure", "Session", "ListItem", "Sheet", "Review", "Profile",
        "Settings", "Seen", "Place", "Device",
    ]

    /// The sixteen model types that make up `Record.store`'s schema, in the
    /// design's table order.
    public static let models: [any PersistentModel.Type] = [
        Item.self, ItemVersion.self, DayState.self, Template.self, Day.self,
        Answer.self, Measure.self, Session.self, ListItem.self, Sheet.self,
        Review.self, Profile.self, Settings.self, Seen.self, Place.self, Device.self,
    ]

    /// `Local.store`'s one model. Never a CKRecord type, so it carries no
    /// neutral-name obligation.
    public static let localModels: [any PersistentModel.Type] = [LocalSetting.self]
}

/// One schema version of the two store files. Core Data writes the version
/// hash of every model type into the metadata of both `Record.store` and
/// `Local.store`, so `models` holds the types of the two configurations
/// together. A staged migration needs this: it finds the store's version
/// and the container's version in the plan from those hashes, and it
/// throws `NSCocoaErrorDomain` 134504 when no version in the plan holds
/// `LocalSetting`.
public protocol RecordStoreSchemaVersion: VersionedSchema {
    /// The types that `Record.store` holds.
    static var recordModels: [any PersistentModel.Type] { get }
    /// The types that `Local.store` holds.
    static var localModels: [any PersistentModel.Type] { get }
}

extension RecordStoreSchemaVersion {
    public static var models: [any PersistentModel.Type] { recordModels + localModels }
}

/// V1's one schema version (data-and-privacy spec, "The schema is frozen and
/// grows by addition only": "V1 MUST ship one schema version"). A later
/// version adds a case here and a migration stage in `RecordMigrationPlan`;
/// it never renames, deletes or retypes an existing type or field.
public enum RecordSchemaV1: RecordStoreSchemaVersion {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    public static var recordModels: [any PersistentModel.Type] { RecordSchema.models }
    public static var localModels: [any PersistentModel.Type] { RecordSchema.localModels }
}

/// The migration plan every store container opens with. V1 holds one
/// schema and no migration stage. The Diagnostics page shows
/// `RecordSchemaV1.versionIdentifier` as the schema version.
///
/// Each schema version here is a `RecordStoreSchemaVersion`. An ordinary
/// open uses the newest version and this plan, so a store at an earlier
/// version migrates. Safe mode opens each store file read-only at the
/// version that the file's metadata names, with no migration (ruling
/// r15-01, mm-t42.28; `RecordStore.makeContainers`). So from the second
/// version on, the reads that Export uses must also read the model types
/// of each earlier version: safe mode opens a store at an earlier version
/// with that version's own types. Bead mm-7sm holds this work, and
/// `FrozenSchemaTests.testOneSchemaVersionInV1` names it when a second
/// version comes.
public enum RecordMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [RecordSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}

/// The schema version of each of the two store files. SwiftData migrates
/// `Record.store` and `Local.store` one at a time, and each file keeps its
/// migration on its own. So when a launch stops in a migration after the
/// first file, the two files hold different versions until the next
/// ordinary open migrates the second file.
struct StoreFileSchemaVersions {
    /// The version that the metadata of `Record.store` names.
    let record: any RecordStoreSchemaVersion.Type
    /// The version that the metadata of `Local.store` names.
    let local: any RecordStoreSchemaVersion.Type

    /// True when both files hold the same version.
    var areTheSame: Bool { record.versionIdentifier == local.versionIdentifier }
}

extension SchemaMigrationPlan {
    /// The plan's schema versions, oldest first. Every version in a plan
    /// that opens the store is a `RecordStoreSchemaVersion`.
    static var storeSchemaVersions: [any RecordStoreSchemaVersion.Type] {
        schemas.compactMap { $0 as? any RecordStoreSchemaVersion.Type }
    }

    /// The schema version that the metadata of the store file at `url`
    /// names (ruling r15-01, mm-t42.28): the version whose model agrees
    /// with the version hashes in the file's metadata. Reads only the
    /// metadata, so the file does not change. Nil when the file is missing
    /// or no version in the plan agrees, for example a file from a later
    /// build.
    static func storeSchemaVersion(ofFileAt url: URL) -> (any RecordStoreSchemaVersion.Type)? {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: url) else { return nil }
        return storeSchemaVersions.first { version in
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: version.models) else { return false }
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }
    }

    /// The schema version of each store file in `directory`. Nil when a
    /// file is missing or the plan holds no version that agrees with the
    /// metadata of a file.
    static func storeFileSchemaVersions(in directory: URL) -> StoreFileSchemaVersions? {
        let urls = RecordStore.storeFileNames.map { directory.appendingPathComponent($0) }
        guard let record = storeSchemaVersion(ofFileAt: urls[0]), let local = storeSchemaVersion(ofFileAt: urls[1]) else { return nil }
        return StoreFileSchemaVersions(record: record, local: local)
    }

    /// The one schema version that both store files in `directory` hold.
    /// Nil when a file is missing, when the plan holds no version that
    /// agrees with the metadata of a file, or when the two files hold
    /// different versions.
    static func storeSchemaVersion(ofFilesIn directory: URL) -> (any RecordStoreSchemaVersion.Type)? {
        guard let versions = storeFileSchemaVersions(in: directory), versions.areTheSame else { return nil }
        return versions.record
    }
}
