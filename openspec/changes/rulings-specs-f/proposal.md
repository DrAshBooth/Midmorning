# Proposal

## Why

Ash gave one ruling on 13 October 2026 (round 25). Ruling r25-01 ("Testers on my sign-off") changes a built requirement: `content` "Clinical sign-off per content version". So this change writes it into `openspec/specs/content` through its delta, and into the copy in `openspec/changes/v1-programme/specs/content`.

- r25-01: a tester build can ship on Ash's sign-off as the owner, recorded as an owner's sign-off. The clinical reviewer's sign-off stays required before the App Store build.

Ash wrote on 12 October 2026, on decision r24-12: "Consider this my sign off for content version 5. Happy with it". The built requirement lets only a clinical psychologist with CBT-E training sign a content version. So the first TestFlight upload waited for the clinical reviewer. This change opens a second lane for tester builds, and it keeps the clinical lane for the launch build.

## What Changes

- `content` "Clinical sign-off per content version": a sign-off file gains the field `kind`, with the two values "owner" and "clinical". Both kinds hold the tone answer for every card and the list of ids reviewed. A matching sign-off of either kind clears the "Draft" flag. The content test fails when a sign-off file has no `kind`. A new environment variable, MIDMORNING_LAUNCH, marks the launch lane. When it is 1 and the matching sign-off does not have the kind "clinical", the content test fails and names the version and the kind. The archive script takes the option `--launch` for the App Store build, and that option sets MIDMORNING_LAUNCH=1. Without `--launch`, the script archives a tester build. The scenario "Sign-off present" names the kind. Six scenarios are new: "A tester build on the owner's sign-off", "The launch lane with an owner's sign-off", "The launch lane with the clinical sign-off", "A sign-off file without a kind", "The archive script for a tester build" and "The archive script with --launch".
- `product-rules` "No AI at runtime", in `openspec/changes/v1-programme/specs` only: before the App Store build, the clinical reviewer's sign-off covers the content bundle and the signed catalogue keys. A tester build can carry the owner's sign-off instead. `openspec/specs` holds no product-rules spec, so this change has no product-rules delta.

The changed content requirement has a copy in `openspec/changes/v1-programme/specs`, and that copy gets the same change. This change keeps every other line of the built text.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `content`

## Impact

This is a correction of the first cut. The code is small: the `kind` field on `SignOff` in `Packages/Content/SignOff.swift`, the launch lane in `ReleaseLane`, the content test in `Packages/Tests/ContentTests/SignOffTests.swift`, the `--launch` option of `scripts/archive`, and `Packages/Content/SIGNOFF.md` if it describes the file. The content version does not rise, because no string changes.

This change is also the build change of task 1.1b (`mm-t11b`). The agent in that worktree builds tasks 3.1 to 3.5 below. The code lands before the first TestFlight upload. Ash then writes `content-signoff-v5.json` with the kind "owner" (the gate bead under `mm-t43`). This change writes no sign-off file. The clinical sign-off of every content version is a launch gate now (`mm-t43.8` and `mm-t43.25` under `mm-t43b`).
