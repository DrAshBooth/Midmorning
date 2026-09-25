# model-foundation

1.2a from `openspec/changes/v1-programme/tasks.md`: the sixteen neutral models, entry versions, per-row change moments, settings rows, the Reconciler, the frozen-schema file and `ProgrammeConstants`.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in a new worktree): 8 seconds. Warm `./verify`: 1 second. Both are well inside the 240-second budget.

## The rules checklist

Every item below is a dated yes for 25 September 2026, written by the agent that built this change. This change adds no screen, no user-facing string, no notification and no card: it is a Swift package change to `Record` and `Constants` only. Each line states why the constraint holds.

- mm-pr1, The never list — yes. This change adds no screen, so it adds no count, total, streak or colour-coded value.
- mm-pr2, Tone of every string — yes. This change adds no user-facing string.
- mm-pr3, Vocabulary — yes. Every model, field and Reconciler name in this change uses a neutral or a defined term (`Entry`, `RecordRow`, `dayKey`, and so on); none names eating, weight or a screening word outside the model layer's own neutral CKRecord names, which the data-and-privacy spec itself requires to stay neutral.
- mm-pr4, Nothing looks like a nutrition app — yes. This change adds no screen and no icon.
- mm-pr5, The product name and the plan slot — yes. This change adds no reminder and no notification.
- mm-pr6, What a notification never shows — yes. This change schedules no notification.
- mm-pr7, The person can put it down — yes. This change adds no screen with a pause control to build.
- mm-pr8, Accessibility everywhere — yes. This change adds no screen; `TodayView` and `NewEntryView` keep the accessibility behaviour `record-entry-on-today` already built, now reading `RecordRow` in place of the old `Entry` model, with no visible or VoiceOver-facing change.
- mm-pr9, Dates and times in strings — yes. `RecordRow.clockTime` keeps the existing en-GB, 24-hour formatter from the walking skeleton; this change adds no new formatted string.
- mm-pr10, Offline and private by default — yes. Every store configuration opens with `cloudKitDatabase: .none`; this change adds no network code and no third-party dependency.
- mm-pr11, No AI at runtime — yes. This change computes no sentence; the Reconciler and `ProgrammeConstants` are deterministic pure functions and values.
- mm-pr12, Appearance — yes. This change adds no screen; `Appearance.swift` is 1.2b's own first child (mm-t12b.3), per the constraint bead's own description.

This change adds no full screen, so no "Get support on every screen" line applies.

## Device checks

None. Every scenario this change builds maps to a `swift test` target; the epic's device-check bead (mm-t12.30) lists none from this change. `record-full` (1.2b) is the change that next touches the App target's screens and will need its own device checks.

## Scope note: Where and Context

`ItemVersion` does not yet carry Where or Context. `design.md`'s "`ItemVersion` carries the skeleton's fields now; Where and Context wait for 1.2b" decision states why: `record-full` (1.2b) is the task that names "Where, Context, edit, delete" as its own scope, and the frozen-schema rule lets it add both fields additively without a second schema version.
