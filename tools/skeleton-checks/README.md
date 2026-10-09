# Skeleton checks on the simulator

These tools produced the evidence for rows 2.4 to 2.9 and 2.12 of
`openspec/changes/archive/2026-09-25-record-entry-on-today/tasks.md` on 25 September 2026.
They are not part of `./verify`.

- `seeder/` writes seeded stores through `RecordStore.add`, as the app does.
- `Harness.xcodeproj` holds a UI-test bundle that drives the installed app by
  its bundle identifier, `uk.midmorning.app`. The host app does nothing.
- `run.sh` copies a seeded store into the app's container and runs one test.

```bash
cd tools/skeleton-checks
(cd seeder && swift build && mkdir -p ../stores/today ../stores/long \
  && .build/debug/Seeder ../stores/today/Record.store today \
  && .build/debug/Seeder ../stores/long/Record.store long)
xcodebuild -project ../../App/Midmorning.xcodeproj -scheme Midmorning \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .dd-app build
xcrun simctl install booted .dd-app/Build/Products/Debug-iphonesimulator/Midmorning.app
xcodebuild build-for-testing -project Harness.xcodeproj -scheme HarnessUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .dd
./run.sh test24_25_Today today
./run.sh test28_Save long
# Row 2.6: run a minute or two before 04:00 in a zone of your choice.
./run.sh test26_Heading today TEST_RUNNER_HEADING_TZ=Pacific/Guadalcanal
```

The first keyboard use shows an iOS tip; the tests dismiss it.

| Test | Store | What it checks |
|------|-------|----------------|
| `test24_25_Today` | today | Headings, row order, row labels (rows 2.4 and 2.5) |
| `test26_OneTap` | today | One tap opens the new-entry screen (2.6) |
| `test26_Heading` | today | The heading after 04:00 on reactivation (2.6); set `TEST_RUNNER_HEADING_TZ` to a zone a minute or two before 04:00 |
| `test27_NewEntry` | today | Keyboard, focus, placeholder, title, star label, order, date range (2.7) |
| `test27_TimeValue` | today | The time control's label and value, and the buttons inside it |
| `test28_Save` | long | Save, dismissal, scroll, and a save with an empty What (2.8) |
| `test29_Switcher` | today | Today in the app switcher (2.9) |
| `test29_SwitcherWithSheet` | today | The new-entry screen in the app switcher, and the state after a return (2.9) |
| `test212_ShameWalk` | today | Screenshots of the starred-entry path (2.12); run once in each appearance with `xcrun simctl ui booted appearance dark` or `light` |
| `testAudit` | today | Xcode's accessibility audit of Today and the new-entry screen; logs every issue |

Each run writes screenshots and `evidence.log` to `out/`.

## Automated device checks (rulings r13-19 and r16-01)

Ash ruled on 26 September 2026 (r13-19, mm-t43.30) that navigation, text
and manifest checks move off the device-check beads into tests. Ash ruled
on 7 October 2026 (r16-01, mm-t43.32) that a flow check is a navigation
check, so flow checks also move into tests.

- Text and manifest checks are package tests in
  `Packages/Tests/AutomatedDeviceChecksTests`. `./verify` runs them. A
  package test proves the words from the string catalogue or the content
  bundle. When it also matches the source of an App file, that part is
  proved from the source text only: it shows that the screen calls the
  words, not where they show. A layout claim needs a UI test.
- Navigation checks, flow checks, and the text checks that need the
  screen, are UI tests in `HarnessUITests/AutomatedChecks.swift` and its
  extensions `AutomatedChecks+RecordPlan.swift`, `+OnboardingReview.swift`,
  `+RemindersExport.swift` and `+AppLock.swift` (127 checks on 7 October
  2026). Each test names its device-check bead. Run them with one command:

```bash
tools/skeleton-checks/automated-checks.sh            # every check
tools/skeleton-checks/automated-checks.sh testPrivacyNotice testDiagnosticsShowsTheEightCounts
```

A new navigation, text, manifest or flow check goes into one of these two
places, not onto a device-check bead. A device-check bead keeps what needs a
device or a person, for example: biometrics, real notifications and calls, a
change of the clock, backups, the network, crashes, Instruments, a
third-party keyboard and the shame walk.

