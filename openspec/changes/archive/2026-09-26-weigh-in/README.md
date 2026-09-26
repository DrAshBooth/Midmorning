# weigh-in

2.2 from `openspec/changes/v1-programme/tasks.md`: the weigh-in day, the
number and its unit, the rolling average, the chart, the one-line
explanation, what the weigh-in never shows, a missed weigh-in day, the
trend feeding safeguarding's underweight check, the store, and
accessibility. Also holds the Weigh-in group of the settings screen and the
weigh-in day reminder from `reminders`.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 17 seconds. Warm `./verify`: 3 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. The weigh-in screen shows the rolling
  average and no goal, target line, BMI, colour or change since last time
  (the spec's own "Weight over time" scenario); `WeighInNeverShowsTests`
  proves the save path adds no confirmation or animation and no
  Text/Button line names a BMI, a height, a goal or a target.
- mm-pr2, Tone of every string — yes. Every string this change adds is
  quoted verbatim from the weigh-in spec ("Your weigh-in day is...",
  "Weekly swings of a kilo or two are normal and mean nothing on their
  own.") or a plain number, date or unit; none praises, shames or cheers.
- mm-pr3, Vocabulary — yes. This change's own strings use "weigh-in",
  "Weight" and "entry"; none uses "up", "down", "lost", "gained", "log",
  "tracker" or "user" (`WeighInNeverShowsTests` scans the never-list
  words at the API level; the string content itself is exhaustively
  spec-quoted, listed above).
- mm-pr4, Nothing looks like a nutrition app — yes. `WeighInScreenView.swift`
  and `WeighInChartView.swift` add no `Image(systemName:)`, no plate, fork,
  scale or tape-measure, and no food photography.
- mm-pr5, The product name and the plan slot — yes. This change writes
  "Midmorning" nowhere beside a meal word; it adds no plan-slot label and
  references no book.
- mm-pr6, What a notification never shows — yes. The weigh-in day
  reminder reuses the shared `DiscreetText`/`ReminderKind` machinery: its
  body is always the time, its explicit title is "Weigh-in day", and it
  carries no weight value (`WeighInStaysOffTodayTests
  .testTheWeighInDayReminderCarriesNoWeightValue`).
- mm-pr7, The person can put it down — yes. "I won't be weighing" is
  always offered, from onboarding and from both the weigh-in screen and
  the settings screen, and turns the weigh-in day off with one tap and no
  message.
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver
  walk, the largest text size and Voice Control still to come (the
  epic's device-check bead). Every control this change adds carries a
  VoiceOver label built from a Programme-owned constant, never a bare
  literal (`WeighInAccessibilityTests`); the weight input, the unit
  control and the weigh-in day control use system controls, which meet
  the 44-by-44 hit area by construction; the chart's line and points
  differ by shape (line vs. point) and by tone (primary vs. secondary),
  not by colour alone.
- mm-pr9, Dates and times in strings — yes. The refusal text's two dates
  and the weigh-in day's name both come from `WeighInDayRule
  .formattedDate`, the en_GB `DateFormatter` the requirement names; the
  reminder time is the 24-hour "HH:mm" every other reminder already uses.
- mm-pr10, Offline and private by default — yes. Every new `RecordStore`
  call (`weighIn`, `weighIns`, `saveWeighIn`, `weighInUnit`,
  `setWeighInUnit`) is a local SwiftData read or write; the weigh-in row
  carries the same file protection and backup exclusion as every other
  row, from the store directory as a whole (`FileProtectionTests`,
  unchanged by this build). This change adds no HealthKit import, no
  HealthKit entitlement and no network call (`WeighInStoreTests
  .testNoHealthKitImportOrEntitlement`).
- mm-pr11, No AI at runtime — yes. `WeighInGate`, `WeighInDayRule`,
  `RollingAverage`, `WeightUnit`, `MissedWeighIn`, `WeighInReminderRule`
  and `UnderweightCheck` are deterministic pure functions over fixed
  inputs; nothing here generates a sentence.
- mm-pr12, Appearance — yes. The screen uses `recordListStyle()` and
  system text styles throughout; the chart uses only `.primary` and
  `.secondary`, the same reasoning `Appearance.swift`'s own accent-colour
  note already documents for contrast (mm-pr12 in `record-full`'s and
  `programme-engine`'s own READMEs); this change adds no new colour, font
  or corner radius.

### Get support on every screen

`WeighInScreenView` carries `.getSupport()` (`GetSupportModifier`, built by
`onboarding-and-safeguarding`, 1.4). It is the one full screen this change
adds; the "Choose a weigh-in day" and "entry" states are the same screen,
not a separate one, so this is its only Get support control to add.

## Constant changes

No `ProgrammeConstants` value changed during this build. `rollingAverageWeeks`
already existed, added by `model-foundation` ahead of this change.

## Scope notes

- "The weigh-in page in an export" is not built: `export` (4.2, `mm-t42`)
  is not merged in this worktree, and this epic names no child bead for
  that requirement. `mm-t42`'s own build ADDs that requirement fresh.
- The sync scenarios of "The weigh-in day" ("The weigh-in day syncs", "Two
  devices set the weigh-in day") and "A widget" (of "The weigh-in stays
  off Today, widgets and notifications") are `deferred: mm-t41b.11` and
  `deferred: mm-t25.15` respectively, per `v1-programme/deferred.md`,
  which named both rows before this change existed.
- "Review without a weigh-in part" (onboarding spec, "Screen 3: weigh-in
  day and quiet hours") stays `deferred: mm-t32.16` (`weekly-review`'s own
  wiring bead), as `onboarding-and-safeguarding`'s own tasks.md already
  set it; this change's onboarding delta adds back only "I won't be
  weighing", the one scenario mm-t22.15 names.
- The weigh-in day reminder's tap-opens-the-screen route
  (`.weighInReminderTapped`) is the first such route any reminder kind
  other than the planned meal's "Add" action has; every other kind still
  falls through to the system's own default (opens Today), because no
  other kind's own requirement yet asks for a different screen.
- `WeighInScreenView.swift`'s `runUnderweightCheck()` is the App-target
  seam that composes `RecordStore` facts into `UnderweightCheckInput` and
  presents `NotRightNowPageView`/`GPSuggestionPageView`; it is not itself
  unit-tested (no App-target test runner), but `RecordTests
  .WeighInSafeguardingFactsTests` and `RecordTests.WeighInWiringTests`
  prove the same composition directly against the real store and the
  real pure functions.
