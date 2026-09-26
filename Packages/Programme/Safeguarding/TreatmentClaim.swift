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
    /// fails a word here when nothing meaning "not" sits right before it.
    public static let selfDescribingWords = ["treatment", "therapy", "treats", "cures", "prevents", "diagnoses", "monitors"]

    /// `true` when the text obeys every rule in "What is a treatment claim".
    public static func passes(_ text: String) -> Bool {
        let lowered = text.lowercased()
        for phrase in forbiddenPhrases where lowered.contains(phrase) {
            return false
        }
        for word in selfDescribingWords {
            guard let range = lowered.range(of: word) else { continue }
            let before = lowered[lowered.startIndex..<range.lowerBound]
            let isNegated = before.hasSuffix("not ") || before.hasSuffix("n't ")
            if !isNegated { return false }
        }
        return true
    }
}
