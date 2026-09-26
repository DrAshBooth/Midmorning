# Tasks

Every task's verify command is `swift test --package-path Packages` and `xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning -destination 'generic/platform=iOS Simulator' build`, folded into `./verify` before each child closes. Each task names its bead, its requirement heading and spec file, and maps each scenario the requirement lists to a test here, to a device check, or to a `deferred: <bead id>` pointer.

## 1. Delete-all

- [x] 1.1 mm-t41.1 — data-and-privacy, "Delete-all". `Record.LocalEraser`, `Record.LocalDeletion` (the tested engine); `App/Midmorning/AppLock/RealDeleteAllSeam.swift` (a thin adapter — the App target has no test target, so the engine it calls is what carries the test coverage); `DeletedScreen.swift`. Scenarios "Delete everything", "Next launch", "Cancel" — `LocalEraserTests.swift`, `LocalDeletionTests.swift`. Scenario "Pending requests first" — built here over fixture facts, with no live dependency on a real notification centre — `LocalDeletionTests.swift`'s `FakeDeleteAllSideEffects`; `mm-t42.20` (a wiring bead) runs it end to end. Scenario "Delete everything offline" is `deferred: mm-t41b.10`.

## 2. Delete from this device

- [x] 2.1 mm-t41.2 — data-and-privacy, "Delete from this device". `RealDeleteAllSeam.deleteFromThisDevice()`, over the same `Record.LocalDeletion` engine; `DeletedScreen.swift`'s "This device's copy is deleted" text. Scenario "Delete from this device with sync off" — `LocalDeletionTests.swift` (the engine draws no distinction between the two calls; both delete the same local files). Scenario "Pending requests first" — built here over fixture facts, with no live dependency — `LocalDeletionTests.swift`; `mm-t42.20` runs it end to end. Scenarios "Delete from this device with sync on" and "Get it back after the deletion" are `deferred: mm-t41b.11`.

## 3. Launch safety

- [x] 3.1 mm-t41.3 — data-and-privacy, "Launch safety". `Record.LaunchSafety`, `Record.AppStoreOpening`; `App/Midmorning/MidmorningApp.swift` (the launch marker file, safe mode), `AppLockRootView.swift` (lazy store opening, the four-phase root), `StoreOpenFailureView.swift`. Scenarios "Marker cleared", "Launch failures counted", "Try again" — `LaunchSafetyTests.swift` (`LaunchSafetyTests`, `AppStoreOpeningTests`). Scenarios "Third launch with an uncleared marker" and "Store fails to open" — built here over fixture facts, with no live dependency on a real three-launch restart or a real container failure — the same file; `mm-t42.20` runs each end to end.

## 4. The app holds no analytics of its own

- [x] 4.1 mm-t41.4 — data-and-privacy, "The app holds no analytics of its own". `SettingsView.swift`'s "Share App Analytics with Apple" row (the Privacy group's own requirement heading is not in `openspec/specs` yet — the settings change, mm-t13, built no scenario of it — so this task adds the row itself, over `UIApplication.openSettingsURLString`, the one public API for opening the app's own page in the iOS Settings app; the requirement's own network-and-CloudKit-container rule holds structurally, because the app writes no analytics event and has no public-database code path anywhere in `RecordStore`. See `mm-t41.4`'s comments: Apple gives no public, App-Store-safe deep link straight to Privacy & Security, Analytics & Improvements, so the row opens the app's own Settings page instead — flagged as a decision for Ash, not a blocker. Scenario "Share App Analytics with Apple": device check, `mm-t41.15`. Scenario "Container has no public data": device check, `mm-t41.15`. Scenario "No event" — built here over the device's only mode this cut ships (sync off; sync is not in the first TestFlight cut) — device check, `mm-t41.15`; the sync-on half is `deferred: mm-t41b.11` ("No event", only the check with sync on).

## 5. Retention

- [x] 5.1 mm-t41.6 — data-and-privacy, "Retention". Both scenarios hold structurally: `Profile` (model-foundation) has no field for a screening date other than `askedAt`, and the record capability's review model has no answer field, only `selfHarmAnswered`. `RetentionTests.swift` proves both as pure-model tests with fixed dates. Scenarios "Screening date" and "Self-harm answer" — `RetentionTests.swift`.

## 6. File protection

- [x] 6.1 mm-t41.7 — data-and-privacy, "File protection". `Record.FileProtection`, `RecordStore.init(directory:)` (applies `NSFileProtectionComplete` to every file the two configurations create). Scenario "Store files" — `FileProtectionTests.swift`, over a temp directory. Scenario "Side files" — built here over fixture facts, with no live dependency on a real action-queue or widget-snapshot file (neither exists yet) — `FileProtectionTests.swift` proves `FileProtection.protectionClass(for:)` returns `.completeUntilFirstUserAuthentication` for both roles; the widget-snapshot half is `deferred: mm-t25.15`. Scenario "Launch before the first unlock" — `Record.AppStoreOpening` (task 3.1) never opens the container before protected data is available, so the App target constructs no `RecordStore` in this state; device check, `mm-t41.15`.

## 7. The app blocks third-party keyboards

- [x] 7.1 mm-t41.8 — data-and-privacy, "The app blocks third-party keyboards". `Record.KeyboardBlockPolicy.shouldAllow`, the pure decision `App/Midmorning/MidmorningApp.swift`'s `AppDelegate.application(_:shouldAllowExtensionPointIdentifier:)` now calls (model-foundation already built the `AppDelegate` method itself, over the same inline rule; this task extracts and tests the rule, with no behaviour change). `KeyboardBlockTests.swift` proves `shouldAllow` for both `ExtensionPointKind` cases. Scenarios "Third-party keyboard installed" and "Dictation": device check, `mm-t41.15`.

