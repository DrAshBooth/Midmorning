import Foundation

/// Reads an Xcode String Catalog (`.xcstrings`), the "string catalogue" the
/// content spec names beside the content bundle. The literal lint accepts a
/// literal that is a key in this file, the same as a content bundle id. The
/// bundle hash covers the en-GB entries of the signed keys
/// (`SignedCatalogueKeys`, ruling r13-01).
public enum XCStringsCatalogue {
    /// One key's en-GB entry: a plain value, or plural forms ("zero", "one",
    /// "other"), or both when the file holds both.
    public struct Entry: Sendable, Equatable {
        public let value: String?
        public let plural: [String: String]

        public init(value: String?, plural: [String: String] = [:]) {
            self.value = value
            self.plural = plural
        }

        /// Every text the app can show from this entry: the value and each
        /// plural form.
        public var texts: [String] {
            (value.map { [$0] } ?? []) + plural.keys.sorted().compactMap { plural[$0] }
        }
    }

    /// `id -> English (en-GB) text`, read from `strings.<id>.localizations.
    /// en-GB.stringUnit.value`, or for a plural entry from its "other" form
    /// (`variations.plural.other.stringUnit.value`). A key with no `en-GB`
    /// value still counts as present, with an empty string.
    public static func read(from url: URL) throws -> [String: String] {
        try readEntries(from: url).mapValues { $0.value ?? $0.plural["other"] ?? "" }
    }

    /// `id -> en-GB entry`, with every plural form the file holds.
    public static func readEntries(from url: URL) throws -> [String: Entry] {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any] ?? [:]
        var result: [String: Entry] = [:]
        for (key, value) in strings {
            let entry = value as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any]
            let enGB = localizations?["en-GB"] as? [String: Any]
            let unit = enGB?["stringUnit"] as? [String: Any]
            let forms = (enGB?["variations"] as? [String: Any])?["plural"] as? [String: Any] ?? [:]
            var plural: [String: String] = [:]
            for (form, raw) in forms {
                if let text = ((raw as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String {
                    plural[form] = text
                }
            }
            result[key] = Entry(value: unit?["value"] as? String, plural: plural)
        }
        return result
    }
}
