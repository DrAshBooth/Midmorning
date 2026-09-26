import Foundation
import Constants

/// The app's string catalogue, read once for every test in this target.
private let appCatalogue: StringCatalogue = {
    do { return try StringCatalogue.appCatalogue() } catch { fatalError("Cannot read Localizable.xcstrings: \(error)") }
}()

extension CatalogueText {
    /// This text in English, from the catalogue the app ships (content spec,
    /// "Strings live in catalogues"). A missing key fails the test.
    var english: String {
        do { return try appCatalogue.render(self) } catch { return "<\(error)>" }
    }
}
