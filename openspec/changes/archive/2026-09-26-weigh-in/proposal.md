# Proposal

## Why

Task 2.2 in `openspec/changes/v1-programme/tasks.md` names this change. The
weigh-in is the one weekly number the programme asks for. The underweight
check reads its trend and can show the not-right-now page or the GP
suggestion page. Decision 59 makes this change follow 2.4, because it holds
the weigh-in day reminder.

## What Changes

- A new `Programme/WeighIn` folder in the existing `Programme` package
  target holds the pure rules: the weigh-in day and the six-day gate, the
  number and its unit, the four-week rolling average, the missed-week
  status, the weigh-in day reminder's own candidate and the safeguarding
  underweight check (Rules A, B and C).
- `RecordStore` gains `unit` and `savedAt` on the model-foundation `Measure`
  row, `weighIn`/`weighIns`/`saveWeighIn`, and `weighInUnit`/`setWeighInUnit`.
- `App/Midmorning/WeighIn/WeighInScreenView.swift` is the weigh-in screen:
  "Choose a weigh-in day", the weight input, the refusal text, the chart and
  its one-line explanation, and the underweight check run once after each
  save. `WeighInChartView.swift` is the rolling-average chart.
- The settings screen gains the Weigh-in group. `ReminderCoordinator` feeds
  the weigh-in day reminder into the same scheduler as an extra candidate,
  and a tap on it opens the weigh-in screen.
- The "Weigh-in" row on the "Getting started" stage screen (built by
  `programme-engine`, 2.1, with no action) now opens the weigh-in screen.

## Capabilities

### Added Capabilities

- `weigh-in`: the weigh-in day, the number and its unit, the rolling
  average, the chart, the one-line explanation, what the weigh-in never
  shows, a missed weigh-in day, the trend feeding safeguarding, the store,
  and accessibility. Not built: "The weigh-in page in an export" (4.2's own
  requirement to add).

### Modified Capabilities

- `safeguarding`: adds "The underweight check" (a new requirement; "The GP
  suggestion page" and "The not-right-now page" already hold the weight and
  GP-suggestion reasons this check triggers, from `onboarding-and-
  safeguarding`, so this change does not modify either).
- `settings`: adds "The Weigh-in group" (a new requirement).
- `reminders`: adds "The weigh-in day reminder" (a new requirement; every
  cross-type scenario that already names it — the cap, the same-minute
  order — was already built and tested by `reminders`, 2.4, ahead of this
  change).
- `onboarding`: modifies "Screen 3: weigh-in day and quiet hours" to add
  back its own "I won't be weighing" scenario, which `onboarding-and-
  safeguarding` deferred to this change (`mm-t14.7`'s own tasks.md).

## Impact

- `Packages/Package.swift`: no new target; `Programme`'s existing target
  and test target gain files under `Programme/WeighIn/` and
  `Tests/ProgrammeTests/`.
- `Packages/Sources/Record/Models/Measure.swift`, `FrozenSchema.json`,
  `RecordStore.swift`: additive fields and a new "Weigh-in" section.
- `App/Midmorning/WeighIn/` (new): `WeighInScreenView.swift`,
  `WeighInChartView.swift`. `TodayView.swift` (the `WeighInRoute`
  destination), `Programme/StageScreenView.swift` (the "Weigh-in" row),
  `SettingsView.swift` (the Weigh-in group), `Reminders/
  ReminderCoordinator.swift` (the extra candidate and the `.weighInDay`
  switch), `RemindersSettingsView.swift` (the time picker now recomputes),
  `Reminders/NotificationActionHandling.swift` and `AppLock/
  AppLockRootView.swift` (the tap-opens-the-screen route) — each changed
  additively.
- `App/Midmorning/Localizable.xcstrings`: `settings.group.weighIn`.

## Decisions this change makes

- A same-device edit inside the 10-minute window writes a new, append-only
  `Measure` row rather than mutating the first row in place —
  `RecordStore.saveWeighIn` keeps the established pattern every other
  synced row in this codebase already uses (`Day`, `Answer`, `Settings`),
  copying the first save's own `savedAt` into the new row so it never
  changes. `MeasureReconciler` (model-foundation) already picks the
  later-`changedAt` row as the winner, so the store still reads as "one row
  per record day key," matching the requirement's own wording, without a
  second CRUD pattern.
- `WeighInGate.inputState` is a fourth, explicit case
  (`.fixedForToday`), not folded into `.refusal`: on the weigh-in day
  itself, once its own 10-minute window has closed, the requirement's text
  reserves the refusal text for "any other day," so the screen shows the
  chart with no weight input and no refusal text.
- The chart's VoiceOver support and audio graph come from Swift Charts'
  own automatic accessible representation over the `LineMark`/`PointMark`
  marks, not a hand-written `AXChartDescriptor`: Swift Charts (iOS 16+)
  builds one from the marks already, so a hand-written descriptor would
  duplicate it. The real VoiceOver walk is a device check.
- A tap on the weigh-in day reminder posts a plain
  `Notification.Name` (`.weighInReminderTapped`), the same pattern "Add"
  already uses for the new-entry screen, rather than the `PendingRoute`
  bypass "Add" needs: the weigh-in screen carries no before-authentication
  concern, so `RunningRootView` presents it as an ordinary
  `fullScreenCover` once the app is active.
