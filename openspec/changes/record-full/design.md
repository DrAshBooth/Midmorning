# Design

## Context

`openspec/changes/v1-programme/design.md`, "Model names, singletons and the
account binding" and "Pure seams the packages expose", sets the shape: a
custom place is a `ListItem` of kind "customPlace"; screen models are values
that a view renders and holds no rule. `model-foundation` (1.2a) built the
sixteen models, `ItemVersion` with the skeleton's own fields, the Reconciler
and `DayState`. This design adds only what 1.2b's own children need.

## Goals / Non-Goals

**Goals:**

- One shared appearance file every screen after this change uses, so a
  later change adds no appearance modifier of its own.
- Where and Context as additive `ItemVersion` fields, with no second schema
  version.
- Pure functions for the gap band, the collapse default and the custom-place
  order, each provable with `swift test` and fixed dates.

**Non-Goals:**

- The Programme screen, the plan beside the record, or a live card slot.
  `programme-engine` (2.1) and `regular-eating-plan` (2.3) build those; this
  change's Today stack holds their slot and reads a fixture fact where a
  scenario needs one.
- Sync. Every store call in this change stays on the device.

## Decisions

### Appearance.swift holds views, not just modifiers

Two of the five bullets in mm-t12b.3 ("a text field that fills its row" and
"a flow layout for chips") are not expressible as a `View` extension alone,
because they change layout, not just style. `Appearance.swift` holds
`RecordField`, `PredictiveTextView`, `RecordOneLineField` and `FlowLayout`
next to the two modifiers (`recordListStyle`, `recordSheetDetent`). Rejected:
a separate file per view. One file matches "every screen uses these and adds
no appearance modifier of its own".

### The accent tint is set once, at the window

`MidmorningApp` sets `.tint(Color.accentColor)` on its one `WindowGroup`
scene. Every control below inherits it; the star toggle overrides it
locally with the system grey, as a closer modifier always wins. Rejected:
tinting each screen. A screen that forgets the modifier would silently fall
back to the system default, which this build found renders black on the
"Liquid Glass" toolbar button style, not the accent colour.

### `PredictiveTextView` wraps `UITextView`

SwiftUI's `TextField` and `TextEditor` expose no modifier for
`UITextInputTraits.inlinePredictionType` in this SDK (checked against the
installed `SwiftUI.swiftmodule` interface: no symbol). `PredictiveTextView`
is a small `UIViewRepresentable` that sets `inlinePredictionType = .no`,
`autocorrectionType = .yes` and `autocapitalizationType = .sentences`, and
drives focus through a plain `Bool` binding rather than SwiftUI's
`@FocusState`, since `.focused()` targets a native focusable view. `onReturn`
lets one instance serve both a multi-line field (Return inserts a line
break, the default) and a one-line field such as "Add a place" (Return calls
back instead). The device check in mm-t12b.1 confirms the trait on a real
keyboard; decision 89 names the fallback if it does not hold.

### Where and Context on `ItemVersion`; custom places as `ListItem`

`whereText` and `context` join `ItemVersion` with an empty default, so a
version from `model-foundation`'s schema still opens (FrozenSchema.json
grows by addition only). A custom place is a `ListItem` of kind
"customPlace": `text` holds the name, `changedAt` doubles as the last-used
moment. `CustomPlaces.ordered(_:)` sorts by `changedAt` descending and caps
the result at eight; saving a ninth custom place touches (updates
`changedAt` on) an existing row with the same text, or inserts a new one and
lets the ordering function drop the oldest from what it returns. The store
never deletes a `ListItem` row for this; a dropped chip's row still exists,
unread, which matches "The Reconciler never deletes a row".

### Day states reuse `DayState`; the collapse choice is a `LocalSetting`

"Didn't record", "Paused" and "Fasting" are `DayState` rows of kind
`didntRecord`, `paused` and `fasting`, exactly as `model-foundation` shaped
the model ("One row per record day and state kind"). This change adds no
model. The collapse-or-expand choice per record day is a `LocalSetting` row
(`key = "collapse.<dateKey>"`, `value = "expanded"` or `"collapsed"`), per
design.md's `Local.store` table entry "collapse or expand choice per record
day". `CollapseChoice.isExpanded(role:kept:)` is the pure default-and-override
rule "Collapse a day to a count" states.

### The gap band and the Today card slot take fixture facts

`GapBand.indexesAfter(times:stage2Open:dayState:constants:)` is a pure
function over an array of entry times and a `Bool` for "stage 2 is open",
because `programme-engine` (2.1) is not built yet. `TodayCardSlot.next(...)`
takes a `[TodayCardFact]` and the last starred-entry-or-outcome moment,
rather than reading `Answer` rows itself, for the same reason. Both compile
and test with `swift test` today; a wiring bead in a later epic (mm-t21.23,
mm-t31.17, mm-t33.16) supplies the live input.

## Risks / Trade-offs

- [`PredictiveTextView` re-implements what `TextField` gives for free, such
  as growth and Dynamic Type] → it sets `adjustsFontForContentSizeCategory`
  and lets `.fixedSize(horizontal: false, vertical: true)` grow the row; the
  largest-text-size scenario is this change's own test of that path.
- [The fixture-fact seam for the gap band and the card slot means "built
  here" scenarios do not yet run against a live stage] → each scenario's
  task line says so, and the epic's device-check bead and `deferred.md`
  keep the live wiring visible until the later epic closes it.
