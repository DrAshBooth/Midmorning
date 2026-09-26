# Tasks

Every task's verify command is `swift test --package-path Packages` and `xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning -destination 'generic/platform=iOS Simulator' build`, folded into `./verify` before each child closes. Each task names its bead, its requirement heading and spec file, and maps each scenario the requirement lists to a test here, to a device check, or to a `deferred: <bead id>` pointer.

## 1. The settings screen and Today's own control

- [x] 1.1 mm-t13.1 — settings, "One screen, one tap from Today". `App/Midmorning/SettingsView.swift`; `TodayView.swift`'s bottom toolbar "Settings" control. Scenario "Reach the settings screen": device check, `mm-t13.8`.

## 2. The Reminders group

- [x] 2.1 mm-t13.2 — settings, "The Reminders group". `RecordStore.ReminderSwitch`, `RecordStore.ReminderTime`, `explicitWordingOn`, `remindAgainMinutes`, `quietHoursOn/Start/End`, `remindersPausedAt`, `pauseReminders`, `turnRemindersOn`; `App/Midmorning/RemindersSettingsView.swift`. Scenario "Reminders paused by the not-right-now page" — built here over fixture facts, with no live dependency on the not-right-now page — `SettingsScreenTests.swift`; `mm-t24.21` (a wiring bead) runs it end to end. Scenario "Turn reminders on" — same fixture-facts basis — `SettingsScreenTests.swift`.

## 3. The Record group

- [x] 3.1 mm-t13.3 — settings, "The Record group" (decision 65). `RecordStore.dayStartHour(effectiveOn:)`, `setDayStartHour(_:now:calendar:)`, `RecordDay.nextDayKey(after:calendar:startHour:)`, `gapBandsOn`, `setGapBandsOn`. "Day starts at" and "Gap bands" carry no scenario of their own in the requirement; `SettingsScreenTests.swift` proves the day-start-applies-from-the-next-day rule and the day-start-never-moves-a-saved-entry rule as pure functions with fixed dates, and gap bands' default and toggle. The requirement's one scenario, "Turn pattern sentences off", is `deferred: mm-t33.15`.

## 4. The Privacy group and the privacy notice

- [x] 4.1 mm-t13.5 — settings, "The Privacy group". `Packages/Sources/Record/DeleteAllSeam.swift` (`DeleteAllSeam`, `StubDeleteAllSeam`); `SettingsView.swift`'s "Delete everything" control and confirmation, and its "Privacy" link. Scenarios "Sync off" and "iCloud full" are `deferred: mm-t41b.9`.
- [x] 4.2 mm-t43.1 — data-and-privacy, "The privacy notice". `App/Midmorning/PrivacyNoticeView.swift`; the controller, lawful basis and Article 9 sections are a placeholder pending `mm-t43.23`. Scenario "Privacy notice" (the screen holds every topic): device check, `mm-t13.8`. Scenario "Erasure" (the screen names "Delete everything") — `ContentTests.LiteralLintTests.testPrivacyNoticeNamesDeleteEverythingInTheErasureSection`. The backup line's exact wording — `ContentTests.LiteralLintTests.testPrivacyNoticeBackupLineMatchesTheRequirementVerbatim`. Scenario "Public URL" is the published notice and its URL, the gate `mm-t43.6`; `deferred: mm-t43.6`.
- [x] 4.3 mm-t13.9 — wiring: `PrivacyAppLockControls` in the real Privacy group, added after this change's own archive. `app-lock` (mm-t15) built `PrivacyAppLockControls.swift` as a standalone fixture over `AppLockController`. This task embeds it for real: `AppLockRootView` shares its one `AppLockController` down to `SettingsView` through `@EnvironmentObject`. `SettingsView.swift` shows the app lock switch, "Lock after" and "Face ID only"/"Touch ID only" as their own section beside the Privacy group's "Privacy" link and "Delete everything" (app-lock spec: each of these three names "The Privacy group of the settings screen"). `Packages/Tests/AppLockTests/AppLockSharedStateIntegrationTests.swift` proves the shared state at the controller level: a call the Privacy section makes changes what the cover reads next, with no second controller.

## 5. The About group

- [x] 5.1 mm-t13.6 — settings, "The About group". The app version and content version rows; the "Draft" badge from `ContentBundle.isDraft`; "Contact" against the catalogue key `about.contact` (decision 99). Scenario "Draft content" — `ContentTests.ContentVersionTests` and `SignOffTests` already prove `isDraft`'s rule; this task's own proof is `ContentTests.BundledCardsTests.testLoadShippedReadsFromTheModuleBundleAndMatchesTheSourceDirectory`, which carries the draft flag through `loadShipped()`. Scenario "Face ID only" is `deferred: mm-t15.13`. Scenario "Diagnostics" is `deferred: mm-t41.13`.

## 6. Content and package wiring

- [x] 6.1 `Packages/Content/Resources/strings.json` adds `about.contact`; `manifest.json` and `content-lock.json` raise the content version to 2; `Packages/Content/SIGNOFF.md` regenerates. Verify: `ContentTests.CatalogueRulesTests.testShippedAboutContactHoldsThePlaceholderAndPassesTheRule`.
- [x] 6.2 `Packages/Content/BundleLoader.swift`'s `loadShipped()` reads through `Bundle.module`, keyed off `manifest.json`, not a `Resources` subdirectory. Verify: `ContentTests.BundledCardsTests.testLoadShippedReadsFromTheModuleBundleAndMatchesTheSourceDirectory`.
- [x] 6.3 `Packages/Package.swift`: `Content`'s resources become one `.copy` line per file, so a bundle-only target with no nested directory passes `codesign` once an app target links it (task 4.5 in `v1-programme`: this task adds no target, so the `swift test` line in `./verify` does not change). `App/Midmorning.xcodeproj/project.pbxproj` adds the `Content` package product to the `Midmorning` target. Verify: `xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning -destination 'generic/platform=iOS Simulator' build`, from a clean `~/Library/Developer/Xcode/DerivedData`.

## 7. Accessibility of the settings screen

- [x] 7.1 mm-t13.7 — settings, "Accessibility of the settings screen". Every control is a plain `Toggle`, `Button`, `NavigationLink`, `DatePicker` or `LabeledContent` with a catalogue-key label, so its VoiceOver label already equals its visible label and Dynamic Type already applies; compound rows (the About group's content-version-and-draft row, and its app-version and contact rows) carry `.accessibilityElement(children: .combine)` so each reads as one stop. Scenario "VoiceOver on a switch": device check, `mm-t13.8`, over "Weekly summary"'s nearest built equivalent, "Gap bands" (the Record group's own switch; "Weekly summary" itself is `3.2`'s row).
