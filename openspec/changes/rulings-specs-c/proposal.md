# Proposal

## Why

Ash ruled on 11 decisions on 7 October 2026, on the Midmorning Decisions page. This change writes the spec text for ten of those rulings. The rulings are final. Each ruling bead holds a comment that quotes the ruling.

- r15-01 (mm-t42.28): safe mode opens a store that needs a schema migration at the schema version that the store holds.
- r15-02 (mm-t12b.25, mm-t12b.26): an edit uses the edit zone for the time control and for the offset on save.
- r15-03 (mm-t15.21): "Turn on" for "Face ID only" or "Touch ID only" makes a biometrics-only request before the hash save.
- r16-02 (mm-t12b.27): the cover window hides entries when the app is not active. Today, the new-entry screen and the edit screen lose `.privacySensitive()` and `.redacted(reason:)`.
- r16-03 (mm-t12b.28): each confirmation dialog with a "Cancel" becomes an alert, which shows both buttons.
- r17-01 (mm-t15.22): the new-entry screen before authentication shows no custom place from the store.
- r17-02 (mm-t11.47, mm-t11.48): the forbidden-list check skips four exact sentences. The three strings that hold them get a bundle copy. The four are the two sentences that `safeguarding` names, line 3 of onboarding screen 1 and the screening question. Line 3 is one whole sentence. The r17-02 decision on the Decisions page names it as one of the three strings.
- r17-03 (mm-t11.50): the weigh-in guidance and the plan soft rules join the signed catalogue keys.
- r17-04 (mm-t41.27): a failed "Delete from this device" shows "Could not delete. Try again." on the cover.
- r17-05 (mm-t33.20): the pattern templates fill {n}, {m} and {hours} from strings with one count each.

## What Changes

- `data-and-privacy`: "Launch safety" opens the store read-only at the store's own schema version, with no migration plan. Export works, and no file changes. The next launch that is not in safe mode runs the migration. A test proves the rule with a second schema version that only the test holds. Decision mm-ue6 is an open gate on this text, as "Open gate" states.
- `app-lock`: "Face ID only or Touch ID only" makes the biometrics-only request at "Turn on". On a cancel or a failure, the setting stays off and the app saves no hash. "A new entry before authentication" shows only the four fixed chips and the places that the person adds on that screen. "Delete from this device after an enrolment change" and "The cover" show "Could not delete. Try again." after a failed deletion. "The cover" also shows over the new-entry screen of an entry point while the app is not active (r16-02). The request at "Turn on" makes no comparison with the kept hash.
- `record`: "Today hides entries when the app is not active" names the cover as the way the app hides entries, with the app lock on or off. "Edit an entry" adds that the save uses the edit zone that the time control showed (r15-02). This rule also applies when the device's time zone changes while the edit screen is open. "Delete an entry" already asks with "Delete" and "Cancel", so r16-03 changes no record text.
- `content`: "The forbidden list" skips four exact sentences, also inside a longer string. "Every bundled string family has ids" gives the three strings that hold them a bundle copy and names the three pattern count strings. "Content versions" adds the weigh-in guidance and plan soft-rule prefixes. "Catalogue rules" says that {n}, {m} and {hours} stand for counts.
- `settings`: the "Face ID only" scenario of "The About group" adds that Face ID succeeds at "Turn on" (r15-03).
- `problem-solving`: "Pattern sentence templates" fills {n}, {m} and {hours} from "pattern.count.group", "pattern.count.total" and "pattern.count.hours". PATTERN_MIN_GROUP = 3 already keeps {n} at 3 or more, so no sentence reads "1 of your 1". This change edits `openspec/changes/v1-programme/specs/problem-solving/spec.md` directly, because problem-solving lives only there.

Each changed requirement that has a copy in `openspec/changes/v1-programme/specs` gets the same change there. A v1 copy keeps its own extra scenarios.

## Capabilities

### Modified Capabilities

- `data-and-privacy`
- `app-lock`
- `record`
- `content`
- `settings`
- `problem-solving` (in `v1-programme` only)

## Open gate

Decision mm-ue6 (label human, open) is a gate on data-and-privacy "Launch safety". The text names one schema version for the store. But SwiftData migrates `Record.store` and `Local.store` one at a time. When a migration stops between the two files, they hold different versions. Commit 93e2c7e on branch rulings2-safemode-schema opens each file at its own version (mm-ue6 option 1). With the text of this change, that state shows the store-failure page with no Export (mm-ue6 option 2). Ash has not ruled on mm-ue6. Do not archive this change before that ruling. Then do task 1.2.

## Impact

This change edits spec text only. The code agents build the code for each ruling and close its bead. r17-05 is spec only now, because problem-solving is second-cut work (epic mm-t33). This change closes mm-t33.20.
