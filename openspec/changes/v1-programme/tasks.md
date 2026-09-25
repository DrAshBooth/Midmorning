# Tasks

Each build task opens one build change from the named spec, and an agent builds it in a worktree. Ash archives the change after the merge. A build change takes its requirements from these specs and adds none. Its delta ADDs each requirement that `openspec/specs` does not hold yet, with only the scenarios that the build change builds. A later change that builds more of a requirement MODIFIES it, with the full text copied from `openspec/specs`. Ash archives v1-programme with `--skip-specs` at v1 complete.

Verify for every build task: `./verify` passes. The build change's tasks map each built scenario to a pure-function test with fixed dates, or to a device check. The agent lists each device check in the epic's device-check bead. Ash does each device check and adds its date and screenshot to the change README.

Each build task is one bead epic, and each requirement is one child bead. The exceptions are the constraint beads, the requirements split across epics, and the string-family requirement, which has one bead per family (decision 54). Task 1.0 is a human chore. Tasks 4.3 and 4.3b are gate epics. Task 4.4 is two chores and a measurement line in each milestone.

## 1. Foundations

- [ ] 1.0 Ash does the device checks of `record-entry-on-today` and archives it. This is a human chore.
- [ ] 1.1 Build change `content-pipeline` from `content` and `product-rules`: the string families, the content versions, the sign-off file, and the content test with its release lane.
- [ ] 1.2a Build change `model-foundation` from `data-and-privacy`: the sixteen neutral models, entry versions, per-row change moments, settings rows, the Reconciler and the frozen-names file. It also holds `ProgrammeConstants` in a `Constants` target.
- [ ] 1.2b Build change `record-full` from `record`: the Today stack, Where, Context, edit, delete, the day states, earlier days, collapse and gap bands. Its delta MODIFIES the skeleton's Today rules that the v1 record spec changes.
- [ ] 1.3 Build change `settings` from `settings`: the screen, the Reminders sub-screen, the groups, and the split between shared and device rows in `Local.store`. It builds "Day starts at" and the "Gap bands" switch. Each later change adds its own controls.
- [ ] 1.4 Build change `onboarding-and-safeguarding` from `onboarding` and `safeguarding`: the four screens, screening, the exclusion page, Get support with the four Beat numbers, the GP paragraph and its variants, the not-right-now page and the GP suggestion page.
- [ ] 1.5 Build change `app-lock` from `app-lock`: the cover with "Unlock" and "Delete everything", "Lock after" on the continuous clock, "Biometrics only", and the lock control on Today.

## 2. The core loop

- [ ] 2.1 Build change `programme-engine` from `programme`. It holds the pure stage engine, week counting, the Programme screen model, opening cards and card answer rows. It also holds the restart re-screen rule from `safeguarding`.
- [ ] 2.2 Build change `weigh-in` from `weigh-in` and the underweight check in `safeguarding`: Rule A to the not-right-now page, Rules B and C to the GP suggestion. It also holds the Weigh-in group of the settings screen and the weigh-in day reminder from `reminders`. It follows 2.4.
- [ ] 2.3 Build change `regular-eating-plan` from `regular-eating-plan`: the builder, templates, planned days, the window, the plan beside the record, the missed planned meal prompt in two forms, "Skipped" and "Add it", and the next-planned-meal line. The third form, "That was it", is 3.3 work.
- [ ] 2.4 Build change `reminders` from `reminders`. It holds the scheduler over the rolling horizon, the reminder types of the first cut, snooze state, the cap and quiet hours. It also holds the notification-action handlers and the action queue from `widgets-and-intents`.
- [ ] 2.5 Build change `widgets-and-intents` from `widgets-and-intents`: the widgets over the snapshot file, the Siri intent and the Control Centre control that open the app, the snapshot's explicit-wording flag, and the Time Sensitive setting with its entitlement.

## 3. The tools

