# Proposal

## Why

Ash ruled on 26 September 2026 on the Midmorning Decisions page. This change writes the spec text for ten of those rulings. The rulings are final. Each ruling bead holds a comment that quotes the ruling.

- r13-01 (mm-t11.40): the bundle hash covers a named subset of catalogue keys. The subset is record, safeguarding and reminder text.
- r13-02 (mm-t11.41): signed-off text keeps its Swift constant and its bundle copy. A test compares the two copies.
- r13-12 (mm-t11.43): a string holds at most one count.
- r13-09 (mm-t14.43): the deterioration reason holds no number.
- r13-11 (mm-t14.44): the ft in and st lb limit messages round inward.
- r14-02 (mm-t21.36): after a restart, weeks of regular eating count from the later of the new start day and the day stage 2 opened.
- r14-03 (mm-t21.37): each StageOpened row holds the record day key of its opening.
- r13-17 (mm-t32.25): the app saves the answers so far in every week, week 1 included.
- r13-08 (mm-t23.24): a VoiceOver label can start with the visible text and add words after it.
- r13-15 (mm-t14.45): validation text uses a neutral text colour, never red.

## What Changes

- `content`: "Content versions" names the signed catalogue keys and `Packages/Content/Resources/signed-catalogue-keys.json`. "Strings live in catalogues" drops the claim that the hash covers every catalogue call. "Every bundled string family has ids" adds the Swift-constant test, the one-count rule strings and the fixed rule strings. "Catalogue rules" adds the one-count rule, the sign-off list source and the VoiceOver label rule.
- `onboarding`: "Screen 2: the screening questions" and "The one-time BMI" give the neutral colour and the announcement. "The one-time BMI" gives the ft in and st lb messages and how the app rounds them.
- `programme`: the stage 2 and stage 3 rule strings come from one-count strings. The restart sentence and the StageOpened record day key change the engine.
- `safeguarding`: the deterioration reason reads "Your starred entries have gone up each week lately."
- `weekly-review`: the week-1 rule allows the save before "Done". The Reviews row, the starred part and the urge part come from one-count strings. The starred line of "Taking stock", which is in `v1-programme` only, also comes from one-count strings.
- `regular-eating-plan`: the "Rename" control keeps its visible text and its longer VoiceOver label.
- `product-rules`: the VoiceOver label rule and the validation text rule change. This change edits `openspec/changes/v1-programme/specs/product-rules/spec.md` directly, because product-rules lives only there.

Each changed requirement also has a copy in `openspec/changes/v1-programme/specs`. This change applies the same edits to each copy.

## Capabilities

### Modified Capabilities

- `content`
- `onboarding`
- `programme`
- `safeguarding`
- `weekly-review`
- `regular-eating-plan`
- `product-rules` (in `v1-programme` only)

## Impact

This change edits spec text only. The code agents build the code for each ruling and close its bead. The one exception is r13-08, which is spec only. This change closes mm-t23.24.
