import SwiftUI
import Record
import Programme

/// The weekly review screen (weekly-review spec, "Finish and reopen a
/// review", "The summary built from the record", "Three reflection
/// questions", "The one thing to change and the pinned note", "The
/// self-harm item at the review", "\"I'm getting worse\"", "Week-1
/// answers", "Accessibility of the review"; decisions 94 and 95). Reached
/// from Today's "Weekly review" line and from the "Reviews" list.
struct ReviewScreenView: View {
    let store: RecordStore
    let week: Int
    var now: () -> Date = Date.init
    var calendar: Calendar = .current
    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var startDay = ""
    @State private var summary: [String] = []
    @State private var weekOneAnswers = ["", "", ""]
    @State private var reflectionAnswers = ["", "", ""]
    @State private var oneThingToChange = ""
    @State private var selfHarmFirst: SelfHarmFirstAnswer?
    @State private var selfHarmSecond: SelfHarmSecondAnswer?
    @State private var selfHarmAlreadyAnswered = false

    @State private var notRightNowReasons: [ExclusionReason]?
    @State private var gpSuggestionReasons: [GPSuggestionReason]?
    @State private var deteriorationCheckedThisSession = false

    var body: some View {
        Form {
            if !summary.isEmpty {
                Section {
                    ForEach(Array(summary.enumerated()), id: \.offset) { _, line in
                        Text(verbatim: line)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(line)
                    }
                }
            }

            if week == 1 {
                Section {
                    ForEach(Array(ReviewContent.weekOneQuestions.enumerated()), id: \.offset) { index, question in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question).accessibilityAddTraits(.isHeader)
                            TextField("", text: $weekOneAnswers[index], axis: .vertical)
                                .accessibilityLabel(question)
                        }
                    }
                }
            }

