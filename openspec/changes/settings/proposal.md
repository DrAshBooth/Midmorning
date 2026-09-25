# Proposal

## Why

Every setting needs one home, one tap from Today. Task 1.3 in `openspec/changes/v1-programme/tasks.md` names this change. It builds the settings screen, the Reminders sub-screen, four of its five groups, the privacy notice screen, and the split between shared and device rows that `Local.store` already defines.

## What Changes

- The app shows one settings screen, reached with the text control "Settings" in Today's bottom toolbar. It shows Reminders, Record, Privacy and About, in that order. The Weigh-in group waits for `weigh-in` (2.2).
- The Reminders group opens as its own screen. It shows six reminder switches, four reminder times, "Say what each reminder is for", "Remind me again in", quiet hours, and the paused line and "Turn reminders on" control. "Worksheet review", "Check-in" and "Break through Focus for planned meals" wait for later changes.
- The Record group shows "Day starts at" and "Gap bands" (decision 65). A changed day start applies from the next record day, never the current one. "Weekly summary", "Pattern sentences", "Export" and the Food rules and Feeling fat notes links wait for their own owning changes.
- The Privacy group shows "Delete everything" and a link to the privacy notice. "Delete everything" calls a stub seam; `local-delete-all` (4.1) builds the real one. Every other Privacy row waits for `app-lock`, `sync` or `widgets-and-intents`.
- The privacy notice opens from the Privacy group's "Privacy" row. It states the topics the requirement lists; the controller, the lawful basis and the Article 9 text are a placeholder until `mm-t43.23` supplies the reviewed wording.
- The About group shows the app version, the content version, "Draft" when the bundle carries no sign-off, and "Contact" against the content catalogue key `about.contact` (decision 99). "Face ID only" and "Diagnostics" wait for `app-lock` and `local-delete-all`.
- `RecordStore` gains synced and device-only key/value reads and writes for every setting this change builds, over the existing `Settings` and `LocalSetting` rows.
- The App target links the `Content` package for the first time, to read the content version, the draft state and `about.contact` at runtime.
- Every full screen this change adds shows a "Get support" control in the trailing position of its navigation bar. It opens a placeholder sheet; `onboarding-and-safeguarding` (1.4, `mm-t14.24`) builds the real support sheet.

## Capabilities

### New Capabilities

None. `settings` and `data-and-privacy` already exist as delta specs under `openspec/changes/v1-programme/specs`; this change's own delta adds each requirement's first-built scenarios to `openspec/specs`.

### Modified Capabilities

None yet in `openspec/specs`: neither `settings` nor `data-and-privacy`'s "The privacy notice" requirement holds a place there before this change archives.

## Impact

- `Packages/Sources/Record/RecordStore.swift`: settings and device-value read and write functions; `RecordDay.nextDayKey(after:calendar:startHour:)`.
- `Packages/Sources/Record/DeleteAllSeam.swift`: the `DeleteAllSeam` protocol and its stub.
- `Packages/Content/BundleLoader.swift`: `loadShipped()` reads through `Bundle.module` by finding `manifest.json`, not by assuming a `Resources` subdirectory, so it works both under `swift test` and inside the built app.
- `Packages/Package.swift`: `Content`'s resources move from one folder `.copy` to one `.copy` line per file. A resource-only bundle with a nested top-level directory fails `codesign` once an app target links it, which `swift test` alone never exercises.
- `Packages/Content/Resources/strings.json`, `manifest.json`, `content-lock.json`, `SIGNOFF.md`: the catalogue key `about.contact`; the content version rises to 2.
- `App/Midmorning.xcodeproj/project.pbxproj`: adds the `Content` package product to the app target.
- `App/Midmorning/SettingsView.swift`, `RemindersSettingsView.swift`, `PrivacyNoticeView.swift`, `ClockTime.swift`: the new screens.
- `App/Midmorning/TodayView.swift`: the "Settings" bottom toolbar control.
- `App/Midmorning/Localizable.xcstrings`: every new catalogue key this change's screens use.

## Decisions this change makes

- Every new setting's key follows the pattern `StoreLayoutTests.swift` already fixed: `reminder.<name>.enabled` for a device switch, `reminder.<name>.time` for a synced time, and a flat key such as `remindersPausedAt` or `record.gapBands.enabled` for a single synced value.
- "Day starts at" writes an append-only `Settings` row keyed by the day it takes effect from, computed as the record day right after the moment of the change under the CURRENT hour, never the record day the person is in when they change it.
- `about.contact` lives in the content bundle, not `Localizable.xcstrings`, because the settings spec ties it to the content catalogue (decision 99); the App target reads it as a dynamic value, so the literal lint's catalogue-key rule never applies to it.
