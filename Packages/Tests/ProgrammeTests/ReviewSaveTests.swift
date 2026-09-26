import XCTest
@testable import Programme

/// The rules for what one save writes into a review's row (code review of
/// 26 September 2026: mm-t32.19, mm-t32.20, mm-t32.21, mm-t32.22). The App
/// target's `WeeklyReviewModel.save` and
/// `WeeklyReviewModel.opensWithDeteriorationPage` call these functions;
/// `RecordTests.ReviewSaveStoreTests` runs them over the real store.
final class ReviewSaveTests: XCTestCase {
    private let startDay = dayKey(2026, 9, 28)

    private func finishedRow(note: String, selfHarmAnswered: Bool = true) -> ReviewRowValues {
        var payload = ReviewAnswersPayload(finished: true)
        payload.oneThingToChange = note
        payload.frozenCounts = FrozenReviewCounts(daysWithEntry: 5, starred: 2, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
        return ReviewRowValues(answersJSON: payload.encoded(), selfHarmAnswered: selfHarmAnswered, pinnedNote: note)
    }

    private func frozenRow() -> ReviewRowValues {
        var payload = ReviewAnswersPayload()
        payload.frozenCounts = FrozenReviewCounts(daysWithEntry: 5, starred: 2, plan: nil, paused: 0, urges: 0, urgesPassed: 0)
        return ReviewRowValues(answersJSON: payload.encoded(), selfHarmAnswered: false, pinnedNote: "")
    }

    // MARK: mm-t32.19, "I'm getting worse" saves the answers so far only

    /// Scenario: Tap it ("I'm getting worse"). The answers so far are kept;
    /// the review stays unfinished and the row's pinned note stays empty.
    func testAnswersSoFarKeepsAnUnfinishedReviewUnfinished() {
        let result = ReviewSave.values(
            existing: frozenRow(), mode: .answersSoFar, week: 2, runStartDay: startDay,
            reflectionAnswers: ["", "Evenings were hard", ""], oneThingToChange: "Half typed", weekOneAnswers: nil,
            selfHarmStepOneAnswered: false
        )
        let payload = ReviewAnswersPayload.decode(result.answersJSON)
        XCTAssertFalse(payload.finished, "only Done finishes the review")
        XCTAssertEqual(result.pinnedNote, "", "only Done moves the one thing to change onto the pinned note")
        XCTAssertEqual(payload.reflectionAnswers, ["", "Evenings were hard", ""], "the store keeps the answers so far")
        XCTAssertEqual(payload.oneThingToChange, "Half typed", "the field shows again with its text when the page closes")
        XCTAssertEqual(payload.frozenCounts?.starred, 2, "the frozen counts stay")
    }

    /// A reopened finished review keeps its finished flag and its pinned
    /// note when the person taps "I'm getting worse" after an edit.
    func testAnswersSoFarKeepsAFinishedReviewAndItsPinnedNote() {
        let result = ReviewSave.values(
            existing: finishedRow(note: "Eat lunch at work"), mode: .answersSoFar, week: 2, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: nil,
            selfHarmStepOneAnswered: false
        )
        XCTAssertTrue(ReviewAnswersPayload.decode(result.answersJSON).finished)
        XCTAssertEqual(result.pinnedNote, "Eat lunch at work", "the pinned note stays until the person taps Done")
    }

    /// Scenario: A pinned note appears. "Done" finishes the review and
    /// mirrors the field onto the pinned note.
    func testDoneFinishesAndPinsTheNote() {
        let result = ReviewSave.values(
            existing: frozenRow(), mode: .done, week: 2, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "Eat lunch at work", weekOneAnswers: nil,
            selfHarmStepOneAnswered: true
        )
        XCTAssertTrue(ReviewAnswersPayload.decode(result.answersJSON).finished)
        XCTAssertEqual(result.pinnedNote, "Eat lunch at work")
        XCTAssertTrue(result.selfHarmAnswered)
    }

    /// Scenario: The next review leaves it empty.
    func testDoneWithAnEmptyFieldClearsTheRowsNote() {
        let result = ReviewSave.values(
            existing: finishedRow(note: "Eat lunch at work"), mode: .done, week: 2, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: nil,
            selfHarmStepOneAnswered: false
        )
        XCTAssertEqual(result.pinnedNote, "")
    }

    // MARK: mm-t32.20, a reopen keeps selfHarmAnswered

    /// Scenario: Answer No, then reopen and tap "Done". The screen hides the
    /// item, so step 1 has no answer on this visit; the row keeps `true`.
    func testAReopenKeepsSelfHarmAnswered() {
        for mode in [ReviewSave.Mode.done, .answersSoFar] {
            let result = ReviewSave.values(
                existing: finishedRow(note: "", selfHarmAnswered: true), mode: mode, week: 2, runStartDay: startDay,
                reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: nil,
                selfHarmStepOneAnswered: false
            )
            XCTAssertTrue(result.selfHarmAnswered, "the app MUST NOT ask the item again (\(mode))")
        }
    }

    /// Scenario: Done with no answer.
    func testDoneWithNoAnswerKeepsFalse() {
        let result = ReviewSave.values(
            existing: frozenRow(), mode: .done, week: 2, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: nil,
            selfHarmStepOneAnswered: false
        )
        XCTAssertFalse(result.selfHarmAnswered)
    }

    // MARK: mm-t32.21, the deterioration page at most once per review

    /// Scenario: Three rising weeks. The page shows once; the flag in the
    /// row stops it on a reopen.
    func testTheDeteriorationPageShowsOncePerReview() {
        let row = frozenRow()
        XCTAssertTrue(ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: [2, 3, 4, 5], reviewAnswersJSON: row.answersJSON))
        let marked = ReviewSave.deteriorationPageShown(existing: row)
        XCTAssertFalse(ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: [2, 3, 4, 5], reviewAnswersJSON: marked.answersJSON), "a reopen does not show it again")
        XCTAssertEqual(ReviewAnswersPayload.decode(marked.answersJSON).frozenCounts, ReviewAnswersPayload.decode(row.answersJSON).frozenCounts)
        XCTAssertEqual(marked.selfHarmAnswered, row.selfHarmAnswered)
        XCTAssertEqual(marked.pinnedNote, row.pinnedNote)
    }

    /// A later save keeps the flag, so "Done" after the page does not
    /// reopen the gate.
    func testASaveAfterThePageKeepsTheFlag() {
        let marked = ReviewSave.deteriorationPageShown(existing: frozenRow())
        let saved = ReviewSave.values(
            existing: marked, mode: .done, week: 5, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: nil,
            selfHarmStepOneAnswered: true
        )
        XCTAssertFalse(ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: [2, 3, 4, 5], reviewAnswersJSON: saved.answersJSON))
    }

    /// Scenario: Rising but small. No page, and the gate reads the rule.
    func testTheGateReadsTheRule() {
        XCTAssertFalse(ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: [0, 1, 2, 3], reviewAnswersJSON: frozenRow().answersJSON))
        XCTAssertEqual(ReviewDeteriorationGate.countsNeeded(), 4, "DETERIORATION_WEEKS + 1")
    }

    /// An older payload with no new field still decodes, so no answer is
    /// lost when the app reads a row from before this change.
    func testAnOlderPayloadStillDecodes() {
        let older = #"{"finished":true,"reflectionAnswers":["a","b","c"],"oneThingToChange":"x"}"#
        let payload = ReviewAnswersPayload.decode(older)
        XCTAssertTrue(payload.finished)
        XCTAssertEqual(payload.reflectionAnswers, ["a", "b", "c"])
        XCTAssertNil(payload.runStartDay)
        XCTAssertNil(payload.deteriorationPageShown)
    }

    // MARK: mm-t32.22, the run start day

    /// Each save writes the run start day into the row once.
    func testASaveWritesTheRunStartDay() {
        let result = ReviewSave.values(
            existing: nil, mode: .done, week: 1, runStartDay: startDay,
            reflectionAnswers: ["", "", ""], oneThingToChange: "", weekOneAnswers: ["", "", ""],
            selfHarmStepOneAnswered: false
        )
        XCTAssertEqual(ReviewAnswersPayload.decode(result.answersJSON).runStartDay, startDay)
    }
}
