# record-full

1.2b from `openspec/changes/v1-programme/tasks.md`: the Today stack, Where,
Context, edit, delete, the day states, earlier days, collapse and gap bands,
on the shared appearance rule (`Appearance.swift`, decision 92).

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 12 seconds. Warm `./verify`: 2 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 25 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. The collapsed count line shows a plain count
  of entries, the one exception "Today's appearance" itself states; no
  screen this change adds shows a total, a streak, a badge or a colour-coded
  entry.
- mm-pr2, Tone of every string — yes. Every string this change adds names a
  control or a fact ("Pause for today", "Didn't record", "Could not save.
  Try again."); none praises, shames or cheers.
- mm-pr3, Vocabulary — yes. No string in this change uses "meal", "food",
  "log", "diary", "intake" or "eat"; "felt like a binge" is the only place
  "binge" appears, as `record` requires.
- mm-pr4, Nothing looks like a nutrition app — yes. The only glyphs this
  change adds are `lock` and `chevron` (in `chevron.down`, `chevron.left`
  and `chevron.right`), both on the allowed list; no food, scale or body
  image.
- mm-pr5, The product name and the plan slot — yes. This change schedules no
  notification and adds no reminder string.
- mm-pr6, What a notification never shows — yes. This change adds no
  notification.
- mm-pr7, The person can put it down — yes. "Pause for today" is reachable
  from Today in one tap, "Didn't record" and "Fasting today" are toggles the
  person can turn off at any time, and none narrates a broken commitment.
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver walk
  still to come (mm-t12b.1). Every row is one accessibility element with the
  order "Accessibility of the additions" states; the day heading carries the
  header trait and "Collapse day"/"Expand day"/"Didn't record" custom
  actions; a two-finger double tap (VoiceOver's Magic Tap) opens the
  new-entry screen; every control keeps a system text style and scales with
  Dynamic Type; the star and every day-state line avoid depending on colour
  alone.
- mm-pr9, Dates and times in strings — yes. `DayHeading` and
  `RecordRow.clockTime` fix the locale to en-GB, the Gregorian calendar and
  the 24-hour clock; nothing in this change reads the device locale.
- mm-pr10, Offline and private by default — yes. Every new `RecordStore`
  call (`update`, `delete`, `setDayState`, `setCollapseChoice`,
  `touchCustomPlace`) is a local SwiftData write; this change adds no
  network code.
- mm-pr11, No AI at runtime — yes. Every rule this change adds
  (`GapBand`, `CollapseDefault`, `TodayCardSlot`, `CustomPlaces`,
  `NewEntryTime`) is a deterministic pure function; nothing generates a
  sentence.
- mm-pr12, Appearance — yes. `Appearance.swift` and the `AccentColor` asset
  are this change's own first child (mm-t12b.3); every later screen in this
  change (`NewEntryView`, `EditEntryView`, `WhereChipsView`,
  `EarlierDaysListView`, `EarlierDayDetailView`) uses `recordListStyle()`,
  `recordSheetDetent()`, `RecordField` or the one accent tint, and adds no
  appearance modifier of its own. See "Appearance evidence" below for the
  accent values and their contrast.

### Get support on every screen

The new-entry and edit sheets close in one tap to Today (Cancel or Save),
where "Get support" is visible, so the safeguarding spec's sheet exemption
covers both ("Get support on every screen": "A sheet that closes in one tap
to a screen with the control is exempt"; its own "New-entry screen" scenario
states this for the new-entry sheet by name). "Earlier days" and its day
detail are pushed screens, not sheets, so each carries its own trailing
"Get support" placeholder beside "Today" on the day detail screen. Every one
of these controls is a placeholder: `onboarding-and-safeguarding` (1.4) has
not landed, so the control opens nothing yet. This is not itself a screen
the safeguarding requirement governs today — that requirement is still a
delta in `v1-programme`, not yet in `openspec/specs` — but the placeholders
keep the later change's own wiring a content change, not a layout change.

## Appearance evidence (mm-t12b.3)

`App/Midmorning/Assets.xcassets/AccentColor.colorset` holds three values,
each contrasting with the row background (`.systemBackground`, white in
light mode and black in dark mode) at 3:1 or more:

| Appearance | Hex | vs white | vs black |
| --- | --- | --- | --- |
| Light (default) | `#1F4E79` | 8.7:1 | — |
| Dark | `#7CB4E6` | — | 9.5:1 |
| Increase Contrast (either mode) | `#5078A0` | 4.6:1 | 4.5:1 |

Screenshots of Today with a starred entry, before this change's own screens
existed (`record-full`'s first child, so still the walking skeleton's row
shape plus the new tint):

- `evidence/appearance-today-light.png` — light mode.
- `evidence/appearance-today-dark.png` — dark mode.
- `evidence/appearance-today-ax5.png` — the largest accessibility text size
  (AX5); no truncation, the asterisk and time keep the primary text colour.

In each, the "Add an entry"-era "+" control (removed later in this change,
by "The Today stack") shows the accent colour, and the time and asterisk
keep the primary text colour, as the scenario "One accent colour on Today"
(product-rules spec, "Appearance") states.

## Simulator evidence (mm-t12.15, mm-t12.16, mm-t12.17, mm-t12.19, mm-t12.20, mm-t12.22, mm-t12b.4)

`tools/skeleton-checks/HarnessUITests/RecordFullChecks.swift` drives the
built app the same way the walking skeleton's checks did (see that folder's
README for the run steps; this change also fixed a stale `RecordCore`
product reference in `tools/skeleton-checks/seeder` that model-foundation's
rename had left behind, so the seeder builds again). Two runs, 25 September
2026:

- `testAddEditDeleteWithWhereAndContext`: opens the new-entry screen from
  "Add an entry", fills What, a fixed Where chip, the star and Context,
  saves, confirms the row shows "23:26\*, Toast and tea, Home, Row with my
  sister" in the order the spec states, opens an entry for editing, deletes
  it from the edit screen's confirmation, and confirms it is gone.
  Screenshots: `evidence/rf-01-today.png` through `evidence/rf-08-today-after-delete.png`.
- `testPauseCollapseAndEarlierDays`: taps "Pause for today" and confirms the
  control reads "Paused for today". Screenshot: `evidence/rf-09-paused.png`.

These runs also confirm the keyboard's own "Save" control
(`PredictiveTextView.makeAccessoryToolbar()`, decision 87): SwiftUI's
`.toolbar(placement: .keyboard)` does not attach to a `UIViewRepresentable`'s
own `UITextView`, so it never appeared in an earlier build of this screen;
`evidence/rf-04-context-filled.png` shows the fix, a floating "Save" control
above the keyboard.

## Device checks

Every device-only check is listed on the epic's device-check bead
(mm-t12b.1): the inline-prediction check in What, Context and "Add a place"
(decision 89), VoiceOver focus and the reading order on the new-entry and
edit screens, the largest-text-size large content viewer on the navigation
bar's buttons, and the shame walk. Ash does each check and adds its date and
screenshot to this README.

## A note on `PredictiveTextView`

SwiftUI's `TextField` and `TextEditor` expose no modifier for
`UITextInputTraits.inlinePredictionType` in this SDK (there is no such
symbol in the installed `SwiftUI.swiftmodule` interface). `Appearance.swift`
wraps `UITextView` directly for What, Context and "Add a place", setting
`inlinePredictionType = .no` while keeping autocorrection and sentence
capitalisation on. The device check in mm-t12b.1 (decision 89) confirms the
trait on a real keyboard; if it does not hold, Ash rules on the documented
fallback (autocorrection, spell check, inline predictions and smart insert
off, with sentence capitalisation on).

## Scope notes

- The Today stack's card slot, the "Getting started" line, "Today's plan"
  and the notification permission line are structural slots this change
  adds no content to: `programme`, `regular-eating-plan` and `reminders` own
  that content, and none of those capabilities is built yet. Showing nothing
  there is the correct state today, not a bug.
- The gap band's `stage2Open` fact and the card slot's pending cards are
  fixture inputs (`GapBand`, `TodayCardSlot`), because `programme-engine`
  (2.1) is not built. `mm-t21.23` is the wiring bead that supplies the live
  values; until then no band and no card shows on a live build, which is the
  safe default.
- `tools/skeleton-checks/seeder`'s stale `RecordCore` reference (from before
  `model-foundation` renamed the product to `Record`) is fixed in this
  change, since this change is the first to need the seeder again.
