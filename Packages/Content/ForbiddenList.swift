import Foundation

/// The forbidden list the "The forbidden list" requirement names. Every
/// entry matches as a whole word, case-insensitive, through `WordMatcher`.
/// The check skips each sentence in `permittedSentences` (ruling r17-02).
public enum ForbiddenList {
    /// The full list. It applies to the cards, the opening sentences, the
    /// rule strings and the Today card strings, the pattern templates,
    /// every question and the alternatives examples.
    public static let full: [String] = [
        "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT",
        "treat", "treats", "treatment", "therapy", "therapist",
        "cure", "recovery", "disorder", "patient", "symptom",
        "diagnosis", "clinical", "calories", "calorie", "portion",
        "log", "tracker", "user", "streak",
        "binger", "bingeing", "binge episode",
        "well done", "great job", "proud", "you've got this",
    ]

    /// The short list. The content test checks `support.*`, `gp.*`,
    /// `exclusion.*`, `notrightnow.*` and `gpsuggestion.*` strings against
    /// this list only, because those strings can name a GP, a diagnosis a
    /// person already has, or a treatment a person is already in.
    public static let short: [String] = [
        "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT",
        "binger", "bingeing", "binge episode",
        "you've got this", "well done", "great job", "proud",
    ]

    /// The families the content test checks against the short list only,
    /// by id prefix.
    public static let shortListPrefixes: [String] = [
        "support.", "gp.", "exclusion.", "notrightnow.", "gpsuggestion.",
    ]

    /// The sentences that the content test does not check against either
    /// list (ruling r17-02, 7 October 2026). Safeguarding, "What is a
    /// treatment claim", permits the first three: the negative statement,
    /// line 3 of onboarding screen 1, which its scenario "A negative
    /// statement" passes, and the description of the method. The fourth is
    /// the screening treatment question (onboarding, "Screen 2: the
    /// screening questions").
    ///
    /// The test compares each sentence of a text with these as a whole,
    /// exact string, with the same letters, case and punctuation. It never
    /// compares words: "It uses ideas from CBT-E.", "it uses ideas from
    /// CBT." and "Midmorning uses ideas from CBT." are still checked.
    public static let permittedSentences: [String] = [
        "It is not therapy.",
        "It is not therapy, and it does not replace your GP or anyone treating you.",
        "It uses ideas from CBT.",
        "Are you getting help from a clinic or a therapist for your eating at the moment?",
    ]

    /// The end of a sentence: the whitespace after a full stop, a question
    /// mark or an exclamation mark.
    private static let sentenceBreak = try! NSRegularExpression(pattern: #"(?<=[.?!])\s+"#)

    /// The sentences of `text`, in order, with no change to their
    /// characters. A sentence ends at a full stop, a question mark or an
    /// exclamation mark that whitespace follows, or at the end of the text.
    public static func sentences(of text: String) -> [String] {
        var sentences: [String] = []
        var start = text.startIndex
        for match in sentenceBreak.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text) else { continue }
            sentences.append(String(text[start..<range.lowerBound]))
            start = range.upperBound
        }
        if start < text.endIndex { sentences.append(String(text[start...])) }
        return sentences
    }

    /// The parts of `text` that the lists apply to: `text` with each
    /// permitted sentence removed. A permitted sentence cuts the text, so a
    /// phrase on a list cannot join across it. A text with no permitted
    /// sentence is one part, the full text.
    public static func checkedParts(of text: String) -> [String] {
        var parts: [String] = []
        var current: [String] = []
        for sentence in sentences(of: text) {
            if permittedSentences.contains(sentence) {
                if !current.isEmpty { parts.append(current.joined(separator: " ")) }
                current = []
            } else {
                current.append(sentence)
            }
        }
        if !current.isEmpty { parts.append(current.joined(separator: " ")) }
        return parts
    }

    /// The list that applies to an id, by its prefix.
    public static func list(for id: String) -> [String] {
        shortListPrefixes.contains(where: { id.hasPrefix($0) }) ? short : full
    }

    /// The first forbidden word or phrase `text` holds, checked against the
    /// list `id`'s family uses, or `nil` when none match. The check skips
    /// each permitted sentence.
    public static func firstMatch(in text: String, id: String) -> String? {
        let entries = list(for: id)
        return checkedParts(of: text).lazy.compactMap { WordMatcher.firstMatch(in: $0, entries: entries) }.first
    }
}
