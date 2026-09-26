import Foundation

/// The plan builder's fixed control positions (regular-eating-plan spec,
/// "Place slots in the plan builder"; decision 94, 25 September 2026). A
/// named fact the view reads, so the layout is proven by a test like any
/// other rule, not left to a screen-by-screen check.
public enum PlanBuilderLayout {
    public enum SaveControlPosition: Sendable, Equatable {
        case fullWidthBelowPlannedMeals
    }

    /// "Cancel" is the leading navigation-bar item; it discards the edit.
    public static let leadingNavigationItem = "Cancel"
    /// "Get support" is the trailing navigation-bar item (`safeguarding` owns
    /// the side; decision 94).
    public static let trailingNavigationItem = "Get support"
    public static let saveControlPosition: SaveControlPosition = .fullWidthBelowPlannedMeals
}
