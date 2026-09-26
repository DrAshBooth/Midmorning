import Foundation
import Constants

/// The three fields of a `Review` row that the review writes, apart from
/// its key, its freeze moment and its `changedAt`. `Programme` does not
/// import `Record`, so the App target maps `RecordStore.ReviewRow` onto
/// this value and back (`WeeklyReviewModel`).
public struct ReviewRowValues: Sendable, Equatable {
    public var answersJSON: String
    public var selfHarmAnswered: Bool
    public var pinnedNote: String

    public init(answersJSON: String, selfHarmAnswered: Bool, pinnedNote: String) {
        self.answersJSON = answersJSON
        self.selfHarmAnswered = selfHarmAnswered
        self.pinnedNote = pinnedNote
    }
}

/// What one save of the review writes into its row (weekly-review spec,
/// "Finish and reopen a review", "The one thing to change and the pinned
/// note", "The self-harm item at the review", "\"I'm getting worse\"").
/// `WeeklyReviewModel` reads the row, calls this function and writes the
/// result, so every rule about the row's content is here, where a test on
/// macOS can reach it.
public enum ReviewSave {
    public enum Mode: Sendable, Equatable {
        /// "Done": the review is finished, and the one thing to change
        /// becomes the row's pinned note.
        case done
        /// "I'm getting worse", or "Yes" then "Yes" at the self-harm item:
        /// the app saves the answers so far. The review stays as finished
        /// or unfinished as it was, and the pinned note stays until the
        /// person taps "Done" ("The pinned note MUST stay until the person
        /// taps 'Done' on the next review.").
        case answersSoFar
    }

    /// The row after a save. `existing` is the row the store holds for the
    /// review's key, or `nil`. `selfHarmStepOneAnswered` is `true` when the
    /// person answered step 1 on this visit. A row that already holds
    /// `selfHarmAnswered: true` keeps it ("When step 1 has an answer, the
    /// store MUST keep `selfHarmAnswered: true` for the review.").
    public static func values(
        existing: ReviewRowValues?,
        mode: Mode,
        week: Int,
        runStartDay: String,
        reflectionAnswers: [String],
        oneThingToChange: String,
        weekOneAnswers: [String]?,
        selfHarmStepOneAnswered: Bool
    ) -> ReviewRowValues {
        var payload = existing.map { ReviewAnswersPayload.decode($0.answersJSON) } ?? ReviewAnswersPayload()
        payload.reflectionAnswers = reflectionAnswers
        payload.oneThingToChange = oneThingToChange
        if week == 1, let weekOneAnswers { payload.weekOneAnswers = weekOneAnswers }
        if payload.runStartDay == nil { payload.runStartDay = runStartDay }

        let pinnedNote: String
        switch mode {
        case .done:
            payload.finished = true
            pinnedNote = oneThingToChange
        case .answersSoFar:
            pinnedNote = existing?.pinnedNote ?? ""
        }
        return ReviewRowValues(
            answersJSON: payload.encoded(),
            selfHarmAnswered: (existing?.selfHarmAnswered ?? false) || selfHarmStepOneAnswered,
            pinnedNote: pinnedNote
        )
    }

    /// The row after the deterioration rule shows the GP suggestion page for
    /// the first time in this review. Every other field stays as it was.
    public static func deteriorationPageShown(existing: ReviewRowValues) -> ReviewRowValues {
        var payload = ReviewAnswersPayload.decode(existing.answersJSON)
        payload.deteriorationPageShown = true
        return ReviewRowValues(answersJSON: payload.encoded(), selfHarmAnswered: existing.selfHarmAnswered, pinnedNote: existing.pinnedNote)
    }
}

/// The once-per-review gate on the deterioration rule (weekly-review spec,
/// "The deterioration rule at the review": "The app MUST show the page from
/// the rule at most once per review."). The gate reads the review's own
/// row, not the screen's state, so a reopen from Today, from the "Reviews"
/// list or from the reminder does not show the page again.
public enum ReviewDeteriorationGate {
    /// The number of frozen starred counts the rule reads: the review's own
    /// week and the `DETERIORATION_WEEKS` weeks before it.
    public static func countsNeeded(constants: ProgrammeConstants = .default) -> Int {
        constants.deteriorationWeeks + 1
    }

    /// `true` when the review opens with the GP suggestion page from the
    /// rule: the rule fires, and this review did not show the page before.
    public static func showsPage(
        lastFrozenStarredCounts counts: [Int],
        reviewAnswersJSON: String,
        constants: ProgrammeConstants = .default
    ) -> Bool {
        guard ReviewAnswersPayload.decode(reviewAnswersJSON).deteriorationPageShown != true else { return false }
        return DeteriorationRule.fires(lastFrozenStarredCounts: counts, constants: constants)
    }
}
