import Foundation

/// The en-GB entries of an Xcode string catalogue (`.xcstrings`), read from
/// its JSON, and a renderer for `CatalogueText` over them. The App target
/// does not use this type: it reads the compiled catalogue through
/// Foundation. A test on macOS uses it to check the words the person reads,
/// from the same catalogue file the app ships.
public struct StringCatalogue: Sendable {
    public enum Failure: Error, Equatable {
        case missingKey(String)
        case missingArgument(key: String, position: Int)
    }

    /// One entry: a plain value, or plural forms ("zero", "one", "other").
    public struct Entry: Sendable, Equatable {
        public let value: String?
        public let plural: [String: String]
    }

    public let entries: [String: Entry]

    public init(contentsOf url: URL) throws {
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
        let strings = json["strings"] as? [String: Any] ?? [:]
        var entries: [String: Entry] = [:]
        for (key, raw) in strings {
            let enGB = ((raw as? [String: Any])?["localizations"] as? [String: Any])?["en-GB"] as? [String: Any]
            let value = (enGB?["stringUnit"] as? [String: Any])?["value"] as? String
            let forms = ((enGB?["variations"] as? [String: Any])?["plural"] as? [String: Any]) ?? [:]
            var plural: [String: String] = [:]
            for (form, unit) in forms {
                if let text = ((unit as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String {
                    plural[form] = text
                }
            }
            entries[key] = Entry(value: value, plural: plural)
        }
        self.entries = entries
    }

    /// The app's own catalogue in this repository, found from this file's
    /// path. For a test on macOS only.
    public static func appCatalogue(filePath: String = #filePath) throws -> StringCatalogue {
        let root = URL(fileURLWithPath: filePath)
            .deletingLastPathComponent() // Constants
            .deletingLastPathComponent() // Sources
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // repository root
        return try StringCatalogue(contentsOf: root.appendingPathComponent("App/Midmorning/Localizable.xcstrings"))
    }

    /// `text` in English, filled the way the app fills it: a plural entry
    /// takes the form for its first count ("zero" only when the entry has
    /// one), and each `%@`, `%lld` or positional `%1$@` takes its argument.
    public func render(_ text: CatalogueText) throws -> String {
        switch text {
        case .verbatim(let value):
            return value
        case .count(let count):
            return String(count)
        case .list(let parts):
            return try parts.map(render).joined(separator: CatalogueText.listSeparator)
        case .entry(let key, let arguments):
            guard let entry = entries[key] else { throw Failure.missingKey(key) }
            let format = try Self.form(of: entry, key: key, arguments: arguments)
            return try fill(format, key: key, arguments: arguments.map(render))
        }
    }

    private static func form(of entry: Entry, key: String, arguments: [CatalogueText]) throws -> String {
        guard !entry.plural.isEmpty else {
            guard let value = entry.value else { throw Failure.missingKey(key) }
            return value
        }
        let count = arguments.lazy.compactMap { argument -> Int? in
            if case .count(let count) = argument { return count }
            return nil
        }.first ?? 0
        if count == 0, let zero = entry.plural["zero"] { return zero }
        if count == 1, let one = entry.plural["one"] { return one }
        guard let other = entry.plural["other"] else { throw Failure.missingKey(key) }
        return other
    }

    private func fill(_ format: String, key: String, arguments: [String]) throws -> String {
        var result = ""
        var next = 0
        var chars = Substring(format)
        while let percent = chars.firstIndex(of: "%") {
            result += chars[chars.startIndex..<percent]
            var rest = chars[chars.index(after: percent)...]
            if rest.first == "%" {
                result += "%"
                chars = rest.dropFirst()
                continue
            }
            var position: Int?
            let digits = rest.prefix { $0.isNumber }
            if !digits.isEmpty, rest.dropFirst(digits.count).first == "$" {
                position = Int(digits)
                rest = rest.dropFirst(digits.count + 1)
            }
            // The conversion: "@", "d", "lld" or "ld".
            let conversion = rest.prefix { $0 == "l" }.count + 1
            rest = rest.dropFirst(conversion)
            let index = (position ?? (next + 1)) - 1
            if position == nil { next += 1 }
            guard arguments.indices.contains(index) else { throw Failure.missingArgument(key: key, position: index + 1) }
            result += arguments[index]
            chars = rest
        }
        return result + chars
    }
}
