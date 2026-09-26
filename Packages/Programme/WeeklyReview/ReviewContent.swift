import Foundation

/// The review's own fixed strings, quoted from the weekly-review spec.
/// `CommonLabels.done` is the "Done" control; this change adds no second
/// copy of it.
public enum ReviewContent {
    public static let reviewsListTitle = "Reviews"
    public static let noRowsAccessibilityHint = "No finished reviews yet"

    /// "What did you notice this week?", "What made things harder?" and
    /// "What helped?" — the three reflection questions, in this order,
    /// every week (weekly-review spec, "Three reflection questions").
    public static let reflectionQuestions: [String] = [
        "What did you notice this week?",
        "What made things harder?",
        "What helped?",
    ]

    /// The three week-1 questions, in order (weekly-review spec, "Week-1
    /// answers").
    public static let weekOneQuestions: [String] = [
        "What do you want to be different by week 12?",
        "What is hardest at the moment?",
        "When are the hardest times of day?",
    ]

    public static let oneThingToChangeQuestion = "What's the one thing to change next week?"

    public static let gettingWorseButton = "I'm getting worse"

    /// Shown in place of the self-harm item once the review already holds
    /// `selfHarmAnswered: true` (weekly-review spec, "The self-harm item at
    /// the review": "The review MUST show the item as answered.").
    public static let selfHarmAnsweredLine = "You answered this."
    public static let gettingWorseHint = "Opens a page about seeing your GP."

    public static let weeklySummarySwitchLabel = "Weekly summary"

    /// "Week %1$lld, %2$@. Starred entries: %3$lld." — a "Reviews" list row
    /// with the summary on.
    public static func rowText(week: Int, dateRange: String, starredCount: Int) -> String {
        "Week \(week), \(dateRange). Starred entries: \(starredCount)."
    }

    /// "Week %1$lld, %2$@" — a row with "Weekly summary" off.
    public static func rowTextWithoutCount(week: Int, dateRange: String) -> String {
        "Week \(week), \(dateRange)"
    }
}
