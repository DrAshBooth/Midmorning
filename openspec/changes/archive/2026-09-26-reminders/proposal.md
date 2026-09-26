# Proposal

## Why

Task 2.4 in `openspec/changes/v1-programme/tasks.md` names this change. Reminders hold the structure of the day for the person: each planned meal, the morning plan, midday, the close of the day, and the seven-silent-day stop. This change also holds the notification-action handlers and the action queue from `widgets-and-intents`, because first-cut reminders needs them (decision 44).

## What Changes

- A new `Packages/Programme/Reminders` folder holds the scheduler: a pure function over a rolling horizon, the cap, the same-minute shift, quiet hours, the snooze decision, the discreet-by-default text, and the day rules for the morning plan, midday, close-the-day and seven-silent-day reminders.
- `Packages/Sources/Record/ActionQueue.swift` holds the action queue's codec and its six-value shape. `RecordStore` gains an applier, a snooze-count store, a morning-plan-unanswered-count store, a silent-day-streak store and a feeling-word store for "Close the day".
- The App target gains notification scheduling and action-handling code that calls the scheduler and the action queue, a Reminders-group permission section, a Today permission line, and the close-the-day screen.
- The change holds only the requirements its child beads name: the reminders capability's own types, the cap, the same-minute shift, quiet hours and the scheduling rule; the app-lock capability's locked-device notification-action scenarios; and the widgets-and-intents capability's notification-action and action-queue requirements. The weigh-in day reminder, the weekly review reminder, worksheet review and check-in reminders, and "Time Sensitive is opt-in" belong to their own owning capabilities and are not part of this change.

## Capabilities

### Added Capabilities

- `reminders`: the scheduler, the eight reminder types' switches, the discreet-by-default text, the snooze decision, the cap, the same-minute shift, quiet hours, the paused-day and reminder-pause rules, and the scheduling rule (local, lazy, bounded).
- `widgets-and-intents`: the notification-action entry point and the action queue only; every other requirement of this capability is `widgets-and-intents` (2.5)'s own work.

### Modified Capabilities

- `app-lock`: the notification-action scenarios of "A new entry before authentication" (the widget scenarios of that requirement are `widgets-and-intents`, 2.5).

## Impact

- `Packages/Package.swift`: no new target. `Programme`'s existing target gains the `Reminders` folder; the `swift test` line does not change (tasks.md 4.5).
- `Packages/Programme/Reminders/*`: `ReminderClock`, `ReminderKind`, `ReminderCandidate`, `ReminderRequest`, `PlannedMealReminderAction`, `DiscreetText`, `ReminderQuietHours`, `ReminderUserInfo`, `SnoozeDecision`, `ReminderCap`, `SameMinuteShift`, `MorningPlanFacts`/`Rule`/`UnansweredTracker`, `MiddayFacts`/`Rule`, `CloseTheDayFacts`/`Rule`, `SilentDayOutcome`/`Tracker`, `DeliveredReminder`/`Removal`, `ReminderDiagnostics`, `ReminderPermissionText`, `Scheduler`.
- `Packages/Sources/Record/ActionQueue.swift` (new); `RecordStore.swift` gains the reminders section (snooze count, morning-plan-unanswered count, silent-day streak, the denied-line-tapped flag, the action-queue applier) and the feeling-word row.
- `App/Midmorning/Reminders/*` (new): notification scheduling, action-category registration, action handling, the Today permission line, the Reminders-group permission section, `CloseTheDayView.swift`.
- `App/Midmorning/Localizable.xcstrings`: the `today.reminders.*` and `settings.reminders.notification.*` interface-chrome keys this change adds.

## Decisions this change makes

- `Scheduler.requests` takes the four types this capability owns (planned meal, morning plan, midday, close-the-day) as resolved `SchedulerDay` facts, and takes every other capability's reminder as a plain `extraCandidates: [ReminderCandidate]` list. The reminders spec's own design (`plan:templates:settings:state:snoozes:now:`) names `plan` and `templates` as inputs; this change resolves the template-or-day fallback at the call site (`RecordStore` already holds that read) rather than inside `Scheduler`, so `Scheduler` never needs a `Plan` import and stays a pure function over plain facts, the same pattern `Programme`'s other pure seams already use.
- `ReminderClock` and `ReminderQuietHours` are `Programme`'s own copies of `Plan.PlanTime` and `Plan.QuietHours`'s shape, not a shared import, because `Programme` imports only `Constants` (design.md, "One umbrella package, five targets"). `Plan.QuietHours` stays regular-eating-plan's own interim reader; absorbing it into this capability's canonical version is not required by any bead here.
- The action queue's codec and its `RecordStore` applier live in `Record`, not `Programme`, because applying a queued action needs the `Answer` and `LocalSetting` writes only `RecordStore` has; the codec itself (`ActionQueueCodec`) is free functions over `Data`, so a notification handler calls it without opening the store, matching the spec's "the handler MUST NOT open the store."
- "Permission denied" (reminders spec) is built here except the "Show me the widget" control, which stays absent until `widgets-and-intents` (2.5, `mm-t25.15`) builds the page it opens — the same placeholder-until-later-change pattern `record-full`'s "Get support" buttons used ahead of `onboarding-and-safeguarding`.
- The Diagnostics page's two counts this change owns (`ReminderDiagnostics.pendingReminderCount`/`queueLength`) are pure functions only; `mm-t41`'s settings child wires them into the real Diagnostics page, so this change's delta does not touch `settings/spec.md`.