- [ ] 3.1 Build change `urge-toolkit` from `urge-toolkit`: the button, the timer, the wave with its tail, "Close" and the open-urge line, the alternatives list, grounding and the urge outcome.
- [ ] 3.2 Build change `weekly-review` from `weekly-review` and the re-screening and deterioration rules in `safeguarding`: the summary with frozen counts, the two-step self-harm item, reflection and the pinned note. It also holds the weekly review reminder from `reminders`.
- [ ] 3.2b Build change `taking-stock` from `weekly-review`: taking stock, its questionnaire and the module recommendation. This is the second part of 3.2 and follows the first cut, with 3.4 and 3.5.
- [ ] 3.3 Build change `problem-solving` from `problem-solving`: pattern sentences, the suggestion card in the card slot, the worksheet, the "Worksheets" list and the worksheet review reminder.
- [ ] 3.4 Build change `food-rules` from `dieting-module` (displayed as "Food rules"): the lists, the ladder, reintroductions into the next 7 record days' plans, and the eating enough check with its question.
- [ ] 3.5 Build change `body-image-module` from `body-image-module`: the cards and Feeling fat notes.
- [ ] 3.6 Build change `staying-on-track` from `staying-on-track`: the maintenance plan, the finish, reduced cadence through `finishDate`, check-ins as a reminder type and a Today line, and the check-in's restart shortcut.

## 4. Data and release

Cut zero is a team-only build of tasks 1.0 to 1.5, 2.1, 2.3, 2.4 and 4.1. The team is the people who build the app. No release gate applies to a build that only the team installs.

The first TestFlight cut is tasks 1.0 to 1.5, 2.1 to 2.4, 3.2, 4.1, 4.2, 4.3 and 4.3c. It leaves out the scenarios that `deferred.md` lists. Tasks 2.5, 3.1, 3.2b, 3.3 to 3.6, 4.1b and 4.3b follow it.

- [ ] 4.1 Build change `local-delete-all` from `data-and-privacy`: Delete-all, "Delete from this device", the deleted screen, safe mode and the launch marker. It also holds Diagnostics, file protection, backup exclusion, the keyboard block, the system-log rule, retention and the privacy manifest.
- [ ] 4.1b Build change `sync` from `data-and-privacy`, on CKSyncEngine: the sync choice, the daily batch, the account binding, the restore flow, the `Erasure` zone, Delete-all across devices and the CloudKit container entitlement. Device checklist: two devices, zone deletion, a device with sync off, an account change, a restore.
- [ ] 4.2 Build change `export` from `export`: the tagged, flowing PDF at fixed sizes, the range, "Include context", the optional weigh-in page, the provenance line, the shared-copies line, empty Creator and Producer, and the share sheet.
- [ ] 4.3 Release gates for the first TestFlight cut. These are not build changes, and Ash does them. Verify: each gate has a dated line in the change README before any build reaches a person outside the team.
  - [ ] 4.3.1 External gates: the written MHRA classification opinion, the DPIA with the children's-code assessment and the co-design panel, the published privacy notice, the co-design panel's shame-response sessions, the beta exit criterion and the contact details check. They start at once, except three. The DPIA and the shame-response sessions wait for the panel. The published notice waits for its legal text.
  - [ ] 4.3.2 Human prerequisites: engage the clinical reviewer; get the stage 1 and 2 card bodies from the reviewer; recruit the co-design panel; write the legal text of the privacy notice; revisit the purging question before beta.
  - [ ] 4.3.3a The regulatory read of every public string, after every first-cut build change.
  - [ ] 4.3.3b The clinical sign-off of the thresholds and both self-harm questions, after 1.4, 2.1, 2.2 and 3.2.
  - [ ] 4.3.3c The clinical sign-off of each content version, after 4.3.3a and 4.3.3b, and again after 4.3c.
  - [ ] 4.3.3d The clinical reviewer's walk of the starred-entry and after-binge paths.
  - [ ] 4.3.4 Gates for each tester build: the cohort cadence line, the tester invitation text, Test Information and the accessibility declarations. A tester build that changes a safeguarding path needs a new thresholds and self-harm routing sign-off.
  - [ ] 4.3.5 The app's App Store Connect entry, the review notes file and the support page, then the first TestFlight upload after 4.3c.
- [ ] 4.3c Build change `gate-corrections`: the corrections that the 4.3.3 gates ask for, with a new content version.
- [ ] 4.3b App Store submission, not a build change: the demo video of every stage, the background modes and their review-notes lines, and the gates for the launch build. Ash does it after the second-cut build changes.
- [ ] 4.4 Measure `./verify` at cut zero, at the first TestFlight cut, after task 2.5 and after task 3.6. Verify: the warm wall clock stays under budget at each point, and each build change README states its cold-run time.
- [ ] 4.5 Every task that adds a target adds it to `Packages/Package.swift`; the `swift test` line in `./verify` does not change.
