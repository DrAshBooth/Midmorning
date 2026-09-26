# Design

See `openspec/changes/v1-programme/design.md`, "Pattern sentences and
reviews are templates plus numbers" and "The programme engine is a pure
function with stored openings as input". This change makes no design
decision `v1-programme` does not already state; its own choices are
narrower and listed here and in `proposal.md`'s "Decisions this change
makes".

## The review's answers are one JSON payload, like `Day.slotsJSON`

`Review.answersJSON` is a generic string field the `data-and-privacy`
model owns; this change defines `Programme.ReviewAnswersPayload` as its one
shape. Splitting the payload into separate `RecordStore` columns would
force every future review-owning change (`mm-t32b`, `mm-t36`) to migrate
the model; keeping it opaque JSON, decoded and encoded only by `Programme`
(which never imports `Record`), matches the existing `Day`/`Answer`/
`Template` pattern exactly.

## The frozen counts and the summary read the same value facts

`Programme.ReviewWeekFacts` is the one input both `FrozenReviewCounts.from`
and `ReviewSummary.parts` read. The App target's `WeeklyReviewModel
.weekFacts` gathers it once; the freeze call and the summary call never
compute two different views of the same week, which the requirement's own
"the review MUST NOT compute an entry's record day again at review time"
and "the counts... MUST NOT change" rules both depend on.

## `ReviewDue`'s week arithmetic reuses `StageEngine.week`

`programme` owns week counting (`StageEngine.week(startDay:currentRecordDay:)`).
`ReviewDue.latestDueWeek` reads it rather than repeating the "days since
start day, divided by 7" arithmetic a second time, so the two capabilities
can never disagree about which week a record day falls in.

## The self-harm item at the review has no new pure function

`Programme.SelfHarmItem` (onboarding-and-safeguarding, 1.4) already states
the two-step outcome and the support line; `NotRightNowPage` and
`SupportSheet` already carry the self-harm reason and Samaritans-first
order. This change adds no second copy: `ReviewScreenView` calls the same
three types `RescreenView` already calls for the restart re-screen.

## `ReminderCoordinator` reads the live stage fact once, not per day

`ProgrammeModel.load(store:)` computes `state.isOpen(.regularEating)`;
`ReminderCoordinator.requests` calls it once per invocation and passes the
one `Bool` into every `SchedulerDay` in the horizon, the same "one fact,
reused" shape `TodayView`'s own `stage2Open` property already has for
`GapBand`/`PlanBuilderAccess`. A per-day call would repeat the same
`StageEngine.state` computation seven times for one, unchanging answer.

## The "Reviews" list and Today's pinned note both read `reviewRowWinners`

Neither result is cached: both call `RecordStore.reviewRowWinners(kind:)`
and filter for `finished`, on demand. The store's own SwiftData fetch is
already the cheap operation in this path (a handful of rows even after a
year of weekly reviews); a cache would add a second place these two
screens could disagree.
