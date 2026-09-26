import Foundation

/// Reads an Xcode String Catalog (`.xcstrings`), the "string catalogue" the
/// content spec names beside the content bundle for plain interface chrome
/// that carries no clinical review, for example "Cancel" and "Save". The
/// literal lint accepts a literal that is a key in this file, the same as
/// a content bundle id.
public enum XCStringsCatalogue {
    /// `id -> English (en-GB) text`, read from `strings.<id>.localizations.
    /// en-GB.stringUnit.value`, or for a plural entry from its "other" form
    /// (`variations.plural.other.stringUnit.value`). A key with no `en-GB`
    /// value still counts as present, with an empty string.
    public static func read(from url: URL) throws -> [String: String] {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any] ?? [:]
        var result: [String: String] = [:]
        for (key, value) in strings {
            let entry = value as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any]
            let enGB = localizations?["en-GB"] as? [String: Any]
            let unit = enGB?["stringUnit"] as? [String: Any]
            let plural = (enGB?["variations"] as? [String: Any])?["plural"] as? [String: Any]
            let other = (plural?["other"] as? [String: Any])?["stringUnit"] as? [String: Any]
            result[key] = (unit?["value"] as? String) ?? (other?["value"] as? String) ?? ""
        }
        return result
    }
}
