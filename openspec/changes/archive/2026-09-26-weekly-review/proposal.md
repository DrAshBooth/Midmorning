# Proposal

## Why

Task 3.2 in `openspec/changes/v1-programme/tasks.md` names this change. The
weekly review states what happened each week and asks the person to
reflect. It also carries the re-screening and deterioration rules that
safeguarding needs at every review, and the reminder that opens it.

## What Changes

- A new `Programme/WeeklyReview` folder in the existing `Programme` package
  target holds the pure rules: when a review becomes due, the frozen-count
  rule, the summary builder, the deterioration rule, the pinned-note hold,
  and the review's own fixed strings.
- `Packages/Programme/Safeguarding/DeteriorationRule.swift` holds the
  deterioration rule itself, since `safeguarding` owns it; `weekly-review`
  reads it at the review.
- `Packages/Programme/Reminders/WeeklyReviewReminderRule.swift` builds the
  weekly review reminder's own candidate.
- `RecordStore` gains Review-row CRUD (`review`, `reviewRowWinners`,
  `upsertReview`) over the `Review` model `model-foundation` already built,
  plus `weeklySummaryOn`/`setWeeklySummaryOn` and `urgeOutcomeDetails`.
- `App/Midmorning/WeeklyReview/WeeklyReviewModel.swift` is the seam that
  gathers `RecordStore` and `Plan` match facts into `Programme`'s value
  types. `ReviewScreenView.swift` is the review; `ReviewsListView.swift` is
  the "Reviews" list.
- `TodayView` gains the pinned note row, the "Weekly review" line, and the
  "Reviews" bottom-bar item; `SettingsView` gains the "Weekly summary"
  switch; `ReminderCoordinator` feeds the weekly review reminder into the
  scheduler and now reads the live stage-2 fact (`ProgrammeModel`) instead
  of a fixture, for the stage-1 reminder scenarios this change's own wiring
  bead runs; a tap on the reminder opens the review.

## Capabilities

### Added Capabilities

- `weekly-review`: when a review is due, finishing and reopening one, the
  summary, the frozen counts, the deterioration rule at the review, the
  weekly summary switch, the three reflection questions, the pinned note,
  the self-harm item at the review, "I'm getting worse", week-1 answers,
  what the review never shows, and accessibility. Not built: "Taking
  stock" and "The taking stock questionnaire and the module recommendation"
  (`mm-t32b`'s own requirements to add).

### Modified Capabilities

- `safeguarding`: adds "Re-screening at every weekly review and check-in"
  and "The deterioration rule" (new requirements); modifies "No question
  about vomiting or laxatives" to add back its own "Weekly review"
  scenario.
- `reminders`: adds "The weekly review reminder" (a new requirement; the
  cap, same-minute order and drop order already treat `.weeklyReview` as
  reserved, from `reminders`, 2.4, ahead of this change).

## Impact

- `Packages/Package.swift`: no new target; `Programme`'s existing target
  and test target gain files under `Programme/WeeklyReview/`, one file
  under `Programme/Safeguarding/`, one under `Programme/Reminders/`, and
  `Tests/ProgrammeTests/`.
- `Packages/Sources/Record/RecordStore.swift`: a new "Reviews" section;
  `Packages/Sources/Record/Reconciler.swift`: `ReviewReconciler.winners`
  gains a same-`frozenAt` tiebreak (see "Decisions this change makes").
- `App/Midmorning/WeeklyReview/` (new): `WeeklyReviewModel.swift`,
  `ReviewScreenView.swift`, `ReviewsListView.swift`. `TodayView.swift` (the
  pinned note, the "Weekly review" line, the `ReviewsListRoute`/
  `WeeklyReviewRoute` destinations, the live "Reviews" bottom-bar item),
  `SettingsView.swift` (the "Weekly summary" switch), `Reminders/
  ReminderCoordinator.swift` (the extra candidate, the `.weeklyReview`
  switch, the live stage-2 fact), `Reminders/NotificationActionHandling.swift`
  and `AppLock/AppLockRootView.swift` (the tap-opens-the-review route).
- `App/Midmorning/Localizable.xcstrings`: `today.weeklyReview`,
  `weeklyReview.title`.

## Decisions this change makes

- `Review.answersJSON`'s shape is `Programme.ReviewAnswersPayload`: `finished`,
  `frozenCounts`, `reflectionAnswers`, `oneThingToChange`, `weekOneAnswers`.
  The model stays the generic row `model-foundation` built; this change
  defines its one owner's payload, the same way `regular-eating-plan` owns
  `Day.slotsJSON`. `mm-t32b` and `mm-t36` extend this same payload rather
  than inventing a second shape.
- `ReviewReconciler.winners` (`Record`, built by `model-foundation`) picked
  the earliest-frozen row with no secondary tiebreak, so an edit that
  correctly carries the original freeze moment forward could lose to the
  stale pre-edit row depending on fetch order. Fixed to pick, among rows at
  the earliest freeze moment, the one with the latest `changedAt` — the
  requirement's own "Every edit to the review MUST write into that row."
  `RecordStore.upsertReview` never reuses a row's own id (a fresh `UUID()`
  every call, `saveWeighIn`'s own convention); the natural key and this
  policy decide the winner, not row identity.
- `RecordStore.upsertReview` takes the complete, already-merged
  `answersJSON` from its caller; the store never reads or writes the
  payload's shape, keeping the same "pure seam" split `ProgrammeModel`
  already uses for the stage engine.
- `ReminderCoordinator` reads the live stage-2 fact
  (`ProgrammeModel.load(store:).state.isOpen(.regularEating)`) once per
  call, replacing the `stage2Open: false` fixture its own doc comment
  named for `programme-engine` (2.1): the stage-1 reminder scenarios this
  change's wiring bead runs ("Stage 1", "An evening entry in stage 1", "No
  entry by midday in stage 1", "No template yet") need the real fact.
