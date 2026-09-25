import Foundation

/// One literal the lint rejects: a string literal that is the first
/// argument of a one-line call to one of the six checked calls, and is not
/// a catalogue key.
public struct LiteralLintFailure: Sendable, Equatable, CustomStringConvertible {
    public let file: String
    public let line: Int
    public let literal: String

    public var description: String {
        "\(file):\(line): literal \"\(literal)\" is not a catalogue key"
    }
}

/// "Strings live in catalogues": the literal lint. It scans `App/**/*.swift`
/// for a string literal that is the first argument of a one-line call to
/// `Text(`, `Label(`, `Button(`, `.navigationTitle(`, `.accessibilityLabel(`
/// or `.accessibilityValue(`. `Text(verbatim:)` is the one escape. A call
/// that spans more than one line is outside the lint.
public enum LiteralLint {
    static let checkedCalls = [
        "Text(", "Label(", "Button(",
        ".navigationTitle(", ".accessibilityLabel(", ".accessibilityValue(",
    ]

    /// Scans every `.swift` file under `directory` and returns each
    /// literal that is not in `validKeys`. `root` is the repository root,
    /// used to make `file` a path relative to it.
    public static func scan(directory: URL, root: URL, validKeys: Set<String>) throws -> [LiteralLintFailure] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: nil) else { return [] }
        var failures: [LiteralLintFailure] = []
        let rootPath = root.standardizedFileURL.path
        for case let url as URL in enumerator {
            guard url.pathExtension == "swift" else { continue }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let relativeFile = url.standardizedFileURL.path.hasPrefix(rootPath + "/")
                ? String(url.standardizedFileURL.path.dropFirst(rootPath.count + 1))
                : url.lastPathComponent
            failures.append(contentsOf: scanFile(text: text, file: relativeFile, validKeys: validKeys))
        }
        return failures.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }

    static func scanFile(text: String, file: String, validKeys: Set<String>) -> [LiteralLintFailure] {
        var failures: [LiteralLintFailure] = []
        let lines = text.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let chars = Array(line)
            for call in checkedCalls {
                var searchStart = 0
                let callChars = Array(call)
                while let matchStart = firstIndex(of: callChars, in: chars, from: searchStart) {
                    searchStart = matchStart + 1
                    // Reject a match that is part of a longer identifier,
                    // for example "MyButton(" matching "Button(".
                    if !call.hasPrefix("."), matchStart > 0 {
                        let before = chars[matchStart - 1]
                        if before.isLetter || before.isNumber || before == "_" || before == "." {
                            continue
                        }
                    }
                    let parenIndex = matchStart + callChars.count - 1
                    guard let closeIndex = matchingCloseParen(chars, openIndex: parenIndex) else {
                        continue // spans more than one line; outside the lint
                    }
                    guard let (literal, isVerbatim) = firstArgumentLiteral(chars, from: parenIndex + 1, to: closeIndex) else {
                        continue // first argument is not a string literal
                    }
                    if isVerbatim { continue } // the one escape
                    if !validKeys.contains(literal) {
                        failures.append(LiteralLintFailure(file: file, line: lineNumber, literal: literal))
                    }
                }
            }
        }
        return failures
    }

    private static func firstIndex(of needle: [Character], in haystack: [Character], from start: Int) -> Int? {
        guard start >= 0, needle.count > 0, start + needle.count <= haystack.count else { return nil }
        var i = start
        while i + needle.count <= haystack.count {
            if Array(haystack[i..<(i + needle.count)]) == needle { return i }
            i += 1
        }
        return nil
    }

    /// Finds the index of the `)` that closes the `(` at `openIndex`,
    /// tracking string literals so a paren inside a string does not count,
    /// and returns `nil` when it does not close before the line ends.
    private static func matchingCloseParen(_ chars: [Character], openIndex: Int) -> Int? {
        var depth = 1
        var i = openIndex + 1
        var inString = false
        while i < chars.count {
            let c = chars[i]
            if inString {
                if c == "\\" { i += 2; continue }
                if c == "\"" { inString = false }
            } else {
                if c == "\"" { inString = true }
                else if c == "(" { depth += 1 }
                else if c == ")" {
                    depth -= 1
                    if depth == 0 { return i }
                }
            }
            i += 1
        }
        return nil
    }

    /// Reads the first argument between `from` and `to` (a call's parens).
    /// Returns the literal string and whether it followed `verbatim:`, or
    /// `nil` when the first argument is not a plain string literal.
    private static func firstArgumentLiteral(_ chars: [Character], from: Int, to: Int) -> (String, Bool)? {
        var i = from
        while i < to, chars[i] == " " || chars[i] == "\t" { i += 1 }
        // Skip an argument label, for example "verbatim: ".
        var isVerbatim = false
        let verbatimLabel = Array("verbatim:")
        if i + verbatimLabel.count <= to, Array(chars[i..<(i + verbatimLabel.count)]) == verbatimLabel {
            isVerbatim = true
            i += verbatimLabel.count
            while i < to, chars[i] == " " || chars[i] == "\t" { i += 1 }
        }
        guard i < to, chars[i] == "\"" else { return nil }
        i += 1
        var literal = ""
        while i < to, chars[i] != "\"" {
            if chars[i] == "\\", i + 1 < to {
                literal.append(chars[i + 1])
                i += 2
            } else {
                literal.append(chars[i])
                i += 1
            }
        }
        return (literal, isVerbatim)
    }
}
