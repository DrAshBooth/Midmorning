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
  `Packages/Tests/AutomatedDeviceChecksTests`. `./verify` runs them.
- Navigation checks are UI tests in `HarnessUITests/AutomatedChecks.swift`.
  Each test names its device-check bead. Run them with one command:

```bash
tools/skeleton-checks/automated-checks.sh            # every check
tools/skeleton-checks/automated-checks.sh testPrivacyNotice testDiagnosticsShowsTheEightCounts
```

The script makes and boots its own simulator (`mm-automated-checks`), so it
does not disturb a simulator that another session uses. It builds and
installs the app, builds the UI tests, and seeds three stores with
`seeder` (`week1`, `review` and `corrupt`; `seeder/Sources/Seeder/AutomatedScenarios.swift`
tells what each holds). Before each launch, a test copies one seeded store
into the app's container. The app then opens on Today with the app lock off.
The log and the result bundle go to `out/automated/`.

The UI tests are not part of `./verify`, for two reasons. First, the 21
checks take about 430 s on a warm simulator (26 September 2026), and a warm
`./verify` must stay under 150 s. Second, a simulator run needs a booted
simulator of its own, and parallel worktrees share one simulator service.
On 26 September 2026 that service stopped for about 20 minutes: every
`simctl` call waited while four simulators stayed in "Shutting Down". The
package tests stay in `./verify`; they take less than one second.

Until mm-t12b.27 is fixed, every check that starts on Today fails: on the
iOS 27.0 simulator Today shows a blank screen. On 26 September 2026 all 21
checks passed on a local build with the fix of that bead, and that build
was not committed.

After a failure, the script keeps the test's screenshot and accessibility
hierarchy in `out/automated/<test>.png` and `<test>.txt`.
