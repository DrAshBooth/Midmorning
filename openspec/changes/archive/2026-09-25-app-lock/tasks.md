# Tasks

Verify for every task below: `swift test --package-path Packages --filter AppLockTests` passes (plus `RecordTests` for `LocalSettingStoreTests`). `./verify` passes before each close.

## 1. Foundations

- [x] 1.1 Add the `AppLock` package target at `Packages/Sources/AppLock`, with `AppLockTests`, and add both to `Packages/Package.swift`. Verify: `swift build --package-path Packages` succeeds.
- [x] 1.2 `RecordStore.localSettingValue(forKey:)` and `setLocalSetting(key:value:)`, the app lock's own read and write access to `LocalSetting` rows. Verify: `LocalSettingStoreTests` passes.

## 2. mm-t15.1 — The app lock is on by default (P1)

- [x] 2.1 `Biometry`, `BiometryLabels.strings(for:)` and `BiometryLabels.isFaceOrTouchOnlyAvailable`. `NSFaceIDUsageDescription` in `App/Midmorning-Info.plist`. Built here: all 8 scenarios ("Default", "Turn off", "Cancel the turn-off", "No passcode", "Same label at onboarding", "Label function in a test", "Touch ID strings", "Face ID usage description"). Verify: `BiometryLabelsTests` passes.

## 3. mm-t15.2 — Lock after (P1)

- [x] 3.1 `LockGrace.label(forSeconds:)` and `LockGrace.choices`, matching `ProgrammeConstants.lockGraceSecondsChoices`. Built here: all 3 scenarios ("Default", "At once", "Five minutes") as pure-function tests over the label and `LockPolicy.shouldAsk`; the settings screen itself is `mm-t13`'s (not merged in this worktree — see `PrivacyAppLockControls`, task 10). Verify: `LockPolicyTests` passes.

## 4. mm-t15.3 — When the app asks (P1)

- [x] 4.1 `LockPolicy.shouldAsk(enteredBackgroundAt:now:grace:)`, `ContinuousClockReading`, `AppLifecycleState`, `AppLifecycleEvent` and `AppLifecycle.reduce`, behind no UIKit import. Built here: all 9 scenarios ("Launch", "Return within the grace period", "Return after the grace period", "Inactive is not background", "Clock change in the background", "Device locked within the grace period", "Device asleep for an hour", "Policy with a stub clock", "Policy with no grace"), each a pure-function test with fixed numbers and a stub clock. Verify: `LockPolicyTests` and `AppLifecycleTests` pass.
- [x] 4.2 `MachContinuousClock` (App target): reads `mach_continuous_time` and `mach_timebase_info`. `AppLockRootView` raises `didEnterBackground`/`didBecomeActive`/`didBecomeInactive` from `scenePhase`, and `protectedDataWillBecomeUnavailable` from the system notification. Device check: real launch, background and foreground timing on a device (mm-t15.14).

## 5. mm-t15.5 — The cover (P1)

- [x] 5.1 `CoverMode` and `AppLifecycleState.coverMode`: `.none`, `.privacyOnly`, `.locked`, `.lockedAfterEnrolmentChange`, as one pure function of scene phase, lock state, enrolment state and the pending route. Built here: `AppLifecycleTests`' own cover-mode tests prove the state machine for every branch ("The cover shows while locked regardless of scene phase", "the app switcher shows the plain cover with the app lock off", "no cover while active and unlocked").
- [x] 5.2 `CoverView` (App target): the full cover ("Midmorning", "Unlock", "Delete everything") and the plain privacy cover ("Midmorning" only, tap to dismiss with the app lock off), wired over Today's whole window in `AppLockRootView`, so it covers whatever screen sits behind it, present or future. Built here: "App switcher", "Unlock control", "App lock off", "Weigh-in screen", "Get support is covered" — the cover is a window-level overlay with no per-screen exception, so it already covers a screen this worktree does not yet build (weigh-in, Get support); a device check proves the visible mechanism now against Today, and again once each of those screens ships. Device check: all 5 scenarios (mm-t15.14; simulator cannot capture a real App Switcher snapshot or drive the system authentication request).

## 6. mm-t15.7 — Delete everything from the cover (P1)

- [x] 6.1 `DeleteAllPerforming`, `RecordingDeleteAllSeam` (the stub 4.1 replaces) and `AppLockController.tapDeleteEverything`/`confirmDeleteEverything`. Built here: all 3 scenarios ("Delete from the cover", "Cancel the authentication", "Two taps") as async controller tests with `FakeAuthenticator` and `RecordingDeleteAllSeam`, proving the seam is called once, only after both taps, and never after a cancelled request. Verify: `AppLockControllerTests` passes. Device check: the real system authentication request and the "Everything is deleted" screen on a device (mm-t15.14).

## 7. mm-t15.8 — Fallback to the device passcode (P1)

