import Foundation
import SwiftData

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

/// V1's one schema version (data-and-privacy spec, "The schema is frozen and
/// grows by addition only": "V1 MUST ship one schema version"). A later
/// version adds a case here and a migration stage in `RecordMigrationPlan`;
/// it never renames, deletes or retypes an existing type or field.
public enum RecordSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    public static var models: [any PersistentModel.Type] { RecordSchema.models }
}

/// The migration plan every `Record.store` container opens with. V1 holds
/// one schema and no migration stage. The Diagnostics page shows
/// `RecordSchemaV1.versionIdentifier` as the schema version.
public enum RecordMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [RecordSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}
