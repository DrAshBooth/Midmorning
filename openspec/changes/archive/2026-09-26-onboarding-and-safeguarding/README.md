# onboarding-and-safeguarding

1.4 from `openspec/changes/v1-programme/tasks.md`: the four onboarding screens, the screening rules, the exclusion page, Get support with the four Beat numbers, the GP paragraph and its variants, the not-right-now page and the GP suggestion page.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this worktree): 16 seconds. Warm `./verify`: 2 seconds. Both are well inside the 240-second budget.

## Scope notes

- **`mm-t21` (programme-engine), `mm-t22` (weigh-in), `mm-t32` (weekly-review), `mm-t36` (staying-on-track) and `mm-t42` (export) are parallel or later worktrees, not merged here.** The GP suggestion page and the not-right-now page take their reasons as a plain argument (design.md) and are proven against fixture reason arrays, per CLAUDE.md's "the agent tests it over fixture facts" rule. Each owning epic's own wiring bead (`mm-t22.15`, `mm-t24.21`, `mm-t32.16`, `mm-t21.23`) opens these same views from its real trigger.
- **The restart re-screen ("Re-screening at a restart") and "Re-screening at every weekly review and check-in" are `mm-t21`'s and `mm-t32`'s own requirements.** This change's delta does not add them; `ScreeningRules`, `SelfHarmItem` and `ExclusionPage`/`NotRightNowPage`'s content are built generally enough for those epics to reuse without change.
- **"Screen 4: the iCloud choice" and "Restore before onboarding" are the later sync change's own requirements** (`mm-t41b`, which also owns `mm-t14.10`, a child of that epic despite its id). This change builds only "Screen 4: your record" — the one-choice, first-cut section.
- **"Regulatory release gates" is `mm-t43.3`'s own index bead.** This change's `TreatmentClaim` gives that gate a reviewer tool; it does not itself perform the MHRA opinion, the clinical sign-off or the App Store listing review.
- **The self-harm item's second answer defaults to "No" behaviour when `nil`** (design.md), because onboarding's own validation never lets "Continue" advance with the second question shown and unanswered.
- **The "Weekly review" scenario of "No question about vomiting or laxatives" is deferred to `mm-t32.18`**, a new follow-up bead, because `weekly-review`'s own screen does not exist in this worktree to inspect.
- **"Check-in" (Get support on every screen) is deferred to `mm-t36.8`**, `staying-on-track`'s own bead.
- **`Screen4View`'s app lock section reads a fixed `.faceID`, not the device's real biometry.** `LocalAuthentication`'s own detection is `app-lock`'s concern; wiring a live `Biometry` value into onboarding is listed as a device check below, alongside `app-lock`'s existing device-check bead.
- **The support sheet's Beat webchat URL is a placeholder** pending the reviewer's own release check (design.md, "The support sheet's Beat webchat URL is a placeholder").

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent that built this change (`bd list -l constraint --all`).

