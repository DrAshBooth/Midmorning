import Foundation

/// The GP paragraph and its two variants (safeguarding spec, "The GP
/// paragraph"). `content` will bundle these from a later change; this
/// capability names the fixed text now so every page that shows it agrees.
public enum GPParagraphVariant: Sendable, Equatable {
    case standard, selfHarm, under18
}

public enum GPParagraph {
    public static let standard = "I'd like to talk about my eating. I've been having times when I eat a lot and feel out of control. I've been following a self-help programme on my phone and I have a record I can show you. Can we talk about what support there is?"

    public static let selfHarmAddition = "I've been having thoughts of hurting myself and I'd like to talk about that."

    public static let under18 = "I'd like to talk about my eating. Is there someone for people my age I can see?"

    public static func text(for variant: GPParagraphVariant) -> String {
        switch variant {
        case .standard:
            return standard
        case .selfHarm:
            return standard + " " + selfHarmAddition
        case .under18:
            return under18
        }
    }

    /// The variant a page with these reasons shows. The age reason always
    /// wins the under-18 variant; the self-harm variant otherwise wins when
    /// no age reason applies (safeguarding spec, "The exclusion page").
    public static func variant(for reasons: [ExclusionReason]) -> GPParagraphVariant {
        if reasons.contains(.age) { return .under18 }
        if reasons.contains(.selfHarm) { return .selfHarm }
        return .standard
    }
}