## 8. The app excludes the whole store directory from backups

- [x] 8.1 mm-t41.9 — data-and-privacy, "The app excludes the whole store directory from backups". `Record.FileProtection.protectStoreDirectory` (shared by `StoreLocation.directory()`, the App target's ordinary launch path, and `LocalEraser.eraseAndRecreate`, so a directory Delete-all just recreated is excluded again at once, not only at the next launch). The "Sync with iCloud is off. A new device starts empty." line belongs beside the "Sync with iCloud" switch itself, which does not exist in this worktree yet (`4.1b`, `sync`); this task does not add either. Scenario "New device with sync off" — `StoreLayoutTests.testANewDeviceWithNoRestoredStoreFileOpensEmpty`, `FileProtectionTests.testProtectStoreDirectorySetsCompleteProtectionAndBackupExclusion`, `LocalEraserTests.testRecreatedDirectoryCarriesCompleteProtectionAndBackupExclusion`. Scenarios "Restore after Delete-all" and "Finder backup inspected": device check, `mm-t41.15`. Scenario "New device with sync on" is `deferred: mm-t41b.11`.

## 9. No record content in the system log or crash reports

- [x] 9.1 mm-t41.10 — data-and-privacy, "No record content in the system log or crash reports". `RecordStore.incrementCrashCount()`; `App/Midmorning/MetricKitSubscriber.swift` (locks the callback, since MetricKit can call `didReceive` on a background queue, and always calls it on the main actor, since `RecordStore` is not thread-safe). Scenarios "Weigh-in save fails" and "Crash while typing" — `NoRecordContentInErrorsTests.swift`: `RecordStore.Failure` carries no associated value (proved over the one save-failure path this change can drive today, `update` with no current version — `weigh-in`, 2.2, has not built its own save path yet), and `RecordStore.swift`'s own source holds no `print(`, `os_log(`, `NSLog(` or `debugPrint(` call. Scenario "MetricKit diagnostic" — `DiagnosticsCountsTests.testIncrementCrashCountKeepsOnlyTheCountAndSurvivesReopening`; the real `MXMetricManagerSubscriber` wiring is a device check, `mm-t41.15` (MetricKit delivers no diagnostic in the simulator).

## 10. The Diagnostics counts come from the device

- [x] 10.1 mm-t41.11 — data-and-privacy, "The Diagnostics counts come from the device". `Record.DiagnosticsCounts`, `Record.DiagnosticsSourceCounts` (the pending-reminders/queue-length seam), `RecordStore.recordReconcileOutcome(winners:losers:)`. Scenarios "Sync off" and "Managed device" — `DiagnosticsCountsTests.swift`. Scenario "Diagnostics content" — built here for six of the eight counts (launch failures, schema version, content version, crash count, pending reminders and queue length as named zero-valued seams, last reconcile outcome as a named zero-valued counter) — `DiagnosticsCountsTests.swift`; the sync-on half (last successful sync day) is `deferred: mm-t41b.11` ("Diagnostics content", only the counts with sync on).

## 11. The privacy manifest and the App Store privacy label

- [x] 11.1 mm-t41.12 — data-and-privacy, "The privacy manifest and the App Store privacy label". `App/Midmorning/PrivacyInfo.xcprivacy`. Scenarios "App Store label" and "Manifest": device check, `mm-t41.15` (a reviewer reads the manifest and the App Store Connect privacy section on a built app). Scenario "Definition of collect" — a dated README line at submission, owned by `mm-t43`'s release gate; this task adds the manifest the gate reads.

## 12. settings: the Diagnostics page

- [x] 12.1 mm-t41.13 — settings, "The About group" (the "Diagnostics" scenario). `SettingsView.swift`'s Diagnostics row and `DiagnosticsView.swift`, over `Record.DiagnosticsCounts` (task 10.1). Scenario "Diagnostics" — device check, `mm-t41.15`, over `DiagnosticsCounts`' own fixed-value tests (task 10.1); `mm-t24.20` wires in the real pending-reminders and queue-length counts end to end.

## 13. What never leaves the device

- [x] 13.1 mm-t41.5 — data-and-privacy, "What never leaves the device". No new code: the requirement holds structurally, because `Record` opens no network connection, writes nothing to Spotlight, Siri, HealthKit or the pasteboard, and includes no third-party SDK — a reviewer can confirm this from the package's own import list (`Foundation` and `SwiftData` only). Scenario "Export" names a control `4.2` (`mm-t42`) has not built yet (0 of its 16 children close in this worktree); its own child `mm-t42.7` ("export: Share sheet only") is the scenario's real owner, so it is `deferred: mm-t42.7`, not built here — see this task's own note on `mm-t41.5` for why that differs from the bead's "Built here" list. Scenario "A day of use" — device check, `mm-t41.15`, over the device's only mode this cut ships (sync off); the sync-on half is `deferred: mm-t41b.11` ("A day of use", only the capture with sync on). Scenario "The App Intent" is `deferred: mm-t25.15`.

## 14. Close

- [x] 14.1 mm-t41.15 device checks for 4.1: list every pending device check above (tasks 4.1, 6.1, 7.1, 8.1, 9.1, 11.1, 12.1, 13.1) as a `bd comments add mm-t41.15` note. Ash does each check and adds a date and a screenshot to this change's README.
- [x] 14.2 Write the rules-checklist and safeguarding lines in this README.
- [x] 14.3 Run `./verify` cold and warm; write both times in this README.
