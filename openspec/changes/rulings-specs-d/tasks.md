# Tasks

Each task changes one requirement and its copy in `openspec/changes/v1-programme/specs`, when a copy exists. The proof for each task is `openspec validate rulings-specs-d --type change --strict` and `openspec validate --all --strict`.

## 1. regular-eating-plan

- [x] 1.1 Modify regular-eating-plan "Accessibility of the plan" for r19-02: end the row's label with the next-planned-meal line. Run `openspec validate rulings-specs-d --type change --strict`.

## 2. app-lock

- [x] 2.1 Modify app-lock "Face ID only or Touch ID only" for r19-04: show no control when no biometric is enrolled, and change the scenario "No biometric enrolled". Run `openspec validate rulings-specs-d --type change --strict`.

## 3. reminders

- [x] 3.1 Add reminders "A tap on a reminder opens its screen from Today" for r20-01, with the scenarios "A tap while another screen shows", "A tap on the weigh-in day reminder while another screen shows" and "A tap over a new entry with a draft". Add the same requirement to the v1-programme reminders spec. Run `openspec validate rulings-specs-d --type change --strict`.
- [x] 3.2 Change "their back control MUST show Today" to "their back control MUST go back to Today", and make the scenario "A tap on the weigh-in day reminder while another screen shows" read "a tap on its back control shows Today". iOS can show "Back" or only a chevron as the back control. Do the same in the v1-programme copy. Run `openspec validate rulings-specs-d --type change --strict`.
- [x] 3.3 Flag the conflict between this requirement and safeguarding "The not-right-now page" and "The GP suggestion page" for Ash, with the cases that the requirement does not give (an empty new-entry screen, the other sheets, a midday reminder over a draft). mm-t45.23 (label `human`) holds the conflict and the options. Do not add a rule for these cases until Ash rules.
- [x] 3.4 Record mm-t45.23 as an open safeguarding gate on mm-t45.23 and mm-t45.12: the lead does not merge commit 0024f4f (branch rulings3-routing-labels) until Ash rules on mm-t45.23. After the ruling, add the exception sentence and one scenario for each case to this requirement and to its v1-programme copy.
- [x] 3.5 Add the r22-01 paragraph (the pages stay until "Done"; the weekly review, the check-in, the restart re-screen and the weigh-in screen stay until the person leaves them; the screen of the reminder opens no second time) and the r22-02 paragraph (each sheet of Today stays; an empty new entry closes; the sheet of the reminder stays; "unsaved input" names text, a Where, a typed place and the star) to the requirement and its v1-programme copy, with nine more scenarios. Run `openspec validate rulings-specs-d --type change --strict`.

## 4. export

- [x] 4.1 Modify export "Accessibility of the export" for r20-02: declare en-GB on each tag, and make the scenario "The document language after the spike" read the tag tree. Run `openspec validate rulings-specs-d --type change --strict`.

## 5. onboarding, safeguarding and data-and-privacy

- [x] 5.1 Modify onboarding "Four screens, once, in order" for r21-01: a passing run of the accessibility audits on the commit of the build is sufficient for a declaration. Change the scenario "Accessibility labels". Run `openspec validate rulings-specs-d --type change --strict`.
- [x] 5.2 Edit safeguarding "Regulatory release gates" in v1-programme for r21-01. Rename the scenario "Accessibility label without a screenshot" to "Accessibility label without a passing audit run". This requirement is in v1-programme only. Run `openspec validate --all --strict`.
- [x] 5.3 Edit data-and-privacy "Release gates and the App Store submission" in v1-programme for r21-01, with the scenario "Accessibility labels declared". This requirement is in v1-programme only. Run `openspec validate --all --strict`.
- [x] 5.4 Change task 4.3.4 and the paragraph on accessibility checks in `openspec/changes/v1-programme/tasks.md`, and `tools/skeleton-checks/README.md`, for r21-01. Run `openspec validate --all --strict`.
- [x] 5.5 Ask Ash on mm-t43.16 if a run with an expected failure from `auditKnownDefects` counts for a declaration. Until Ash rules, task 4.3.4 and the README paragraph "Known defects and a declaration" say that such a run does not count. After the ruling, write the answer as one sentence in safeguarding "Regulatory release gates" and in the README.
- [x] 5.6 Change the scenario name in the description and the notes of index bead mm-t43.3 to "Accessibility label without a passing audit run", and change the description of gate mm-t43.16 to the r21-01 rule.
- [x] 5.7 State the result of the interim answer in task 4.3.4 and in the README paragraph "Known defects and a declaration": while `auditKnownDefects` holds the entries for mm-t45.18, mm-t45.20 and mm-t45.21, no run counts, and the team declares no accessibility label. Add the same text as a comment on mm-t43.16. Run `openspec validate --all --strict`.

## 6. product-rules

- [x] 6.1 Edit product-rules "Appearance" in v1-programme for r21-02: add the sentence on the text of a filled button and the scenario "A filled button in dark mode". This requirement is in v1-programme only. Run `openspec validate --all --strict`.
- [x] 6.2 Name the system colour of the text of a filled button: the system background colour (`systemBackground`), so the text is not a custom colour. Run `openspec validate --all --strict`.

## 7. safeguarding (r19-01)

