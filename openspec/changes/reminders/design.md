# Design

See `openspec/changes/v1-programme/design.md`, "The scheduler is a pure function over a rolling horizon" and "Locked-state actions use the notification's payload". This change makes no design decision `v1-programme` does not already state; its own choices are narrower and listed in `proposal.md`'s "Decisions this change makes".

## The seven-step pipeline as one function over plain candidates

`Scheduler.pipeline(_:switches:remindersPausedAt:quietHoursOn:quietHoursStart:quietHoursEnd:constants:)` takes a flat `[ReminderCandidate]` list (a kind, a record day key, an optional slot index, a clock time) and returns the survivors. Steps 1, 2 and 4 are whole-list operations; steps 5 and 6 group by record day first, because the cap and the same-minute shift are each one record day's own rule; step 7 is a whole-list quiet-hours filter. Step 3 (a paused day drops the rest of that day) is the caller's own job: `Scheduler.candidates(for:settings:)` returns no candidate at all for a `SchedulerDay` with `isPaused` set, so a paused day never reaches the pipeline in the first place.

Step 4, the reduced cadence after `finishDate`, is a first-cut no-op: nothing here computes it, because `staying-on-track` (3.6) owns the rule (`mm-t36.17`/`mm-t36.21`, `deferred.md`). The pipeline still names the step, in comments, at its place in the order, so a later change adds one line rather than restructuring the function.

## The same-minute shift as one forward sweep

The naive reading of "move the lower-priority one five minutes later, repeat until none share a minute" is an iterative fixed-point loop. That loop can move two colliding candidates to the same new minute when a later candidate's own natural time coincides with an earlier candidate's post-shift time (traced by hand against the "Three at one minute" scenario, which the loop failed). `SameMinuteShift` instead sorts every candidate once, by (natural minute, priority), and sweeps forward, assigning each one `max(its own natural minute, the last assigned minute + 5)`. This is the same algorithm as scheduling non-overlapping intervals in priority order, and it is correct in one pass because the sort order already agrees with the assignment order.

## `PlannedMealFact.matchedBeforeReminderTime` instead of a live match call

The reminders spec bases "An entry before the time" and "The plan changes" on `regular-eating-plan`'s own window-and-match rule, which lives in `Plan`. Since `Scheduler` cannot import `Plan`, the caller (a `RecordStore`-backed helper in the App target) runs `PlanMatching.match` itself and passes the boolean result in. The scheduler's own contract is therefore "the caller has already resolved the match", not "the scheduler resolves the match" — consistent with the design's existing seam list, which gives `Plan` sole ownership of the window-and-match algorithm.

## Rejected: a shared canonical `QuietHours` type in `Constants`

Moving `Plan.QuietHours` and this change's `ReminderQuietHours` into `Constants` would remove the duplication `proposal.md` names. Rejected for this change: `Constants` is a leaf value-only target (`ProgrammeConstants`); giving it a function type changes its shape for every target that imports it, which no bead here asks for. Cost to reverse: low — a later change can move both call sites to a shared type without changing either one's public API shape (both already take `time`, `start`, `end` as "HH:mm" strings).
