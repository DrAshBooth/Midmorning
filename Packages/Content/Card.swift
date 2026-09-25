import Foundation

/// One in-app link on a card. `target` names the screen the link opens, for
/// example "Feeling fat notes". A `target` that looks like a URL is a web
/// link, which the content test rejects.
public struct CardLink: Sendable, Equatable, Codable {
    public let target: String

    public init(target: String) {
        self.target = target
    }

    /// `true` when `target` names a page outside the app rather than a
    /// screen inside it.
    public var isWebLink: Bool {
        target.lowercased().hasPrefix("http://") || target.lowercased().hasPrefix("https://")
    }
}

/// One card. The content bundle at content version 1 holds three to five
/// cards for each of the seven stages, and three to five for each stage 6
/// module. `id` never changes across versions; `title` and `body` can.
public struct Card: Sendable, Equatable, Codable, Identifiable {
    /// The stage a card belongs to, 1 to 7. Stage 6 also carries a module.
    public enum Section: Sendable, Equatable, Codable {
        case stage(Int)
        case module(Module)

        public enum Module: String, Sendable, Equatable, Codable {
            case dieting
            case body
        }
    }

    public let id: String
    public let section: Section
    public let title: String
    public let body: String
    public let oneThing: String
    public let links: [CardLink]
    public let retired: Bool

    public init(
        id: String,
        section: Section,
        title: String,
        body: String,
        oneThing: String,
        links: [CardLink] = [],
        retired: Bool = false
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.body = body
        self.oneThing = oneThing
        self.links = links
        self.retired = retired
    }

    /// The number of words in `body`, counted as maximal runs of
    /// non-whitespace, so that the 500-word limit can be checked.
    public var bodyWordCount: Int {
        body.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
