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

## Automated device checks (ruling r13-19)

Ash ruled on 26 September 2026 (r13-19, mm-t43.30) that navigation, text
and manifest checks move off the device-check beads into tests.

- Text and manifest checks are package tests in
  `Packages/Tests/AutomatedDeviceChecksTests`. `./verify` runs them. A
  package test proves the words from the string catalogue or the content
  bundle. When it also matches the source of an App file, that part is
  proved from the source text only: it shows that the screen calls the
  words, not where they show. A layout claim needs a UI test.
- Navigation checks, and the text checks that need the screen, are UI
  tests in `HarnessUITests/AutomatedChecks.swift` (35 checks). Each test
  names its device-check bead. Run them with one command:

```bash
tools/skeleton-checks/automated-checks.sh            # every check
tools/skeleton-checks/automated-checks.sh testPrivacyNotice testDiagnosticsShowsTheEightCounts
```

A new navigation, text or manifest check goes into one of these two
places, not onto a device-check bead. A device-check bead keeps what needs a
device or a person, for example: VoiceOver, Voice Control, the largest text
size, contrast, biometrics, real notifications and calls, a change of the
clock, backups, the network, crashes, Instruments, a third-party keyboard
and the shame walk.

Flow checks wait for decision r16-01 on the Midmorning Decisions page. A
flow check does a sequence of actions and then looks at what the app shows
or keeps. The review fixes (commit aee8059) added UI tests for 12 flow
items: mm-t12b.6, .7, .9, .10 and .12; mm-t13.11 and .13; mm-t21.28;
mm-t22.24 ("saves nothing"); mm-t32.19, .20 and .24. The tests stay in the
suite, but until Ash answers r16-01, those items stay device checks.
"Point contrast" on mm-t22.16 also waits for r16-01.

The script makes and boots its own simulator (`mm-automated-checks`), so it
does not disturb a simulator that another session uses. It reads the
content version in `Packages/Content/Resources/manifest.json` and gives
`testDraftShowsAboveTheCardTitle` the draft state to expect: a draft when
that folder holds no `content-signoff-v<version>.json`. It builds and
installs the app, builds the UI tests, and seeds three stores with
`seeder` (`week1`, `review` and `corrupt`; `seeder/Sources/Seeder/AutomatedScenarios.swift`
tells what each holds). Before each launch, a test copies one seeded store
into the app's container. The app then opens on Today with the app lock off.
The log and the result bundle go to `out/automated/`.

When to run. Run the checks between 09:00 and 03:30 in the Mac's time
zone. The seeder puts no entry after now, and the gap band on the current
record day needs 5 hours of that day; before 09:00 the seeder stops with an
error. The run takes about 13 minutes, and it must end before 04:00, when
the record day changes.

The UI tests are not part of `./verify`, for two reasons. First, the 35
checks take about 13 minutes (794 s) on a warm simulator (26 September
2026), and a warm `./verify` must stay under 240 s. Second, a simulator run needs a booted
simulator of its own, and parallel worktrees share one simulator service.
On 26 September 2026 that service stopped for about 20 minutes: every
`simctl` call waited while four simulators stayed in "Shutting Down". The
package tests stay in `./verify`; they take less than one second.

After a failure, the script keeps the test's screenshot and accessibility
hierarchy in `out/automated/<test>.png` and `<test>.txt`.

### When Ash can skip a device check

A bead comment that says "Automated by ... (r13-19)" moves that check to
this suite. Ash can skip a UI-test item only after a dated run in which
every check passes on a committed build. A package-test item needs only
`./verify`. Write that run as a line in the table below: the date, the
commit, the simulator runtime and the result. The script writes that line
at its end. It also says loudly at the start and in that line when the
working tree has changes that are not committed, or when only named checks
ran: such a run does not count.

A tester build or a release build that skips an "Automated by" UI-test
item needs a new line for the commit of that build (gate mm-t43.31). A
build on which Ash does each of those checks by hand does not need the
line.

Two bugs change what the suite checks until they are fixed:

- mm-t12b.27: on the iOS 27.0 simulator Today is blank while TodayView,
  NewEntryView and EditEntryView apply `.privacySensitive()`. Ash ruled on
  7 October 2026 (r16-02): remove `.privacySensitive()` and
  `.redacted(reason:)` from the three screens. Branch rulings2-record-review
  removes them. The cover window hides every screen while the app is not
  active, with the app lock on or off.
- mm-t12b.28: on iOS 27, "Delete this entry?" shows no "Cancel".
  `tapDialogButton` taps outside the dialog to cancel. The fix of
  mm-t12b.28 makes the helper require the "Cancel" button. The fix waits
  for decision r16-03.

mm-t32.28 (each self-harm row at the review reads the question) does not
change the result: `reviewSelfHarmRows` finds the rows by the question
while the bug is open and by the answer after its fix. On 26 September
2026 the review checks passed both with and without a local fix of
mm-t32.28.

| Date | Commit | Runtime | Result |
|------|--------|---------|--------|
| 26 September 2026 | rulings-automation, not committed: the build removed the two modifiers of mm-t12b.27 | iOS 27.0 (24A434) | 35 of 35 passed in 794 s. This run does not count, because the build was not committed. |
