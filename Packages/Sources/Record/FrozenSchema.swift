import Foundation
import SwiftData

/// Freezes the CKRecord type names and every field name (data-and-privacy
/// spec, "The schema is frozen and grows by addition only"). The frozen file
/// lives at `FrozenSchema.json`, beside this file. A later change adds only
/// an optional field with a default, or a new record type, and updates the
/// file in the same commit. It never renames, deletes or retypes a type or a
/// field.
public enum FrozenSchema {
    /// The live schema's entity names, each with its own property names,
    /// read from `RecordSchema.models` through SwiftData's `Schema`.
    public static func currentFields() -> [String: Set<String>] {
        var fields: [String: Set<String>] = [:]
        for entity in Schema(RecordSchema.models).entities {
            fields[entity.name] = Set(entity.properties.map(\.name))
        }
        return fields
    }

    /// The frozen file's own directory, resolved from this source file's
    /// path so the test finds it under `swift test` on any machine
    /// (design.md, "Pure seams the packages expose": "the repository root
    /// from `#filePath`").
    public static var fileURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("FrozenSchema.json")
    }

    /// Reads the frozen file at `url`: entity name to its frozen field names.
    public static func load(from url: URL = fileURL) throws -> [String: Set<String>] {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([String: [String]].self, from: data)
        return decoded.mapValues(Set.init)
    }

    /// The entity names where `current` and `frozen` disagree: a field is
    /// missing from `current` (a rename or a delete — MUST NOT happen), a
    /// field is missing from `frozen` (an addition not yet recorded there),
    /// or a whole entity is missing on either side.
    public static func violations(current: [String: Set<String>], frozen: [String: Set<String>]) -> [String] {
        var names = Set(current.keys).union(frozen.keys)
        names = names.filter { current[$0] != frozen[$0] }
        return names.sorted()
    }
}
