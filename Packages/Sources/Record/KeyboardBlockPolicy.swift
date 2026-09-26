import Foundation

/// The one extension point the app blocks, named without UIKit so this
/// decision compiles and tests on macOS (data-and-privacy spec, "The app
/// blocks third-party keyboards"). The App target's `AppDelegate` maps
/// `UIApplication.ExtensionPointIdentifier` to this and calls `shouldAllow`.
public enum ExtensionPointKind: Sendable, Equatable {
    case keyboard
    case other
}

public enum KeyboardBlockPolicy {
    /// The system keyboard, dictation and the emoji keyboard are never an
    /// extension point, so they stay available; only a third-party keyboard
    /// extension is blocked.
    public static func shouldAllow(_ kind: ExtensionPointKind) -> Bool {
        kind != .keyboard
    }
}
