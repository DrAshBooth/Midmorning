import Foundation
import SwiftData

/// Freezes the CKRecord type names, every field name, and each field's
/// value type and optionality (data-and-privacy spec, "The schema is frozen
/// and grows by addition only"). The frozen file lives at
/// `FrozenSchema.json`, beside this file: record type to field name to
/// type, for example `"weightKg": "Double"`, with a `?` after an optional
/// type (`"setAt": "Date?"`). A later change adds only an optional field
/// with a default, or a new record type, and updates the file in the same
/// commit. It never renames, deletes or retypes a type or a field, and it
/// never changes a field's optionality.
public enum FrozenSchema {
    /// Record type name to field name to frozen type.
    public typealias Fields = [String: [String: String]]

    /// The live schema's entity names, each with its own properties and
    /// their types, read from `RecordSchema.models` through SwiftData's
    /// `Schema`.
    public static func currentFields() -> Fields {
        var fields: Fields = [:]
        for entity in Schema(RecordSchema.models).entities {
            var types: [String: String] = [:]
            for property in entity.properties {
                types[property.name] = typeName(valueType: property.valueType, isOptional: property.isOptional)
            }
            fields[entity.name] = types
        }
        return fields
    }

    /// "Double", or "Date?" for an optional field. SwiftData reports an
    /// optional attribute's value type as `Optional<Date>`; the frozen file
    /// holds the wrapped type with a `?`.
    static func typeName(valueType: Any.Type, isOptional: Bool) -> String {
        var name = String(describing: valueType)
        if name.hasPrefix("Optional<"), name.hasSuffix(">") {
            name = String(name.dropFirst("Optional<".count).dropLast())
        }
        return isOptional ? name + "?" : name
    }

    /// The frozen file's own directory, resolved from this source file's
    /// path so the test finds it under `swift test` on any machine
    /// (design.md, "Pure seams the packages expose": "the repository root
    /// from `#filePath`").
    public static var fileURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("FrozenSchema.json")
    }

    /// Reads the frozen file at `url`.
    public static func load(from url: URL = fileURL) throws -> Fields {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Fields.self, from: data)
    }

    /// One line for each disagreement between `current` and `frozen`, each
    /// naming the record type and, when there is one, the field: a field
    /// missing from `current` (a rename or a delete, which MUST NOT
    /// happen), a field missing from `frozen` (an addition not yet written
    /// to the file), a field whose type or optionality changed, or a whole
    /// record type missing on either side. Empty when they agree.
    public static func violations(current: Fields, frozen: Fields) -> [String] {
        var lines: [String] = []
        for name in Set(current.keys).union(frozen.keys) {
            guard let live = current[name] else {
                lines.append("\(name): record type missing from the schema")
                continue
            }
            guard let kept = frozen[name] else {
                lines.append("\(name): record type not in the frozen file")
                continue
            }
            for field in Set(live.keys).union(kept.keys) {
                switch (live[field], kept[field]) {
                case (nil, _?):
                    lines.append("\(name).\(field): field missing from the schema (a rename or a delete)")
                case (let type?, nil):
                    lines.append("\(name).\(field): field \(type) not in the frozen file")
                case (let type?, let frozenType?) where type != frozenType:
                    lines.append("\(name).\(field): type \(type), frozen as \(frozenType)")
                default:
                    break
                }
            }
        }
        return lines.sorted()
    }
}