- mm-pr1, The never list — yes. No screen this change adds shows a calorie, a macro, a total, a streak, a badge, a score or a colour-coded food; the exclusion, not-right-now and GP suggestion pages show a reason and a fixed line, never a number, a weight value or a count.
- mm-pr2, Tone of every string — yes. Every string this change shows is copied verbatim from the onboarding and safeguarding specs; none praises restriction, shames eating or cheers, and the exclusion and not-right-now pages state a reason with warmth, never a diagnosis.
- mm-pr3, Vocabulary — yes. Every string uses the defined terms ("entry", "record", "plan", "weigh-in", "starred") and no banned word; screen 1, the exclusion page and Get support use "binge eat"/"binge eating" as the PRD allows outside Today and the new-entry screen, and no string uses "binger", "bingeing" or "binge episode" (`TreatmentClaimTests.testEveryOnboardingStringPasses` proves it for every onboarding string).
- mm-pr4, Nothing looks like a nutrition app — yes. Every screen this change adds is text and system controls; no plate, fork, apple, scale or tape-measure image, and no food photography.
- mm-pr5, The product name and the plan slot — yes. Every string writes "Midmorning" with no hyphen; this change schedules no notification and references no book.
- mm-pr6, What a notification never shows — yes. This change schedules no notification; "Allow notifications" only opens the system permission request.
- mm-pr7, The person can put it down — yes. The app lock switch and "Quiet hours" are each a setting the person can turn off; onboarding frames no answer as a commitment the person can break, and an exclusion explicitly says "You can come back if this changes."
- mm-pr8, Accessibility everywhere — yes. Every control in the four screens and the three safeguarding pages carries a VoiceOver label (`.accessibilityLabel`/`.accessibilityFocused` throughout), every text uses a system text style so it scales with Dynamic Type, and no control's meaning depends on colour alone (the weigh-in day and start-day choices are a native `Picker`, whose selection state VoiceOver and Voice Control read on their own). This epic has no separate P2 accessibility bead; each screen bead above builds its own labels and reading order, per CLAUDE.md, and a device check (listed below) proves VoiceOver reading order, focus movement and AX5 layout on real hardware.
- mm-pr9, Dates and times in strings — yes. `StartDayChoice.label` and `DayBoundaryLine.text` both use the en_GB locale and the 24-hour clock, fixed regardless of device locale; the app lock section says "device", never "iPhone".
- mm-pr10, Offline and private by default — yes. No screen this change adds makes a network call except "Beat webchat", which opens the bundled URL in an `SFSafariViewController`; every safeguarding rule, every page's content and the pasteboard's local-only option keep data on the device.
- mm-pr11, No AI at runtime — yes. `ScreeningRules`, `SelfHarmItem`, `BMI`, `TreatmentClaim` and every page's content are deterministic pure functions and bundled strings; this change generates no sentence and calls no model.
- mm-pr12, Appearance — yes, with one exception noted at the fix. Every view uses system colours, system text styles, the plain list style and the system sheet; a `Picker` supplies every single-choice control (its own system checkmark, not an app-added glyph) instead of a hand-drawn selection indicator, and "This device only" shows as chosen with a `LabeledContent` value, never an image. No custom colour, corner radius or font is set anywhere in this change.

## Get support on every screen

Every full screen this change adds applies `GetSupportModifier`: the four onboarding screens ("What this is and isn't", "A few questions first", "Your start", "Permissions"), the caution sheet, the exclusion page, the not-right-now page and the GP suggestion page. The support sheet itself shows "Close" instead, per the spec's own exemption for the sheet Get support opens. `Today` (`record-full`'s own screen) now opens the real sheet in place of its placeholder button.

## Device checks

Every scenario below needs a device or the simulator's own hardware-backed behaviour (VoiceOver, Dynamic Type at AX5, the system phone-call flow, `UIPasteboard`'s real clear-after-60-seconds timing, Universal Clipboard, `SFSafariViewController`, Touch ID enrolment) that `swift test` cannot drive. Ash does each check and adds a date and a screenshot to this README; the agent lists these on the epic's device-check bead (`mm-t14.28`), which is a `human`-labelled bead this agent does not close.

1. "Accessibility labels" — the VoiceOver check on the four screens, before the team declares the label in App Store Connect (task 27.1; requirement "Four screens, once, in order").
2. "Largest text size" on "What this is and isn't" — "Continue" stays below the last line and the person scrolls to reach it (task 16.1; requirement "Screen 1: what this is and isn't").
3. "BMI on no screen" — a reviewer's walk of every screen after onboarding (task 18.1; requirement "The one-time BMI").
4. "VoiceOver on the example" — the example row reads "13:05, Toast and tea" (task 21.1; requirement "Screen 3: the record in three sentences").
5. "Lock sentence on a Touch ID device" — needs a device or simulator with Touch ID enrolled and `LocalAuthentication`'s real `Biometry` detection wired in, not this build's fixed `.faceID` (task 23.1; requirement "Screen 4: permissions").
6. "Call Beat" on the exclusion page — the real system call flow for 0808 801 0677 (task 6.1; requirement "The exclusion page").
7. "Call Samaritans", "Cancel the call", "Call Beat in Scotland", "Copy a number", "Beat webchat" — the confirmation dialog, the real call flow, the pasteboard write and the `SFSafariViewController`, on the support sheet (task 11.1; requirement "The support sheet").
8. "Release check" — a reviewer checks each number, its hours and the webchat URL against the service's own website (task 11.1; requirement "The support sheet").
9. "The pasteboard clears", "Universal Clipboard", "Copy and paste into Messages", "Largest text size" — the GP paragraph's "Copy" control (task 12.1; requirement "The GP paragraph").
