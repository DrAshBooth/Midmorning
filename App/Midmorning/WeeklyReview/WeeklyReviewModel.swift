import Foundation
import Record
import Programme

/// The one seam the App target uses to build and save the weekly review
/// (`v1-programme/design.md`, "Pure seams the packages expose"). Gathers
/// `Programme.ReviewWeekFacts` from `RecordStore` and `Plan`'s own match
/// (through `PlanToday.load`, the same seam `DaySection` uses), then calls
/// `Programme`'s pure review functions. `TodayView`, `ReviewScreenView` and
/// `ReviewsListView` all go through this.
@MainActor
enum WeeklyReviewModel {
    /// "It passed" is `urge-toolkit`'s own outcome vocabulary (not yet
    /// built); `weekly-review`'s own summary reads only this one value.
    private static let passedOutcome = "It passed"

    struct Snapshot {
        /// The week whose "Weekly review" line Today shows, or `nil`.
        let dueWeek: Int?
        let dueDayKey: String?
        let startDay: String
        let calendar: Calendar
        let pinnedNote: String?
        /// The review whose note is pinned, with its own run's start day,
        /// so a tap on the note opens that review also after a restart
        /// (weekly-review spec, "Edit from Today").
        let pinnedNoteReview: ReviewRunWeek?
        /// `true` from the moment the first weekly review becomes due
        /// (record spec, "The Today stack": "'Reviews', from the moment the
        /// first weekly review becomes due").
        let reviewsControlShows: Bool
        /// The latest week whose review is due, finished or not, or `nil`
        /// before the first review is due. A tap on the weekly review
        /// reminder opens this week (reminders spec, "The weekly review
        /// reminder").
        let latestDueWeek: Int?
    }

    static func load(store: RecordStore, now: Date, calendar: Calendar = .current) -> Snapshot {
        let currentRecordDay = RecordDay.key(containing: now, calendar: calendar, schedule: (try? store.dayStartSchedule()) ?? .standard)
        let startDay = (try? store.startDayKey()) ?? currentRecordDay
        freezeAllDueWeeks(store: store, startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar, now: now)
        let dueWeek = ReviewDue.todayLineWeek(
            startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar,
            isFinished: { week in isFinished(store: store, week: week, startDay: startDay, calendar: calendar, now: now) }
        )
        let dueDayKey = dueWeek.map { ReviewDue.dueDayKey(week: $0, startDay: startDay, calendar: calendar) }
        let latestDueWeek = ReviewDue.latestDueWeek(startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar)
        let reviewsControlShows = latestDueWeek != nil
        let (note, noteReview) = currentPinnedNoteAndReview(store: store, startDay: startDay, calendar: calendar, now: now)
        return Snapshot(
            dueWeek: dueWeek, dueDayKey: dueDayKey, startDay: startDay, calendar: calendar,
            pinnedNote: note, pinnedNoteReview: noteReview, reviewsControlShows: reviewsControlShows,
            latestDueWeek: latestDueWeek
        )
    }

    /// Freezes every week whose review has become due and is not yet frozen
    /// (weekly-review spec, "The week's counts are frozen in the Review
    /// row": "The app MUST write the counts whether or not the person opens
    /// the review."). Idempotent and cheap once every week is frozen.
    static func freezeAllDueWeeks(store: RecordStore, startDay: String, currentRecordDay: String, calendar: Calendar, now: Date) {
        guard let latest = ReviewDue.latestDueWeek(startDay: startDay, currentRecordDay: currentRecordDay, calendar: calendar) else { return }
        for week in 1...latest {
            freezeIfNeeded(store: store, week: week, startDay: startDay, calendar: calendar, now: now)
        }
    }

