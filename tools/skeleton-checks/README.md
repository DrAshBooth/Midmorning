# Skeleton checks on the simulator

These tools produced the evidence for rows 2.4 to 2.9 and 2.12 of
`openspec/changes/record-entry-on-today/tasks.md` on 25 September 2026.
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
