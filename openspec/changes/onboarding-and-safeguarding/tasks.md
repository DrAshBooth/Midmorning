# Tasks

Verify for every task below: `swift test --package-path Packages --filter ProgrammeTests` and `--filter RecordTests` and `--filter AppLockTests` pass. `./verify` passes before each close.

## 1. Foundations

- [x] 1.1 Add the `Programme` package target at `Packages/Programme`, with `ProgrammeTests`, and add both to `Packages/Package.swift`. Verify: `swift build --package-path Packages` succeeds.
- [x] 1.2 `RecordStore.profile()`/`setProfile`, `startDayKey()`/`setStartDayKey`, `weighInDayChoice()`/`setWeighInDayChoice`, `installMoment()`/`setInstallMoment`, `onboardingCompleted()`/`setOnboardingCompleted`, `syncOn()`/`setSyncOn` — onboarding's own read and write access to the `Profile` row, the synced `Settings` rows and `Local.store`'s device state. Verify: `OnboardingStoreTests` passes.
- [x] 1.3 `StartDayChoice` and `DayBoundaryLine` (`Packages/Sources/Record`), the record-day-aware "Today, Thursday 24 September" label and the "A day runs from..." line. Verify: `StartDayChoiceTests` passes.
- [x] 1.4 `AppLock.BiometryStrings` gains `onboardingSentence`; `BiometryLabels.strings(for:)` fills it for every `Biometry` case, so onboarding's own lock sentence comes from the one label function `app-lock` already defines. Verify: `BiometryLabelsTests.testOnboardingLockSentencePerBiometry` passes.

## 2. mm-t14.15 — safeguarding: Screening rules for age, pregnancy and treatment (P1)

- [x] 2.1 `ScreeningRules` (age, pregnancy, treatment) and `ExclusionReason`. Built here: all 6 scenarios ("Under 18", "Exactly 18", "In treatment with agreement", "Pregnancy does not apply", "Two reasons", "No Declared Age Range"). Verify: `ScreeningRulesTests` passes.

## 3. mm-t14.16 — safeguarding: The self-harm item (P1)

- [x] 3.1 `SelfHarmItem.outcome`, `showsSecondQuestion`, `supportLine`. Built here: all 4 scenarios ("No", "Rather not say", "Thoughts without a method", "Thoughts with a method"). Verify: `SelfHarmItemTests` passes.

## 4. mm-t14.17 — safeguarding: Screening rules for BMI (P1)

- [x] 4.1 `ScreeningRules.bmiExcludes`/`cautionFlag`, `CautionSheetView`. Built here: all 4 scenarios ("Below 18.5", "Caution band", "Above the caution band", "Exactly 18.5"). Verify: `ScreeningRulesTests` passes.

## 5. mm-t14.18 — safeguarding: No question about vomiting or laxatives (P1)

