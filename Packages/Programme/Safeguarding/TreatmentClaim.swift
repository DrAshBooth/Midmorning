import Foundation

/// What the app can and cannot claim about itself (safeguarding spec, "What
/// is a treatment claim"). A reviewer runs `passes(_:)` over a card draft, a
/// marketing draft or an App Store string before it ships; the four onboarding
/// screens' own bundled strings already pass, because they are copied
/// verbatim from the spec.
public enum TreatmentClaim {
    /// A phrase that MUST NOT appear anywhere, checked case-insensitively.
    public static let forbiddenPhrases = [
        "clinically proven",
        "the treatment nice recommends",
        "binger",
        "bingeing behaviour",
        "binge episode",
    ]

    /// A word the app MUST NOT use to describe itself. Each stays allowed in
    /// a negative statement ("It is not therapy."), so `passes(_:)` only
    /// fails a use of a word here when the word right before it is not
    /// "not" or a word that ends in "n't".
    public static let selfDescribingWords = ["treatment", "therapy", "treats", "cures", "prevents", "diagnoses", "monitors"]

    /// `true` when the text obeys every rule in "What is a treatment claim".
    /// The check reads every use of each word, as a whole word: "It is not
    /// therapy. Midmorning is therapy in your pocket." fails on the second
    /// use, and "retreats" is not "treats".
    public static func passes(_ text: String) -> Bool {
        let lowered = text.lowercased()
        for phrase in forbiddenPhrases where lowered.contains(phrase) {
            return false
        }
        let tokens = words(in: lowered)
        for (index, token) in tokens.enumerated() where selfDescribingWords.contains(token) {
            let previous = index > 0 ? tokens[index - 1] : ""
            let isNegated = previous == "not" || previous.hasSuffix("n't")
            if !isNegated { return false }
        }
        return true
    }

    /// The words of `text` in order. A word is a run of letters, digits and
    /// apostrophes; a curly apostrophe counts as a straight one.
    static func words(in text: String) -> [String] {
        text.replacingOccurrences(of: "\u{2019}", with: "'")
            .split { !($0.isLetter || $0.isNumber || $0 == "'") }
            .map(String.init)
    }
}
