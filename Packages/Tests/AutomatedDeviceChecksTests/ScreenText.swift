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
    /// no comments, and with each run of spaces, tabs and line breaks
    /// changed to one space. A check that matches this text does not fail
    /// when a reformat changes the indentation or the line breaks. It fails
    /// when the code loses a call and only a comment keeps its words.
    static func source(_ path: String) throws -> String {
        normalised(withoutComments(try String(contentsOf: AppFiles.appSources.appendingPathComponent(path), encoding: .utf8)))
    }

    /// `swift` with each `//` comment (`///` included) and each `/* */`
    /// comment removed. A comment becomes one space. String literals stay,
    /// so a URL such as "https://…" stays whole. The scan knows single-line
    /// and multi-line (`"""`) literals and nested block comments; it does
    /// not parse string interpolation, which is enough for the App files.
    static func withoutComments(_ swift: String) -> String {
        let characters = Array(swift)
        let count = characters.count
        var result = ""
        result.reserveCapacity(count)
        var index = 0
        func isPair(_ first: Character, _ second: Character) -> Bool {
            index + 1 < count && characters[index] == first && characters[index + 1] == second
        }
        func isTripleQuote() -> Bool {
            index + 2 < count && characters[index] == "\"" && characters[index + 1] == "\"" && characters[index + 2] == "\""
        }
        /// Copies one character of a literal; a backslash takes the next
        /// character with it, so an escaped quote does not end the literal.
        func copyLiteralCharacter() {
            if characters[index] == "\\", index + 1 < count {
                result.append(characters[index])
                index += 1
            }
            result.append(characters[index])
            index += 1
        }
        while index < count {
            if isPair("/", "/") {
                while index < count, !characters[index].isNewline { index += 1 }
                result.append(" ")
            } else if isPair("/", "*") {
                var depth = 0
                repeat {
                    if isPair("/", "*") { depth += 1; index += 2 }
                    else if isPair("*", "/") { depth -= 1; index += 2 }
                    else { index += 1 }
                } while depth > 0 && index < count
                result.append(" ")
            } else if isTripleQuote() {
                result.append("\"\"\"")
                index += 3
                while index < count, !isTripleQuote() { copyLiteralCharacter() }
                if index < count { result.append("\"\"\""); index += 3 }
            } else if characters[index] == "\"" {
                result.append("\"")
                index += 1
                while index < count, characters[index] != "\"", !characters[index].isNewline { copyLiteralCharacter() }
                if index < count { result.append(characters[index]); index += 1 }
            } else {
                result.append(characters[index])
                index += 1
            }
        }
        return result
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
