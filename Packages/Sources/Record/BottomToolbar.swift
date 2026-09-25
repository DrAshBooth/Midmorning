import Foundation

/// The Today stack's bottom toolbar (record spec, "The Today stack"):
/// "Programme", "Reviews" only from the moment the first weekly review
/// becomes due, then "Settings".
public enum BottomToolbar {
    public static func items(reviewsDue: Bool) -> [String] {
        reviewsDue ? ["Programme", "Reviews", "Settings"] : ["Programme", "Settings"]
    }
}
