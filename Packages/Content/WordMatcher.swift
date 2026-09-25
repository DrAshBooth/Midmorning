import Foundation

/// Whole-word, case-insensitive matching for the forbidden list and the UK
/// spelling list. A word is a maximal run of letters, digits, apostrophes
/// and hyphens. An entry with a space matches as a run of whole words in
/// that order, so "binge episode" does not match inside "a binge episodes
/// away" but does match inside "a binge episode happened".
public enum WordMatcher {
    /// The tokens in `text`: maximal runs of letters, digits, apostrophes
    /// and hyphens, lowercased, in order.
    public static func tokens(of text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        func isWordCharacter(_ c: Character) -> Bool {
            c.isLetter || c.isNumber || c == "'" || c == "\u{2019}" || c == "-"
        }
        for character in text {
            if isWordCharacter(character) {
                current.append(character)
            } else if !current.isEmpty {
                tokens.append(current.lowercased())
                current = ""
            }
        }
        if !current.isEmpty { tokens.append(current.lowercased()) }
        return tokens
    }

    /// `true` when `entry` (one word or a run of words) appears as whole
    /// words, in order, anywhere in `text`.
    public static func contains(_ text: String, entry: String) -> Bool {
        let haystack = tokens(of: text)
        let needle = tokens(of: entry)
        guard !needle.isEmpty, needle.count <= haystack.count else { return false }
        for start in 0...(haystack.count - needle.count) {
            if Array(haystack[start..<(start + needle.count)]) == needle {
                return true
            }
        }
        return false
    }

    /// The first entry in `entries` that `text` contains as whole words, or
    /// `nil` when none match. Checks entries in the order given.
    public static func firstMatch(in text: String, entries: [String]) -> String? {
        entries.first { contains(text, entry: $0) }
    }
}
