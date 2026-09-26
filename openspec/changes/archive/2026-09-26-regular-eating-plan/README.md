# regular-eating-plan

2.3 from `openspec/changes/v1-programme/tasks.md`: the plan builder,
templates, planned days, the window, the plan beside the record, the missed
planned meal prompt in its first two forms, and the next-planned-meal line.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 12 seconds. Warm `./verify`: 2 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. No planned meal row, prompt or line shows a
  tick, a cross, a colour, a count or a percentage (`PlannedMealDisplay`,
  `PlannedMealRowView`); the soft-rules check states a plain count of meals
  and snacks, never a total or a score.
- mm-pr2, Tone of every string — yes. Every string this change adds names a
  fact or a control ("Skipped, or not recorded yet?", "This day has %@ and
  %@...", "%@ at %@ still happens."); none praises, shames, cheers or uses
  medical language. A starred entry still shows nothing about itself on the
  new-entry screen.
- mm-pr3, Vocabulary — yes. This change's strings use "plan", "planned
  meal", "entry" and "What"; none uses "log", "diary", "intake", "portion"
  or "tracker".
- mm-pr4, Nothing looks like a nutrition app — yes. This change adds no
  glyph at all: no `Image(systemName:)` appears in any file it adds.
- mm-pr5, The product name and the plan slot — yes. `Slot.all`'s label is
  "Mid-morning" (hyphenated); `SlotLabel.isProductName` rejects "Midmorning"
  (unhyphenated), in any letter case, as the rename rule requires. This
  change schedules no notification, so the notification-wording half of the
  rule does not yet apply; `reminders` (2.4) owns it.
- mm-pr6, What a notification never shows — yes. This change adds no
  notification.
- mm-pr7, The person can put it down — yes. Every placed slot has a one-tap
  "Remove %@"; every missed planned meal prompt has a one-tap "Skipped";
  nothing frames an unanswered planned meal as a broken commitment.
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver walk
  still to come (mm-t23.15). Every planned meal row is one accessibility
  element with the label order "Accessibility of the plan" states; the
  prompt's buttons are also VoiceOver custom actions on the row; every
  button this change adds is at least 44 points tall with 8 points between
  them (`PlannedMealRowView.promptButtons`); every control uses a system
  text style and scales with Dynamic Type; no state depends on colour
  alone.
- mm-pr9, Dates and times in strings — yes. `PlanTime.string(hour:minute:)`
  fixes "HH:mm" on the 24-hour clock; `PlanDuration.string(minutes:)` and
  every `Plan` sentence are locale-independent, fixed English text. The
  builder's time control is a system `DatePicker`, the same pattern
  `NewEntryView`'s own time wheel already uses.
- mm-pr10, Offline and private by default — yes. Every new `RecordStore`
  call (`setTemplateSlotsJSON`, `setDayPlan`, `materialiseDayFromTemplate`,
  `setPlannedMealAnswer`, `setSlotLabel`) is a local SwiftData write; this
  change adds no network code.
- mm-pr11, No AI at runtime — yes. Every rule this change adds (`PlanWindows`,
  `PlanMatching`, `PlannedDay`, `SoftRules`, `NextPlannedMeal`,
  `MissedMealPrompt`) is a deterministic pure function filling a fixed
  template; nothing generates a sentence.
- mm-pr12, Appearance — yes. `PlanBuilderView` uses `recordListStyle()` and
  `recordSheetDetent()` and adds no appearance modifier of its own; every
  row on Today shares `EntryRow`'s background, height, spacing and text
  style (`PlannedMealRowView`); the builder adds no new glyph, font, colour
  or corner radius.

### Get support on every screen

`PlanBuilderView` is the one full screen this change adds, and it carries
its own trailing "Get support" (`today.getSupport`, `GetSupportPlaceholderSheet`,
the same placeholder `settings` (mm-t13) wired). The rename sheet closes in
one tap (Cancel or Save) to the builder, which already has the control, so
the safeguarding spec's sheet exemption covers it ("Get support on every
screen": "A sheet that closes in one tap to a screen with the control is
exempt"). `onboarding-and-safeguarding` (1.4) has not landed, so, like every
other screen before it, this one opens the same placeholder sheet rather
than the real support sheet.

## Scope notes

- `programme-engine` (2.1) is not built. "The plan builder opens at stage 2"
  and every stage-2 gate in this change read a `stage2Open` fixture fact
  (`TodayView`'s own `@State`), the same pattern `GapBand`'s `stage2Open`
  already uses. `mm-t21.23` wires the live stage into both at once.
- `reminders` (2.4) is not built. Quiet hours (`QuietHours`) is this
  change's own minimal, interim reading of the same settings rows
  `RecordStore.quietHoursStart`/`quietHoursEnd`/`quietHoursOn` already keep;
  `reminders` owns the canonical definition and the scheduler that reads it.
- `problem-solving` (3.3) owns "That was it" and "That was it, then a later
  window moves over the entry" (`deferred: mm-t33.14`). This change shows
  the "Skipped, or was that %@?" form and its candidate time
  (`MissedMealPrompt.candidateEntry`), with "That was it" as a visible,
  unwired placeholder button — the same pattern record-full's "Get support"
  placeholders use ahead of their own owning change.
- `mm-t41b.11` (import) owns "A Day row arrives by import" for this
  capability's Day rows; the store-level rule it rests on
  (`RecordStore.materialiseDayFromTemplate` never writes a second row for an
  existing key) is already built and tested here.
- `mm-t42.20` (local-delete-all) owns the real erasure end to end; this
  change's own "Delete-all" scenario is a fixture-level store check, since
  plan rows live in the same `Record.store` directory `DeleteAllSeam`
  already deletes whole.
- The plan builder's four entry points ("Today's plan", "Tomorrow's plan",
  "Weekday plan", "Weekend plan") sit together in the current day heading's
  menu, below a divider, after "Earlier days". The spec fixes only "Today's
  plan" there; the other three's placement is this change's own choice
  (`proposal.md`, "Decisions this change makes").

## Device checks

Every device-only check is listed on the epic's device-check bead
(mm-t23.15): VoiceOver's reading order and custom actions on the plan rows
and in the builder, the largest-accessibility-text-size check on the
builder and Today, and the shame walk (which also covers the missed planned
meal prompt and the next-planned-meal line). Ash does each check and adds
its date and screenshot to this README.
