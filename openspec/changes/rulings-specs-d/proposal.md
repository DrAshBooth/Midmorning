# Proposal

## Why

Ash gave rulings on 9 October 2026, on the Midmorning Decisions page. Each ruling is final. Each ruling bead holds a comment that quotes the ruling. This change writes the spec text for seven of those rulings. Ash gave seven more rulings on 11 October 2026 (round 22). This change also writes the spec text for them, and the same branch builds them.

- r19-01 (mm-t45.5): the Beat webchat link uses the new URL of Beat's one-to-one web chat page.
- r19-02 (mm-t23.26): the label of a planned meal row ends with the next-planned-meal line when the row shows it.
- r19-04 (mm-t15.24): with no biometric enrolled, the Privacy group shows no "Face ID only" or "Touch ID only" control.
- r20-01 (mm-t45.12): a tap on a reminder removes every screen from Today's navigation stack, then opens the screen of that reminder.
- r20-02 (mm-t42.31): each tag of the export PDF declares en-GB, and the document catalog holds no language.
- r21-01 (mm-t43.16): a passing run of the accessibility audits on the commit of the build is sufficient to declare an accessibility label in App Store Connect.
- r21-02 (mm-t12b.29): every control uses the AccentColor asset, and a filled button shows near-black text in dark mode.
- r22-01 (mm-t45.23): a reminder tap does not close the not-right-now page or the GP suggestion page. It also does not close the weekly review, the check-in, the restart re-screen or the weigh-in screen. The screen of the reminder opens after the person leaves them.
- r22-02 (mm-t45.12, mm-t45.25): a reminder tap while another sheet shows keeps the build on main. The app waits for each sheet of Today and for a new entry with any input, closes an empty new entry, and the midday reminder counts an open new entry as its screen.
- r22-03 (mm-t43.16): a passing audit run supports an accessibility label only for a feature with no known fault and no logged issue in that run.
- r22-04 (mm-t12b.29): system alerts keep the system blue.
- r22-05 (mm-t12b.30): the export screen shows its dates as wheel date pickers.
- r22-06 (mm-t45.17): primary text and the text of a button contrast at 4.5:1 or more; secondary text, large text and glyphs at 3:1 or more.
- r22-07 (mm-t45.19): `automated-checks.sh --audits` gets a pass with Increase Contrast on.

## What Changes

- `regular-eating-plan`: "Accessibility of the plan" puts the next-planned-meal line at the end of the row's label, after a comma and a space. A new scenario reads the Mid-afternoon row with the line.
- `app-lock`: "Face ID only or Touch ID only" shows no control when no biometric is enrolled. The control stays disabled when the app lock is off. The scenario "No biometric enrolled" changes to agree. The app already does this.
- `reminders`: the new requirement "A tap on a reminder opens its screen from Today" holds the r20-01 rule and three scenarios. No current requirement holds a rule for a tap on every reminder type, so this change adds one. The new-entry screen with unsaved text stays in front, and the screen of the reminder opens after it closes. The back control of the weigh-in screen and the weekly review goes back to Today. "Add" and the app-lock rule for "Add" do not change. On 9 October 2026 this requirement conflicted with safeguarding "The not-right-now page" and "The GP suggestion page": a reminder tap removed the screen under the page, so the page closed. Rulings r22-01 and r22-02 settle the conflict. The requirement now keeps each page until "Done", keeps the weekly review, the check-in, the restart re-screen and the weigh-in screen until the person leaves them, and gives a rule for each sheet of Today, with eight more scenarios.
- `export`: "Accessibility of the export" declares en-GB on each tag. The scenario "The document language after the spike" reads the tag tree, not the document properties. "Choose a date range" makes each date control a wheel date picker with its label above it (r22-05), with the scenario "The dates are wheels".
- `onboarding`: "Four screens, once, in order" lets the team declare an accessibility label after a passing run of the accessibility audits. The scenario "Accessibility labels" reads the dated line of that run.
- `safeguarding` and `data-and-privacy` (in `v1-programme` only): "Regulatory release gates" and "Release gates and the App Store submission" get the same rule as onboarding. Both, and onboarding, also get the r22-03 rule: a run supports a label only for a feature with no known fault and no logged issue. Safeguarding gets the scenario "A passing run that logs a contrast issue". The scenario "Accessibility label without a screenshot" becomes "Accessibility label without a passing audit run". The scenario "Accessibility labels declared" keeps its name.
- `product-rules` (in `v1-programme` only): "Appearance" gets sentences and one scenario for the text of a filled button. The text uses the system background colour (`systemBackground`), so it is not a custom colour. From round 22: "Accessibility everywhere" sets 4.5:1 for primary text and button text, and 3:1 for secondary text, large text and glyphs (r22-06), and names the audit pass with Increase Contrast (r22-07), with three scenarios. "Appearance" keeps the system blue on alerts with the scenario "An alert keeps the system blue" (r22-04), raises the accent asset and the filled button text to 4.5:1, asks for an Increase Contrast value for each mode, and makes a control that deletes data use the accent colour, not red.
- `v1-programme/tasks.md` (4.3.4 and the paragraph on accessibility checks) and `tools/skeleton-checks/README.md` state the r21-01 rule and the r22-03 answer to the question on mm-t43.16. The README maps each App Store label to the kinds of audit issue, and states the r22-06 limits and the r22-07 pass.
- `v1-programme/design.md`: the export line states the r20-02 rule.
- r19-01 changes no spec. No spec names the webchat URL. The URL is in the bundled strings, as safeguarding "The support sheet" states.

Each changed requirement that has a copy in `openspec/changes/v1-programme/specs` gets the same change there. A v1 copy keeps its own extra scenarios. The v1 reminders spec adds the new requirement under its ADDED requirements.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `regular-eating-plan`
- `app-lock`
- `reminders`
- `export`
- `onboarding`
- `safeguarding` (in `v1-programme` only)
- `data-and-privacy` (in `v1-programme` only)
- `product-rules` (in `v1-programme` only)

## Impact

The part of this change from 9 October 2026 edits spec text and two documents only. The round 22 part also builds its rulings on the same branch: `TodayRouteGate` and `ReminderRouteOpening` for r22-01 and r22-02, the wheel date pickers of `ExportScreenView` for r22-05, the audit limits of `AutomatedChecks+Accessibility.swift`, the AccentColor asset and the colour of the controls that delete for r22-06, and the pass in `automated-checks.sh` for r22-07. The build choice for r22-01: a screen with answers holds the route from its first appearance until SwiftUI removes it (`holdsReminderRoutesWhileOpen`), so the route does not open while the screen's own page covers it; when the held screen is the screen of the reminder, the app keeps it and opens nothing. This is the same as the interim build for the pages, which held the route until "Done". The code agents build the code for r19-01, r19-02, r20-01 and r21-02, and close their beads. r19-04 and r20-02 need no code, so this change closes mm-t15.24 and mm-t42.31. mm-t43.16 is a gate that Ash closes; this change adds a comment to it. Ruling r22-03 answers its question on known defects: while the entries of `auditKnownDefects` for mm-t45.18, mm-t45.20 and mm-t45.21 take findings in each run, a run supports none of the labels "Sufficient Contrast", "Dark Interface", "VoiceOver" and "Voice Control". Ruling r22-01 closes the safeguarding gate mm-t45.23; main holds commit 0024f4f and the interim build, and this branch builds the ruling over them.
