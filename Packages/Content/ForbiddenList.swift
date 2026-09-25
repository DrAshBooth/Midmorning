import Foundation

/// The forbidden list the "The forbidden list" requirement names. Every
/// entry matches as a whole word, case-insensitive, through `WordMatcher`.
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

    /// The list that applies to an id, by its prefix.
    public static func list(for id: String) -> [String] {
        shortListPrefixes.contains(where: { id.hasPrefix($0) }) ? short : full
    }

    /// The first forbidden word or phrase `text` holds, checked against the
    /// list `id`'s family uses, or `nil` when none match.
    public static func firstMatch(in text: String, id: String) -> String? {
        WordMatcher.firstMatch(in: text, entries: list(for: id))
    }
}
