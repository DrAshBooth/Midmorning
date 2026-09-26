import Foundation

/// `Packages/Content/Resources/signed-catalogue-keys.json`: the key prefixes
/// of `Localizable.xcstrings` whose text goes under the content hash, the
/// content version rise and the clinical sign-off (ruling r13-01). These are
/// the families that hold record, safeguarding and reminder text. A key
/// that no prefix matches is interface chrome, and a change to it needs no
/// content version rise.
///
/// The bundle hash, `scripts/content-lock` and `scripts/content-signoff-list`
/// read this one file. To put a family under the sign-off, add its prefix
/// here and run `scripts/content-lock`.
public struct SignedCatalogueKeys: Sendable, Equatable, Codable {
    /// The prefixes, grouped by the family they belong to: "record",
    /// "reminders" and "safeguarding".
    public let prefixes: [String: [String]]

    public init(prefixes: [String: [String]]) {
        self.prefixes = prefixes
    }

    public static let fileName = "signed-catalogue-keys.json"

    /// Every prefix, in sorted order.
    public var allPrefixes: [String] {
        prefixes.values.flatMap { $0 }.sorted()
    }

    /// `true` when `key` starts with a signed prefix.
    public func isSigned(_ key: String) -> Bool {
        allPrefixes.contains { key.hasPrefix($0) }
    }

    /// The keys in `keys` that have the segment `segment` and that no prefix
    /// matches, sorted. A segment is a part of the key that full stops
    /// separate, before the first space. A key that holds reminder text has
    /// the segment "reminders" (content spec, "Content versions"), so each
    /// key with that segment must be signed.
    public func unsignedKeys(withSegment segment: String, in keys: some Sequence<String>) -> [String] {
        keys.filter { key in
            let name = key.split(separator: " ", maxSplits: 1).first ?? ""
            return name.split(separator: ".").contains { $0 == segment } && !isSigned(key)
        }.sorted()
    }

    /// The entries of `catalogue` whose key is signed.
    public func signedEntries(of catalogue: [String: XCStringsCatalogue.Entry]) -> [String: XCStringsCatalogue.Entry] {
        catalogue.filter { isSigned($0.key) }
    }

    public static func read(from directory: URL) throws -> SignedCatalogueKeys {
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else {
            throw BundleLoaderError.fileNotFound(fileName)
        }
        return try JSONDecoder().decode(SignedCatalogueKeys.self, from: data)
    }
}
