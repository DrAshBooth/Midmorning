import Foundation

/// The on-disk shape of one card in `Resources/cards.json`. `section` is
/// "stage1".."stage7" or "module.dieting" / "module.body".
struct CardFile: Codable {
    let id: String
    let section: String
    let title: String
    let body: String
    let oneThing: String
    let links: [String]
    let retired: Bool

    init(id: String, section: String, title: String, body: String, oneThing: String, links: [String] = [], retired: Bool = false) {
        self.id = id; self.section = section; self.title = title
        self.body = body; self.oneThing = oneThing; self.links = links; self.retired = retired
    }
}

/// The on-disk shape of one string family entry in `Resources/strings.json`.
struct StringEntryFile: Codable {
    let id: String
    let text: String
    let plural: PluralForms?

    init(id: String, text: String, plural: PluralForms? = nil) {
        self.id = id; self.text = text; self.plural = plural
    }
}

/// `Resources/manifest.json`: the bundle's declared content version.
struct ManifestFile: Codable {
    let contentVersion: Int
}

public enum BundleLoaderError: Error, CustomStringConvertible {
    case invalidSection(String)
    case fileNotFound(String)

    public var description: String {
        switch self {
        case .invalidSection(let s): return "invalid card section \"\(s)\""
        case .fileNotFound(let name): return "missing content resource \(name)"
        }
    }
}

/// Reads the content bundle from `Resources/*.json`. The app calls
/// `loadShipped()`, which reads the package's bundled copy through
/// `Bundle.module`. The content test and `scripts/content-lock` call
/// `load(from:)` directly against the source `Resources` directory, so a
/// change to a JSON file is visible before the next build copies it.
public enum BundleLoader {
    public static func parseSection(_ raw: String) throws -> Card.Section {
        if raw.hasPrefix("stage"), let n = Int(raw.dropFirst("stage".count)) {
            return .stage(n)
        }
        if raw == "module.dieting" { return .module(.dieting) }
        if raw == "module.body" { return .module(.body) }
        throw BundleLoaderError.invalidSection(raw)
    }

    static func sectionKey(_ section: Card.Section) -> String {
        switch section {
        case .stage(let n): return "stage\(n)"
        case .module(let m): return "module.\(m.rawValue)"
        }
    }

    /// Reads the bundle from a `Resources` directory on disk (source, not
    /// the built resource bundle). `environment` is the process environment
    /// the sign-off check reads `MIDMORNING_RELEASE` from.
    public static func load(from directory: URL, environment: [String: String] = ProcessInfo.processInfo.environment) throws -> ContentBundle {
        let decoder = JSONDecoder()

        let manifestURL = directory.appendingPathComponent("manifest.json")
        guard let manifestData = try? Data(contentsOf: manifestURL) else {
            throw BundleLoaderError.fileNotFound("manifest.json")
        }
        let manifest = try decoder.decode(ManifestFile.self, from: manifestData)

        let cardsURL = directory.appendingPathComponent("cards.json")
        guard let cardsData = try? Data(contentsOf: cardsURL) else {
            throw BundleLoaderError.fileNotFound("cards.json")
        }
        let cardFiles = try decoder.decode([CardFile].self, from: cardsData)
        let cards = try cardFiles.map { file -> Card in
            Card(
                id: file.id,
                section: try parseSection(file.section),
                title: file.title,
                body: file.body,
                oneThing: file.oneThing,
                links: file.links.map { CardLink(target: $0) },
                retired: file.retired
            )
        }

        let stringsURL = directory.appendingPathComponent("strings.json")
        guard let stringsData = try? Data(contentsOf: stringsURL) else {
            throw BundleLoaderError.fileNotFound("strings.json")
        }
        let stringFiles = try decoder.decode([StringEntryFile].self, from: stringsData)
        let strings = stringFiles.map { StringEntry(id: $0.id, text: $0.text, plural: $0.plural) }

        var bundle = ContentBundle(contentVersion: manifest.contentVersion, cards: cards, strings: strings, isDraft: true)
        let signOff = SignOff.matching(bundle: bundle, in: directory)
        bundle.isDraft = (signOff == nil)
        return bundle
    }

    /// Reads the bundle from the package's own resource bundle
    /// (`Bundle.module`), the path a real, installed app uses. Unlike
    /// `load(from:)` against `RepositoryRoot`, this needs no source checkout
    /// on disk, so it works inside a sandboxed app on a device. Finds
    /// `manifest.json` through `Bundle.module` rather than assuming a
    /// `Resources` subdirectory exists inside the bundle: `swift build`'s
    /// macOS bundle nests it under `Contents/Resources`, while Xcode's own
    /// build of the iOS app flattens every resource to the bundle's root;
    /// this works under both.
    public static func loadShipped(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> ContentBundle {
        guard let manifestURL = Bundle.module.url(forResource: "manifest", withExtension: "json") else {
            throw BundleLoaderError.fileNotFound("manifest.json")
        }
        return try load(from: manifestURL.deletingLastPathComponent(), environment: environment)
    }
}
