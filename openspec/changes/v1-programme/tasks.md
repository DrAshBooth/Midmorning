# Tasks

Each task opens one build change from the named spec, builds it, and archives it. A build change takes its requirements from these specs and adds none. Verify for every task: `./verify` passes. The build change's tasks map every scenario to a pure-function test with fixed dates, or to a named device check. A device check has a date and a screenshot in the change README. Each task is one bead epic; each requirement is one child bead; each deferred.md row has a remainder bead under its owning change.

## 1. Foundations

- [ ] 1.1 Build change `content-pipeline` from `content` and `product-rules`: the string families, versions, the sign-off file, the content test with its release lane.
- [ ] 1.2a Build change `model-foundation` from `data-and-privacy` (the model rules): the sixteen neutral models with kinds, entry versions and the on-read winner, per-row change moments and deleted flags, keys not relationships, settings rows, the Reconciler as a pure function, the frozen-names file and its content test.
- [ ] 1.2b Build change `record-full` from `record`: the Today stack, Where, Context, edit, delete, "didn't record", "Pause for today", "Fasting today", earlier days, collapse, gap bands and their switch, "Day starts at".
- [ ] 1.3 Build change `settings` from `settings`: the screen, the Reminders sub-screen, its groups, the shared and device split in `Local.store`.
- [ ] 1.4 Build change `onboarding-and-safeguarding` from `onboarding` and `safeguarding`: the four screens with the sync choice, screening, the exclusion page, Get support with the four Beat numbers, the GP paragraph and variants, the not-right-now page, the GP suggestion page.
- [ ] 1.5 Build change `app-lock` from `app-lock`: the cover with "Unlock" and "Delete everything", "Lock after" on the continuous clock, "Biometrics only", the lock control on Today.

## 2. The core loop

- [ ] 2.1 Build change `programme-engine` from `programme`: `ProgrammeConstants` as a value, the stage state as a pure function over value facts with stored openings, week counting from stage 2, the Programme screen model, opening cards in the card slot, card answer rows, the restart re-screen rule from `safeguarding`.
- [ ] 2.2 Build change `weigh-in` from `weigh-in` and the underweight check in `safeguarding`: Rule A to the not-right-now page, Rules B and C to the GP suggestion.
- [ ] 2.3 Build change `regular-eating-plan` from `regular-eating-plan`: the builder, templates, planned days, the window with overlap and clipping, the plan beside the record, the missed planned meal prompt with its three forms, the next-planned-meal line.
- [ ] 2.4 Build change `reminders` from `reminders`: the scheduler over the rolling horizon, every type including "Worksheet review" and "Check-in", actions from userInfo, the notification-action handlers and the action queue from `widgets-and-intents`, snooze state, the cap with planned meals separate, quiet hours with wrap-around, the Time Sensitive entitlement.
- [ ] 2.5 Build change `widgets-and-intents` from `widgets-and-intents`: the widgets over the snapshot file, the Siri intent and the Control Centre control that open the app, the snapshot's explicit-wording flag.

## 3. The tools

- [ ] 3.1 Build change `urge-toolkit` from `urge-toolkit`: the button, the timer, the wave with its tail, "Close" and the open-urge line, the alternatives list, grounding, the urge outcome.
- [ ] 3.2 Build change `weekly-review` from `weekly-review` and the re-screening and deterioration rules in `safeguarding`: the summary with frozen counts, the two-step self-harm item, reflection, the pinned note.
- [ ] 3.2b Build change `taking-stock` from `weekly-review`: taking stock, its questionnaire and the module recommendation. This is the second part of 3.2 and follows the first cut, with 3.4 and 3.5.
- [ ] 3.3 Build change `problem-solving` from `problem-solving`: pattern sentences, the suggestion card in the card slot, the worksheet, the "Worksheets" list, the worksheet review reminder.
- [ ] 3.4 Build change `food-rules` from `dieting-module` (displayed as "Food rules"): the lists, the ladder, reintroductions into the next 7 record days' plans, the eating enough check with its question.
- [ ] 3.5 Build change `body-image-module` from `body-image-module`: the cards and Feeling fat notes.
- [ ] 3.6 Build change `staying-on-track` from `staying-on-track`: the maintenance plan, the finish, reduced cadence through `finishDate`, check-ins as a reminder type and a Today line, the check-in's restart shortcut and its re-screen scenario.

## 4. Data and release

Cut zero is a team-only build of tasks 1.0 to 1.5, 2.1, 2.3, 2.4 and 4.1; no release gate applies to a build that only the team installs. The first TestFlight cut is tasks 1.1 to 1.5, 2.1 to 2.4, 3.2, 4.1, 4.2 and 4.3. It leaves out the requirements that `deferred.md` lists and labels each one as deferred. Tasks 2.5, 3.1, 3.2b, 3.3 to 3.6 and 4.1b follow it.

- [ ] 4.1 Build change `local-delete-all` from `data-and-privacy`: Delete-all of the whole directory, "Delete from this device", the deleted screen, the launch marker and safe mode, the MetricKit count, Diagnostics, file protection, backup exclusion, the keyboard block, the log rule, retention, the privacy manifest. This is in the first cut.
- [ ] 4.1b Build change `sync` from `data-and-privacy`, on CKSyncEngine: the sync choice, the daily batch, the account binding, the restore flow, the `Erasure` zone with its ask-before-delete rule, Delete-all across devices, the CloudKit container entitlement. Not in the first cut. Device checklist: two devices, zone deletion, a device with sync off, an account change, a restore.
- [ ] 4.2 Build change `export` from `export`: the tagged, flowing PDF at fixed sizes, the range, "Include context", the optional weigh-in page, the provenance line, the shared-copies line, empty Creator and Producer, the share sheet.
- [ ] 4.3 Release gates, not build changes: the written MHRA classification opinion, the DPIA with the children's-code assessment and the co-design panel, the privacy notice with the contents `data-and-privacy` names, the regulatory read of every public string, the clinical sign-off of every content version and of the strings the clinical review listed, the co-design panel's shame-response sessions, the beta exit criterion, the contact details check with dates, the clinical sign-off of the screening thresholds and both self-harm questions, the cohort cadence line per build, the tester invitation text, Test Information and the accessibility declarations. One build task sits with them: the App Store Connect record, signing, the Info.plist keys, the review notes file, the support page and the first TestFlight upload. The external gates start at once; the string gates wait for every first-cut build change. Verify: each gate has a dated line in the change README before any build reaches a person outside the team.
- [ ] 4.4 Measure `./verify` after task 2.5 and again after task 3.6. Verify: the warm wall clock stays under budget at both points, and each build change README states its cold-run time.
- [ ] 4.5 Every task that adds a target adds it to `Packages/Package.swift`; the `swift test` line in `./verify` does not change.
