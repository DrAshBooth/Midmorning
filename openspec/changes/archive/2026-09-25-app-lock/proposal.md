# Proposal

## Why

Task 1.5 of `v1-programme`. The app holds a person's eating record, so the app lock protects it when the device leaves the person's hands. This change adds the cover, the "Lock after" choice, "Face ID only" and "Touch ID only", the lock control on Today, and the routes from the cover to Delete-all. `mm-t12` (model-foundation) is merged, so `Local.store` and `LocalSetting` already exist for this change to use.

## What Changes

- The `AppLock` package: the label function (`Biometry`, `BiometryLabels`), the lock-grace policy (`LockPolicy`, `LockGrace`), the cover state machine (`AppLifecycle`, `AppLifecycleState`, `CoverMode`), the authentication policy (`AuthenticationPolicy`, `EnrolmentState`), the two seams (`AuthenticationPerforming`, `DeleteAllPerforming`) and the controller (`AppLockController`) that brings them together. Every pure rule is a test with fixed numbers and no clock, no LocalAuthentication and no device.
- `RecordStore.localSettingValue(forKey:)` and `setLocalSetting(key:value:)`, the first read and write access to `LocalSetting` rows, for the app lock's own settings.
- The cover (`CoverView`), wired into the app window over Today (`AppLockRootView`), driven by `AppLockController`. Shows "Midmorning" only while merely inactive (App Switcher privacy, on or off), and "Midmorning", "Unlock" and "Delete everything" (or, after an enrolment change, "Delete from this device" instead of "Unlock") while locked.
- The system authentication request (`LAContextAuthenticator`), the continuous clock (`MachContinuousClock`, from `mach_continuous_time`), biometry detection (`BiometryDetector`) and the enrolment-state hash (`EnrolmentHash`, `evaluatedPolicyDomainState` hashed with SHA-256; a device check confirms the spec's iOS 18 API name, see the README).
- `NSFaceIDUsageDescription` in `App/Midmorning-Info.plist`.
- A stub `DeleteAllPerforming` (`AppLock.RecordingDeleteAllSeam`) the cover calls until 4.1 (`local-delete-all`) lands; it records each call and deletes nothing.
- Two fixture-only views, each built and tested standalone because `settings` (1.3, mm-t13) is not merged in this worktree: `PrivacyAppLockControls` (the app lock switch, "Face ID only"/"Touch ID only" and "Lock after" for the Privacy group) and `LockControlButton` (the lock glyph for Today's navigation bar, decision 91). Neither is wired into a real screen; the change README names the wiring beads that do.
- The pure rule "A new entry before authentication" adds to `AppLock`: `PendingRoute` and the `coverMode` rule that shows no cover while a pending route is set. The entry points themselves (a widget, a notification action, the App Intent, the Control Centre control) are 2.4's and 2.5's own work; this change builds the rule only.

Not in this change: the settings screen itself (1.3, mm-t13, in a parallel worktree), the real Delete-all deletion (4.1), the notification-action and widget entry points (2.4, 2.5), and the App Switcher, VoiceOver, Dynamic Type and biometric-hardware scenarios `deferred.md`-style device checks name in the README.

## Capabilities

### New Capabilities
- `app-lock`: the cover, the lock-grace policy, the authentication policy, the enrolment-state check and the routes to Delete-all, as this change's delta states.

### Modified Capabilities
None. `app-lock` is a new capability in `openspec/specs`. This change also touches one scenario of `settings`' "The About group" (see the delta); `settings` itself stays a new capability for `openspec/specs` until `1.3` archives.

## Impact

- New SwiftPM package target `AppLock` (library) and `AppLockTests`, added to `Packages/Package.swift`.
- `Packages/Sources/Record/LocalSettingStore.swift`: `RecordStore` gains two methods; `context` changes from `private` to internal so the extension, in the same target, can use it.
- `App/Midmorning/AppLock/`: `CoverView.swift`, `AppLockRootView.swift`, `LocalAuthenticationAdapter.swift`, `PrivacyAppLockControls.swift`, `LockControlButton.swift`.
- `App/Midmorning/MidmorningApp.swift`: wraps `TodayView` in `AppLockRootView`.
- `App/Midmorning/Localizable.xcstrings`: the cover's and the delete confirmations' interface strings.
- `App/Midmorning-Info.plist`: `NSFaceIDUsageDescription`.
- `App/Midmorning.xcodeproj/project.pbxproj`: links the `AppLock` package product.
- No network. No new third-party dependency. `AppLock` imports Foundation (and Combine for `ObservableObject`) only; the App target's adapters import LocalAuthentication and CryptoKit, both system frameworks.
