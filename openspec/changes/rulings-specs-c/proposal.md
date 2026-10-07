# Proposal

## Why

Ash ruled on 11 decisions on 7 October 2026, on the Midmorning Decisions page. This change writes the spec text for ten of those rulings. The rulings are final. Each ruling bead holds a comment that quotes the ruling.

- r15-01 (mm-t42.28): safe mode opens a store that needs a schema migration at the schema version that the store holds.
- r15-02 (mm-t12b.25, mm-t12b.26): an edit uses the edit zone for the time control and for the offset on save.
- r15-03 (mm-t15.21): "Turn on" for "Face ID only" or "Touch ID only" makes a biometrics-only request before the hash save.
- r16-02 (mm-t12b.27): the cover window hides entries when the app is not active. Today, the new-entry screen and the edit screen lose `.privacySensitive()` and `.redacted(reason:)`.
- r16-03 (mm-t12b.28): each confirmation dialog with a "Cancel" becomes an alert, which shows both buttons.
- r17-01 (mm-t15.22): the new-entry screen before authentication shows no custom place from the store.
- r17-02 (mm-t11.47, mm-t11.48): the forbidden-list check skips three exact strings, and those strings get a bundle copy.
- r17-03 (mm-t11.50): the weigh-in guidance and the plan soft rules join the signed catalogue keys.
- r17-04 (mm-t41.27): a failed "Delete from this device" shows "Could not delete. Try again." on the cover.
- r17-05 (mm-t33.20): the pattern templates fill {n}, {m} and {hours} from strings with one count each.

## What Changes

- `data-and-privacy`: "Launch safety" opens the store read-only at the store's own schema version, with no migration plan. Export works, and no file changes. The next launch that is not in safe mode runs the migration. A test proves the rule with a second schema version that only the test holds.
- `app-lock`: "Face ID only or Touch ID only" makes the biometrics-only request at "Turn on". On a cancel or a failure, the setting stays off and the app saves no hash. "A new entry before authentication" shows only the four fixed chips and the places that the person adds on that screen. "Delete from this device after an enrolment change" and "The cover" show "Could not delete. Try again." after a failed deletion.
- `record`: "Today hides entries when the app is not active" names the cover as the way the app hides entries, with the app lock on or off. "Edit an entry" and "The app keeps the entry's UTC offset and creation moment" already state r15-02, so they do not change. "Delete an entry" already asks with "Delete" and "Cancel", so r16-03 changes no record text.
- `content`: "The forbidden list" skips three exact strings. "Every bundled string family has ids" gives those strings a bundle copy and names the three pattern count strings. "Content versions" adds the weigh-in guidance and plan soft-rule prefixes. "Catalogue rules" says that {n}, {m} and {hours} stand for counts.
- `settings`: the "Face ID only" scenario of "The About group" adds that Face ID succeeds at "Turn on" (r15-03).
- `problem-solving`: "Pattern sentence templates" fills {n}, {m} and {hours} from "pattern.count.group", "pattern.count.total" and "pattern.count.hours". PATTERN_MIN_STARRED is 2 or more, so no sentence reads "1 of your 1". This change edits `openspec/changes/v1-programme/specs/problem-solving/spec.md` directly, because problem-solving lives only there.

Each changed requirement that has a copy in `openspec/changes/v1-programme/specs` gets the same change there. A v1 copy keeps its own extra scenarios.

## Capabilities

### Modified Capabilities

- `data-and-privacy`
- `app-lock`
- `record`
- `content`
- `settings`
- `problem-solving` (in `v1-programme` only)

## Impact

This change edits spec text only. The code agents build the code for each ruling and close its bead. r17-05 is spec only now, because problem-solving is second-cut work (epic mm-t33). This change closes mm-t33.20.
