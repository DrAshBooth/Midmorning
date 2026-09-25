# Proposal

## Why

`record-entry-on-today` builds the whole stack for one entry on Today. The PRD describes a 12-week programme. The record and the regular eating plan are its core, and every other tool attaches to them. This change specifies the whole of V1 as one set of capability specs. Each later build change takes its requirements from here and adds none of its own.

## What Changes

- The record gains: Where chips, the Context field, edit and delete, "didn't record" days, day navigation, collapse to a count, "Pause for today", the gap band from stage 2.
- Onboarding with screening, commitment and permissions. No account.
- Safeguarding: exclusion at onboarding, re-screening at every weekly review, the underweight check, the deterioration rule, the not-right-now page, Get support on every screen.
- The programme's stages, opening rules and pacing, with every threshold a named constant.
- Bundled, versioned, clinically signed-off content cards.
- The regular eating plan with its builder, templates, the plan beside the record and the missed planned meal prompt.
- Reminders for every planned meal and for the day's open and close, discreet by default, capped at eight a day.
- The weekly weigh-in with a rolling average and nothing else.
- The urge toolkit, problem solving, the weekly review and taking stock.
- The Food rules module in full, the body image module as content plus Feeling fat notes, staying on track.
- Data and privacy: iCloud private-database sync that the person chooses, which the app sends once a day, and Delete-all across devices. Also no analytics of our own, the app lock, widgets and intents, and a tagged PDF export.
- One settings screen, one tap from Today.
- Product rules that every screen obeys, in one spec that overrides the others on conflict.

Not in V1: weight loss or nutrition of any kind, diagnosis, a human guide, an AI companion, social features. Also not in V1: Android, web, a Watch app, HealthKit, NHS procurement, medical device certification, a paywall, human support.

## Capabilities

### New Capabilities
- `product-rules`: the never list, tone, vocabulary, appearance, name rules, accessibility, offline, no AI. Overrides the others on conflict.
- `settings`: the settings screen, its groups, every switch and its default, what syncs.
- `onboarding`: four screens under three minutes; commitment and permissions; no account.
- `safeguarding`: screening and exclusion, re-screening, underweight and deterioration checks, the not-right-now page, Get support.
- `programme`: stages, opening rules, constants, pacing, week counting, home screen.
- `content`: cards per stage, tone, versions, sign-off, externalised strings.
- `regular-eating-plan`: builder, templates, the plan beside the record, the missed planned meal prompt, the next-planned-meal line.
- `reminders`: every reminder type, actions, snooze, cap, quiet hours, discreet wording, switches.
- `weigh-in`: weekly, chosen day only, a rolling average and no number that invites fixation.
- `urge-toolkit`: the Urge button, timer, alternatives list, grounding, urge outcome.
- `problem-solving`: pattern sentences and the six-step worksheet.
- `weekly-review`: the weekly summary, reflection, the pinned note, re-screening, taking stock.
- `dieting-module`: food rules, avoided foods, the ladder, reintroductions.
- `body-image-module`: cards and Feeling fat notes.
- `staying-on-track`: maintenance plan, reduced cadence, check-ins, restart.
- `data-and-privacy`: sync, Delete-all, analytics events, what never leaves the device.
- `app-lock`: Face ID lock, when it asks, what it covers.
- `widgets-and-intents`: Lock Screen and Home Screen widgets, App Intents, Control Centre.
- `export`: a PDF of any date range like the paper record.

### Modified Capabilities
- `record`: this change adds requirements, including the Today stack. Two sentences in `record-entry-on-today` now scope the empty-Today rule and the word ban to that change's screens. The team made that edit in place because the change is not archived.

## Impact

- Every capability becomes its own later build change, in the order tasks.md gives. Each build change takes its requirements from these specs and adds none.
- `Packages/Record` becomes the model for every entity. New packages hold the plan, the programme engine and the content. The app target keeps only views and platform code.
- No network in the core loop. iCloud sync and analytics are the only network paths and both are the person's choice.

## Decisions Ash made on 24 September 2026

- V1 asks nothing about vomiting or laxatives. There is no Compensated field, no compensation taper and no purging exclusion. Consequence: that criterion does not screen out a person who purges often. The weight trend, the self-harm item and Get support remain the safeguards.
- The app sends opt-in analytics to the CloudKit public database of our container: counts and events only, never entry text or weight values. No third-party SDK. No server we run.
- The stage 2 gate is five recorded days, one named constant beside the other thresholds.
- No paywall and no human support in V1. Get support lists external services only.

## Decisions Ash made on 25 September 2026, after the six-lens review

