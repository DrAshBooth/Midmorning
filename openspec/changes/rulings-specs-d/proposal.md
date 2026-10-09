# Proposal

## Why

Ash gave rulings on 9 October 2026, on the Midmorning Decisions page. Each ruling is final. Each ruling bead holds a comment that quotes the ruling. This change writes the spec text for seven of those rulings.

- r19-01 (mm-t45.5): the Beat webchat link uses the new URL of Beat's one-to-one web chat page.
- r19-02 (mm-t23.26): the label of a planned meal row ends with the next-planned-meal line when the row shows it.
- r19-04 (mm-t15.24): with no biometric enrolled, the Privacy group shows no "Face ID only" or "Touch ID only" control.
- r20-01 (mm-t45.12): a tap on a reminder removes every screen from Today's navigation stack, then opens the screen of that reminder.
- r20-02 (mm-t42.31): each tag of the export PDF declares en-GB, and the document catalog holds no language.
- r21-01 (mm-t43.16): a passing run of the accessibility audits on the commit of the build is sufficient to declare an accessibility label in App Store Connect.
- r21-02 (mm-t12b.29): every control uses the AccentColor asset, and a filled button shows near-black text in dark mode.

## What Changes

- `regular-eating-plan`: "Accessibility of the plan" puts the next-planned-meal line at the end of the row's label, after a comma and a space. A new scenario reads the Mid-afternoon row with the line.
- `app-lock`: "Face ID only or Touch ID only" shows no control when no biometric is enrolled. The control stays disabled when the app lock is off. The scenario "No biometric enrolled" changes to agree. The app already does this.
- `reminders`: the new requirement "A tap on a reminder opens its screen from Today" holds the r20-01 rule and three scenarios. No current requirement holds a rule for a tap on every reminder type, so this change adds one. The new-entry screen with unsaved text stays in front, and the screen of the reminder opens after it closes. "Add" and the app-lock rule for "Add" do not change.
- `export`: "Accessibility of the export" declares en-GB on each tag. The scenario "The document language after the spike" reads the tag tree, not the document properties.
- `onboarding`: "Four screens, once, in order" lets the team declare an accessibility label after a passing run of the accessibility audits. The scenario "Accessibility labels" reads the dated line of that run.
- `safeguarding` and `data-and-privacy` (in `v1-programme` only): "Regulatory release gates" and "Release gates and the App Store submission" get the same rule as onboarding. The scenario "Accessibility label without a screenshot" becomes "Accessibility label without a passing audit run". The scenario "Accessibility labels declared" keeps its name.
- `product-rules` (in `v1-programme` only): "Appearance" gets one sentence and one scenario for the text of a filled button.
- `v1-programme/tasks.md` (4.3.4 and the paragraph on accessibility checks) and `tools/skeleton-checks/README.md` state the r21-01 rule.
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

This change edits spec text and two documents only. The code agents build the code for r19-01, r19-02, r20-01 and r21-02, and close their beads. r19-04 and r20-02 need no code, so this change closes mm-t15.24 and mm-t42.31. mm-t43.16 is a gate that Ash closes; this change adds a comment to it.
