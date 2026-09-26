import Foundation

/// The kinds of string the "Catalogue rules" requirement sets a character
/// limit for.
public enum CatalogueStringKind: Sendable {
    case navigationOrCardControl
    case notificationAction
    case chipOrSlotLabel
    case widgetLine
    case switchLabel
    case stateOrTodayLine
    case oneLineMessage

    /// The character limit the requirement sets for this kind.
    public var limit: Int {
        switch self {
        case .navigationOrCardControl: return 16
        case .notificationAction: return 20
        case .chipOrSlotLabel: return 20
        case .widgetLine: return 16
        case .switchLabel: return 40
        case .stateOrTodayLine: return 40
        case .oneLineMessage: return 80
        }
    }
}

/// One placeholder token found in a catalogue string, for example `%lld` or
/// `%1$@`.
struct PlaceholderToken {
    let position: Int?
    /// `true` for `%lld` or a positional `%1$lld`: a count. `%@` is never a
    /// count (ruling r13-12).
    let isCount: Bool

    var isPositional: Bool { position != nil }
}

/// The pure, machine-checkable rules from the "Catalogue rules" requirement.
/// Each function matches one rule the requirement states; `ContentBundle`
/// runs the ones that apply to every string it holds, and the tests also
/// exercise each one directly with the requirement's own fixtures.
public enum CatalogueRules {
    private static let placeholderPattern = try! NSRegularExpression(pattern: #"%(?:(\d+)\$)?(lld|@)"#)

    static func placeholders(in text: String) -> [PlaceholderToken] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return placeholderPattern.matches(in: text, range: range).map { match in
            let isCount = Range(match.range(at: 2), in: text).map { text[$0] == "lld" } ?? false
            if let r = Range(match.range(at: 1), in: text), let n = Int(text[r]) {
                return PlaceholderToken(position: n, isCount: isCount)
            }
            return PlaceholderToken(position: nil, isCount: isCount)
        }
    }

    /// `true` when `text` holds more than one placeholder and at least one
    /// of them is not positional.
    public static func hasUnpositionedMultiplePlaceholders(_ text: String) -> Bool {
        let tokens = placeholders(in: text)
        return tokens.count > 1 && tokens.contains { !$0.isPositional }
    }

    /// The number of counts in `text`: every `%lld`, with or without a
    /// position. A `%@` is not a count (ruling r13-12).
    public static func countPlaceholderCount(_ text: String) -> Int {
        placeholders(in: text).filter(\.isCount).count
    }

    /// `true` when `text` holds a count, `%lld` or a positional `%1$lld`,
    /// and so needs plural forms. A `%@` alone never needs them.
    public static func requiresPluralForms(_ text: String) -> Bool {
        countPlaceholderCount(text) > 0
    }

    /// `true` when `text` holds more than one count. A string holds at most
    /// one count, so that its plural forms follow that one count (ruling
    /// r13-12). A string with two counts becomes two strings with one
    /// count each.
    public static func holdsMoreThanOneCount(_ text: String) -> Bool {
        countPlaceholderCount(text) > 1
    }

    /// `true` when `text` holds a run of two or more digits that is not the
    /// position prefix of a placeholder, for example "20" in "Buzz at 20
    /// minutes". A constant MUST enter a string through `%lld`, never as a
    /// literal number.
    public static func hasLiteralConstant(_ text: String) -> Bool {
        let chars = Array(text)
        var index = 0
        while index < chars.count {
            if chars[index].isNumber {
                var end = index
                while end < chars.count, chars[end].isNumber { end += 1 }
                // A position prefix reads "%<digits>$"; skip it.
                let precededByPercent = index > 0 && chars[index - 1] == "%"
                let followedByDollar = end < chars.count && chars[end] == "$"
                if !(precededByPercent && followedByDollar), (end - index) >= 2 {
                    return true
                }
                index = end
            } else {
                index += 1
            }
        }
        return false
    }

    /// `true` when `text` is longer than `kind`'s character limit.
    public static func exceedsLimit(_ text: String, kind: CatalogueStringKind) -> Bool {
        text.count > kind.limit
    }

    /// `true` when `text` ends with a full stop.
    public static func endsWithFullStop(_ text: String) -> Bool {
        text.hasSuffix(".")
    }

    /// `true` when `text` uses the bare plural "binges".
    public static func hasBarePluralBinges(_ text: String) -> Bool {
        WordMatcher.contains(text, entry: "binges")
    }

    /// `true` when `text` starts with an upper-case letter, the sentence-case
    /// rule the requirement sets. Ignores a leading quotation mark.
    public static func isSentenceCase(_ text: String) -> Bool {
        guard let first = text.first(where: { $0.isLetter }) else { return true }
        return first.isUppercase
    }

    private static let emailPattern = try! NSRegularExpression(pattern: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#)

    /// "The catalogue key 'about.contact'... MUST hold the placeholder or
    /// an email address." The sentence-case and full-stop rules do not
    /// apply to this one key; the caller skips them for it.
    public static func isValidContactValue(_ text: String) -> Bool {
        if text == "contact@example.invalid" { return true }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return emailPattern.firstMatch(in: text, range: range) != nil
    }
}

/// A count string's plural forms, for the categories the requirement names:
/// zero, one and other. English does not distinguish zero from other, so a
/// string that never reaches zero can repeat `other` there.
public struct PluralForms: Sendable, Equatable, Codable {
    public let zero: String
    public let one: String
    public let other: String

    public init(zero: String, one: String, other: String) {
        self.zero = zero
        self.one = one
        self.other = other
    }

    public func text(for count: Int) -> String {
        switch count {
        case 0: return zero
        case 1: return one
        default: return other
        }
    }
}
