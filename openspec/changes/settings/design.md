# Design

## Context

This change builds task 1.3 from `openspec/changes/v1-programme/tasks.md`. `openspec/changes/v1-programme/design.md`'s section "Two store configurations in one directory" states the `Settings` and `LocalSetting` shapes this change reads and writes; "Pure seams the packages expose" names `ErasureZone` as the seam "Delete everything" calls. This file states only the decisions this change itself makes.

## Decisions

### Every setting key follows one pattern

A device-only switch is `reminder.<name>.enabled`; a synced time is `reminder.<name>.time`; a single synced flag is a flat key such as `record.gapBands.enabled` or `remindersPausedAt`. `StoreLayoutTests.swift` (`mm-t12.5`) already used this exact shape as its own fixture keys, before this change existed. Keeping the same shape means a reviewer who reads that test already knows this change's naming, and a later change's own settings row reads as one family, not several ad hoc ones. Rejected: a nested JSON blob per group. Cost to reverse: low, one row per key, but every read and write site would need the same key change.

### "Day starts at" applies from the next record day

The requirement text states a changed day start MUST take effect from the next day start and MUST NOT move a saved entry's record day. `RecordStore.setDayStartHour(_:now:calendar:)` reads the CURRENT hour in force, computes the record day right after `now` under that hour with `RecordDay.nextDayKey(after:calendar:startHour:)`, and writes the new hour keyed to that day. `dayStartHour(effectiveOn:)` then picks the latest append-only row whose key is that day or earlier. Rejected: writing the new row keyed to today and reading "tomorrow" as a special case at the call site — this would put the exception in every caller instead of in the one write. Cost to reverse: low; the row shape stays the same either way.

### `Bundle.module`-based content loading, keyed off `manifest.json`, not a `Resources` folder

`BundleLoader.loadShipped()` had never been called before this change: nothing in the App target read the `Content` package. Wiring it in for "Contact" and the content version surfaced two gaps this change closes:

- `loadShipped()` read `RepositoryRoot.contentResourcesDirectory`, a path from `#filePath` at compile time. That path exists on the machine that compiled the code, never inside a sandboxed app on a device. `loadShipped()` now finds `manifest.json` through `Bundle.module` and reads its enclosing directory, which works under both `swift test`'s macOS bundle layout (`Contents/Resources/manifest.json`) and the iOS app's own flat layout (`manifest.json` at the bundle's root); it assumes no fixed subdirectory name.
- `Packages/Package.swift` declared `Content`'s resources as one folder `.copy("Resources")`. `swift test` never showed a problem, because `swift build`'s own macOS bundle nests `Resources` under `Contents/` where `codesign` expects it. Once the App target linked `Content`, Xcode's own build produced a flat iOS bundle with a bare `Resources` directory at its root, alongside `Info.plist`, and `codesign` refused it: "bundle format unrecognized, invalid, or unsuitable". `Content`'s resources are now one `.copy` line per file; Xcode's build then places each file at the bundle's own root, with no nested directory, and `codesign` accepts it. Rejected: turning code signing off for the bundle target — the setting did not reach the Swift package's own synthesized bundle target at all, so it stayed signed regardless, and disabling it project-wide would also touch the app's own binary. Cost to reverse: low; a later resource file adds one more `.copy` line, same as before.

### The support sheet, the delete-all seam and the privacy notice's own legal text are stubs

`onboarding-and-safeguarding` (1.4) owns the real support sheet (`mm-t14.24`) and its cross-screen wiring (`mm-t14.23`); `local-delete-all` (4.1) owns `ErasureZone`; `mm-t43.23` supplies the privacy notice's controller, lawful basis and Article 9 text. This change ships a placeholder for each: a plain sheet titled "Get support" with no content yet, `StubDeleteAllSeam` (does nothing, never throws), and a placeholder paragraph in each of the notice's three legal sections. Rejected: leaving the "Get support" control or the "Delete everything" control out of the screens entirely until the owning change lands — the settings spec and the safeguarding "Get support on every screen" requirement both need the control present now, and a stub the owning change replaces costs less than adding it retroactively to three screens later. Cost to reverse: low; each stub is one small file or one placeholder string, swapped for the real thing at the call site.

### Plain system styling until `Appearance.swift` lands

`record-full` (1.2b, `mm-t12b`) builds `Appearance.swift` and the shared `AccentColor` asset in a worktree building in parallel with this one. This change's screens use the system's own list style, text styles and tint throughout, with no custom colour or list-row styling of their own, so there is nothing to migrate once `Appearance.swift` lands beyond adopting its tint. Rejected: inventing an interim accent colour — the Appearance requirement (`mm-pr12`) reserves that decision for the one shared asset.

## Risks / Trade-offs

- [The privacy notice's controller, lawful basis and Article 9 sections are placeholder text] → the screen structure and the rest of its content (the Apple, App Analytics, your-data, backup and complaints sections) are real and reviewable now; `mm-t43.23` fills the three placeholder sections without changing the screen's shape.
- [`about.contact` holds `contact@example.invalid` until `mm-t43.17` confirms the real address] → the content test (`CatalogueRulesTests`) already accepts either form, so no test changes when the real address lands.
- [The Reminders group's six switches and four times have no live scheduler yet] → each read and write is a pure `RecordStore` function tested with fixed dates; `reminders` (2.4) reads the same rows once it builds the scheduler, and `mm-t24.21` (a wiring bead) proves the paused and turn-on scenarios end to end.