            Section {
                ForEach(Array(ReviewContent.reflectionQuestions.enumerated()), id: \.offset) { index, question in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question).accessibilityAddTraits(.isHeader)
                        TextField("", text: $reflectionAnswers[index], axis: .vertical)
                            .accessibilityLabel(question)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ReviewContent.oneThingToChangeQuestion).accessibilityAddTraits(.isHeader)
                    TextField("", text: $oneThingToChange, axis: .vertical)
                        .accessibilityLabel(ReviewContent.oneThingToChangeQuestion)
                }
            }

            selfHarmSection

            Section {
                Button(ReviewContent.gettingWorseButton) { tapGettingWorse() }
                    .accessibilityHint(ReviewContent.gettingWorseHint)
            }
        }
        .recordListStyle()
        .navigationTitle("weeklyReview.title")
        .getSupport()
        .safeAreaInset(edge: .bottom) {
            Button(CommonLabels.done, action: tapDone)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.bar)
        }
        .onAppear(perform: load)
        .fullScreenCover(isPresented: Binding(get: { notRightNowReasons != nil }, set: { if !$0 { notRightNowReasons = nil } })) {
            NotRightNowPageView(store: store, reasons: notRightNowReasons ?? []) { notRightNowReasons = nil }
        }
        .fullScreenCover(isPresented: Binding(get: { gpSuggestionReasons != nil }, set: { if !$0 { gpSuggestionReasons = nil } })) {
            GPSuggestionPageView(store: store, reasons: gpSuggestionReasons ?? []) { gpSuggestionReasons = nil }
        }
    }

    @ViewBuilder
    private var selfHarmSection: some View {
        Section(header: Text(ScreeningQuestionCatalog.questions[5]).accessibilityAddTraits(.isHeader)) {
            if selfHarmAlreadyAnswered {
                Text(ReviewContent.selfHarmAnsweredLine)
                    .accessibilityLabel(ReviewContent.selfHarmAnsweredLine)
            } else {
                Picker(ScreeningQuestionCatalog.questions[5], selection: $selfHarmFirst) {
                    Text(CommonLabels.no).tag(SelfHarmFirstAnswer?.some(.no))
                    Text(CommonLabels.yes).tag(SelfHarmFirstAnswer?.some(.yes))
                    Text(CommonLabels.ratherNotSay).tag(SelfHarmFirstAnswer?.some(.ratherNotSay))
                }
                .pickerStyle(.inline)
                .accessibilityLabel(ScreeningQuestionCatalog.questions[5])

                if selfHarmFirst == .yes {
                    Picker(ScreeningQuestionCatalog.selfHarmSecondQuestion, selection: $selfHarmSecond) {
                        Text(CommonLabels.no).tag(SelfHarmSecondAnswer?.some(.no))
                        Text(CommonLabels.yes).tag(SelfHarmSecondAnswer?.some(.yes))
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel(ScreeningQuestionCatalog.selfHarmSecondQuestion)
                }

                if selfHarmFirst == .yes, selfHarmSecond == .no {
                    // The support sheet's items, inline, Samaritans first
                    // (safeguarding spec, "Re-screening at every weekly
                    // review and check-in").
                    Text(SelfHarmItem.supportLine)
                    VStack(alignment: .leading) {
                        Text(CommonLabels.samaritansName).font(.headline)
                        Text(SupportSheet.samaritansNumber)
                        Text(SupportSheet.samaritansLine).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: selfHarmSecond) { _, newValue in
            if newValue == .yes { showNotRightNow() }
        }
    }

    // MARK: Actions

    private func tapGettingWorse() {
        saveInProgress()
        gpSuggestionReasons = [.gettingWorse]
    }

    private func showNotRightNow() {
        saveInProgress()
        notRightNowReasons = [.selfHarm]
    }

    /// Saves the answers gathered so far, with no answer to the self-harm
    /// item required (weekly-review spec, "\"I'm getting worse\"": "The app
    /// MUST save the review's answers so far.").
    private func saveInProgress() {
        _ = WeeklyReviewModel.saveDone(
            store: store, week: week, startDay: startDay, calendar: calendar,
            reflectionAnswers: reflectionAnswers, oneThingToChange: oneThingToChange,
            weekOneAnswers: week == 1 ? weekOneAnswers : nil,
            selfHarmFirst: selfHarmFirst, selfHarmSecond: selfHarmSecond, now: now()
        )
    }

    private func tapDone() {
        saveInProgress()
        // reminders spec, "The weekly review reminder": "When the person
        // completes the review before that time, the scheduler MUST cancel
        // the reminder." The scheduler recomputes from scratch, so a
        // finished review simply stops offering its own candidate.
        ReminderCoordinator.recomputeAndApply(store: store)
        dismiss()
        onDone()
    }

    private func load() {
        startDay = (try? store.startDayKey()) ?? RecordDay.key(containing: now(), calendar: calendar, schedule: (try? store.dayStartSchedule()) ?? .standard)
        summary = WeeklyReviewModel.summary(store: store, week: week, startDay: startDay, calendar: calendar)

        let dueDayKey = ReviewDue.dueDayKey(week: week, startDay: startDay, calendar: calendar)
        if let existing = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey) {
            let payload = ReviewAnswersPayload.decode(existing.answersJSON)
            reflectionAnswers = payload.reflectionAnswers
            oneThingToChange = payload.oneThingToChange
            if let saved = payload.weekOneAnswers { weekOneAnswers = saved }
            selfHarmAlreadyAnswered = existing.selfHarmAnswered
        }

        checkDeteriorationOnce()
    }

    /// The deterioration rule fires at most once per review (weekly-review
    /// spec, "The deterioration rule at the review"): checked once when the
    /// review opens; "I'm getting worse" can still show the page again at
    /// any later tap in the same session.
    private func checkDeteriorationOnce() {
        guard !deteriorationCheckedThisSession else { return }
        deteriorationCheckedThisSession = true
        var counts: [Int] = []
        for offset in stride(from: 3, through: 0, by: -1) {
            let checkedWeek = week - offset
            guard checkedWeek >= 1 else { return }
            let dueDayKey = ReviewDue.dueDayKey(week: checkedWeek, startDay: startDay, calendar: calendar)
            guard let row = try? store.review(kind: .weeklyReview, dueDateKey: dueDayKey),
                  let starred = ReviewAnswersPayload.decode(row.answersJSON).frozenCounts?.starred
            else { return }
            counts.append(starred)
        }
        if DeteriorationRule.fires(lastFrozenStarredCounts: counts) {
            gpSuggestionReasons = [.deterioration]
        }
    }
}
