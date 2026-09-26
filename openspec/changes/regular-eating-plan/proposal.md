# Proposal

## Why

Task 2.3 in `openspec/changes/v1-programme/tasks.md` names this change. The
plan is the person's regular eating pattern: which slots happen on a day,
and at what time. This change builds the plan builder, the weekday and
weekend templates, planned days, the window that matches a planned meal to
an entry, the plan beside the record on Today, the missed planned meal
prompt in its first two forms, and the next-planned-meal line.

## What Changes

- A new `Plan` package target holds the plan's pure logic: the six slots,
  the planned-meal JSON shape, the window and match rule, the planned-day
  rule, the soft rules, materialisation's template choice, and the
  next-planned-meal and missed-planned-meal-prompt rules. `Record` depends
  on `Plan` for this shape; `Plan` depends on `Constants` only.
- `RecordStore` gains read and write calls for the `Template`, `Day` and
  `Answer` rows model-foundation already added to the schema, and for a
  slot's label (a `Settings` row).
- The plan builder screen (`App/Midmorning/PlanBuilderView.swift`) places,
  times, renames and removes slots, shows the gap and the quiet-hours
  message, runs the soft-rules check on save, and, on the weekday template,
  offers "Copy to weekend plan".
- Today's day heading menu offers "Today's plan", "Tomorrow's plan",
  "Weekday plan" and "Weekend plan" from stage 2. Today shows each planned
  meal beside the record, in time order, with the missed planned meal
  prompt and the next-planned-meal line.
- "Add it" on the missed planned meal prompt opens `NewEntryView` with the
  planned meal's own time.

## Capabilities

### Added Capabilities

- `regular-eating-plan`: the plan builder, templates, planned days, the
  window, the plan beside the record, the missed planned meal prompt (first
  two forms) and the next-planned-meal line.

## Impact

- `Packages/Package.swift`: a new `Plan` target and `PlanTests` test target;
  `Record` gains a dependency on `Plan`.
- `Packages/Sources/Plan/*`: `Slot`, `PlannedMeal`/`PlanCodec`, `PlanTime`,
  `PlanOrdering`, `SlotLabel`, `PlanWindow`, `PlanMatch`, `PlannedDay`,
  `SoftRules`, `Materialisation`, `NextPlannedMeal`, `MissedMealPrompt`,
  `PlanBuilderAccess`, `PlanEditing`, `PlanBuilderLayout`,
  `PlanBuilderAccessibility`, `PlannedMealRow`, `QuietHours`.
- `Packages/Sources/Record/RecordStore.swift`: the "Plan" section (templates,
  days, planned-meal answers, slot labels).
- `App/Midmorning/PlanBuilderView.swift`, `PlanTodayModel.swift`,
  `PlannedMealRowView.swift` (new); `TodayView.swift`, `DaySection.swift`,
  `NewEntryView.swift` (each changed, additively).
- `App/Midmorning/Localizable.xcstrings`: the `plan.*` interface-chrome keys
  this change adds.

## Decisions this change makes

- A planned meal's time is a wall-clock "HH:mm" string
  (`PlannedMeal.time`), not a slot-relative offset. Ordering, the window and
  the soft rules all derive a slot's place in the record day from it and
  "Day starts at" (`PlanOrdering.minutesAfterDayStart`), so a template's
  saved time keeps its meaning even after a later "Day starts at" change.
- The plan builder's own entry points — "Today's plan", "Tomorrow's plan",
  "Weekday plan" and "Weekend plan" as four items in the day heading's menu —
  are this change's own navigation choice; the spec fixes only "Today's
  plan" there and leaves the template screens' entry point open.
- Materialisation writes a `Day` row with `changedAt: .distantPast`
  (data-and-privacy spec: "Materialisation MUST NOT write `changedAt`"): a
  sentinel a real edit's own `changedAt` always outranks, matching the
  pattern `ConflictRulesTests.testDayRowAfterAnImportKeepsTheImportedRowAndWritesNoChangedAt`
  already fixed in model-foundation.
- The next-planned-meal line's trigger ("the previous slot was answered
  'Skipped' with no matched entry, or a starred entry falls between the two
  slots' own times") is a structural, stateless rule
  (`NextPlannedMeal.isTriggered`), recomputed on every read rather than kept
  as a flag, so it needs no new stored row.
- Every spec-exact sentence this change fills (the soft-rules lines, the
  next-planned-meal line, the missed-planned-meal-prompt lines, and "This
  time is in quiet hours...") is a hardcoded `Plan` function, the same
  pattern `GapBand.accessibilityLabel` and `RecordRow.accessibilityLabel`
  already use, not a `Localizable.xcstrings` key or a Content-bundle string:
  each is a deterministic, spec-fixed sentence with placeholders the
  function fills, not free clinical prose. `Localizable.xcstrings` gains a
  key only for a plain, unparameterised control label ("Skipped", "Add it",
  "Rename", "Save anyway", "Go back", the four menu titles).
