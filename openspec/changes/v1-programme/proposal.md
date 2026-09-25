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
- `data-and-privacy`: sync, Delete-all, what never leaves the device, and the rule that the app holds no analytics of its own.
- `app-lock`: Face ID lock, when it asks, what it covers.
- `widgets-and-intents`: Lock Screen and Home Screen widgets, App Intents, Control Centre.
- `export`: a PDF of any date range like the paper record.

### Modified Capabilities
- `record`: this change adds requirements, including the Today stack. Two sentences in `record-entry-on-today` now scope the empty-Today rule and the word ban to that change's screens. The team made that edit in place because the change is not archived. Ash ruled on 25 September 2026 (decision 64) that the v1 record rules win. The record-full change (1.2b) MODIFIES "Today's appearance", "Today shows the record day's entries in time order" and "Accessibility of the record" after mm-t10 archives the skeleton.

## Impact

- tasks.md maps the capabilities to build changes. Each build change takes its requirements from these specs and adds none.
- `Packages/Record` becomes the model for every entity. New packages hold the plan, the programme engine and the content. The app target keeps only views and platform code.
- No network in the core loop. iCloud sync is the only network path, and it is the person's choice. The app holds no analytics of its own.

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
27. One umbrella package with one `swift test` line (five targets since decision 61). A warm-run budget.

## Decisions Ash made on 25 September 2026, after the third review round

28. The model foundation moves into the record build change. `deferred.md` lists the first TestFlight cut. The team never deletes a requirement to fit the cut. (Decision 54 refines this.)
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

42. Ash dispatches one worktree per build change, and the change's requirement beads are its checklist.
43. The epic chain is shorter: content, the model foundation, settings, onboarding, app lock, the engine, weigh-in and the plan run in parallel where the specs permit.
44. The reminders change (2.4) builds the notification-action handlers and the action queue.
45. A named bead builds each deferred scenario, and the `deferred:` marker gives its id.
46. The settings change (1.3) builds the settings shell, and each feature change adds its own controls. (Decision 65: 1.3 also builds "Day starts at" and the "Gap bands" switch.)
47. The external release gates start at once. The string gates wait for every first-cut build change. Four gates and one submission task join them.
48. The programme change (2.1) builds re-screening at a restart. Only the check-in shortcut waits for 3.6.
49. A delete writes a kept version with the deleted flag, and every reader hides it.
50. Cut zero is a team-only build of the core loop before the first TestFlight cut.
51. Beads point at spec headings, not line numbers. Ash archives v1-programme at v1 complete.
52. CLAUDE.md holds the worktree protocol in a short section.
53. Ash pushes the beads with `bd dolt push` after each batch.
54. The build changes `model-foundation` (1.2a) and `record-full` (1.2b) are separate. The string-family requirement splits into one bead per family.
55. The product-rules beads are constraints, and Ash closes them at the first cut.
56. No dependency blocks second-cut work. The dispatch command filters by the first-cut label. (Decision 69 adds eight edges.)
57. Foundation beads are P0, and accessibility and never-shows beads are P2. Every requirement, remainder and constraint bead carries a size label; the two gate index beads have none.

## Decisions Ash made on 25 September 2026, after the second bead review

58. Ash does the skeleton device checks (mm-t10) first, and 1.2a waits for them.
59. The weigh-in change (2.2) owns the weigh-in day reminder and follows 2.4, so cut zero leaves weigh-in out.
60. A scenario that needs a later change runs over fixture facts in its own change. A wiring bead in the later change runs it end to end. A bead-level edge replaces the fixture where the edge costs nothing.
61. `ProgrammeConstants` lives in a small `Constants` target that 1.2a builds.
62. In the first cut, the app writes the StageOpened rows of stages 3 to 7 and shows no new card. Each stage's opening card shows once, when its tool ships.
63. The Focus card waits for 2.5.
64. The v1 record rules win over the skeleton's Today rules. The record-full change (1.2b) MODIFIES the skeleton requirements it changes.
65. The settings change (1.3) builds "Day starts at" and the "Gap bands" switch.
66. A build change ADDs a requirement with only its built scenarios, and a later change MODIFIES it with the full text. Ash archives v1-programme with `--skip-specs`.
67. Each worktree starts its branch from local HEAD. Ash pushes main and the beads after each merge.
68. An agent closes a child when its tests pass. Each epic has a device-check bead that Ash closes after the device checks.
69. Eight edges hold second-cut epics behind the epics their scenarios need.
70. An answer that excludes at a restart opens the not-right-now page with its reason. The weight reason pauses reminders, as Rule A does.
71. The 84-record-day re-screen window counts from the last screening.
72. In taking stock, the chosen module opens after "Done", so the self-harm item and "I'm getting worse" always come first.
73. The clinical sign-off of the thresholds follows the builds it certifies. A gate-corrections change (4.3c) applies what the gates ask for before the first upload.

