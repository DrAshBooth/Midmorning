import Foundation

/// The Today stack's bottom toolbar (record spec, "The Today stack"):
/// "Programme", "Reviews" only from the moment the first weekly review
/// becomes due, then "Settings".
public enum BottomToolbar {
    public enum Item: Sendable, Hashable {
        case programme, reviews, settings
    }

    public static func items(reviewsDue: Bool) -> [Item] {
        reviewsDue ? [.programme, .reviews, .settings] : [.programme, .settings]
    }
}
