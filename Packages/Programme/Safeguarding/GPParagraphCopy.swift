import Foundation

/// The pure part of "Copy" on the GP paragraph (safeguarding spec, "The GP
/// paragraph"): which text goes on the pasteboard, and the fixed timings.
/// The pasteboard write itself (local-only, 60-second expiry, no Universal
/// Clipboard, the VoiceOver announcement) is App-target, system-API code a
/// device check proves; `swift test` cannot drive `UIPasteboard`.
public enum GPParagraphCopy {
    public static let pasteboardExpirySeconds: TimeInterval = 60
    public static let copiedLabelDurationSeconds: TimeInterval = 2
    public static let copiedConfirmationLine = "Copied. It clears in a minute."
    public static let copyLabel = "Copy"
    public static let copiedLabel = "Copied"
    public static let voiceOverAnnouncement = "Copied"

    /// The text "Copy" places on the pasteboard: the person's edit if they
    /// made one, otherwise the bundled paragraph for the variant.
    public static func textToCopy(bundled: String, edited: String?) -> String {
        edited ?? bundled
    }
}