    static func isFinished(store: RecordStore, week: Int, startDay: String, calendar: Calendar, now: Date) -> Bool {
        let dueDayKey = ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar)
        guard let row = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: now, calendar: calendar) else { return false }
        return ReviewAnswersPayload.decode(row.answersJSON).finished
    }

    /// The latest finished review's own pinned-note text and its review
    /// (weekly-review spec, "The one thing to change and the pinned note"):
    /// "The pinned note MUST stay until the person taps 'Done' on the next
    /// review."
    private static func currentPinnedNoteAndReview(store: RecordStore, startDay: String, calendar: Calendar, now: Date) -> (String?, ReviewRunWeek?) {
        guard let winners = try? store.reviewRowWinners(kind: .weeklyReview, now: now, calendar: calendar) else { return (nil, nil) }
        guard let latest = winners
            .filter({ ReviewAnswersPayload.decode($0.answersJSON).finished })
            .max(by: { $0.dueDateKey < $1.dueDateKey })
        else { return (nil, nil) }
        guard !latest.pinnedNote.isEmpty else { return (nil, nil) }
        return (latest.pinnedNote, runWeeks(winners, currentStartDay: startDay, calendar: calendar)[latest.dueDateKey])
    }

    /// Every stored review's run and week (`ReviewRuns`), so that a review
    /// from before a restart keeps its own week number.
    static func runWeeks(_ winners: [RecordStore.ReviewRow], currentStartDay: String, calendar: Calendar) -> [String: ReviewRunWeek] {
        let rows = winners.map { ReviewRuns.Row(dueDayKey: $0.dueDateKey, runStartDay: ReviewAnswersPayload.decode($0.answersJSON).runStartDay) }
        return ReviewRuns.runWeeks(rows: rows, currentStartDay: currentStartDay, calendar: calendar)
    }

    /// Whether Today MUST hold back the pinned note for the rest of this
    /// record day (decision 90; the same predicate `TodayCardSlot` uses for
    /// the card slot).
    static func pinnedNoteHeld(starredEntryOrOutcomeAt: Date?, currentRecordDay: DateInterval) -> Bool {
        PinnedNoteHold.isHeld(starredEntryOrOutcomeAt: starredEntryOrOutcomeAt, currentRecordDay: currentRecordDay)
    }

    // MARK: One week's facts

    /// Gathers `week`'s facts from the real store: entries, day states, the
    /// plan's own match (reusing `PlanToday.load`, Today's own seam), urges
    /// and the weigh-in.
    static func weekFacts(store: RecordStore, week: Int, startDay: String, calendar: Calendar, now: Date) -> ReviewWeekFacts {
        let weekDayKeys = ReviewDue.weekDayKeys(week: week, startDay: startDay, calendar: calendar)

        var entries: [ReviewEntryFact] = []
        var exemptDayKeys: Set<String> = []
        var pausedDayKeys: Set<String> = []
        var closeTheDayWords: [String: String] = [:]
        var anyPlannedDay = false
        var plannedMatchedCount = 0

        for dayKey in weekDayKeys {
            let dayEntries = (try? store.entries(dayKey: dayKey)) ?? []
            entries.append(contentsOf: dayEntries.map { ReviewEntryFact(dayKey: $0.dayKey, time: $0.time, starred: $0.feltLikeABinge) })

            let states = (try? store.dayStates(dateKey: dayKey)) ?? []
            if states.contains(.didntRecord) || states.contains(.fasting) { exemptDayKeys.insert(dayKey) }
            if states.contains(.paused) { pausedDayKeys.insert(dayKey) }

            if let word = try? store.feelingWord(dateKey: dayKey), !word.isEmpty {
                closeTheDayWords[dayKey] = word
            }

            let dayStartHour = (try? store.dayStartHour(effectiveOn: dayKey)) ?? RecordDay.startHour
            if let interval = Self.interval(forDayKey: dayKey, dayStartHour: dayStartHour, calendar: calendar) {
                let plan = PlanToday.load(dateKey: dayKey, recordDay: interval, store: store, entries: dayEntries, now: interval.start, calendar: calendar)
                if !plan.rows.isEmpty {
                    anyPlannedDay = true
                    plannedMatchedCount += plan.matchedEntryIds.count
                }
            }
        }

        let weekDaySet = Set(weekDayKeys)
        let urgeDetails = ((try? store.urgeOutcomeDetails()) ?? []).filter { weekDaySet.contains($0.dayKey) }
        let weighInDayChosen: Bool
        if case .weekday = try? store.weighInDayChoice() { weighInDayChosen = true } else { weighInDayChosen = false }
        let weighInDayKey = ReviewWeekFacts.weighInDoneDayKey(
            weighInDayKeys: ((try? store.weighIns()) ?? []).map(\.dateKey), weekDayKeys: weekDayKeys, weighInDayChosen: weighInDayChosen
        )

        var previousWeekFrozenStarred: Int? = nil
        if week > 1 {
            let previousDueDayKey = ReviewDue.dueDayKey(week: week - 1, startDay: startDay, calendar: calendar)
            if let previousRow = try? store.review(kind: .weeklyReview, dueDateKey: previousDueDayKey, now: now, calendar: calendar) {
                previousWeekFrozenStarred = ReviewAnswersPayload.decode(previousRow.answersJSON).frozenCounts?.starred
            }
        }

        return ReviewWeekFacts(
            weekDayKeys: weekDayKeys,
            entries: entries,
            exemptDayKeys: exemptDayKeys,
            pausedDayKeys: pausedDayKeys,
            plannedMealsWithEntryCount: anyPlannedDay ? plannedMatchedCount : nil,
            urgesCount: urgeDetails.count,
            urgesPassedCount: urgeDetails.filter { $0.outcome == passedOutcome }.count,
            weighInDoneDayKey: weighInDayKey,
            closeTheDayWordsByDayKey: closeTheDayWords,
            previousWeekFrozenStarred: previousWeekFrozenStarred
        )
    }

    /// The review's opening summary, or `[]` when "Weekly summary" is off.
    static func summary(store: RecordStore, week: Int, startDay: String, calendar: Calendar, now: Date) -> [String] {
        guard (try? store.weeklySummaryOn()) ?? true else { return [] }
        return ReviewSummary.parts(weekFacts(store: store, week: week, startDay: startDay, calendar: calendar, now: now), calendar: calendar)
    }

    /// Freezes `week`'s review when it is ready (weekly-review spec, "The
    /// week's counts are frozen in the Review row"). Call on every Today
    /// load and whenever the review or the Reviews list opens.
    static func freezeIfNeeded(store: RecordStore, week: Int, startDay: String, calendar: Calendar, now: Date) {
        let dueDayKey = ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar)
        guard (try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: now, calendar: calendar)) == nil else { return }
        let syncOn = (try? store.syncOn()) ?? false
        guard ReviewFreeze.readyToFreeze(dueDayKey: dueDayKey, dayStart: (try? store.dayStartHour(effectiveOn: dueDayKey)) ?? RecordDay.startHour, calendar: calendar, now: now, syncOn: syncOn, lastSyncMoment: nil) else { return }
        let facts = weekFacts(store: store, week: week, startDay: startDay, calendar: calendar, now: now)
        var payload = ReviewAnswersPayload()
        payload.frozenCounts = FrozenReviewCounts.from(facts)
        payload.runStartDay = startDay
        try? store.upsertReview(kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: now, answersJSON: payload.encoded(), selfHarmAnswered: false, pinnedNote: "", changedAt: now)
    }

    /// Saves `week`'s review: merges the person's own answers into the row
    /// the store already holds for that key (the frozen counts, when
    /// present). `ReviewSave` holds the rules: "Done" sets `finished` and
    /// mirrors "the one thing to change" onto the row's own `pinnedNote`;
    /// "I'm getting worse" and the self-harm "Yes" then "Yes" save the
    /// answers so far and change neither. A row that holds
    /// `selfHarmAnswered: true` keeps it.
    @discardableResult
    static func save(
        _ mode: ReviewSave.Mode, store: RecordStore, week: Int, startDay: String, calendar: Calendar,
        reflectionAnswers: [String], oneThingToChange: String, weekOneAnswers: [String]?,
        selfHarmFirst: SelfHarmFirstAnswer?, now: Date
    ) -> RecordStore.ReviewRow? {
        let dueDayKey = ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar)
        let existing = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: now, calendar: calendar)
        let values = ReviewSave.values(
            existing: existing.map(rowValues), mode: mode, week: week, runStartDay: startDay,
            reflectionAnswers: reflectionAnswers, oneThingToChange: oneThingToChange, weekOneAnswers: weekOneAnswers,
            selfHarmStepOneAnswered: selfHarmFirst != nil
        )
        return try? store.upsertReview(
            kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: existing?.frozenAt, answersJSON: values.answersJSON,
            selfHarmAnswered: values.selfHarmAnswered, pinnedNote: values.pinnedNote, changedAt: now
        )
    }

    /// Whether `week`'s review opens with the GP suggestion page from the
    /// deterioration rule (weekly-review spec, "The deterioration rule at
    /// the review"). Reads the frozen starred counts of the review's week
    /// and the `DETERIORATION_WEEKS` weeks before it. When the page shows,
    /// writes the flag into the review's own row, so a reopen of the same
    /// review does not show it again ("at most once per review").
    static func opensWithDeteriorationPage(store: RecordStore, week: Int, startDay: String, calendar: Calendar, now: Date) -> Bool {
        let needed = ReviewDeteriorationGate.countsNeeded()
        guard week >= needed else { return false }
        var counts: [Int] = []
        for checkedWeek in (week - needed + 1)...week {
            let dueDayKey = ReviewDue.dueDayKey(week: checkedWeek, startDay: startDay, calendar: calendar)
            guard let row = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: now, calendar: calendar),
                  let starred = ReviewAnswersPayload.decode(row.answersJSON).frozenCounts?.starred
            else { return false }
            counts.append(starred)
        }
        let dueDayKey = ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar)
        guard let current = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey, now: now, calendar: calendar),
              ReviewDeteriorationGate.showsPage(lastFrozenStarredCounts: counts, reviewAnswersJSON: current.answersJSON)
        else { return false }
        let marked = ReviewSave.deteriorationPageShown(existing: rowValues(current))
        try? store.upsertReview(
            kind: .weeklyReview, dueDateKey: dueDayKey, frozenAt: current.frozenAt, answersJSON: marked.answersJSON,
            selfHarmAnswered: marked.selfHarmAnswered, pinnedNote: marked.pinnedNote, changedAt: now
        )
        return true
    }

    private static func rowValues(_ row: RecordStore.ReviewRow) -> ReviewRowValues {
        ReviewRowValues(answersJSON: row.answersJSON, selfHarmAnswered: row.selfHarmAnswered, pinnedNote: row.pinnedNote)
    }

    /// Every finished review, newest first, for the "Reviews" list.
    struct ReviewListRow: Identifiable {
        var id: String { dueDayKey }
        let dueDayKey: String
        /// The review's week and its own run's start day, so a row from
        /// before a restart opens its own review.
        let review: ReviewRunWeek
        let text: String
    }

    static func reviewsListRows(store: RecordStore, calendar: Calendar, now: Date) -> [ReviewListRow] {
        let startDay = (try? store.startDayKey()) ?? RecordDay.key(containing: now, calendar: calendar, schedule: (try? store.dayStartSchedule()) ?? .standard)
        let summaryOn = (try? store.weeklySummaryOn()) ?? true
        let allWinners = (try? store.reviewRowWinners(kind: .weeklyReview, now: now, calendar: calendar)) ?? []
        let runs = runWeeks(allWinners, currentStartDay: startDay, calendar: calendar)
        let winners = allWinners
            .filter { ReviewAnswersPayload.decode($0.answersJSON).finished }
            .sorted { $0.dueDateKey > $1.dueDateKey }
        return winners.compactMap { row -> ReviewListRow? in
            guard let review = runs[row.dueDateKey] else { return nil }
            let range = ReviewDue.weekRange(week: review.week, startDay: review.runStartDay, calendar: calendar)
            let dateRange = ReviewText.weekDateRangeText(firstDayKey: range.first, lastDayKey: range.last, calendar: calendar)
            let text: String
            if summaryOn, let starred = ReviewAnswersPayload.decode(row.answersJSON).frozenCounts?.starred {
                text = ReviewContent.rowText(week: review.week, dateRange: dateRange, starredCount: starred)
            } else {
                text = ReviewContent.rowTextWithoutCount(week: review.week, dateRange: dateRange)
            }
            return ReviewListRow(dueDayKey: row.dueDateKey, review: review, text: text)
        }
    }

    /// The record-day interval `dayKey` names, at `dayStartHour` — the
    /// moment one hour after that calendar date's own day start always
    /// falls inside it, since "Day starts at" only ever ranges 00:00 to
    /// 12:00 (settings spec, "The Reminders group").
    private static func interval(forDayKey dayKey: String, dayStartHour: Int, calendar: Calendar) -> DateInterval? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]; components.month = parts[1]; components.day = parts[2]
        components.hour = dayStartHour + 1
        guard let moment = calendar.date(from: components) else { return nil }
        return RecordDay.interval(containing: moment, calendar: calendar, startHour: dayStartHour)
    }
}
