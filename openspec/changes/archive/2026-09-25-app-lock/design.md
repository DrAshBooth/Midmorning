# Design

## Context

This change builds task 1.5 from `openspec/changes/v1-programme/tasks.md`. `openspec/changes/v1-programme/design.md`'s section "App lock covers the window, not the data" states the parent shape: a cover over the window, `mach_continuous_time` for the grace period, the entry-point exception, the enrolment-change route to "Delete from this device", and the biometrics-only policy. Its "Pure seams the packages expose" section names `AppLifecycle.reduce(state, event)`, `LockPolicy.shouldAsk` and `Biometry` as the seams this change must build. This file states only the decisions this change itself makes, where the parent design leaves a gap.

`settings` (1.3, task-numbered `mm-t13`) builds in a separate worktree at the same time as this change and is not merged here. `settings` owns the settings screen itself, its five groups and the Reminders sub-screen; `app-lock` owns what the Privacy group's own three rows say and do. This change cannot embed those rows in a real screen it cannot see, so it builds and tests them as fixtures instead (CLAUDE.md, "Worktrees and beads": "When a scenario needs an epic that Ash has not merged yet, the agent tests it over fixture facts").

## Decisions

### One `coverMode` computed property, never a stored flag

"The cover" and "The lock control on Today" both describe what the app shows while inactive, locked or merely backgrounded, across four distinct pictures: nothing, "Midmorning" only, the full cover, and the full cover with no "Unlock". `AppLifecycleState.coverMode` computes this from `pendingRoute`, `isLocked`, `appLockEnabled`, `enrolmentChanged` and `scenePhase`, so the cover and the state it is drawn from can never disagree, and a test proves every scenario with fixed field values and no view. The one refinement past the parent design: locking through the lock control with the app lock off must show the plain "Midmorning" cover, dismissed by a tap with no authentication request, never the full cover with "Unlock" and "Delete everything" — `coverMode` returns `.privacyOnly` whenever `isLocked` is true but `appLockEnabled` is false. Cost to reverse: low, a pure function with no stored state to migrate.

### `AppLockController` is one `@MainActor` class in the `AppLock` package, not the App target

Every method the cover, the lock control and the Privacy fixture call — `tapUnlock`, `tapDeleteEverything`, `confirmDeleteEverything`, `confirmDeleteFromThisDevice`, `tapTurnOffAppLock`, `tapTurnOffFaceOrTouchOnly` — is `async` over the two protocol seams (`AuthenticationPerforming`, `DeleteAllPerforming`), so it carries no LocalAuthentication or UIKit import and a test drives every request-response flow ("Two taps", "Cancel the authentication", "Delete from this device") with `FakeAuthenticator` and `RecordingDeleteAllSeam`. The App target supplies the real seams (`LAContextAuthenticator`, and the same `RecordingDeleteAllSeam` as an interim stub) and the SwiftUI views that call the controller. Cost to reverse: low — a later change can split the controller in two without changing either seam's shape.

### Delete-all calls a recording stub until 4.1 lands

`DeleteAllPerforming` is a two-method protocol (`deleteEverything`, `deleteFromThisDevice`); the app registers `AppLock.RecordingDeleteAllSeam`, an actor that only counts each call. `mm-t15.7` and `mm-t15.10` build the cover's two controls and their confirmations, proven against the recording stub; 4.1 (`local-delete-all`) replaces the app's registered implementation with the real `ErasureZone` state machine `openspec/changes/v1-programme/design.md` names, with no change to the protocol. The "Everything is deleted" screen shows regardless, because it is the cover's own UI, not the seam's concern. Cost to reverse: none — swapping the implementation is the design's whole point.

### The enrolment-state hash reads `evaluatedPolicyDomainState`, not the spec's named iOS 18 API

`app-lock`'s "Face ID only or Touch ID only" requirement names `LAContext.domainState.biometry.stateHash` on iOS 18 and later. `EnrolmentHash.current()` instead reads `context.evaluatedPolicyDomainState` (stable since iOS 8) on every OS version and hashes it with SHA-256, so the type compiles against whatever SDK `./verify`'s `xcodebuild` step uses without a `#available` branch this change cannot test either side of. `EnrolmentState.hasChanged(current:kept:)`, the pure comparison, is what a test drives with fixed hashes; which real API supplies the "current" hash is a device concern the epic's device-check bead lists. Cost to reverse: low — swapping the hash source changes one function's body, never its callers.

### Two fixture views stand in for the Privacy group and Today's lock control

`PrivacyAppLockControls` (the app lock switch, "Face ID only"/"Touch ID only", "Lock after") and `LockControlButton` (the lock glyph) are SwiftUI views built and previewable on their own, over `AppLockController`, with no settings screen or Today toolbar to embed them in yet. `mm-t13`'s own wiring bead embeds the first in the real Privacy group; `mm-t24.21` embeds the second in Today's navigation bar. Neither uses the shared accent colour, because `Appearance.swift` and the `AccentColor` asset are `record-full`'s (`mm-t12b`) own first child and are not in this worktree; both adopt it once that change merges. Cost to reverse: low — each is a small, self-contained view a wiring bead composes into a parent screen.

## Risks / Trade-offs

- [Two build changes each touch `LocalSetting` and the Privacy group at once] → `mm-t13` and `mm-t15` build in parallel worktrees; Ash resolves the merge, and each side's keys (`appLock.*` here) are namespaced so a merge cannot silently overwrite the other's row.
- [Simulator cannot verify Face ID, Touch ID, an enrolment change or the App Switcher snapshot] → every such scenario is a device check in this change's device-check bead (`mm-t15.14`), never a `swift test`; `openspec/changes/v1-programme/design.md`'s own risk register already states this for the whole programme.
- [`RecordStore.context` changes from `private` to internal] → `LocalSettingStore.swift` needed it to add `LocalSetting` access without touching `RecordStore`'s own file; `context` stays invisible outside the `Record` target, so no external contract changes.
