import Foundation

/// Which of the current day's planned meals the builder lets the person
/// change or delete (regular-eating-plan spec, "Edit tonight for tomorrow,
/// or this morning for today"). An unanswered planned meal has no matched
/// entry and no "Skipped" answer.
public enum PlanEditing {
    public static func canChangeOrDelete(hasMatchedEntry: Bool, hasSkippedAnswer: Bool) -> Bool {
        !hasMatchedEntry && !hasSkippedAnswer
    }
}
