# Design

See `openspec/changes/v1-programme/design.md`, "Pure seams the packages
expose" and the `Measure`/`Settings` rows in its store table. This change
makes no design decision `v1-programme` does not already state; its own
choices are narrower and listed here and in `proposal.md`'s "Decisions this
change makes".

## The screen's input state is one pure function over plain facts

`WeighInGate.inputState(weighInWeekday:currentDayKey:todaysWeighIn:
lastWeighInDayKey:now:calendar:)` returns one of four cases: `.chooseDay`,
`.entry(prefill:)`, `.fixedForToday` or `.refusal(nextDayKey:)`. The
screen's own `reload()` gathers the facts from `RecordStore` and hands them
to this one function, the same "screen models are values" seam
`v1-programme/design.md` already states for `StageScreenModel`. Keeping
`.fixedForToday` distinct from `.refusal` matters: the requirement's
refusal text is stated for "any other day," not for the weigh-in day itself
once its own 10-minute window has closed, so folding the two together would
show refusal text the spec never asks for on the weigh-in day itself.

## The six-day gate as a forward scan, not a closed-form date

`WeighInDayRule.nextAcceptedDayKey` scans forward one day at a time,
checking the weekday and the six-day gate together, for at most fourteen
days. A closed-form calculation (next occurrence of the weekday, then push
forward again if the gate still fails) needs the same two checks and the
same worst case (the gate can push past one weekly occurrence, never two,
since the gate's own minimum is six days and a weekday repeats every
seven); the scan reads directly against the requirement's own two rules and
needs no separate proof that the closed form covers every input.

## Rule C's own comparison point comes from the rolling-average series, not the raw weigh-ins

Safeguarding's Rule C compares "the rolling average with the rolling
average at the latest weigh-in 28 or more days earlier" — both sides are
already-averaged values, not raw weigh-ins. `RollingAverage
.averageAtLeastDaysEarlier` takes the same `[RollingAveragePoint]` series
the chart itself builds, so the two never compute the window twice with a
chance of disagreeing.

## `UnderweightCheckInput` takes a plain `Double?`, not a series

`Packages/Programme/Safeguarding/UnderweightCheck.swift` takes
`averageAtLeast28DaysEarlierKg: Double?` rather than the weigh-in series
itself. `safeguarding`'s own folder never imports anything from
`WeighIn`'s series type this way; the caller (the screen, or a test)
resolves the lookup first. This mirrors `v1-programme/design.md`'s existing
rule that a pure function takes the fact it needs, not the larger value the
fact comes from.

## Reused, not rebuilt: the not-right-now and GP suggestion pages

`onboarding-and-safeguarding` (1.4) already built `NotRightNowPageView` and
`GPSuggestionPageView` generically, anticipating this change's own trigger
(`mm-t14.21`/`mm-t14.22`'s own doc comments name `mm-t22` directly). This
change adds no new page, paragraph or reason text: `UnderweightCheck
.notRightNowReasons`/`.gpSuggestionReasons` map Rules A/B/C onto the
existing `ExclusionReason`/`GPSuggestionReason` cases those pages already
render.

## Rejected: a hand-written `AXChartDescriptor` for the chart

Swift Charts (iOS 16+) builds its own accessible representation, including
the audio graph, directly from a `Chart`'s marks. A hand-written
`AXChartDescriptor` would duplicate that representation for no behaviour
the default does not already give, and risks disagreeing with it. Rejected
for this reason; the real VoiceOver walk over the default representation is
a device check (mm-t22.14, the epic's device-check bead). Cost to reverse:
low, since adding a custom descriptor later would only add detail, not
replace anything this change relies on.