- [x] 5.1 `ScreeningQuestionCatalog` (the six questions plus the self-harm second question, and the compensation-word check), `NoCompensationFieldTests` (Record's own models carry no such field). Built here: "Screening", "The store", "The sentence in Get support". Verify: `ScreeningQuestionCatalogTests` and `NoCompensationFieldTests` pass.
- [ ] 5.2 Deferred: "Weekly review" (mm-t32.18 — `weekly-review`'s own screen does not exist in this worktree to inspect).

## 6. mm-t14.19 — safeguarding: The exclusion page (P1)

- [x] 6.1 `ExclusionPage` (Programme) and `ExclusionPageView` (App target), wired from screen 2's screening result. Built here: all 4 scenarios ("Under 18", "Self-harm first", "Done", "Call Beat" — the call flow itself is a device check, listed on the epic's device-check bead). Verify: `ExclusionPageTests` passes.

## 7. mm-t14.20 — safeguarding: The app keeps nothing from an exclusion (P1)

- [x] 7.1 By construction: an exclusion never calls `RecordStore.setProfile` or any other write, so the store holds nothing from it; `OnboardingRootView`'s `reset()` clears in-memory answers before returning to screen 1. Built here: both scenarios ("Relaunch after exclusion", "The store after exclusion"). Verify: `OnboardingStoreTests.testNoProfileRowBeforeAnyWrite` passes.

## 8. mm-t14.21 — safeguarding: The GP suggestion page (P1)

- [x] 8.1 `GPSuggestionPage` (Programme) and `GPSuggestionPageView` (App target), taking reasons as a plain argument (design.md, "The GP suggestion page and the not-right-now page take reasons as a plain argument"). Built here over fixture facts, with no live dependency: "From the weigh-in" (mm-t22.15 runs it end to end), "Nothing closes" (mm-t24.21), "At the review" (mm-t32.16). Verify: `GPSuggestionPageTests` passes.

## 9. mm-t14.22 — safeguarding: The not-right-now page (P1)

- [x] 9.1 `NotRightNowPage` (Programme) and `NotRightNowPageView` (App target). Built here: "The record stays". Built here over fixture facts, with no live dependency: "Weight reason", "Reminders paused by the weight reason" (mm-t22.15), "Reminders kept by the self-harm reason", "Self-harm reason" (mm-t32.16), "Reminders back on" (mm-t24.21), "Two reasons at a re-screen", "Four reasons at a re-screen" (mm-t21.23). Verify: `NotRightNowPageTests` passes.

## 10. mm-t14.23 — safeguarding: Get support on every screen (P1)

- [x] 10.1 `GetSupportModifier` (App target), applied to Today and every screen this change adds. Built here: "Today", "Onboarding", "The side of the control", "The cover" (app-lock's own cover already shows no such control, unchanged), "New-entry screen" (`NewEntryView` shows no control by construction — this change adds none there). Built here over fixture facts, with no live dependency: "Weekly review" (mm-t32.16), "Restart re-screen" (mm-t21.23).
- [ ] 10.2 Deferred: "Check-in" (mm-t36.8).

## 11. mm-t14.24 — safeguarding: The support sheet (P1)

- [x] 11.1 `SupportSheet` (Programme) and `SupportSheetView`, `BeatContactsView`, `NumberRow`, `SafariView` (App target). Built here: "The list", "From a self-harm reason", "Offline" as pure-content tests; "Call Samaritans", "Cancel the call", "Call Beat in Scotland", "Copy a number", "Beat webchat" are built (the confirmation dialog, the pasteboard write, the `SFSafariViewController`) but need a device or the simulator's own hardware-backed behaviour to prove, so each is also listed on the epic's device-check bead. "Release check" needs Ash's own review against each service's website. Verify: `SupportSheetTests` passes.

## 12. mm-t14.25 — safeguarding: The GP paragraph (P1)

- [x] 12.1 `GPParagraph`, `GPParagraphCopy` (Programme) and `GPParagraphView` (App target). Built here as pure-function tests: "Copy" (text selection), "Copy after an edit", "Edit not kept". Built (real `UIPasteboard`/`UIAccessibility` code) but proven only by a device check: "The pasteboard clears", "Universal Clipboard", "Copy and paste into Messages", "Largest text size". Verify: `GPParagraphTests` passes.

## 13. mm-t14.26 — safeguarding: V1 does not read free text for risk (P1)

- [x] 13.1 No scanner is added anywhere in this change; `RecordStore.add`/`update` (unchanged, from `mm-t12b`) save free text as given. Built here: all 3 scenarios ("Free text about self-harm" — proven by `record-full`'s own existing entry tests, unchanged by this build; "The bundle" — this change's own source review finds no word list or classifier; "Get support unchanged" — `GetSupportModifier` reads no entry content). No test target change needed; this requirement is a negative constraint this change does not violate.

## 14. mm-t14.27 — safeguarding: What is a treatment claim (P1)

- [x] 14.1 `TreatmentClaim` (Programme). Built here: all 5 scenarios ("Screen 1", "A card draft", "A marketing draft", "A negative statement", "A forbidden form"), plus `testEveryOnboardingStringPasses` over every string this change's screens show. Verify: `TreatmentClaimTests` passes.

## 15. mm-t14.2 — onboarding: No account (P1)

- [x] 15.1 `OnboardingStrings.all` scanned for an account-shaped phrase. Built here: both scenarios ("Fields on the four screens", "Device signed out of iCloud" — the app reads no iCloud account anywhere in this build). Verify: `OnboardingContentTests.testNoAccountFieldAnywhere` passes.

## 16. mm-t14.3 — onboarding: Screen 1: what this is and isn't (P1)

- [x] 16.1 `Screen1Content` (Programme) and `Screen1View` (App target). Built here: "The screen opens", "Nothing happens without a tap" (no timer, no swipe — the view has neither), "Continue"; "Largest text size" is built (Dynamic Type, no fixed frame) and listed on the epic's device-check bead. Verify: `OnboardingContentTests.testScreen1ContentIsTheSevenLinesInOrder` passes.

## 17. mm-t14.4 — onboarding: Screen 2: the screening questions (P1)

- [x] 17.1 `Screen2View`, wired to `ScreeningRules` and `SelfHarmItem`. Built here: all 5 scenarios ("The questions", "One answer missing", "Screening continues", "Thoughts without a method", "Screening excludes"). Verify: `ScreeningQuestionCatalogTests` and `ScreeningRulesTests` pass (the screen's own focus-and-validation behaviour is a code-reviewable fact — `attemptContinue()` — with no App-target test target to drive it).

## 18. mm-t14.5 — onboarding: The one-time BMI (P1)

- [x] 18.1 `BMI`, `ScreeningLimits` (Programme), wired into `Screen2View`'s height and weight fields. Built here: all 6 scenarios ("Metric input", "Imperial input", "Weight below the range", "Height outside the range", "No upper weight bound"); "BMI on no screen" is a reviewer's walk of the built app, listed on the epic's device-check bead. Verify: `BMITests` passes.

## 19. mm-t14.6 — onboarding: Screen 3: the start day (P1)

- [x] 19.1 `StartDayChoice` (Record), wired into `Screen3View`. Built here: all 4 scenarios ("Default", "Tomorrow", "A later start day wins", "After midnight"). Verify: `StartDayChoiceTests` and `OnboardingStoreTests.testALaterStartDayWins` pass.

## 20. mm-t14.7 — onboarding: Screen 3: weigh-in day and quiet hours (P1)

- [x] 20.1 `Weekday` (Programme) and `Screen3View`'s weigh-in-day and quiet-hours sections, wired to `RecordStore.setWeighInDayChoice`/`setQuietHours*` (quiet hours already existed from `mm-t13`). Built here: "No weigh-in day chosen", "Weigh-in day chosen", "Default quiet hours", "Quiet hours changed", "Quiet hours off". Verify: `OnboardingStoreTests.testTheStoreAfterOnboarding` passes.
- [ ] 20.2 Deferred: "I won't be weighing" (mm-t22.15 — the weigh-in screen's own "Choose a weigh-in day" does not exist in this worktree; `RecordStore.WeighInDayChoice.wontBeWeighing` and `Screen3View`'s own control are built and tested now, so `mm-t22.15` only wires the weigh-in screen's side), "Review without a weigh-in part" (mm-t32.16).

## 21. mm-t14.8 — onboarding: Screen 3: the record in three sentences (P1)

- [x] 21.1 `Screen3Content` (Programme), `DayBoundaryLine` (Record), wired into `Screen3View`. Built here: "The three sentences", "The day line follows the setting", "The example is not an entry" (the example row is static content, never written to the store). "VoiceOver on the example" is built (`accessibilityElement(children: .combine)` + `accessibilityLabel`) and listed on the epic's device-check bead. Verify: `OnboardingContentTests` and `StartDayChoiceTests.testDayBoundaryLineWithDefaultDayStart`/`testDayBoundaryLineFollowsTheSetting` pass.

## 22. mm-t14.9 — onboarding: Screen 4: your record (P1)

- [x] 22.1 `Screen4Content` (Programme) and `Screen4View`'s "Your record" section, wired to `RecordStore.setSyncOn(false)`. Built here: all 3 scenarios ("The section opens", "This device only", "Signed out of iCloud" — the section reads no iCloud account). Verify: `OnboardingStoreTests.testSyncOffByDefault` passes.

## 23. mm-t14.11 — onboarding: Screen 4: permissions (P1)

- [x] 23.1 `Screen4View`'s notifications, app lock and widget sections, wired to `BiometryLabels.strings(for:)` and `RecordStore.setLocalSettingValue` (`AppLockSettingsKeys.enabled`). Built here: "App lock default", "App lock off". Built here over fixture facts, with no live dependency: "Notifications denied", "Notifications not asked" (mm-t24.21 runs the scheduler side end to end). "Lock sentence on a Touch ID device" needs a real Touch ID device or simulator enrolment and `LocalAuthentication`'s own `Biometry` detection (not wired to a live value in this first cut — `currentBiometry` is `.faceID`), so it is listed on the epic's device-check bead.
- [ ] 23.2 Deferred: "Widget skipped" (mm-t25.15).

## 24. mm-t14.12 — onboarding: What onboarding keeps and what it never keeps (P1)

- [x] 24.1 `OnboardingRootView.writeScreeningResult`/`finish`, writing exactly the four Profile values, the start day, the weigh-in day and quiet hours, and Local.store's device state — never the typed age or weight. Built here: both scenarios ("The store after onboarding", "First weigh-in day"). Verify: `OnboardingStoreTests.testTheStoreAfterOnboarding` and `testFirstWeighInDayHasNoOnboardingWeight` pass.

## 25. mm-t14.13 — onboarding: Not weight loss, three times (P1)

- [x] 25.1 `OnboardingStrings.notWeightLossSentences`/`forbiddenGoalPhrases`. Built here: both scenarios ("Three sentences on three screens", "No goal"). Verify: `OnboardingContentTests.testThreeSentencesOnThreeScreens`/`testNoGoalPhraseAnywhereInOnboarding` pass.

## 26. mm-t14.14 — onboarding: Finish (P1)

- [x] 26.1 `Screen4View.start()`/`OnboardingRootView.finish()`: sets the completion flag, shows Today via `AppRootView`. Built here: "Start today", "Start tomorrow" (both start-day choices reach the same "Start" path); "Left on screen 3" holds by construction — a fresh launch always creates a new `OnboardingRootView` at screen 1 with fresh `OnboardingAnswers`, keeping no answer from an unfinished run. Verify: `OnboardingStoreTests` passes; the launch behaviour is a code-reviewable fact (`AppRootView`'s `@State` initialiser), with no App-target test target to drive it.

## 27. mm-t14.1 — onboarding: Four screens, once, in order (P1)

- [x] 27.1 `AppRootView` (`MidmorningApp.swift`) and `OnboardingRootView`, gating onboarding ahead of `AppLockRootView` (design.md, "`OnboardingRootView` sits above `AppLockRootView`, not inside it"). Built here: "First launch" (writes the install moment), "Second launch" (the completion flag skips straight to `AppLockRootView`), "No network" (no screen makes a network call), "Typed numbers" (five number fields: age, height, weight, in whichever units), "Accessibility labels" (every control carries a VoiceOver label; the App Store declaration itself is a device check on the epic's device-check bead). Built here over fixture facts, with no live dependency: "After Delete-all" (mm-t42.20 runs it end to end — `data-and-privacy`'s own Delete-all does not exist in this worktree). Verify: `OnboardingStoreTests.testNoProfileRowBeforeAnyWrite`/`testInstallMomentRoundTrips` pass.

## 28. Close

- [x] 28.1 mm-t14.28 device checks for 1.4: list every pending device check above (tasks 6.1, 11.1, 12.1, 16.1, 18.1, 21.1, 23.1, 27.1) as a `bd comments add mm-t14.28` note. Ash does each check and adds a date and a screenshot to this change's README.
- [x] 28.2 File the "Weekly review" follow-up bead under `mm-t32` (task 5.2).
- [x] 28.3 Write the rules-checklist and safeguarding lines in this README.
- [x] 28.4 Run `./verify` cold and warm; write both times in this README.