An accessibility check is never a device check, because Ash does not test
accessibility features by hand (8 October 2026, bd memory
`ash-no-accessibility-device-checks`). So a device-check bead keeps no
VoiceOver, Voice Control, largest text size (AX5), contrast, Increase
Contrast, Reduce Motion or Accessibility Inspector check. An agent proves an
accessibility check with an automated test: Xcode's accessibility audit
(`performAccessibilityAudit`) in a UI test, or an assertion on the
accessibility tree. If no automated test can prove a part, no person checks
that part by hand. The app must still meet product-rules "Accessibility
everywhere" and the accessibility requirement of each spec.

An automated test is not a device check. The specs let the team declare an
accessibility label in App Store Connect only after a device check with a
dated screenshot. So the team declares no accessibility label until Ash
rules on this conflict (mm-t43.16).

A flow check does a sequence of actions and then looks at what the app
shows or keeps. The review fixes (commit aee8059) added UI tests for 12 flow
items: mm-t12b.6, .7, .9, .10 and .12; mm-t13.11 and .13; mm-t21.28;
mm-t22.24 ("saves nothing"); mm-t32.19, .20 and .24. Each of these items
has an "Automated by ... (r13-19, r16-01)" comment on its device-check bead.
Ash can skip them under the same conditions as the other UI-test items
(see "When Ash can skip a device check"). mm-t43.32 and mm-t43.33 (epic
mm-t45) automate the other flow checks that the simulator can run. Until
one of them adds the test for an item, that item stays on its device-check
bead. A part of a flow that needs a device or a person stays a device
check, for example the real weekly review reminder of mm-t32.21. An
accessibility part of a flow is not a device check, for example the
VoiceOver action of mm-t12b.7. "Point contrast" on mm-t22.16 measures a
colour in dark mode with Increase Contrast. Ruling r16-01 kept it as a
device check. It is a contrast check, so it left the device-check list on
8 October 2026.

The script makes and boots its own simulator (`mm-automated-checks`), so it
does not disturb a simulator that another session uses. It reads the
content version in `Packages/Content/Resources/manifest.json` and gives
`testDraftShowsAboveTheCardTitle` the draft state to expect: a draft when
that folder holds no `content-signoff-v<version>.json`. It builds and
uninstalls and installs the app (so each run starts with the notification
permission not asked and a new data container), builds the UI tests, and
seeds the stores with `seeder`. `AutomatedScenarios.swift` holds `week1`,
`review` and `corrupt`; `RecordPlanScenarios.swift`,
`OnboardingReviewScenarios.swift` (the `or-` stores),
`RemindersExportScenarios.swift` and `AppLockScenarios.swift` (the `lock-`
stores) hold the rest, and each file tells what its stores hold. Before each
launch, a test copies one seeded store into the app's container. Some
stores are seeded in a fixed-offset zone (`Etc/GMT±N`) and the test
launches the app with `TZ` set to it, so a check that needs an evening or a
night time does not depend on the hour of the run. The log and the result
bundle go to `out/automated/`.

Tools the tests use:

- The app-lock test seam, `App/Midmorning/AppLock/AppLockTestSeam.swift`,
  is in Debug builds only (`AppLockTestSeamSourceTests` in `./verify` proves
  that a Release build holds none). A UI test turns it on with the launch
  environment variable `MIDMORNING_APP_LOCK_SCRIPT`: each system
  authentication request takes the next scripted result (succeed, fail,
  cancel or no passcode), and the enrolment hash comes from the script. The
  real Face ID prompt, the passcode fallback and a real enrolment change
  stay device checks.
- Simulated reminders. `push-relay.sh` sends each file that a test writes
  to `out/automated/push` with `xcrun simctl push`. The script starts the
  relay before the checks and stops it at the end.
- Some tests read the store files with SQLite3, read an export PDF with
  PDFKit, read a label hidden from VoiceOver with Vision text recognition,
  or make the store files read-only so that a save fails.

When to run. Start the checks between 09:00 and 02:45 in the Mac's time
zone. The seeder puts no entry after now, and the gap band on the current
record day needs 5 hours of that day; before 09:00 the seeder stops with an
error. A full run takes about 75 minutes (4536 s on 7 October 2026), and it
must end before 04:00, when the record day changes.

Known causes of a failure that a second run does not repeat: the keyboard
tip of a new simulator, which has its own "Continue"; and, after a test
allows notifications, a reminder banner of the Mac's own clock time over
the app. Run the failed test alone by name before you look for an app
bug.

