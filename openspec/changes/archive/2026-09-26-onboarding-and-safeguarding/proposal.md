# Proposal

## Why

Task 1.4 of `v1-programme`. The person must pass onboarding before the record and the programme open, and the app must carry safeguarding's duty of care from the first screen onward. This change adds the four onboarding screens, the screening rules, the exclusion page, the not-right-now page, the GP suggestion page, the support sheet, the GP paragraph and Get support on every screen. `mm-t11` (content-pipeline), `mm-t12b` (record-full) and `mm-t15` (app-lock) are merged, so `RecordStore`, the Today shell and the app lock already exist for this change to build on.

## What Changes

- The `Programme` package (new target, `Packages/Programme`, per `design.md`'s "One umbrella package, five targets"): the safeguarding rules (`ScreeningRules`, `SelfHarmItem`, `BMI`, `ScreeningLimits`, `ScreeningQuestionCatalog`, `TreatmentClaim`), the fixed content for every safeguarding page (`ExclusionPage`, `NotRightNowPage`, `GPSuggestionPage`, `SupportSheet`, `GPParagraph`, `GPParagraphCopy`) and onboarding's own fixed content (`Screen1Content`...`Screen4Content`, `CommonLabels`, `Weekday`). Every rule and every string is a value the app never re-types, and every rule is a pure function a test drives with fixed inputs.
- `RecordStore` gains the `Profile` row's read/write (`profile()`, `setProfile`), the start day, the weigh-in day choice and Local.store's onboarding state (install moment, the completion flag, the sync choice) — the first read and write access to these values, following the same inline pattern `settings` and `app-lock` used for their own settings.
- `RecordStore` gains `StartDayChoice` and `DayBoundaryLine` (`Packages/Sources/Record`), the record-day-aware "Today, Thursday 24 September" label and the "A day runs from 04:00 to 03:59." line, both pure functions over `RecordDay`.
- `AppLock.BiometryStrings` gains `onboardingSentence`, the fourth string the app lock's one label function returns, so onboarding's lock sentence and the settings screen's own label can never disagree (onboarding spec, "Screen 4: permissions": "The label function that `app-lock` defines returns it.").
- Four onboarding screens (`App/Midmorning/Onboarding`): `Screen1View` ("What this is and isn't"), `Screen2View` ("A few questions first", wired to the screening rules and the caution sheet), `Screen3View` ("Your start": the start day, weigh-in day and quiet hours, and the record in three sentences) and `Screen4View` ("Permissions": your record, notifications, app lock, widget, "Start"). `OnboardingRootView` coordinates the four screens, the exclusion page and the caution sheet, and is gated in ahead of `AppLockRootView` from `MidmorningApp` so the cover never shows before the person has chosen the app lock.
- Three safeguarding pages and two sheets (`App/Midmorning/Safeguarding`): `ExclusionPageView`, `NotRightNowPageView`, `GPSuggestionPageView`, `SupportSheetView`, `GPParagraphView`, `CautionSheetView`, `BeatContactsView` and `GetSupportModifier` (the reusable "Get support" navigation-bar control every full screen this change adds applies). `ExportStubButton` stands in for the export control until `mm-t42` lands.
- `TodayView`'s placeholder "Get support" button, added by `record-full`, now opens the real support sheet.

## Capabilities

### New Capabilities
- `onboarding`: the four screens, once, in order; "No account"; the one-time BMI; what onboarding keeps and never keeps; "Not weight loss, three times"; "Finish". "Screen 4: the iCloud choice" and "Restore before onboarding" are the later sync change's own requirements and are not part of this delta.
- `safeguarding`: the screening rules, the self-harm item, the three safeguarding pages, the support sheet, the GP paragraph, Get support on every screen, "V1 does not read free text for risk" and "What is a treatment claim". "Re-screening at every weekly review and check-in", "Re-screening at a restart", "The underweight check", "The deterioration rule" and "Regulatory release gates" are other epics' own requirements (`mm-t21`, `mm-t22`, `mm-t32`, `mm-t43.3`) and are not part of this delta.

## Impact

- New SwiftPM package target `Programme` (library, path `Packages/Programme`) and `ProgrammeTests`, added to `Packages/Package.swift`.
- `Packages/Sources/Record/RecordStore.swift`: `RecordStore` gains the Profile, start-day, weigh-in-day and onboarding-state methods listed above.
- `Packages/Sources/Record/StartDayChoice.swift` (new): `StartDayChoice`, `DayBoundaryLine`.
- `Packages/Sources/AppLock/Biometry.swift`: `BiometryStrings` gains `onboardingSentence`; `strings(for:)` fills it for every `Biometry` case.
- `App/Midmorning/Onboarding/`: `OnboardingAnswers.swift`, `OnboardingRootView.swift`, `Screen1View.swift`, `Screen2View.swift`, `Screen3View.swift`, `Screen4View.swift`.
- `App/Midmorning/Safeguarding/`: `GetSupportModifier.swift`, `GPParagraphView.swift`, `BeatContactsView.swift`, `SupportSheetView.swift`, `ExclusionPageView.swift`, `NotRightNowPageView.swift`, `GPSuggestionPageView.swift`, `CautionSheetView.swift`, `ExportStubButton.swift`.
- `App/Midmorning/MidmorningApp.swift`: adds `AppRootView`, which shows `OnboardingRootView` until the completion flag is set, then `AppLockRootView`.
- `App/Midmorning/TodayView.swift`: the placeholder "Get support" button now opens `SupportSheetView`.
- `App/Midmorning.xcodeproj/project.pbxproj`: links the `Programme` package product.
- No network except the webchat link, which opens in `SFSafariViewController`. No new third-party dependency. `Programme` imports Foundation and `Constants` only.
