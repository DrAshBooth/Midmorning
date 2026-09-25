import Foundation

/// The card screen as a value: what "The card screen and the card list"
/// requires the screen to show, with nothing added and nothing truncated.
/// The view renders this value and holds no rule of its own. `mm-t21.23`
/// wires it into the Programme screen and proves it on a device.
public struct CardScreen: Sendable, Equatable {
    public static let oneThingHeading = "One thing to do"

    public let title: String
    public let body: String
    public let oneThing: String
    public let link: CardLink?

    public init(card: Card) {
        title = card.title
        body = card.body
        oneThing = card.oneThing
        link = card.links.first
    }

    /// The headings VoiceOver stops at when it moves by heading: the title,
    /// then "One thing to do". The screen holds no other heading.
    public var voiceOverHeadings: [String] {
        [title, Self.oneThingHeading]
    }

    /// The controls the screen shows, and no other. "Close" and Get support
    /// are always present; the card's in-app link shows only when the card
    /// holds one.
    public enum Control: Sendable, Equatable {
        case close
        case getSupport
        case link(CardLink)
        case scroll
    }

    public var controls: [Control] {
        var controls: [Control] = [.close, .getSupport]
        if let link { controls.append(.link(link)) }
        controls.append(.scroll)
        return controls
    }

    /// The screen never truncates or caps its text; a fixed line limit
    /// would break "Largest text size" at AX5. `body` and `oneThing` above
    /// keep the card's full text with no length cap.
    public var showsNoImage: Bool { true }
}

/// The stage or module list of card titles, in bundle order, as "The card
/// screen and the card list" states. Retired cards do not appear. The list
/// shows no count, percentage, tick or read state; this type carries none.
public enum CardList {
    public static func titles(for section: Card.Section, in bundle: ContentBundle) -> [String] {
        bundle.activeCards(in: section).map(\.title)
    }
}
