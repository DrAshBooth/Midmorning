import XCTest
import Constants
@testable import Programme

/// Covers the pending-card scenarios of programme spec.md, "A stage opening
/// shows one card" (mm-t21.10), "Two stage 1 cards come to Today" (mm-t21.13)
/// and "A card when the plan is not set" (mm-t21.14). The barring composition
/// with `Record`'s `TodayCardSlot` — "No opening card after a binge in the
/// same record day" (mm-t21.12) and this bead's own starred-entry scenario —
/// lives in `RecordTests.PendingCardsCompositionTests`.
final class PendingCardsTests: XCTestCase {
    private func pending(
        entries: [EntryFact] = [], openings: [StageOpenedRecord] = [], cardAnswers: Set<String> = [],
        stagesWithToolInBuild: Set<Int> = [1, 2], hasTemplate: Bool = true,
        now: Date, currentRecordDay: String, settings: ProgrammeSettings = defaultSettings, constants: ProgrammeConstants = .default
    ) -> (state: ProgrammeState, cards: [PendingCard]) {
        let state = StageEngine.state(facts: ProgrammeFacts(entries: entries), openings: openings, settings: settings, constants: constants, now: now, restartAt: nil, currentRecordDay: currentRecordDay, calendar: engineTestCalendar)
        let cards = StageEngine.pendingCards(state: state, facts: ProgrammeFacts(entries: entries), cardAnswers: cardAnswers, stagesWithToolInBuild: stagesWithToolInBuild, hasTemplate: hasTemplate, currentRecordDay: currentRecordDay, settings: settings, calendar: engineTestCalendar)
        return (state, cards)
    }

    // MARK: mm-t21.10, "A stage opening shows one card"

