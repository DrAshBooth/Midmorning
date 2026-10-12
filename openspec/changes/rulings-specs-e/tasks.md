# Tasks

Each spec task changes one requirement and its copy in `openspec/changes/v1-programme/specs`. The proof for each spec task is `openspec validate --type change rulings-specs-e --strict` and `openspec validate --all --strict`. Ash ruled r24-11 on 12 October 2026.

## 1. programme

- [x] 1.1 Modify programme "Stage 3 opens after seven planned days or two weeks of regular eating" for r24-11: the full stop, and "You have %lld." from the record day on which stage 2 opened. Change the scenario "The stage 3 rule string" and add "The stage 3 rule with its count". Do the same in the v1-programme copy.
- [x] 1.2 Modify programme "Stage 4 opens after the first urge outcome or seven recorded days" for r24-11: "Opens after Alternatives" before stage 3 opens, then the true fallback with "You have %lld.". Add the scenarios "The stage 4 rule before stage 3 opens" and "The stage 4 rule with its count". Do the same in the v1-programme copy.
- [x] 1.3 Modify programme "Reading ahead is never blocked" for r24-11: the list of rule strings, the three counts and the full-stop rule. Add the scenario "The rules of stages 3 and 4 before stage 2 opens". Do the same in the v1-programme copy.
- [x] 1.4 Modify programme "The stage screen" for r24-11: the counts of stages 3 and 4 are exceptions to "no count". Add the scenario "The stage 4 screen with its count". Do the same in the v1-programme copy.
- [x] 1.5 Modify programme "Accessibility of the Programme screen" for r24-11: the label holds the rule and its count. Change the scenario "Label of a closed stage". Do the same in the v1-programme copy.

## 2. content

- [x] 2.1 Modify content "Every bundled string family has ids" for r24-11: the ids "rule.stage3.count", "rule.stage4.beforeStage3" and "rule.stage4.count", the text of "rule.stage3" and "rule.stage4", and the full-stop rule. Change the scenarios "The stage 3 rule string" and "The rule strings match programme". Add "The stage 3 rule string with its count" and "The stage 4 rule strings". Do the same in the v1-programme copy.
- [x] 2.2 Modify content "Catalogue rules" for r24-11: the full-stop exception covers the rules of stages 2, 3 and 4. Add the scenario "A rule string that a count can follow". Do the same in the v1-programme copy.
- [x] 2.3 Add the new and the changed rule strings, and the note on "urge outcome", to the list for the clinical reviewer in `openspec/changes/v1-programme/README.md`.

## 3. Build

A later agent builds these tasks. This change writes no code.

- [ ] 3.1 Change `StageRuleText`. The stage 3 rule ends with a full stop and takes "You have %lld." from the record day on which stage 2 opened. The stage 4 rule is "Opens after Alternatives" before stage 3 opens, and "Opens after your first urge outcome, or after %lld recorded days." then "You have %lld." from the record day on which stage 3 opened. Proof: tests with fixed dates for each scenario of tasks 1.1 to 1.5.
- [ ] 3.2 Give `ProgrammeScreenBuilder` and `StageScreenBuilder` the planned days that count toward stage 3 and the recorded days that count toward the stage 4 fallback, from the stage engine. Proof: the scenarios "The stage 3 rule with its count", "The stage 4 rule with its count" and "The stage 4 screen with its count".
- [ ] 3.3 Change `Packages/Content/Resources/strings.json`: the text of "rule.stage3" and "rule.stage4", and the new strings "rule.stage3.count", "rule.stage4.beforeStage3" and "rule.stage4.count". Each string with a count carries plural forms. Proof: the test that compares each Swift constant with its bundle copy (r13-02), and the scenarios of task 2.1.
- [ ] 3.4 Change the full-stop check of the rule strings, for example in `OpeningAndRuleStringsTests`, to the rule of "Catalogue rules". Proof: the scenario "A rule string that a count can follow".
- [ ] 3.5 Raise the content version. Ash sets it at the merge with `scripts/content-lock`. Run `./verify`.
