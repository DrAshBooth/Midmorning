# weekly-review

3.2 from `openspec/changes/v1-programme/tasks.md`: the summary with frozen
counts, the two-step self-harm item, reflection and the pinned note. Also
holds the re-screening and deterioration rules in `safeguarding` and the
weekly review reminder from `reminders`.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 21 seconds. Warm `./verify`: 3 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. The review shows only the fixed templates
  `ReviewSummary` builds; it adds no score, rating, percentage, streak,
  badge or comparison to a "good" week, a target or other people
  (`ReviewNeverShowsTests`); it shows no weight value.
- mm-pr2, Tone of every string — yes. Every string this change adds is
  quoted verbatim from the weekly-review or safeguarding spec, or a plain
  number, date or duration; none praises, shames or cheers
  (`ReviewNeverShowsTests.testNoScoreRatingOrPercentage` and the
  banned-word scan across every scenario's own text).
- mm-pr3, Vocabulary — yes. This change's own strings use "weekly review",
  "entry", "pinned note" and "urge"; none uses "log", "tracker", "streak",
  "badge", "score" or "user". `ScreeningQuestionCatalog.mentionsCompensation`
  also proves none of the review's questions names vomiting, laxatives or
  compensation (`NoCompensationQuestionAtAWeeklyReviewTests`).
- mm-pr4, Nothing looks like a nutrition app — yes. `ReviewScreenView.swift`
  and `ReviewsListView.swift` add no `Image(systemName:)` but the pinned
  note's pin glyph (a neutral marker, not a food or body image), no plate,
  fork, scale or tape-measure, and no food photography.
- mm-pr5, The product name and the plan slot — yes. This change writes
  "Midmorning" nowhere beside a meal word; it adds no plan-slot label and
  references no book.
- mm-pr6, What a notification never shows — yes. The weekly review reminder
  reuses the shared `DiscreetText`/`ReminderKind` machinery: its body is
  always the time, its explicit title is "Weekly review", and it carries no
  review content (`ReviewSummary`'s output never reaches
  `ReminderCoordinator`).
- mm-pr7, The person can put it down — yes. "Weekly summary" is a switch in
  the settings screen, on by default, and turning it off drops only the
  summary; the self-harm item, "I'm getting worse", the reflection
  questions and the pinned note all stay (`RecordTests.ReviewStoreTests
  .testSwitchOffSafeguardingStillCounts`).
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver walk
  and the largest text size still to come (the epic's device-check bead).
  Every summary sentence is one accessibility element whose label is its
  own text; "I'm getting worse" carries the spec's own hint; every
  free-text field's label is its own question; no control depends on
  colour alone (`ReviewAccessibilityTests`).
- mm-pr9, Dates and times in strings — yes. The gap duration, the weekday
  name and the date range all come from `ReviewText`'s own en_GB
  formatters; the reminder time is the 24-hour "HH:mm" every other reminder
  already uses.
- mm-pr10, Offline and private by default — yes. Every new `RecordStore`
  call (`review`, `reviewRowWinners`, `upsertReview`, `weeklySummaryOn`,
  `setWeeklySummaryOn`, `urgeOutcomeDetails`) is a local SwiftData read or
  write; the self-harm answer itself never enters the store, only whether
  it was answered (`ReviewStoreTests.testTheStoreAfterAReviewKeepsNoAnswer`);
  this change adds no network call.
- mm-pr11, No AI at runtime — yes. `ReviewDue`, `ReviewFreeze`,
  `ReviewSummary`, `DeteriorationRule`, `PinnedNoteHold` and
  `WeeklyReviewReminderRule` are deterministic pure functions over fixed
  inputs; nothing here generates a sentence.
- mm-pr12, Appearance — yes. Both screens use `recordListStyle()` and
  system text styles throughout; the pinned note uses the text colour, not
  a new one; this change adds no new colour, font or corner radius.

### Get support on every screen

Both full screens this change adds carry `.getSupport()`:
`ReviewScreenView` and `ReviewsListView`. Neither is a sheet that closes in
one tap to a screen that already has the control, so neither is exempt.

## Constant changes

No `ProgrammeConstants` value changed during this build. `deteriorationWeeks`
already existed, added by `model-foundation` ahead of this change.

## Scope notes

- "Taking stock" and "The taking stock questionnaire and the module
  recommendation" are not built: `mm-t32b` (3.2b, `taking-stock`) is the
  second part of 3.2 and adds both requirements fresh, per its own
  proposal.
- "After the finish" (`weekly-review`'s "When a weekly review is due", and
  `reminders`' "The weekly review reminder") stays `deferred: mm-t36.15`,
  the wiring bead in `staying-on-track` (3.6) that runs it end to end.
- "A check-in", "A check-in with no entries", and the check-in half of "I
  won't be weighing" (`weekly-review`'s "The summary built from the
  record") stay `deferred: mm-t36.21`.
- "A binge outcome holds the pinned note" is built over a fixture urge
  fact (`PinnedNoteHoldTests`), since `urge-toolkit` (3.1) is not merged in
  this worktree; `mm-t31.19` runs it end to end.
- "VoiceOver on the chosen module" and the taking-stock half of "Largest
  text size" (`weekly-review`'s "Accessibility of the review") stay
  `deferred: mm-t32b.5`.
- `ReminderCoordinator.requests` now reads the live stage-2 fact
  (`ProgrammeModel.load(store:).state.isOpen(.regularEating)`) in place of
  the `stage2Open: false` fixture its own doc comment named for
  `programme-engine` (2.1); `mm-t32.16`'s own wiring tests need it for the
  stage-1 reminder scenarios.
- `RemindersSettingsView.swift`'s "Weekly review time" `DatePicker` was
  missing the `ReminderCoordinator.recomputeAndApply(store:)` call every
  other time picker in that screen already makes; fixed alongside this
  change's own reminder wiring (small, in the file this change was already
  touching).
- `Record.Reconciler.ReviewReconciler.winners` gained a same-`frozenAt`
  tiebreak; see `proposal.md`'s "Decisions this change makes" and
  `tasks.md` 1.2 for the bug this fixes and the test that proves it.
- `WeeklyReviewModel.freezeAllDueWeeks` (called from
  `TodayView.reload`) is the App-target seam that composes `RecordStore`
  facts into `Programme.ReviewWeekFacts` and calls
  `FrozenReviewCounts.from`/`RecordStore.upsertReview`; it is not itself
  unit-tested (no App-target test runner), but `RecordTests.ReviewStoreTests`
  and `RecordTests.WeeklyReviewWiringTests` prove the same composition
  directly against the real store and the real pure functions.
