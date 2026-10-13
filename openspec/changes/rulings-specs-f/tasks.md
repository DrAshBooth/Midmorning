# Tasks

Each spec task changes one requirement and its copy in `openspec/changes/v1-programme/specs`. The proof for each spec task is `openspec validate --type change rulings-specs-f --strict` and `openspec validate --all --strict`. Ash ruled r25-01 on 13 October 2026.

## 1. content

- [x] 1.1 Modify content "Clinical sign-off per content version" for r25-01: the field `kind` with the values "owner" and "clinical", the launch lane with MIDMORNING_LAUNCH, and `scripts/archive --launch`. Change the scenario "Sign-off present" to name the kind. Add the scenarios "A tester build on the owner's sign-off", "The launch lane with an owner's sign-off", "The launch lane with the clinical sign-off", "A sign-off file without a kind", "The archive script for a tester build" and "The archive script with --launch". Do the same in the v1-programme copy.

## 2. product-rules

- [x] 2.1 Modify product-rules "No AI at runtime" in `openspec/changes/v1-programme/specs/product-rules/spec.md` only, for r25-01: before the App Store build, the clinical reviewer's sign-off covers the content bundle and the signed catalogue keys. A tester build can carry the owner's sign-off instead. `openspec/specs` holds no product-rules spec, so this change has no product-rules delta.

## 3. Build

The agent of the epic `mm-t11b` (task 1.1b) builds these tasks in the worktree of this change. The child bead is `mm-t11b.1`. The agent writes no sign-off file.

- [ ] 3.1 Add the field `kind` to `SignOff` in `Packages/Content/SignOff.swift`, with the two values "owner" and "clinical". A file with no `kind` does not decode as a sign-off, and the content test fails and names the file. Proof: the scenarios "Sign-off present", "A tester build on the owner's sign-off" and "A sign-off file without a kind".
- [ ] 3.2 Add the launch lane to `ReleaseLane`: the environment key MIDMORNING_LAUNCH. When it is 1, the gate passes only a matching sign-off of the kind "clinical". The failure names the content version and the kind. Proof: the scenarios "The launch lane with an owner's sign-off" and "The launch lane with the clinical sign-off".
- [ ] 3.3 Change the content test in `Packages/Tests/ContentTests/SignOffTests.swift`: the release-lane test over the shipped bundle also checks the kind when MIDMORNING_LAUNCH is 1. Keep the five first-cut scenarios green. Proof: the scenarios "Release without sign-off", "Release with a sign-off for an older hash" and "A local test run without sign-off".
- [ ] 3.4 Add the option `--launch` to `scripts/archive`. With it, the script runs the content test with MIDMORNING_RELEASE=1 and MIDMORNING_LAUNCH=1, and names the launch lane in its refusal. Without it, the script runs the content test with MIDMORNING_RELEASE=1 only. Proof: the scenarios "The archive script and a Draft bundle", "The archive script for a tester build" and "The archive script with --launch", as tests that read the script text, as `testArchiveScriptStopsBeforeArchivingOnFailure` does now.
- [ ] 3.5 Describe the `kind` field in `Packages/Content/SIGNOFF.md` when that file describes the sign-off file; the id list stays generated. Run `./verify`. The content version does not rise.
