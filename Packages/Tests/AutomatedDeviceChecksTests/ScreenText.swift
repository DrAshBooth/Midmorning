import Foundation
import XCTest
import Constants

/// The two halves of a text check (ruling r13-19, mm-t43.30): the words
/// come from the string catalogue that the app ships, and the screen's own
/// App file shows them. A text check on a device asked "does the screen
/// show these words"; these helpers answer it from the repository.
enum ScreenText {
    /// The app's string catalogue, read once.
    static let catalogue: StringCatalogue = {
        do { return try StringCatalogue.appCatalogue() } catch { fatalError("Cannot read Localizable.xcstrings: \(error)") }
    }()

    /// `text` in English, as the app fills it. A missing key gives a
    /// marker that no assertion matches.
    static func english(_ text: CatalogueText) -> String {
        do { return try catalogue.render(text) } catch { return "<\(error)>" }
    }

    /// The source of one App file, by its path under `App/Midmorning`.
    static func source(_ path: String) throws -> String {
        try String(contentsOf: AppFiles.appSources.appendingPathComponent(path), encoding: .utf8)
    }

    /// Fails unless the App file `path` holds each snippet: the call or the
    /// catalogue key that puts the words on that screen.
    static func assertScreen(_ path: String, shows snippets: [String], file: StaticString = #filePath, line: UInt = #line) throws {
        let text = try source(path)
        for snippet in snippets {
            XCTAssertTrue(text.contains(snippet), "\(path) shows \(snippet)", file: file, line: line)
        }
    }
}
