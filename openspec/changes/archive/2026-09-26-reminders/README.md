# reminders

2.4 from `openspec/changes/v1-programme/tasks.md`: the scheduler over the
rolling horizon, the reminder types of the first cut, snooze state, the cap
with planned meals separate, and quiet hours with wrap-around. It also holds
the notification-action handlers and the action queue from
`widgets-and-intents`.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 10 seconds. Warm `./verify`: 2 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. No count, total, streak, badge, score or
  colour-coded state appears in any string or screen this change adds.
- mm-pr2, Tone of every string — yes. Every string this change adds names a
  fact or a control (a time, "Reminders need notification permission.",
  "Each device sends its own reminders.", "One word for how today felt");
  none praises, cheers, shames or uses medical language.
- mm-pr3, Vocabulary — yes. This change's strings use "entry", "plan",
  "planned meal" and "reminder"; none uses "log", "diary", "tracker" or
  "portion".
- mm-pr4, Nothing looks like a nutrition app — yes. This change adds no
  `Image(systemName:)` anywhere.
- mm-pr5, The product name and the plan slot — yes. `DiscreetText` never
  writes "Midmorning" itself; iOS appends it once. The explicit title for a
  planned meal is the slot's own label, which `SlotLabel.isProductName`
  (regular-eating-plan) already rejects for "Midmorning" in any case.
- mm-pr6, What a notification never shows — yes. The discreet body is the
  time only; every explicit title names a reminder type or a slot label,
  never entry text, food, binge or weight.
- mm-pr7, The person can put it down — yes. Every reminder type this change
  schedules has its own switch (`settings`, already built); "Pause for
  today" (already built) silences everything for the rest of the day. No
  string frames a missed reminder as a broken commitment.
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver walk
  still to come (the epic's device-check bead). Every control this change
  adds is a plain system `Button`, `Toggle` or `TextField` with a
  catalogue-key label equal to its visible text; every row uses the system
  list style, so its hit area is the system default.
- mm-pr9, Dates and times in strings — yes. `ReminderClock.string(hour:
  minute:)` is a fixed "HH:mm" formatter, independent of the device locale,
  the same pattern `Plan.PlanTime` already uses.
- mm-pr10, Offline and private by default — yes. The scheduler and the
  notification-action handler use only `UNUserNotificationCenter` and local
  files; this change adds no network call.
- mm-pr11, No AI at runtime — yes. `DiscreetText` and
  `ReminderPermissionText` are deterministic functions over fixed templates;
  nothing generates a sentence.
- mm-pr12, Appearance — yes. Every screen this change adds or extends uses
  `Form`, system controls and no custom colour, font or glyph.
  `CloseTheDayView` (a screen that asks for an answer: a feeling word)
  opens as a sheet, the same rule `NewEntryView` already follows.

### Get support on every screen

`CloseTheDayView` is the one full screen this change adds, and it carries
the real `getSupport()` modifier (`onboarding-and-safeguarding`, 1.4, has
landed, so this change uses the real support sheet, not a placeholder).

## Scope notes

- This change takes only the requirements its child beads name from four
  spec files. "The weigh-in day reminder", "The weekly review reminder",
  "Worksheet review and check-in reminders" and "Time Sensitive is opt-in"
  (all in `reminders/spec.md`) belong to `weigh-in` (2.2), `weekly-review`
  (3.2), `problem-solving` (3.3)/`staying-on-track` (3.6) and a later change
  respectively; none has a bead here, so none is in this change's delta.
- `widgets-and-intents` (2.5) is not built. This change takes only
  "Notification actions are entry points" and "The action queue" from that
  capability (decision 44); every other requirement (the two widgets, the
  snapshot, the App Intent, the Control Centre control, "Keep it private"
  and the accessibility requirement) is 2.5's own work.
- `programme-engine` (2.1) is not built. Every stage-2 gate this change
  reads (`MorningPlanFacts.stage2Open`) is a fixture fact, the same pattern
  `GapBand`'s and `PlanBuilderAccess`'s own `stage2Open` already use;
  `mm-t21.23` wires the live stage in.
- `mm-t24.21`'s wiring is built: `ReminderCoordinator` (App target) gathers
  real `RecordStore`/`Plan` facts and calls `Scheduler.requests`, called from
  every Reminders-group change and from activation; the Today lock control
  now dispatches the real `AppLockController`. `TodayView`'s own permission
  *line* still reads a fixture `notificationPermission` fact (`stage2Open`'s
  own pattern), because nothing yet reads the real permission on Today
  itself; the Reminders-group section's `UNUserNotificationCenter` calls are
  real. The App target has no `swift test` target, so `ReminderCoordinator`
  and the lock-control fix are proved by the epic's device checks, the same
  way `LocalAuthenticationAdapter` and every other App-target adapter
  already are.
- `Programme` cannot import `Plan` or `Record` (design.md, "One umbrella
  package, five targets"), so `Scheduler` takes every day's facts
  (materialised or template-resolved plan, the match against entries, stage
  2, quiet hours) as plain, caller-resolved values. `proposal.md`'s
  "Decisions this change makes" states this in full.
- `DeliveredReminderCleanup` (App target) removes a delivered reminder
  correctly by record day; a planned meal reminder's own window-end removal
  needs the live plan's window minutes (`Plan.PlanWindow`), which
  `mm-t24.21`'s wiring supplies.

## Device checks

Every device-only check is listed on the epic's device-check bead
(mm-t24.22): the real system permission dialog and its effect on the
schedule; a real `ReminderCoordinator.recomputeAndApply` after "Turn
reminders on", a switch, a time or quiet hours changes; the Today lock
control's real cover, now that it dispatches the real `AppLockController`;
"Skipped" and "Add" while the device is locked (the authentication and
foreground options); a snooze delivered and rescheduled on a real device;
Notification Centre grouping and removal timing; the largest accessibility
text size on the Reminders group and the close-the-day screen; VoiceOver's
reading order and custom actions; and the shame walk, which also covers a
reminder on the Lock Screen at work.
