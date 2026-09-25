# Proposal

## Why

Task 1.2b in `openspec/changes/v1-programme/tasks.md` names this change. The
walking skeleton (`record-entry-on-today`) built one entry with a time, a
What and a star. The full record needs Where, Context, edit, delete, the day
states, earlier days, collapse and gap bands, so the person can use the
record the way the paper record worked. This change builds the rest of the
Today stack and the new-entry screen on the shared appearance rule.

## What Changes

- `Appearance.swift` and the `AccentColor` asset (decision 92): the shared
  list style, sheet detent, labelled-field layout, chip flow layout and
  accent tint every screen after this change uses.
- `ItemVersion` gains a `whereText` field and a `context` field, added to the
  frozen schema. Both default to an empty string, so an old row still opens.
- Today's shell follows decision 91: the lock control and "Get support" in
  the navigation bar, a bottom toolbar with "Programme", "Reviews" and
  "Settings", and a pinned header with the current day heading and "Add an
  entry".
- The new-entry screen's controls take the order What, Where, "felt like a
  binge", Context, Time (decision 86), with a "Save" control in the
  keyboard's toolbar (decision 87) and record-day segments in the time
  control (decision 88).
- The person can edit and delete an entry, mark a day "Didn't record",
  "Paused" or "Fasting", open earlier record days, collapse a day to a
  count, and see a gap band on a long gap.
- The delta MODIFIES four requirements `record-entry-on-today` already put
  in `openspec/specs/record/spec.md`: "Today's appearance", "Today shows the
  record day's entries in time order", "Accessibility of the record" and
  "Create an entry" (decision 64; mm-t12b.2).

## Capabilities

### Modified Capabilities

- `record`: adds Where, Context, edit, delete, the day states, earlier days,
  collapse, the gap band and the new-entry screen's full control order, and
  modifies four requirements `record-entry-on-today` already added.

## Impact

- `App/Midmorning/Appearance.swift` (new): the shared appearance modifiers
  and the `RecordField`, `PredictiveTextView` and `FlowLayout` views.
- `App/Midmorning/Assets.xcassets/AccentColor.colorset` (new): the accent
  colour, with a light, a dark and an Increase Contrast value.
- `App/Midmorning/TodayView.swift`, `NewEntryView.swift`: the full Today
  stack and new-entry screen; new files `EditEntryView.swift`,
  `EarlierDaysView.swift`, `WhereChips.swift`.
- `Packages/Sources/Record/Models/Item.swift`: `ItemVersion` gains
  `whereText` and `context`.
- `Packages/Sources/Record/FrozenSchema.json`: the two added fields.
- `Packages/Sources/Record/RecordStore.swift`: `update`, `delete`, the day
  state and collapse-choice reads and writes, and custom-place storage.
- New pure-logic files in `Packages/Sources/Record`: `GapBand.swift`,
  `CollapseChoice.swift`, `CustomPlaces.swift`, `DayStates.swift`.
- `tools/skeleton-checks/seeder`: the stale `RecordCore` reference now reads
  `Record` (the product model-foundation renamed), so the seeder builds
  again.

## Decisions this change makes

- Where and Context live on `ItemVersion` as `whereText` and `context`,
  additive fields with an empty default, per the frozen-schema growth rule.
  A custom place is a `ListItem` of kind "customPlace" (design.md, "Model
  names, singletons and the account binding"); its `changedAt` doubles as
  its last-used moment, so recency order needs no new field.
- "Didn't record", "Paused" and "Fasting" are `DayState` rows model-
  foundation already built (kinds `didntRecord`, `paused`, `fasting`); this
  change adds no model for them. The collapse-or-expand choice is a
  `LocalSetting` row keyed by record day, per design.md's `Local.store`
  table.
- `PredictiveTextView` wraps `UITextView` directly. Neither `TextField` nor
  `TextEditor` exposes `UITextInputTraits.inlinePredictionType` in this SDK;
  the representable is the only way to turn inline predictions off while
  keeping autocorrection and sentence capitalisation on (decision 89).