- [x] 7.1 `AuthenticationPolicy.policy(faceOrTouchOnly:)` and `LAContextAuthenticator`'s mapping to `LAPolicy`. Built here: the policy selection behind all 3 scenarios ("Face ID fails", "No biometric enrolled", "Face ID locked out") as a pure-function test. Verify: `AuthenticationPolicyTests` passes. Device check: the real system authentication request offering (or not offering) the device passcode (mm-t15.14).

## 8. mm-t15.9 — Face ID only or Touch ID only (P1)

- [x] 8.1 `EnrolmentState.hasChanged`, `BiometryDetector`, `EnrolmentHash` (App target) and the controller's turn-on/turn-off flows. Built here: "Turn on", "Cancel the turn-on", "Touch ID device", "Face ID fails with Face ID only", "Enrolment changed", "No biometric enrolled" as pure-function and async controller tests. Built here over fixture facts, with no live dependency: "Delete everything after an enrolment change" (mm-t42.20 runs the erasure marker itself end to end; mm-t41b.10 builds that one part). Verify: `AuthenticationPolicyTests` and `AppLockControllerTests` pass. Device check: every biometric-hardware scenario needs a device with Face ID or Touch ID enrolled (mm-t15.14).

## 9. mm-t15.10 — Delete from this device after an enrolment change (P1)

- [x] 9.1 `AppLockController.confirmDeleteFromThisDevice` (no authentication). Built here: all 3 scenarios ("Delete from this device", "Cancel", "Not shown before an enrolment change") — the no-authentication call and the cover's own `coverMode` gating are both pure/async tests. Verify: `AppLockControllerTests` and `AppLifecycleTests` pass. Device check: the real deletion, once 4.1 replaces the stub seam (mm-t15.14).

## 10. mm-t15.11 — Unsaved text survives the lock (P1)

- [x] 10.1 Design decision, not new code: `CoverView` is a window-level overlay that never dismisses `NewEntryView`'s sheet, so its `@State private var what` outlives a lock/unlock cycle with no extra store. Device check: both scenarios ("Return to a draft", "Draft in the app switcher") need a running app and cannot be proven as a pure function (mm-t15.14).

## 11. mm-t15.4 — The lock control on Today (P1)

- [x] 11.1 `LockControlButton` (App target) and `AppLockController.tapLockControl`/`tapCoverToDismiss`. Built here over fixture facts, with no live dependency: "Lock at once", "Lock control with the app lock off" (`AppLifecycleTests`; `mm-t24.21` wires the button into Today's own toolbar end to end). Verify: `AppLifecycleTests` passes.

## 12. mm-t15.6 — A new entry before authentication (P1)

- [x] 12.1 `PendingRoute` and the `coverMode` rule that shows no cover while a pending route is set, plus `pendingRouteRequested`/`pendingRouteResolved` in `AppLifecycle.reduce`. Built here: none (the rule only). Verify: `AppLifecycleTests`' pending-route tests pass.
- [ ] 12.2 Deferred: "Widget tap while locked" (mm-t25.15), "Save while locked" (mm-t25.15), "Cancel the request at Save" (mm-t25.15), "Cancel on the screen" (mm-t25.15), "Notification action while locked" (mm-t24.19), "Actions on a planned meal reminder" (mm-t24.19), "Skipped while the app is locked" (mm-t24.19), "Skipped on the locked device" (mm-t24.19), "Snooze while the device is locked" (mm-t24.19).

## 13. mm-t15.13 — settings: Face ID only in the About group (P1)

- [x] 13.1 Built here over fixture facts, with no live dependency: "Face ID only" (`AuthenticationPolicyTests.testFaceOrTouchOnlySelectsTheBiometricsOnlyPolicy` proves the cover's policy never offers the passcode; `settings`'s own wiring bead under 2.4 shows this beside the real About group). Verify: `AuthenticationPolicyTests` passes.

## 14. mm-t15.12 — Accessibility of the cover (P2)

- [x] 14.1 `CoverView` builds `accessibilityLabel`, `accessibilityFocused` and system text styles for "Unlock", "Delete everything" and "Delete from this device" (built in task 5, "The cover"; this bead proves them, per CLAUDE.md, it does not add them). Device check: all 3 scenarios ("VoiceOver on the cover", "Focus through the system request", "Largest text size") — VoiceOver reading order and focus movement, and AX5 layout, need a device or the simulator's Accessibility Inspector, never a pure-function test (mm-t15.14).

## 15. Close

- [x] 15.1 mm-t15.14 device checks for 1.5: list every pending device check above (tasks 4.2, 5.2, 6.1, 7.1, 8.1, 9.1, 10.1, 14.1) as a `bd comments add mm-t15.14` note. Ash does each check and adds a date and a screenshot to this README.
- [x] 15.2 Write the rules-checklist and safeguarding lines in this README.
- [x] 15.3 Run `./verify` cold and warm; write both times in this README.
