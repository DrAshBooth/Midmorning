import Foundation

/// The exclusion page's fixed content (safeguarding spec, "The exclusion
/// page"). The page shows one paragraph per reason that applies, in
/// `ExclusionReason`'s declared order.
public enum ExclusionPage {
    public static let heading = "Not right now"
    public static let intro = "From your answers, this programme isn't the right thing for you at the moment. Here's why, and what can help instead."
    public static let whatToDoInstead = "What to do instead"
    public static let closing = "You can come back if this changes."

    public static func paragraph(for reason: ExclusionReason) -> String {
        switch reason {
        case .selfHarm:
            return "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999."
        case .age:
            return "Midmorning is built for adults. Beat's Youthline is for anyone under 18: 0808 801 0711."
        case .weight:
            return "Your height and weight put you in a range where this programme isn't the right tool for you. This is not a judgement about you. Your GP can look at this with you, and Beat can help you get there."
        case .pregnancy:
            return "Pregnancy changes what eating needs to look like, and this programme isn't designed for that. Your GP or midwife can help with eating during pregnancy."
        case .treatment:
            return "The people treating you are the right ones to decide what sits alongside it. Ask them about Midmorning. If they're happy, you can come back and start."
        }
    }

    /// The reasons that apply, in the page's fixed order.
    public static func ordered(_ reasons: [ExclusionReason]) -> [ExclusionReason] {
        ExclusionReason.allCases.filter { reasons.contains($0) }
    }
}
