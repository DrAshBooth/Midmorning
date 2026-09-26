import Foundation

/// The not-right-now page's fixed content (safeguarding spec, "The
/// not-right-now page"). A re-screen at a restart can give any of these
/// four reasons, in this fixed order: self-harm, weight, pregnancy,
/// treatment. `mm-t22` (weigh-in), `mm-t32` (weekly-review) and `mm-t21`
/// (programme-engine) open this page from their own triggers; this change
/// builds the page and its content only.
public enum NotRightNowPage {
    public static let heading = "This may not be right for you now"

    public static let selfHarmReason = "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999."

    public static let weightReason = "Your weight has fallen to a point where this programme isn't the right tool for you. This is not a judgement about you. This is not a diagnosis. Your GP can look at this with you."

    public static let recordStaysLine = "Your record stays here, and you can keep adding to it."
    public static let remindersPausedLine = "Reminders are paused. You can turn them on again in Settings."
    public static let remindersStayOnLine = "Your plan and its reminders stay on. You can turn them off in Settings."

    /// Pregnancy and treatment reuse the exclusion page's own paragraphs,
    /// from the same bundled strings; the team writes no new wording for them.
    public static func paragraph(for reason: ExclusionReason) -> String? {
        switch reason {
        case .selfHarm: return selfHarmReason
        case .weight: return weightReason
        case .pregnancy: return ExclusionPage.paragraph(for: .pregnancy)
        case .treatment: return ExclusionPage.paragraph(for: .treatment)
        case .age: return nil // A re-screen never gives the age reason.
        }
    }

    /// The page's fixed order: self-harm, weight, pregnancy, treatment.
    public static let order: [ExclusionReason] = [.selfHarm, .weight, .pregnancy, .treatment]

    public static func ordered(_ reasons: [ExclusionReason]) -> [ExclusionReason] {
        order.filter { reasons.contains($0) }
    }

    /// The reminders line: paused with the weight reason, otherwise kept on.
    public static func remindersLine(for reasons: [ExclusionReason]) -> String {
        reasons.contains(.weight) ? remindersPausedLine : remindersStayOnLine
    }
}