The UI tests are not part of `./verify`, for two reasons. First, the 127
checks take about 75 minutes on a warm simulator (7 October 2026), and a
warm `./verify` must stay under 240 s. Second, a simulator run needs a booted
simulator of its own, and parallel worktrees share one simulator service.
On 26 September 2026 that service stopped for about 20 minutes: every
`simctl` call waited while four simulators stayed in "Shutting Down". The
package tests stay in `./verify`; they take less than one second.

After a failure, the script keeps the test's screenshot and accessibility
hierarchy in `out/automated/<test>.png` and `<test>.txt`.

### When Ash can skip a device check

A bead comment that says "Automated by ... (r13-19)" or "Automated by ...
(r13-19, r16-01)" moves that check to this suite. Ash can skip a UI-test
item only after a dated run in which every check passes on a committed
build. A package-test item needs only `./verify`. Write that run as a line
in the table below: the date, the commit, the simulator runtime and the
result. The script writes that line
at its end. It also says loudly at the start and in that line when the
working tree has changes that are not committed, or when only named checks
ran: such a run does not count.

A tester build or a release build that skips an "Automated by" UI-test
item needs a new line for the commit of that build (gate mm-t43.31). A
build on which Ash does each of those checks by hand does not need the
line.

Two bugs change what the suite checks:

- mm-t12b.27: on the iOS 27.0 simulator Today is blank while TodayView,
  NewEntryView and EditEntryView apply `.privacySensitive()`. Ash ruled on
  7 October 2026 (r16-02): remove `.privacySensitive()` and
  `.redacted(reason:)` from the three screens. Branch rulings2-record-review
  removes them. The cover window hides every screen while the app is not
  active, with the app lock on or off.
- mm-t12b.28: on iOS 27, "Delete this entry?" shows no "Cancel".
  This occurs with a confirmation dialog, which shows as a popover with
  no "Cancel" from iOS 26. Ash ruled on 7 October 2026 (r16-03) that each
  confirmation with a "Cancel" is an alert, which shows both buttons.
  Commit d9340d7 makes this change. `tapDialogButton` fails when no alert
  with a "Cancel" button shows.

mm-t32.28 (each self-harm row at the review reads the question) is fixed
on branch rulings2-record-review: each row reads its own answer, and
`reviewSelfHarmRows` finds the rows by the answer only.

| Date | Commit | Runtime | Result |
|------|--------|---------|--------|
| 26 September 2026 | rulings-automation, not committed: the build removed the two modifiers of mm-t12b.27 | iOS 27.0 (24A434) | 35 of 35 passed in 794 s. This run does not count, because the build was not committed. |
| 7 October 2026 | 458b403 (rulings2-record-review), a branch build before the merge: the fixes of mm-t12b.27 and mm-t32.28 | iOS 27.0 (24A434) | 5 of 5 passed in 210 s: testGetSupportOnToday, testRecordStrings, testExportFromTheNotRightNowPage, testStepTwoLosesItsAnswerWhenStepOneChanges and testTheAnsweredSelfHarmItemStaysAnswered. This run does not count for gate mm-t43.31, because only the named checks ran, on a branch build. |
| 7 October 2026 | 530265b (main) | iOS 27.0 (24A434) | 34 of 35 passed in 824 s. testOnboardingScreen3 failed: the keyboard tip took the tap on screen 2's "Continue"; the test passed alone, and 68dc58e fixes the test. |
| 7 October 2026 | 68dc58e (main) | iOS 27.0 (24A434) | 35 of 35 passed in 798 s. |
| 7 October 2026 | 237aeb7 (main), the merge of the five automation branches | iOS 27.0 (24A434) | 126 of 127 passed in 4536 s. testRecordStrings failed (the app showed Settings after a tap); it passed alone. This run does not count. |
| 7 October 2026 | 42bf6a8 (main) | iOS 27.0 (24A434) | 143 of 144 passed in 5198 s. testRecordStrings failed again: the previous day's menu sat under the toolbar and the tap opened Settings; 1f55da8 fixes the test. |
| 7 October 2026 | 1f55da8 (main) | iOS 27.0 (24A434) | 142 of 144 passed in 5066 s. testOnboardingScreen4WithTheAppLockOffAndOn and testSafeModeChangesNoStoreFileAndCountsBothFailures stayed on onboarding screen 2: their walk could answer one question twice and leave another blank. The next commit gives every walk the checked completeScreen2. |
| 7 October 2026 | 567927e (main) | iOS 27.0 (24A434) | 144 of 144 passed in 5238 s. |
