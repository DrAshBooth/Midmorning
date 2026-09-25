# app-lock

1.5 from `openspec/changes/v1-programme/tasks.md`: the cover with "Unlock" and "Delete everything", "Lock after" on the continuous clock, "Face ID only"/"Touch ID only", and the lock control on Today.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this worktree): 11 seconds. Warm `./verify`: 8 seconds. Both are well inside the 240-second budget.

## Scope notes

- **`settings` (1.3, `mm-t13`) is a parallel worktree, not merged here.** `PrivacyAppLockControls` (the app lock switch, "Face ID only"/"Touch ID only", "Lock after") and `LockControlButton` (Today's lock glyph) are built and tested as standalone, fixture-only views over `AppLockController`, per CLAUDE.md's "the agent tests it over fixture facts" rule. `mm-t13`'s own wiring bead embeds `PrivacyAppLockControls` in the real Privacy group; `mm-t24.21` embeds `LockControlButton` in Today's own navigation bar.
- **`Appearance.swift` and the shared `AccentColor` asset (decision 92, mm-pr12) are `record-full`'s (`mm-t12b`) own first child and are not in this worktree.** Every view this change adds uses plain system styling — system colours (`Color(.systemBackground)`), system text styles (`.largeTitle`, `.title2`, `.body`) and the one SF Symbol product-rules allows for a lock ("lock") — and sets no colour of its own, so a `Button`'s default tint already becomes the accent colour automatically once that asset lands, with no further change needed here.
- **The enrolment-state hash reads a stable API, not the spec's named iOS 18 one.** `app-lock`'s "Face ID only or Touch ID only" requirement names `LAContext.domainState.biometry.stateHash` on iOS 18 and later. `EnrolmentHash.current()` reads `context.evaluatedPolicyDomainState` (stable since iOS 8) on every OS version instead, hashed with SHA-256, documented in `design.md`. A device check confirms the real enrolment-change behaviour; the pure comparison (`EnrolmentState.hasChanged`) is what a test drives.
- **Delete-all is a stub until 4.1 (`local-delete-all`) merges.** The cover's "Delete everything" and "Delete from this device" controls, and their confirmations, call `AppLock.RecordingDeleteAllSeam`, which only records each call and deletes nothing. 4.1 replaces the app's registered `DeleteAllPerforming` implementation; the protocol does not change.
- **"A new entry before authentication" (mm-t15.6) builds the pure rule only.** `PendingRoute` and the `coverMode` rule that shows no cover while a pending route is set are built and tested; every scenario belongs to an entry point 2.4 (`mm-t24.19`) or 2.5 (`mm-t25.15`) builds, so none is added to this change's own spec delta — see `tasks.md`, section 12.

## The rules checklist

Every item below is a dated yes for 25 September 2026, written by the agent that built this change (`bd list -l constraint --all`).

- mm-pr1, The never list — yes. The cover shows "Midmorning" and two or three controls only; it never shows an entry, a count, a weight or a plan, and this change adds no total, streak or colour-coded value.
- mm-pr2, Tone of every string — yes. Every string this change adds ("Unlock", "Delete everything", "Delete from this device", the two enrolment warnings, the deletion messages) is copied verbatim from the app-lock spec's own requirement text; this change invents no new user-facing wording.
- mm-pr3, Vocabulary — yes. Every string uses the defined terms ("record", "plan", "weigh-ins", "lists", "settings", "Delete-all") and no banned word; "the app lock" and "Face ID only"/"Touch ID only" are the spec's own names, not synonyms for anything on the never list.
- mm-pr4, Nothing looks like a nutrition app — yes. The cover shows text only, no image; `LockControlButton`'s one glyph is the lock SF Symbol, which product-rules' Appearance requirement names directly, not a plate, fork, apple, scale or tape measure.
- mm-pr5, The product name and the plan slot — yes. The cover writes "Midmorning" with no hyphen and beside no meal word; this change adds no reminder or notification.
- mm-pr6, What a notification never shows — yes. This change schedules no notification.
- mm-pr7, The person can put it down — yes. The app lock switch, "Face ID only"/"Touch ID only" and "Lock after" are each a setting the person can turn off or change; this change does not touch "Pause for today".
- mm-pr8, Accessibility everywhere — yes. `CoverView` gives "Unlock", "Delete everything" and "Delete from this device" a VoiceOver label equal to their visible text, uses system text styles throughout, and moves accessibility focus to "Unlock" (or "Delete from this device" after an enrolment change) when the cover appears; every control is a standard `Button`, which keeps the system's 44-point hit area. The P2 accessibility bead (mm-t15.12) proves VoiceOver reading order, focus during the system request, and AX5 layout on a device, per CLAUDE.md ("the P2 accessibility bead proves them with tests and device checks; it does not add them").
- mm-pr9, Dates and times in strings — yes. This change adds no date- or time-formatted string; "Lock after"'s four labels ("At once", "30 seconds", "2 minutes", "5 minutes") are fixed words, not a formatted duration.
- mm-pr10, Offline and private by default — yes. `LocalAuthentication` and `mach_continuous_time` need no network; every app-lock setting is a `LocalSetting` row in `Local.store`, which never syncs; this change adds no network code and no third-party dependency.
- mm-pr11, No AI at runtime — yes. This change computes no generated sentence; `AppLifecycle.reduce`, `LockPolicy.shouldAsk` and the label function are deterministic pure functions over fixed inputs.
- mm-pr12, Appearance — yes, with the scope note above. Every view uses system colours and system text styles, sets no custom colour, and uses only the "lock" glyph from product-rules' four allowed symbols; a control's tint is left at the system default, which becomes the shared accent colour automatically once `mm-t12b` lands the `AccentColor` asset, with no further change needed here.

## Get support on every screen

The cover is the one full screen this change adds, and the safeguarding spec states the cover is exempt by name: "The cover is exempt, because the cover names nothing" (safeguarding spec, "Get support on every screen"). `app-lock`'s own "The cover" requirement states the same rule from this side: "The cover MUST NOT show Get support, because the cover names nothing." `CoverView` shows no Get support control, matching both. `PrivacyAppLockControls` and `LockControlButton` are rows and a toolbar button for another screen to embed, not full screens of their own, so neither needs the control.

## Device checks

Every scenario below needs a device or the simulator's own hardware-backed behaviour (Face ID, Touch ID, the App Switcher snapshot, VoiceOver, Dynamic Type at AX5) that `swift test` cannot drive; `design.md`'s parent risk register states this for the whole programme. Ash does each check and adds a date and a screenshot to this README; the agent lists these on the epic's device-check bead (`mm-t15.14`), which is a `human`-labelled bead this agent does not close.

1. Launch, background and foreground timing against the real clock (task 4.2; requirement "When the app asks").
2. "App switcher", "Unlock control", "App lock off" — all against Today, which exists in this worktree now; "Weigh-in screen" and "Get support is covered" — the same window-level cover mechanism, re-verified once each screen ships (task 5.2; requirement "The cover").
3. The real system authentication request and the "Everything is deleted" screen for "Delete everything from the cover" (task 6.1).
4. The device passcode fallback for "Fallback to the device passcode" (task 7.1).
5. Every biometric-hardware scenario of "Face ID only or Touch ID only": "Turn on", "Cancel the turn-on", "Touch ID device", "Face ID fails with Face ID only", "Enrolment changed", "Delete everything after an enrolment change", "No biometric enrolled" (task 8.1).
6. The real deletion for "Delete from this device after an enrolment change", once 4.1 replaces the stub seam (task 9.1).
7. "Return to a draft" and "Draft in the app switcher" for "Unsaved text survives the lock" (task 10.1).
8. "VoiceOver on the cover", "Focus through the system request" and "Largest text size" for "Accessibility of the cover" (task 14.1).