## Decisions Ash made on 25 September 2026, on the questions round 5 opened

74. After a self-harm "Yes" then "Yes" in a taking stock review, "Done" completes taking stock and opens no module. The chosen module stays one tap away on the Programme screen.
75. "Done" completes taking stock only with a module chosen. Without one, the next review asks taking stock again.
76. A restart re-screen counts even when the person then taps "Cancel"; "Cancel" only keeps the old start day.
77. The edit screen's time control covers only the entry's own record day.
78. On the edit screen, "Delete entry" is the last control that VoiceOver reaches, after Cancel.
79. A tap on "I'm getting worse" shows the GP suggestion page each time, also after the deterioration rule showed it.
80. The weekly review, the check-in and the restart re-screen show Get support, because each asks the self-harm item.

## Decisions Ash made on 25 September 2026, on the questions round 6 opened

81. When a taking stock review reopens after the system or the person closed the app, its "Done" with a chosen module completes the session and opens no module.
82. Each repeat of taking stock opens the same session with the answers saved so far, from any taking-stock row.
83. A Feeling fat note follows the entry rule: an edit keeps the time inside the note's own record day.

## Decisions Ash made on 25 September 2026, after the final bead review

84. The co-design panel sees the record in person two times: after 1.2b merges, on Ash's device, and on cut zero.
85. Before iOS asks for permission, Today's line reads "Allow notifications to get reminders." After a refusal it reads "Notifications are off in iOS Settings." This refines decision 39.
86. The new-entry screen's order is What, Where, "felt like a binge", Context, Time, so the Context label that the star changes sits under the star.
87. A "Save" control sits in the keyboard's accessory bar and in the navigation bar. What stays multi-line.
88. The time control is two record-day segments, named as Today's headings name the days, and the system hour-and-minute wheel. The edit screen shows one segment.
89. What, Context and "Add a place" keep autocorrection and sentence capitalisation, and turn off inline predictions. A device check confirms that the keyboard does not offer a What back.
90. After a starred entry or an "I binged" outcome, Today holds the pinned note until the next record day, as it holds the cards.
91. Today uses a notes-style shell: the lock glyph and "Get support" in the bar, "Programme", "Reviews" and "Settings" in a bottom toolbar, and one pinned "Add an entry". This refines decision 38.
92. A product-rules "Appearance" requirement, a shared Appearance.swift and one sober accent colour give every worktree one look. The panel confirms the accent colour.
93. A tap on a stage row opens a stage screen with its cards and, for an open stage, a "Tools" group. The weigh-in route is Today, Programme, Getting started, Weigh-in.
94. "Get support" is the trailing bar item on every screen that shows it. A screen's confirming action is a full-width button below the content.
95. "Reviews" and "Earlier days" appear only when they have something to show. "New worksheet" sits above an empty "Worksheets" list, with no text.
96. After "Get it back", onboarding screen 4 stays, with a status line and "Start" disabled, until the import completes or fails.
97. The agent writes draft bodies for the stage 1 and 2 cards under the Draft flag. The clinical reviewer replaces them.
98. The App Store subtitle is "12-week binge eating programme". The long sentence is the first line of the description.
99. One human bead confirms the legal entity, the organisation account, the support domain, the support page and the Contact email. mm-t43.17 waits for it.
100. The stage 7 lapse card is the one card that appears in the same record day as the starred entry.
101. One clinical walk of the after-binge paths occurs before the launch build.
102. In the first TestFlight cut, the rows of stages 3 to 7 show a neutral "Comes in a later version", with no marker and no tap.
103. The weigh-in screen hides the chart while no weigh-in day exists. The weigh-ins stay for the export and for a later opt-in.
104. "Add" on a planned meal reminder sets the entry time to now. "Add it" keeps the planned time.
105. Every reminder plays the system default sound.

## Decisions Ash made on 25 September 2026, after the simulator checks of the skeleton

106. Cancel and Save stay in the navigation bar of the new-entry and edit screens, and VoiceOver reads them before the content. Focus moves to What when the screen opens. "Delete entry" stays last on the edit screen.

## Decision Ash made on 25 September 2026, on the question round 10 opened

107. When a first import succeeds after a failed one, the restored record wins: the app writes the imported profile and settings again, so the restored start day wins. The entries from both periods stay.

Ash closed mm-t10 with a draft of the skeleton's shame walk from simulator screenshots, in place of a walk on the built app. The walk in mm-t12b.1 is the first by a person.

## Assumptions the specs make where the PRD is silent

Each spec lists its own under its Purpose or in the writer's report. The design lists the ones that shape the data model.
