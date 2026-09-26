# Design

See `openspec/changes/v1-programme/design.md`, "One umbrella package, five
targets" (the `Plan` target's place in the dependency graph) and "A planned
meal matches entries by a window" (the window and matching algorithm this
change implements). This change makes no design decision `v1-programme`
does not already state; its own choices are narrower and listed in
`proposal.md`'s "Decisions this change makes".

## Why `Plan` takes value facts, not `Record` models

`Plan`'s functions never see a `RecordRow` or an `Answer`. They take
`PlannedMeal` (a slot index and a "HH:mm" time), `PlanEntryFact` (an id and a
time) and plain booleans (`hasMatchedEntry`, `hasSkippedAnswer`, and so on).
The app target and `RecordStore`'s call sites gather these facts from the
store and pass them in. This keeps every rule testable with fixed dates on
macOS, the same seam `Programme` (2.1) will later use for the stage engine,
and it is why `Record` can depend on `Plan` (for the slot and planned-meal
shape) with no cycle: `Plan` depends on nothing but `Constants`.

## Why the plan builder locks a slot, not the whole day

"Edit tonight for tomorrow, or this morning for today" locks a planned meal
that already has a matched entry or a "Skipped" answer, one slot at a time,
rather than locking "Today's plan" once anything on it has an entry. A
person often adds entries through the day while other planned meals are
still ahead; locking the whole screen after the first entry would block
every edit to the rest of the day, which the requirement's own scenario ("the
person can change Evening meal") rules out.
