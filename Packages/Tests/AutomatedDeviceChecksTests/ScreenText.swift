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

    /// The source of one App file, by its path under `App/Midmorning`, with
    /// each run of spaces, tabs and line breaks changed to one space. A
    /// check that matches this text does not fail when a reformat changes
    /// the indentation or the line breaks.
    static func source(_ path: String) throws -> String {
        normalised(try String(contentsOf: AppFiles.appSources.appendingPathComponent(path), encoding: .utf8))
    }

    /// `text` with each run of white space changed to one space.
    static func normalised(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Fails unless the App file `path` holds each snippet: the call or the
    /// catalogue key that puts the words on that screen. The match ignores
    /// the white space in the snippet and in the file (`normalised`).
    ///
    /// A match proves that the source holds the call; it does not prove the
    /// layout on the screen. A layout claim (for example, "above the title")
    /// needs a UI test in `tools/skeleton-checks/HarnessUITests/AutomatedChecks.swift`.
    static func assertScreen(_ path: String, shows snippets: [String], file: StaticString = #filePath, line: UInt = #line) throws {
        let text = try source(path)
        for snippet in snippets {
            XCTAssertTrue(text.contains(normalised(snippet)), "\(path) shows \(snippet)", file: file, line: line)
        }
    }

    /// The place of `snippet` in the App file text `text` (from `source`),
    /// with the white space ignored.
    static func range(of snippet: String, in text: String) -> Range<String.Index>? {
        text.range(of: normalised(snippet))
    }
}
