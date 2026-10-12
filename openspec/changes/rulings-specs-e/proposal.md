# Proposal

## Why

Ash gave fifteen rulings on 12 October 2026 (round 24). Fourteen change only the specs in `openspec/changes/v1-programme`. Ruling r24-11 changes built text: the rule strings of stages 3 and 4. So this change writes it into `openspec/specs/programme` and `openspec/specs/content`.

- r24-11 ("True text with counts, as r3-05"): from the day stage 2 opens, the stage 3 rule shows the count toward its gate. Before stage 3 opens, the stage 4 rule reads "Opens after Alternatives". From the day stage 3 opens, the stage 4 rule states its true fallback and shows the count toward it.

The old stage 4 rule, "Opens after your first urge outcome, or a week from now", is not true: its fallback is seven recorded days, not a week. The old stage 3 rule shows no count, but ruling r3-05 (decision 32) shows the count toward a gate.

## What Changes

- `programme` "Stage 3 opens after seven planned days or two weeks of regular eating": the rule ends with a full stop. From the record day on which stage 2 opened, "You have %lld." follows it, with the planned days that count toward stage 3. The scenario "The stage 3 rule string" changes. The scenario "The stage 3 rule with its count" is new.
- `programme` "Stage 4 opens after the first urge outcome or seven recorded days": before stage 3 opens, the rule is "Opens after Alternatives". From the record day on which stage 3 opened, the rule is "Opens after your first urge outcome, or after %lld recorded days." then "You have %lld.". The scenarios "The stage 4 rule before stage 3 opens" and "The stage 4 rule with its count" are new.
- `programme` "Reading ahead is never blocked": the list of rule strings, the counts of stages 3 and 4, and the full-stop rule change. The scenario "The rules of stages 3 and 4 before stage 2 opens" is new.
- `programme` "The stage screen": the counts of stages 3 and 4 join the count of stage 2 as the exceptions to "no count". The scenario "The stage 4 screen with its count" is new.
- `programme` "Accessibility of the Programme screen": the label of a row holds the rule and its count. The scenario "Label of a closed stage" changes.
- `content` "Every bundled string family has ids": the new ids "rule.stage3.count", "rule.stage4.beforeStage3" and "rule.stage4.count", the new text of "rule.stage3" and "rule.stage4", and the full-stop rule. The scenarios "The stage 3 rule string" and "The rule strings match programme" change. The scenarios "The stage 3 rule string with its count" and "The stage 4 rule strings" are new.
- `content` "Catalogue rules": the full-stop exception covers the rules of stages 2, 3 and 4. The scenario "A rule string that a count can follow" is new.

Each changed requirement has a copy in `openspec/changes/v1-programme/specs`, and that copy gets the same change. This change keeps every other line of the built text. For example, it keeps the "urge.buzz" line of "Every bundled string family has ids" and the example "Buzz at 20 minutes" of "Catalogue rules". Ruling r24-15 removes the buzz, so the v1-programme copies do not hold them. The build change of the urge toolkit (3.1) removes them from the built specs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `programme`
- `content`

## Impact

This is a correction of the first cut. `StageRuleText`, the bundle strings in `Packages/Content/Resources/strings.json` and their tests hold the rule strings now. The change raises the content version, because the text of "rule.stage3" and "rule.stage4" changes and three bundle strings are new. Ash sets the content version at the merge with `scripts/content-lock`. The new and the changed strings go to the clinical reviewer, as `openspec/changes/v1-programme/README.md` lists them, with a note that "urge outcome" is a word of the app and not a word that a person uses.

The first cut holds the tools of stages 1 and 2 only. So its rows of stages 3 and 4 show "Comes in a later version" (decision 102), and a person sees the new rule strings first in the build that adds the tool of the stage. The tests prove the strings with each stage's tool in the build, as the tests of the rule strings do now.

This change writes no code. A later agent builds tasks 3.1 to 3.5.