- [x] 7.1 Confirm that no spec names the Beat webchat URL, so r19-01 changes no spec. Run `grep -rn "one-to-one-webchat" openspec/specs openspec/changes/v1-programme`; it finds nothing.

## 8. Follow-ups

This change does not build code. These beads hold the build work for the rulings.

- mm-t45.5 builds r19-01 in `SupportSheet.beatWebchatURLString` and its bundle copy in `Packages/Content/Resources/strings.json`.
- mm-t23.26 builds r19-02 in `PlannedMealAccessibility.label`.
- mm-t45.12 builds r20-01 in `ReminderRouteOpening`. Commit 0024f4f (branch rulings3-routing-labels) put its UI tests in `AutomatedChecks+RouteFromAnyScreen.swift`.
- mm-t12b.29 builds r21-02 in the app target's build settings and the filled button style.
- r19-04 and r20-02 need no code. This change closes mm-t15.24 and mm-t42.31.
- mm-t43.16 is a gate. Ash closes it.
- mm-t45.23 (P1, label `human`) holds the conflict between r20-01 and the safeguarding pages. It is an open safeguarding gate. Commit 0024f4f (branch rulings3-routing-labels) builds r20-01 as written, so the lead does not merge 0024f4f until Ash rules on mm-t45.23. mm-t45.25 holds the other sheets that a reminder tap closes.
- mm-t45.26 adds a UI test for the scenario "No biometric enrolled" (r19-04): the Privacy group shows no "Face ID only" or "Touch ID only" control. Item (5) of device-check bead mm-t15.14 stays on that bead until the test exists.
- mm-t45.24 holds three code comments that give the rules from before r19-04 and r20-02. Task 9.1 changed the design line in `openspec/changes/v1-programme/design.md`.
- After the archive of this change, set the spec_id of mm-t45.12 to the new heading: `bd update mm-t45.12 --spec-id "openspec/specs/reminders/spec.md#A tap on a reminder opens its screen from Today"`. Before the archive, `openspec/specs` does not hold that heading, so `scripts/check-beads` cannot find it.

## 9. design

- [x] 9.1 Change the export line of `openspec/changes/v1-programme/design.md` ("Export renders a tagged, flowing column at fixed sizes") for r20-02: each tag declares en-GB, and the document catalog holds no language. Run `openspec validate --all --strict`.

## 10. Round 22 (11 October 2026)

- [x] 10.1 r22-05: modify export "Choose a date range" (wheel date pickers, the scenario "The dates are wheels"), here and in the v1-programme copy. Run `openspec validate rulings-specs-d --type change --strict`.
- [x] 10.2 r22-06 and r22-07: edit product-rules "Accessibility everywhere" in v1-programme (4.5:1 and 3:1, the audit pass with Increase Contrast, three scenarios). Run `openspec validate --all --strict`.
- [x] 10.3 r22-04 and r22-06: edit product-rules "Appearance" in v1-programme (alerts keep the system blue, the scenario "An alert keeps the system blue", 4.5:1 for the asset and the text of a filled button, an Increase Contrast value for each mode, a control that deletes uses the accent colour). Run `openspec validate --all --strict`.
- [x] 10.4 r22-03: add the rule to safeguarding "Regulatory release gates" (with the scenario "A passing run that logs a contrast issue"), data-and-privacy "Release gates and the App Store submission", onboarding "Four screens, once, in order" here and in v1-programme, task 4.3.4 of `v1-programme/tasks.md` and `tools/skeleton-checks/README.md`. Run `openspec validate --all --strict`.
- [x] 10.5 Build r22-01 and r22-02: `TodayRouteGate.Hold` and the step `keepTheScreen`; `holdsReminderRoutesWhileOpen` on the weekly review, the re-screen and the weigh-in screen; the midday reminder over a new entry with input keeps it. Proof: `TodayRouteGateTests`, `ReminderRouteHoldSourceTests`, and the UI tests of `AutomatedChecks+RouteFromAnyScreen.swift`, with the new `testReminderTapWaitsForAScreenWithAnswers`.
- [x] 10.6 Build r22-05: `ExportScreenView` shows wheel date pickers. Proof: `testExportInNewYorkShowsTheSameDates` and `assertTheExportDatesAreWheels` in the export audits; the entry for mm-t12b.30 leaves `auditKnownDefects`.
- [x] 10.7 Build r22-06: the audits measure each part at its own limit (`auditContrastLimit`); the keyboard "Save" at 4.5:1; the controls that delete use the accent colour; the AccentColor asset gets Increase Contrast values 143552 (light) and A8D2F7 (dark). Proof: `AccentContrastTests` and the audits.
- [x] 10.8 Build r22-07: the pass with Increase Contrast in `automated-checks.sh --audits` (`INCREASE_CONTRAST`, `auditIncreaseContrast`). Proof: a run of `--audits`.
- The check-in part of r22-01 (no scenario of this change), deferred: mm-t36.8. The check-in screen does not exist yet. Its build gives it `holdsReminderRoutesWhileOpen(.checkIn)`; the hold kind is in `TodayRouteGate.Hold`.
- Two cases that r22-02 keeps as built (no scenario of this change), deferred: mm-t45.25. The edit screen of an earlier day and the plan builder of a stage screen close with their screen after a reminder tap, and unsaved changes in them go.

