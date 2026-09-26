# Proposal

## Why

Task 4.1 of `v1-programme`. The Privacy group's "Delete everything" and the
cover's "Delete everything"/"Delete from this device" each call a stub today
(`Record.StubDeleteAllSeam`, `AppLock.RecordingDeleteAllSeam`). Neither
deletes a file. `mm-t12` (model-foundation), `mm-t13` (settings) and `mm-t15`
(app-lock) are merged, so this change can replace both stubs with the real
local deletion, and add the launch-safety, Diagnostics and data-protection
requirements the first TestFlight cut needs.

## What Changes

- `Record.LocalEraser`: the pure, testable local-deletion engine. Deletes the
  whole store directory and creates it again empty. `App/Midmorning`'s
  `RealDeleteAllSeam` conforms to both `Record.DeleteAllSeam` and
  `AppLock.DeleteAllPerforming`, so the Privacy group and the cover call the
  same real deletion. The erasure marker and the sync-zone deletion stay
  stubbed; `4.1b` (`sync`) owns `CKSyncEngine` and the "Erasure" zone.
- The "Everything is deleted" and "This device's copy is deleted" screens,
  each shown until the next launch, which then starts onboarding.
- `Record.LaunchSafety`: the pure launch-marker state machine (safe mode on
  the third consecutive uncleared marker), wired into `MidmorningApp` and
  `TodayView`.
- `Record.AppStoreOpening`: the pure decision behind opening the store only
  when protected data is available, and the "cannot open your record" page
  for any other container failure, in place of today's `fatalError`.
- The Diagnostics page (About group) and `Record.DiagnosticsCounts`: schema
  version, content version, launch failures and crash count for real; last
  successful sync day, pending reminders, queue length and last reconcile
  outcome as named seams `4.1b`, `2.4` and `2.5` fill in.
- `Record.CrashDiagnosticsCounter` and an `App/Midmorning` `MXMetricManager`
  subscriber: MetricKit crash diagnostics keep only a count in `Local.store`.
- File protection on every file `RecordStore` creates in the store directory
  (`NSFileProtectionComplete`), on top of the directory-level protection
  `mm-t12` already sets.
- The privacy manifest (`PrivacyInfo.xcprivacy`): the two required-reason API
  categories, no tracking, an empty `NSPrivacyCollectedDataTypes`.
- The rules checklist and the safeguarding "Get support on every screen" line
  in this change's README, for the two screens it adds (the deleted screen
  and the "cannot open your record" page).

Not in this change: the erasure marker, the "Erasure" zone and "Delete
everything offline" (`4.1b`); the widget-snapshot half of "Side files" and
"Widget after Delete-all" (`2.5`); the action-queue and pending-reminders
counts (`2.4`); the App Store submission gate (`mm-t43`).

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `data-and-privacy`: adds "Delete-all", "Delete from this device", "Launch
  safety", "The app holds no analytics of its own", "What never leaves the
  device", "Retention", "File protection", "The app blocks third-party
  keyboards", "The app excludes the whole store directory from backups", "No
  record content in the system log or crash reports", "The Diagnostics
  counts come from the device" and "The privacy manifest and the App Store
  privacy label", each with only the scenarios this change builds.
- `settings`: modifies "The About group" to add the "Diagnostics" scenario.

## Impact

- `Packages/Sources/Record/`: `LocalEraser.swift`, `LaunchSafety.swift`,
  `AppStoreOpening.swift`, `DiagnosticsCounts.swift`,
  `CrashDiagnosticsCounter.swift`, `FileProtection.swift`; `RecordStore`
  gains the file-protection call and a `LocalSetting`-backed reconcile-outcome
  writer.
- `App/Midmorning/AppLock/`: `RealDeleteAllSeam.swift` (conforms to both
  `AppLock.DeleteAllPerforming` and `Record.DeleteAllSeam`),
  `AppLockRootView.swift` (uses the real seam, adds the deleted screen and
  the store-opening states).
- `App/Midmorning/`: `SettingsView.swift` (the Diagnostics page and the real
  seam), `MidmorningApp.swift` (lazy store opening, the launch marker, the
  MetricKit subscriber), `DeletedScreen.swift`, `StoreOpenFailureView.swift`.
- `App/Midmorning-Info.plist` / a new `PrivacyInfo.xcprivacy` file.
- No new SwiftPM package target. No new third-party dependency. `Record`
  keeps importing only Foundation and SwiftData; the App target's adapters
  add UserNotifications and MetricKit, both system frameworks.
