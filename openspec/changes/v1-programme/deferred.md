# Deferred from the first TestFlight cut

Ash chose the first cut on 25 September 2026. A row here is a requirement the first cut does not build. The spec keeps the requirement. A first-cut build change's tasks map each such scenario to `deferred: deferred.md#<requirement>`. When the team archives the owning change, it moves those rows to that change's README. Each row has a remainder bead under its owning change.

| Spec | Requirement | First-cut behaviour | Owning build change |
| --- | --- | --- | --- |
| data-and-privacy | Sync is off until the person chooses it, and every sync, account, restore and Erasure requirement | Onboarding offers "This device only" as the one choice with "iCloud sync comes in a later version." | 4.1b sync |
| data-and-privacy | Every install has one device row; Devices with your record | Not shown | 4.1b sync |
| widgets-and-intents | every requirement | Entry points are the app only; no widget, intent, control or snapshot; the action queue and the handlers are 2.4 work | 2.5 widgets-and-intents |
| app-lock | A new entry before authentication: the widget, intent and control scenarios | Vacuous until 2.5; the four notification-action scenarios are first-cut work with 2.4 | 2.5 widgets-and-intents |
| reminders | Worksheet review and Check-in reminder types; the background refresh task | Not scheduled | 3.3 problem-solving, 3.6 staying-on-track |
| reminders | Time Sensitive is opt-in | The switch is absent; the entitlement waits | 2.5 widgets-and-intents |
| regular-eating-plan | The "That was it" form of the missed planned meal prompt and its later-window rule | Two forms only: "Skipped" and "Add it" | 3.3 problem-solving |
| programme | The seven stages and their tools: stages 3 to 7 | Rows show their opening rule; no tool opens beyond stage 2 | 3.1 to 3.6 |
| programme | A gate change never closes a stage; the clock guards | Constants do not change during the first cohort | 3.6 staying-on-track |
| content | Cards for stages 3 to 7 | Only stage 1 and 2 cards in the bundle; the content version is 1 | 3.1 to 3.6 |
| urge-toolkit | every requirement | The Urge button is absent | 3.1 urge-toolkit |
| problem-solving | every requirement | Absent | 3.3 problem-solving |
| weekly-review | Taking stock and the questionnaire | The review of week 6 is a plain review | 3.2b taking-stock, with 3.4 and 3.5 |
| dieting-module | every requirement | Absent | 3.4 food-rules |
| body-image-module | every requirement | Absent | 3.5 body-image-module |
| staying-on-track | every requirement | Absent. "Start week 1 again" is a `programme` requirement and stays in the first cut | 3.6 staying-on-track |
| onboarding | Restore before onboarding | Skipped; no CloudKit read | 4.1b sync |
| settings | The Reminders group, the Record group and the Privacy group: the switches, links and controls of deferred features | Absent until the owning change adds each control | 2.5, 3.3, 3.4, 3.5, 3.6, 4.1b |
| safeguarding | Re-screening at a restart: "Restart from a check-in" | The restart control re-screens; no check-in exists | 3.6 staying-on-track |
| data-and-privacy | Delete-all: the erasure marker, the zone deletion and "Delete everything offline" | Local deletion only | 4.1b sync |
| data-and-privacy | Release gates and the App Store submission: the demo video, the background modes and their review-notes lines | Not part of the first TestFlight build | 4.3 second part |
| content | Every bundled string family has ids: the families later changes own | Absent from the bundle | 3.1 to 3.6 |
