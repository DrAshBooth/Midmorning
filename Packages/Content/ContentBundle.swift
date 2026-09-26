import Foundation

/// The content bundle: every card and every reviewed string family, with
/// the content version. "Content is data with a version and a sign-off
/// file" (design.md). The app reads it from the package's bundled
/// resources; nothing here is generated at runtime.
public struct ContentBundle: Sendable, Equatable {
    public let contentVersion: Int
    public let cards: [Card]
    public let strings: [StringEntry]
    /// The en-GB entries of the signed keys of `Localizable.xcstrings`
    /// (`SignedCatalogueKeys`, ruling r13-01). The bundle hash covers them.
    /// The content test and the tools read them from the repository; the
    /// app on a device has no copy of the catalogue file, so there this is
    /// empty and the sign-off check reads the lock (`BundleLoader.
    /// loadShipped`).
    public let signedCatalogue: [String: XCStringsCatalogue.Entry]
    public var isDraft: Bool
    /// The language of every card and string in this bundle (content spec,
    /// "Strings live in catalogues": "The content bundle MUST be per
    /// language. V1 MUST ship en-GB only."). A card view keeps it.
    public let language: String

    /// The base language, and the one language V1 ships.
    public static let baseLanguage = "en-GB"

    public init(
        contentVersion: Int,
        cards: [Card],
        strings: [StringEntry],
        signedCatalogue: [String: XCStringsCatalogue.Entry] = [:],
        isDraft: Bool = true,
        language: String = ContentBundle.baseLanguage
    ) {
        self.contentVersion = contentVersion
        self.cards = cards
        self.strings = strings
        self.signedCatalogue = signedCatalogue
        self.isDraft = isDraft
        self.language = language
    }

    /// Reads the bundle from a `Resources` directory on disk. `design.md`
    /// names this the package's pure seam; `BundleLoader` holds the parsing.
    /// With `catalogue`, the bundle also holds the signed keys of that
    /// string catalogue, and its hash covers them.
    public static func load(from directory: URL, catalogue: URL? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) throws -> ContentBundle {
        try BundleLoader.load(from: directory, catalogue: catalogue, environment: environment)
    }

    /// Every id the clinical reviewer signs off, sorted: the cards, the
    /// bundle strings and the signed catalogue keys.
    public var signOffIds: [String] {
        (cards.map(\.id) + strings.map(\.id) + signedCatalogue.keys).sorted()
    }

    public func card(id: String) -> Card? {
        cards.first { $0.id == id }
    }

    public func string(id: String) -> StringEntry? {
        strings.first { $0.id == id }
    }

    /// The non-retired cards for a stage, in bundle order. Stage 6 splits
    /// into its two modules; pass `.module(.dieting)` or `.module(.body)`
    /// for those.
    public func activeCards(in section: Card.Section) -> [Card] {
        cards.filter { $0.section == section && !$0.retired }
    }

    /// Every card, including retired ones, for a section. The three-to-
    /// five-card count and the shipped-id check both read this, because a
    /// retired card stays in the bundle.
    public func allCards(in section: Card.Section) -> [Card] {
        cards.filter { $0.section == section }
    }

    // MARK: - Canonical JSON and the bundle hash

    /// The canonical JSON of the bundle and the signed keys of the string
    /// catalogue, sorted keys, no whitespace, UTF-8, as the "Content
    /// versions" requirement states (ruling r13-01).
    public var canonicalJSON: JSONValue {
        var cardsObject: [String: JSONValue] = [:]
        for card in cards {
            cardsObject[card.id] = .object([
                "section": .string(sectionKey(card.section)),
                "title": .string(card.title),
                "body": .string(card.body),
                "oneThing": .string(card.oneThing),
                "links": .array(card.links.map { .string($0.target) }),
                "retired": .bool(card.retired),
            ])
        }
        var stringsObject: [String: JSONValue] = [:]
        for entry in strings {
            var fields: [String: JSONValue] = ["text": .string(entry.text)]
            if let plural = entry.plural {
                fields["plural"] = .object([
                    "zero": .string(plural.zero),
                    "one": .string(plural.one),
                    "other": .string(plural.other),
                ])
            }
            stringsObject[entry.id] = .object(fields)
        }
        var catalogueObject: [String: JSONValue] = [:]
        for (key, entry) in signedCatalogue {
            var fields: [String: JSONValue] = [:]
            if let value = entry.value { fields["value"] = .string(value) }
            if !entry.plural.isEmpty { fields["plural"] = .object(entry.plural.mapValues(JSONValue.string)) }
            catalogueObject[key] = .object(fields)
        }
        return .object([
            "contentVersion": .int(contentVersion),
            "cards": .object(cardsObject),
            "strings": .object(stringsObject),
            "catalogue": .object(catalogueObject),
        ])
    }

    /// The SHA-256 of `canonicalJSON`.
    public var bundleHash: String {
        CanonicalJSON.sha256Hex(of: canonicalJSON)
    }

    private func sectionKey(_ section: Card.Section) -> String {
        switch section {
        case .stage(let n): return "stage\(n)"
        case .module(let m): return "module.\(m.rawValue)"
        }
    }
}