1. Purging stays unasked. Screen 1 warns in one sentence, and a stage-2 card explains why compensating for a binge fails. The team revisits this before beta.
2. The self-harm item has two steps and an "I'd rather not say" answer. Reminders never stop because of it.
3. Sync is off until the person chooses it at onboarding, with neither answer preselected.
4. Analytics is one weekly summary event with buckets only and no identifier. The team reads it through the CloudKit Dashboard and deletes it after 90 days.
5. Only Rule A stops the programme. Rules B and C and the deterioration rule suggest a GP and keep the plan on. A written MHRA opinion is a release gate.
6. The EDE-QS is out of V1. V1 does not collect the PRD's outcome row.
7. Entries are append-only versions, and the store applies the conflict rule on read. Delete-all writes an erasure marker that every device honours. There are two store configurations.
8. The programme engine is pure with stored opening moments as input. Deletions never close a stage.
9. Weeks 6 and 10 count from the day stage 2 opened. Stage 4 opens after the first urge outcome or seven recorded days with stage 3 open.
10. No opening card on a Today load after a starred entry or "I binged". The urge screen has "Close".
11. Planned meal reminders never drop; at most two other reminders a day; the weekly review reminder never drops.
12. The store keeps `NSFileProtectionComplete`; two side files carry the after-first-unlock class; the container opens lazily.

## Decisions Ash made on 25 September 2026, after the second review round

13. The app writes nothing to the CloudKit public database. The team reads Apple's App Analytics only.
14. "Biometrics only", a "Lock after" choice with "At once" as default, and a lock control on Today.
15. No support from the cover. Get support appears after authentication.
16. The store fixes an entry's record day at save from its own offset, and the day never changes.
17. "Day starts at" is a setting, default 04:00. Slot labels are renameable.
18. "Fasting today" beside "Pause for today". A fasting day counts no gap.
19. The weigh-in is optional at onboarding. No upper weight bound. A restrictive-history line on screen 1.
20. The dieting module has the name "Food rules". "Feeling fat notes" stays.
21. The store lives in the app's own container. The App Group holds only the widget snapshot and the action queue.
22. Sync sends one batch per record day at a random moment.
23. A discreet reminder offers "Add" and "Remind me in 15 minutes". "Skipped" needs explicit wording and an unlocked device.
24. The export PDF is tagged. No password.
25. App Store category Lifestyle, overruling the PRD. No App Shortcuts provider. A "Keep it private" sheet.
26. A TestFlight build every 45 days at most, and a counts-only Diagnostics page. No managed-device handling.
27. One umbrella package with four targets and one `swift test` line. A warm-run budget.

## Decisions Ash made on 25 September 2026, after the third review round

28. The model foundation moves into the record build change. `deferred.md` lists the first TestFlight cut. The team never deletes a requirement to fit the cut.
29. The first cut leaves sync out, and the sync change builds on CKSyncEngine when the team builds it.
30. An entry point shows the empty new-entry screen before authentication; Save authenticates.
31. "Skipped" is on every reminder and needs the device unlocked; the order is snooze, Add, Skipped.
32. Rule strings show the count toward a gate.
33. "Done" always closes a review; the review asks an unanswered self-harm item again next week.
34. A planned day is a template day with an entry, or a day the person set. The morning plan reminder, two nudge cards, a stage 3 time fallback and a seven-day stop rule make stage 2 start and stop its prompts.
35. "Start week 1 again" is on the Programme screen at all times.
36. Reviews open with days recorded; the list shows starred per week; no skipped count; the review states paused days.
37. One missed-meal prompt a day, on the latest.
38. "Add an entry" is full width under the heading; Fasting, Didn't record and Earlier days are in the heading's menu.
39. Close-the-day only when something is missing, two stage-1 cards in the flow, a Focus card, and a permission line that re-requests.
40. A demo video and fixed review notes for App Review; a published privacy notice and support page; Lifestyle stays with a justification.
41. The enrolment-change cover offers "Delete from this device"; still no support on the cover.

The data-model review's findings need no decision; the team applies them. Every row carries its own change moment and a deleted flag, and settings are one row per key. The app hard-deletes nothing, and every reference is a key that the reader resolves on read.

## Decisions Ash made on 25 September 2026, after the bead review

42. One worktree per build change; the change's requirement beads are its checklist.
43. The epic chain loosens: content, the model foundation, settings, onboarding, app lock, the engine, weigh-in and the plan run in parallel where the specs permit.
44. The notification-action handlers and the action queue are 2.4 work.
45. Each deferred.md row has a remainder bead under its owning change.
46. 1.3 builds the settings shell; each feature change adds its own controls.
47. The external release gates start at once; the string gates wait for every first-cut build change; four gates and one submission task are added.
48. Re-screening at a restart is 2.1 work; only the check-in shortcut waits for 3.6.
49. A delete is a kept version with the deleted flag; every reader hides it.
50. Cut zero is a team-only build of the core loop before the first TestFlight cut.
51. Beads point at spec headings, not line numbers; v1-programme is archived at v1 complete.
52. The worktree protocol is a short section in CLAUDE.md.
53. Beads sync with `bd dolt push` after each batch.
54. 1.2 splits into 1.2a model-foundation and 1.2b record-full; the string-family requirement splits by owning change.
55. The product-rules beads are constraints that close at the first cut.
56. Second-cut work is not blocked; the dispatch command filters by the first-cut label.
57. Foundation beads are P0, accessibility and never-shows beads P2; every bead carries a size label.

## Assumptions the specs make where the PRD is silent

Each spec lists its own under its Purpose or in the writer's report. The design lists the ones that shape the data model.
