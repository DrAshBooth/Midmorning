import Foundation

/// The full set of catalogue keys a literal in `App/**/*.swift` can name:
/// every key in the app's `Localizable.xcstrings`, plus every card and
/// string-family id in the shipped content bundle. "Strings live in
/// catalogues" treats both as "a string catalogue or the content bundle".
public enum AppCatalogueKeys {
    public static func load(
        xcstringsURL: URL = RepositoryRoot.appDirectory.appendingPathComponent("Midmorning/Localizable.xcstrings"),
        contentDirectory: URL = RepositoryRoot.contentResourcesDirectory
    ) throws -> Set<String> {
        var keys = Set(try XCStringsCatalogue.read(from: xcstringsURL).keys)
        let bundle = try ContentBundle.load(from: contentDirectory, environment: [:])
        keys.formUnion(bundle.cards.map(\.id))
        keys.formUnion(bundle.strings.map(\.id))
        return keys
    }
}