    /// Scenario: Stage 2 opens.
    func testStage2Opens() {
        let entries = (0..<5).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 13)) }
        let (state, cards) = pending(entries: entries, now: moment(2026, 10, 3, 14), currentRecordDay: dayKey(2026, 10, 3))
        XCTAssertTrue(state.isOpen(.regularEating))
        XCTAssertEqual(cards.filter { $0.kind == .opening }, [PendingCard(id: "opening.2", kind: .opening, becameDueAt: moment(2026, 10, 3, 13))])
    }

    /// Scenario: Close. Answering the card takes it out of the pending list.
    func testClose() {
        let entries = (0..<5).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 9, 29 + i), starred: false, savedAt: moment(2026, 9, 29 + i, 13)) }
        let (_, cards) = pending(entries: entries, cardAnswers: ["opening.2"], now: moment(2026, 10, 3, 14), currentRecordDay: dayKey(2026, 10, 3))
        XCTAssertTrue(cards.filter { $0.kind == .opening }.isEmpty)
    }

    /// A build without a stage's own tool shows no opening card for it, from
    /// the "A stage opening shows one card" rule: "the app writes the
    /// StageOpened rows of stages 3 to 7 and shows no new card". The card at
    /// the tool's own first launch is `deferred: mm-t31.15` (stage 3).
    func testNoOpeningCardForAStageWithoutItsToolInTheBuild() {
        let openings = [StageOpenedRecord(stage: 3, moment: moment(2026, 10, 1, 4))]
        let (_, cards) = pending(openings: openings, now: moment(2026, 10, 2), currentRecordDay: dayKey(2026, 10, 2))
        XCTAssertTrue(cards.filter { $0.kind == .opening }.isEmpty)
    }

    // MARK: mm-t21.13, "Two stage 1 cards come to Today"

    /// Scenario: The second recorded day.
    func testTheSecondRecordedDay() {
        let entries = [
            EntryFact(id: "1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 9)),
            EntryFact(id: "2", dayKey: dayKey(2026, 10, 2), starred: false, savedAt: moment(2026, 10, 2, 12, 40)),
        ]
        let (_, cards) = pending(entries: entries, now: moment(2026, 10, 2, 13), currentRecordDay: dayKey(2026, 10, 2))
        XCTAssertEqual(cards.filter { $0.kind == .stage1 }, [PendingCard(id: "stage1.why", kind: .stage1, becameDueAt: moment(2026, 10, 2, 12, 40))])
    }

    /// Scenario: The fourth recorded day.
    func testTheFourthRecordedDay() {
        let entries = (1...4).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, i), starred: false, savedAt: moment(2026, 10, i, 9)) }
        let (_, cards) = pending(entries: entries, cardAnswers: ["stage1.why"], now: moment(2026, 10, 4, 10), currentRecordDay: dayKey(2026, 10, 4))
        XCTAssertEqual(cards.filter { $0.kind == .stage1 }, [PendingCard(id: "stage1.cycle", kind: .stage1, becameDueAt: moment(2026, 10, 4, 9))])
    }

    /// Scenario: Read. Answering "Why write it down" takes it off Today.
    func testRead() {
        let entries = [EntryFact(id: "1", dayKey: dayKey(2026, 10, 1), starred: false, savedAt: moment(2026, 10, 1, 9)), EntryFact(id: "2", dayKey: dayKey(2026, 10, 2), starred: false, savedAt: moment(2026, 10, 2, 9))]
        let (_, cards) = pending(entries: entries, cardAnswers: ["stage1.why"], now: moment(2026, 10, 2, 10), currentRecordDay: dayKey(2026, 10, 2))
        XCTAssertTrue(cards.filter { $0.id == "stage1.why" }.isEmpty)
    }

    /// Scenario: Close. "How it keeps itself going" leaves Today; the card
    /// itself stays part of the stage 1 card list `content` builds — this
    /// bead only ever suppresses Today's own pending-card slot, never a
    /// stage's card list.
    func testCloseHowItKeepsItselfGoing() {
        let entries = (1...4).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, i), starred: false, savedAt: moment(2026, 10, i, 9)) }
        let (_, cards) = pending(entries: entries, cardAnswers: ["stage1.why", "stage1.cycle"], now: moment(2026, 10, 4, 10), currentRecordDay: dayKey(2026, 10, 4))
        XCTAssertTrue(cards.filter { $0.kind == .stage1 }.isEmpty)
    }

    /// Scenario: Stage 2 opens first.
    func testStage2OpensFirst() {
        var constants = ProgrammeConstants.default
        constants.recordedDaysForStage2 = 3
        let entries = (1...4).map { i in EntryFact(id: "\(i)", dayKey: dayKey(2026, 10, i), starred: false, savedAt: moment(2026, 10, i, 9)) }
        let (state, cards) = pending(entries: entries, cardAnswers: ["stage1.why"], now: moment(2026, 10, 4, 10), currentRecordDay: dayKey(2026, 10, 4), constants: constants)
        XCTAssertTrue(state.isOpen(.regularEating))
        XCTAssertTrue(cards.filter { $0.id == "stage1.cycle" }.isEmpty, "no 'How it keeps itself going' card once stage 2 is open")
    }

    // MARK: mm-t21.14, "A card when the plan is not set"

    /// Scenario: Three record days without a template.
    func testThreeRecordDaysWithoutATemplate() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let (_, cards) = pending(openings: openings, hasTemplate: false, now: moment(2026, 10, 8, 8), currentRecordDay: dayKey(2026, 10, 8))
        XCTAssertEqual(cards.filter { $0.kind == .plan }.map(\.id), ["plancard.3"])
    }

    /// Scenario: Set it up. Answering the plan card takes it off Today.
    func testSetItUp() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let (_, cards) = pending(openings: openings, cardAnswers: ["plancard.3"], hasTemplate: false, now: moment(2026, 10, 8, 8), currentRecordDay: dayKey(2026, 10, 8))
        XCTAssertTrue(cards.filter { $0.kind == .plan }.isEmpty)
    }

    /// Scenario: Ten record days without a template.
    func testTenRecordDaysWithoutATemplate() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let (_, cards) = pending(openings: openings, cardAnswers: ["plancard.3"], hasTemplate: false, now: moment(2026, 10, 15, 8), currentRecordDay: dayKey(2026, 10, 15))
        XCTAssertEqual(cards.filter { $0.kind == .plan }.map(\.id), ["plancard.10"])
    }

    /// Scenario: A template before day 10.
    func testATemplateBeforeDay10() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let (_, cards) = pending(openings: openings, cardAnswers: ["plancard.3"], hasTemplate: true, now: moment(2026, 10, 15, 8), currentRecordDay: dayKey(2026, 10, 15))
        XCTAssertTrue(cards.filter { $0.kind == .plan }.isEmpty)
    }

    /// Scenario: A template before day 3.
    func testATemplateBeforeDay3() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let day8 = pending(openings: openings, hasTemplate: true, now: moment(2026, 10, 8, 8), currentRecordDay: dayKey(2026, 10, 8)).cards
        let day15 = pending(openings: openings, hasTemplate: true, now: moment(2026, 10, 15, 8), currentRecordDay: dayKey(2026, 10, 15)).cards
        XCTAssertTrue(day8.filter { $0.kind == .plan }.isEmpty)
        XCTAssertTrue(day15.filter { $0.kind == .plan }.isEmpty)
    }

    /// Scenario: The first Today load after a missed day.
    func testTheFirstTodayLoadAfterAMissedDay() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let (_, cards) = pending(openings: openings, hasTemplate: false, now: moment(2026, 10, 10, 8), currentRecordDay: dayKey(2026, 10, 10))
        XCTAssertEqual(cards.filter { $0.kind == .plan }.map(\.id), ["plancard.3"])
    }

    /// The first Today load is on day 11 (code review of 26 September 2026,
    /// mm-t21.32). The day-10 card shows; after "Close" no plan card comes
    /// back as the day-3 card ("Each of the two cards returns no more after
    /// either control.").
    func testAFirstLoadOnDay11ThenCloseShowsNoPlanCard() {
        let openings = [StageOpenedRecord(stage: 2, moment: moment(2026, 10, 5, 9))]
        let first = pending(openings: openings, hasTemplate: false, now: moment(2026, 10, 16, 8), currentRecordDay: dayKey(2026, 10, 16)).cards
        XCTAssertEqual(first.filter { $0.kind == .plan }.map(\.id), ["plancard.10"])
        let afterClose = pending(openings: openings, cardAnswers: ["plancard.10"], hasTemplate: false, now: moment(2026, 10, 16, 9), currentRecordDay: dayKey(2026, 10, 16)).cards
        XCTAssertTrue(afterClose.filter { $0.kind == .plan }.isEmpty)
    }

    /// `PendingCard.openingStage` parses the stage back out of an opening
    /// card's own id, the App target's seam for pushing that stage's screen
    /// on "Open" (programme spec, "A stage opening shows one card": "'Open'
    /// MUST show the stage on the Programme screen.").
    func testOpeningStageParsesTheIdAndOnlyForOpeningCards() {
        XCTAssertEqual(PendingCard(id: "opening.3", kind: .opening, becameDueAt: .now).openingStage, .alternatives)
        XCTAssertNil(PendingCard(id: "stage1.why", kind: .stage1, becameDueAt: .now).openingStage)
        XCTAssertNil(PendingCard(id: "plancard.3", kind: .plan, becameDueAt: .now).openingStage)
    }
}
