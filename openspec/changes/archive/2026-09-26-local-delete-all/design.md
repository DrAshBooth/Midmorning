# Design

## Context

`openspec/changes/v1-programme/design.md` already states the two decisions
this change builds against: "Delete-all writes an erasure marker before it
deletes the zone" and "No analytics of our own". This document states only
the decisions this change adds on top of them, because sync (`4.1b`) is not
merged yet and the erasure marker and the sync zone are its work, not this
change's.

## Decisions

### `LocalEraser` deletes the directory; the App target drops the store first

`Record.LocalEraser.eraseAndRecreate(directory:fileManager:)` deletes every
item in the store directory, then creates the directory again empty with
`NSFileProtectionComplete`. It never opens a `ModelContainer` and never
touches iCloud. `RealDeleteAllSeam` (App target) sets its `RecordStore`
reference to `nil` before it calls `LocalEraser`, so no open SQLite file
handle from `ModelContainer`/`ModelContext` fights the deletion; the deleted
screen needs no store, so `AppLockRootView` shows it with no reference to a
store at all.

Rejected: deleting each store's tables through `ModelContext`. SwiftData
gives no "drop every model" call, and a directory delete also removes the
`-wal` and `-shm` files and any future sibling file with no per-model list to
maintain.

### Store opening is lazy and checks protected data first

`Record.AppStoreOpening.attempt(protectedDataAvailable:openSucceeded:)` is a
pure decision: `.waitingForProtectedData` when protected data is
unavailable, `.opened` or `.failed` otherwise. `MidmorningApp` no longer
opens `RecordStore` in `init()`. `AppLockRootView` checks
`UIApplication.shared.isProtectedDataAvailable` first and only then
constructs `RecordStore`; it never calls `fatalError`. While waiting it
shows a plain "Midmorning" screen with no control, because the app lock's own
settings live in the store it cannot yet open. A `ModelContainer` failure for
any other reason shows the "cannot open your record" page (`StoreOpenFailureView`)
with Get support, "Try again" and "Delete everything".

Rejected: classifying the thrown error to detect "protected data
unavailable" after the fact. Checking `isProtectedDataAvailable` first is one
system property, not a guess at an error's cause, and it never attempts an
open that would otherwise hang or throw while the device is locked.

### The launch marker tracks a streak, separately from the lifetime count

`Record.LaunchSafety.startLaunch(markerWasUncleared:previousFailureCount:previousConsecutiveUnclearedCount:)`
returns the new lifetime failure count (the Diagnostics page's own count,
which never resets) and the new consecutive-uncleared streak (which resets
to zero the moment Today clears the marker). Safe mode starts at a streak of
three; the lifetime count keeps counting past three on a device that never
recovers.

### Diagnostics counts: three seams stand in for three later epics

`Record.DiagnosticsCounts` is a value with all eight fields. Four counts are
real from this change alone: launch failures, schema version, content
version and crash count. `lastSuccessfulSyncDay` reads a `LocalSetting` key
`4.1b` writes and shows "Never" until then. `pendingReminders` and
`queueLength` come from a `DiagnosticsSourceCounts` seam with a stub
returning zero, which `2.4`'s wiring bead (`mm-t24.20`) replaces.
`lastReconcileOutcome` reads two `LocalSetting` counters
(`RecordStore.recordReconcileOutcome(winners:losers:)`) that stay at zero
until a later change calls a batch reconcile pass; nothing in the shipped
first cut runs one yet, so zero is the true count, not a placeholder.

### MetricKit: a real subscriber, one counter, no payload

`App/Midmorning`'s `MetricKitSubscriber` (an `MXMetricManagerSubscriber`)
calls `Record.CrashDiagnosticsCounter.increment` on
`didReceive(_: [MXDiagnosticPayload])`, which appends one to the crash count
`LocalSetting` and keeps nothing else. The subscriber is a thin adapter with
no logic of its own to unit-test; `CrashDiagnosticsCounter.increment` is the
pure, tested part.

## Risks / Trade-offs

- [The deleted screen and the "cannot open your record" page make
  `AppLockRootView` show one of four things — waiting, the real app, the
  deleted screen, or the failure page] → each is a `switch` over one pure
  `enum` (`Record.AppStoreOpening` plus a `deleted` case `AppLockRootView`
  itself adds), so the branches stay exhaustive and the compiler catches a
  missed one.
- [Zero-valued Diagnostics counts before `2.4`/`4.1b` land look identical to
  a broken counter] → each seam and stub is named in this file and in the
  README's scope note, and `mm-t24.20`/`mm-t41b.11` are the beads that
  replace them.
