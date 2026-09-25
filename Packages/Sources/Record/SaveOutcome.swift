import Foundation

/// The new-entry and edit screens' save outcome, as a pure value (design.md,
/// "Pure seams the packages expose": "Screen models are values... Views
/// render them and hold no rule"). record spec, "A save that fails": when a
/// save throws, the screen stays open, shows this text under the navigation
/// bar and no other text, and keeps the typed text and the chosen values —
/// which holds by construction, because a `.failed` outcome never clears the
/// screen's own bound state.
public enum SaveOutcome: Sendable, Equatable {
    case saved
    case failed

    public static let failureMessage = "Could not save. Try again."
}
