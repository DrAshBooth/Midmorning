import Foundation

/// The fixed list of screening questions onboarding's screen 2 asks
/// (onboarding spec, "Screen 2: the screening questions"), and the words
/// none of them may use (safeguarding spec, "No question about vomiting or
/// laxatives": "The app MUST NOT ask about vomiting, laxatives, missed
/// medicine or any other compensation at onboarding... at a weekly review, a
/// check-in, taking stock or any other screen."). Keeping the catalog here,
/// not only in the App target's view, lets a `swift test` run prove the
/// constraint; the App target's screen renders this catalog and adds no
/// question of its own.
public enum ScreeningQuestionCatalog {
    /// One screening question's prompt, read by a test and by the screen.
    public static let questions: [String] = [
        "How old are you?",
        "Your height",
        "Your weight",
        "Are you getting help from a clinic or a therapist for your eating at the moment?",
        "We ask everyone the same questions. Pregnancy changes what eating needs to look like, so: are you pregnant at the moment?",
        "Over the last two weeks, have you had thoughts that you'd be better off dead, or of hurting yourself?",
    ]

    /// The self-harm item's second question, shown only after "Yes" to the
    /// first (safeguarding spec, "The self-harm item").
    public static let selfHarmSecondQuestion = "Have you thought about how you would do it?"

    /// Words the app never uses in a screening question, at onboarding, a
    /// weekly review, a check-in or any other screen.
    public static let bannedWords = ["vomit", "sick", "laxative", "medicine", "insulin", "compensat", "purge"]

    /// `true` when a question mentions a banned word. The one legitimate
    /// mention of some of these words is Get support's "Talk to your GP"
    /// sentence, which is not a question and lives in `SupportSheet`, not here.
    public static func mentionsCompensation(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return bannedWords.contains { lowered.contains($0) }
    }

    /// `true` when every question in the catalog, plus the self-harm item's
    /// second question, is free of a compensation word.
    public static func hasNoCompensationQuestion() -> Bool {
        !(questions + [selfHarmSecondQuestion]).contains { mentionsCompensation($0) }
    }
}
