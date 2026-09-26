import Foundation

/// One failure the content test reports. `id` names the card or string the
/// failure belongs to, when the requirement asks the test to name one.
public struct ContentIssue: Sendable, Equatable, CustomStringConvertible {
    public let id: String?
    public let message: String

    public init(id: String? = nil, message: String) {
        self.id = id
        self.message = message
    }

    public var description: String {
        id.map { "\($0): \(message)" } ?? message
    }
}

/// The people who address the person as something other than "you".
private let disallowedAddresses = ["user", "patient", "client"]

/// A curly-brace placeholder, for example "{weighInDay}". A card MUST hold
/// no such placeholder; the app never fills one at runtime.
private let cardPlaceholderPattern = try! NSRegularExpression(pattern: #"\{[^{}]+\}"#)

/// A markdown-style image reference or an `<img` tag, the two forms a card
/// body could hold an image reference in.
private let imageReferencePattern = try! NSRegularExpression(pattern: #"!\[[^\]]*\]\([^)]*\)|<img\b"#, options: .caseInsensitive)

extension Card {
    /// Every text the card screen shows: the title, the body and the one
    /// thing to do. A rule about what "a card" holds reads all three.
    var readableTexts: [String] { [title, body, oneThing] }
}

extension StringEntry {
    /// The entry's text and, when it has them, its plural forms. A rule
    /// about what a string holds reads every form the app can show.
    var readableTexts: [String] {
        guard let plural else { return [text] }
        return [text, plural.zero, plural.one, plural.other]
    }
}

private func holdsPlaceholder(_ text: String) -> Bool {
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return cardPlaceholderPattern.firstMatch(in: text, range: range) != nil
}

/// The machine-checkable rules from the content spec, run over a real
/// `ContentBundle` or a fixture built for one scenario. Each function
/// matches one requirement; `ContentBundleTests` calls the whole set
/// against the shipped bundle, and each scenario's own test calls the one
/// function that scenario names.
public enum ContentChecks {
    /// "Each stage has three to five cards": every section present in
    /// `sections` MUST hold 3 to 5 non-retired cards.
    public static func cardCounts(_ bundle: ContentBundle, sections: [Card.Section]) -> [ContentIssue] {
        sections.map { section in
            let count = bundle.activeCards(in: section).count
            return (section, count)
        }.compactMap { section, count in
            guard count < 3 || count > 5 else { return nil }
            return ContentIssue(message: "\(describe(section)) holds \(count) cards, not 3 to 5")
        }
    }

    public static func describe(_ section: Card.Section) -> String {
        switch section {
        case .stage(let n): return "stage \(n)"
        case .module(let m): return "the \(m.rawValue) module"
        }
    }

    /// "Each stage has three to five cards": a body over 500 words fails.
    public static func wordLimit(_ cards: [Card]) -> [ContentIssue] {
        cards.filter { $0.bodyWordCount > 500 }.map {
            ContentIssue(id: $0.id, message: "body holds \($0.bodyWordCount) words, over the 500-word limit")
        }
    }

    /// "Each stage has three to five cards": a body with an image reference
    /// fails.
    public static func noImageReference(_ cards: [Card]) -> [ContentIssue] {
        cards.filter { hasImageReference($0.body) }.map {
            ContentIssue(id: $0.id, message: "body holds an image reference")
        }
    }

    static func hasImageReference(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return imageReferencePattern.firstMatch(in: text, range: range) != nil
    }

    /// "One in-app link on a card": at most one link, and it MUST NOT be a
    /// web link.
    public static func links(_ cards: [Card]) -> [ContentIssue] {
        cards.flatMap { card -> [ContentIssue] in
            var issues: [ContentIssue] = []
            if card.links.count > 1 {
                issues.append(ContentIssue(id: card.id, message: "holds \(card.links.count) links, at most one allowed"))
            }
            if card.links.contains(where: { $0.isWebLink }) {
                issues.append(ContentIssue(id: card.id, message: "holds a link outside the app"))
            }
            return issues
        }
    }

    /// "Plain UK English": UK spelling, in the title, the body and the one
    /// thing to do.
    public static func ukSpelling(_ cards: [Card]) -> [ContentIssue] {
        cards.compactMap { card in
            card.readableTexts.lazy.compactMap { USSpellings.firstMatch(in: $0) }.first.map {
                ContentIssue(id: card.id, message: "holds the US spelling \"\($0)\"")
            }
        }
    }

    /// "Plain UK English": the card addresses the person as "you", never
    /// "user", "patient" or "client", in any of its texts.
    public static func addressesPerson(_ cards: [Card]) -> [ContentIssue] {
        cards.compactMap { card in
            card.readableTexts.lazy.compactMap { WordMatcher.firstMatch(in: $0, entries: disallowedAddresses) }.first.map {
                ContentIssue(id: card.id, message: "addresses the person as \"\($0)\"")
            }
        }
    }

    /// "Every card ends with the one thing to do": `oneThing` MUST NOT be
    /// empty.
    public static func oneThingPresent(_ cards: [Card]) -> [ContentIssue] {
        cards.filter { $0.oneThing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { ContentIssue(id: $0.id, message: "holds an empty oneThing") }
    }

    /// "The forbidden list", applied to every card's title, body and one
    /// thing to do and, with the id's own list, to every string entry's
    /// text and plural forms.
    public static func forbiddenWordsInCards(_ cards: [Card]) -> [ContentIssue] {
        cards.compactMap { card in
            card.readableTexts.lazy.compactMap { ForbiddenList.firstMatch(in: $0, id: card.id) }.first.map {
                ContentIssue(id: card.id, message: "holds the forbidden word \"\($0)\"")
            }
        }
    }

    public static func forbiddenWordsInStrings(_ entries: [StringEntry]) -> [ContentIssue] {
        entries.compactMap { entry in
            entry.readableTexts.lazy.compactMap { ForbiddenList.firstMatch(in: $0, id: entry.id) }.first.map {
                ContentIssue(id: entry.id, message: "holds the forbidden word \"\($0)\"")
            }
        }
    }

    /// "The app bundles the cards": a card MUST hold no runtime
    /// placeholder, in its title, its body or its one thing to do.
    public static func noRuntimePlaceholder(_ cards: [Card]) -> [ContentIssue] {
        cards.filter { $0.readableTexts.contains(where: holdsPlaceholder) }
            .map { ContentIssue(id: $0.id, message: "holds a runtime placeholder") }
    }

    /// A reviewed string, like a card, MUST hold no runtime placeholder
    /// when its family forbids one (for example the reflection and week-1
    /// questions, which take no fill at all). Checks the plural forms too.
    public static func noRuntimePlaceholder(in entry: StringEntry) -> [ContentIssue] {
        guard entry.readableTexts.contains(where: holdsPlaceholder) else { return [] }
        return [ContentIssue(id: entry.id, message: "text holds a runtime placeholder")]
    }

    /// "Every bundled string family has ids": no two strings share an id,
    /// and no string has an empty id.
    public static func idUniqueness(_ entries: [StringEntry]) -> [ContentIssue] {
        var seen = Set<String>()
        var issues: [ContentIssue] = []
        for entry in entries {
            if entry.id.isEmpty {
                issues.append(ContentIssue(message: "a string has no id"))
            } else if !seen.insert(entry.id).inserted {
                issues.append(ContentIssue(id: entry.id, message: "two strings share this id"))
            }
        }
        return issues
    }

    /// "Every bundled string family has ids" (cards: "the ids in the card
    /// catalogue"): no two cards share an id, and no card has an empty id.
    /// The content-lock hash keys cards by id, so a second card with the
    /// same id would also hide the first from the hash.
    public static func cardIdUniqueness(_ cards: [Card]) -> [ContentIssue] {
        var seen = Set<String>()
        var issues: [ContentIssue] = []
        for card in cards {
            if card.id.isEmpty {
                issues.append(ContentIssue(message: "a card has no id"))
            } else if !seen.insert(card.id).inserted {
                issues.append(ContentIssue(id: card.id, message: "two cards share this id"))
            }
        }
        return issues
    }

    /// "The card catalogue": every id in `shippedIds` MUST be present in
    /// the bundle (retired cards still count).
    public static func shippedIdsPresent(_ bundle: ContentBundle, shippedIds: [String]) -> [ContentIssue] {
        shippedIds.filter { bundle.card(id: $0) == nil }
            .map { ContentIssue(id: $0, message: "a shipped id is missing from the bundle") }
    }

    /// "Tone of every card": a card MUST use "binge" only in "binge
    /// eating", "binge eat" and "a binge". Any other standalone use fails.
    public static func bingeUsageViolations(_ cards: [Card]) -> [ContentIssue] {
        let allowed = ["binge eating", "binge eat", "a binge"]
        return cards.compactMap { card -> ContentIssue? in
            for text in card.readableTexts {
                let tokens = WordMatcher.tokens(of: text)
                for (index, token) in tokens.enumerated() where token == "binge" {
                    let precededByA = index > 0 && tokens[index - 1] == "a"
                    let followedByEating = index + 1 < tokens.count && tokens[index + 1] == "eating"
                    let followedByEat = index + 1 < tokens.count && tokens[index + 1] == "eat"
                    if !(precededByA || followedByEating || followedByEat) {
                        return ContentIssue(id: card.id, message: "uses \"binge\" outside \(allowed)")
                    }
                }
            }
            return nil
        }
    }

    /// "Catalogue rules": every rule the content test can check by machine,
    /// applied to one string.
    public static func catalogueRuleIssues(id: String, text: String, kind: CatalogueStringKind?, plural: PluralForms?) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        if CatalogueRules.hasUnpositionedMultiplePlaceholders(text) {
            issues.append(ContentIssue(id: id, message: "holds more than one placeholder without positions"))
        }
        if CatalogueRules.requiresPluralForms(text), plural == nil {
            issues.append(ContentIssue(id: id, message: "holds a count with no plural forms"))
        }
        if let kind, CatalogueRules.exceedsLimit(text, kind: kind) {
            issues.append(ContentIssue(id: id, message: "holds \(text.count) characters, over the \(kind.limit)-character limit"))
        }
        if CatalogueRules.hasBarePluralBinges(text) {
            issues.append(ContentIssue(id: id, message: "holds the bare plural \"binges\""))
        }
        return issues
    }
}
