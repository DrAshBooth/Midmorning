import Foundation
import Constants

/// Fills a package's `CatalogueText` from the app's own string catalogue
/// (content spec, "Strings live in catalogues"). A plural entry takes its
/// form from the count through Foundation, the same as `String(localized:)`.
extension CatalogueText {
    var string: String {
        switch self {
        case .verbatim(let value):
            return value
        case .count(let count):
            return String(count)
        case .list(let parts):
            return parts.map(\.string).joined(separator: CatalogueText.listSeparator)
        case .entry(let key, let arguments):
            let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
            guard !arguments.isEmpty else { return format }
            let values: [CVarArg] = arguments.map { argument in
                if case .count(let count) = argument { return count }
                return argument.string
            }
            return String(format: format, locale: .current, arguments: values)
        }
    }
}
