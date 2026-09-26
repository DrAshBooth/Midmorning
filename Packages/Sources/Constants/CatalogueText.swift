import Foundation

/// Text the person reads, held as keys in the app's string catalogue
/// (`App/Midmorning/Localizable.xcstrings`), never as English in code
/// (content spec, "Strings live in catalogues"). A package function
/// returns this value; the App target fills it from the catalogue, and a
/// test on macOS fills it with `StringCatalogue`.
public indirect enum CatalogueText: Sendable, Equatable {
    /// A catalogue key and the values for its placeholders, in order.
    case entry(key: String, arguments: [CatalogueText])
    /// Text that is not catalogue text: the person's own words, a label
    /// they chose, or a time or a duration from a formatter.
    case verbatim(String)
    /// A count for a `%lld` placeholder. The key's plural forms pick the
    /// words.
    case count(Int)
    /// Parts that VoiceOver reads as one label, joined by ", ".
    case list([CatalogueText])

    /// The catalogue entry `key`, filled with `arguments`.
    public static func key(_ key: String, _ arguments: CatalogueText...) -> CatalogueText {
        .entry(key: key, arguments: arguments)
    }

    /// The separator between the parts of a `list`.
    public static let listSeparator = ", "
}
